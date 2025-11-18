# Load the required library for importing and manipulating GTF files
library(rtracklayer)

# Import GTF files for different transcriptomes
bart <- import("BaRTv2.gtf")
hvmx <- import("hvmx.gtf")
pan <- import("PanBaRT20.gtf")

# Filter to include only exons from each imported transcriptome
bart <- bart[bart$type == 'exon']
hvmx <- hvmx[hvmx$type == 'exon']
pan <- pan[pan$type == 'exon']

# Add a new column to store transcript IDs as source_trans for bart and hvmx
hvmx$source_trans <- hvmx$transcript_id
bart$source_trans <- bart$transcript_id

# Combine all filtered transcriptomes into a list
rtd0 <- list(bart = bart, hvmx = hvmx, pan = pan)

# Extract each transcriptome from the list (unpacking them back to separate variables)
bart <- rtd0$bart
hvmx <- rtd0$hvmx
pan <- rtd0$pan

# Concatenate all transcriptomes and sort them by sequence name, start, and end position
gr <- c(bart, hvmx, pan)
gr <- sort(gr, by = ~seqnames + start + end)

###---> Merge redundant transcripts

# Identify and reduce mono-exon transcripts
mono <- getMonoExonTrans(gr)
mono_trans <- reduce(mono)
mono_trans$transcript_id <- paste0('mono_trans', 1:NROW(mono_trans))

# Map original transcripts to the reduced mono-exon transcripts
hits <- findOverlaps(mono, mono_trans, type = 'within')
mapping <- data.frame(transcript_id = mono_trans$transcript_id[hits@to],
                      transcript_id0 = mono$transcript_id[hits@from])
mapping <- unique(mapping)

# Combine original transcript IDs for each merged transcript
transcript_id0 <- split(mapping$transcript_id0, mapping$transcript_id)
transcript_id0 <- sapply(transcript_id0, function(x) paste0(x, collapse = ','))

# Add metadata for the reduced mono-exon transcripts
mono_trans$transcript_id0 <- transcript_id0[mono_trans$transcript_id]
mono_trans$type <- 'exon'
mono_trans$gene_id <- mono_trans$transcript_id 

# Process multi-exon transcripts, obtain intron chains and merge
multi <- getMultiExonTrans(gr)
sj <- getIntronChain(multi)
multi$intron_chain <- sj[multi$transcript_id]

mapping <- data.frame(transcript_id = multi$transcript_id, intron_chain = multi$intron_chain)
mapping <- unique(mapping)

# Create groups by intron chain and reduce them to avoid redundancy
intron_chain <- split(mapping$transcript_id, mapping$intron_chain)
intron_chain <- sapply(intron_chain, function(x) paste0(x, collapse = ','))
multi_split <- split(multi, multi$intron_chain)
multi_split <- reduce(multi_split)

# Create metadata for the reduced multi-exon transcripts
multi_trans <- unlist(multi_split)
multi_trans$transcript_id <- names(multi_trans)
multi_trans$transcript_id0 <- intron_chain[names(multi_trans)]
names(multi_trans) <- NULL
multi_trans$type <- 'exon'
multi_trans$gene_id <- multi_trans$transcript_id 

########################
###---> Merge mono-exon and multi-exon transcripts

# Add notes to distinguish mono-exon and multi-exon transcripts
mono_trans$note <- 'mono_exon'
multi_trans$note <- 'multi_exon'

# Concatenate the mono and multi-exon transcripts and sort them
gr1 <- c(mono_trans, multi_trans)
gr1 <- sort(gr1, by = ~seqnames + start + end)

########################
###---> Assign the same gene ID to overlapped transcripts

# Reduce ranges to represent gene loci and sort them
loci <- reduce(getGeneRange(gr1))
loci <- sort(loci, by = ~seqnames + start + end)
loci$loci_id <- paste0('gene', 1:NROW(loci))

# Assign gene IDs to transcripts that overlap with the same loci
hits <- findOverlaps(gr1, loci)
gr1$gene_id[hits@from] <- loci$loci_id[hits@to]

# Remove unnecessary columns and add new placeholders
gr1$source <- NA
gr1$exon_id <- NULL
gr1$exon_number <- NULL

#########################################
###---> Identify intronic genes

# Identify and annotate intronic genes
intronic <- getIntronicGene(gr1)
mapping <- data.frame(transcript_id = intronic$transcript_id, gene_id = intronic$gene_id)
mapping <- unique(mapping)
rownames(mapping) <- mapping$transcript_id

# Update gene and note information for intronic transcripts
idx <- which(gr1$transcript_id %in% mapping$transcript_id)
gr1$note[idx] <- paste0(gr1$note[idx], ',intronic')
gr1$gene_id[idx] <- paste0(gr1$gene_id[idx], '_', mapping[gr1$transcript_id[idx], 'gene_id'])

#########################################
###---> Identify chimeric genes

# Identify overlapping transcripts to define chimeric gene candidates
mapping <- data.frame(transcript_id = gr1$transcript_id, gene_id = gr1$gene_id)
mapping <- unique(mapping)
rownames(mapping) <- mapping$transcript_id

trans_range <- getTransRange(gr1)
trans_range$gene_id <- mapping[trans_range$transcript_id, 'gene_id']

# Find overlapping transcript pairs that potentially form chimeric structures
hits <- findOverlaps(query = trans_range, subject = trans_range)
idx <- which(queryHits(hits) != subjectHits(hits))
hits <- hits[idx,]

g1 <- trans_range[queryHits(hits)]
g2 <- trans_range[subjectHits(hits)]

# Define tolerance for identifying chimeric overlaps
chimeric_tolerance <- 0.05
overlaps <- pintersect(g1, g2)
p1 <- width(overlaps) / width(g1)
p2 <- width(overlaps) / width(g2)

# Filter overlaps that meet the chimeric tolerance criteria
idx <- which(p1 < chimeric_tolerance & p2 < chimeric_tolerance)
overlaps_pass <- overlaps[idx]
overlaps_pass$from <- g1$transcript_id[idx]
overlaps_pass$to <- g2$transcript_id[idx]
overlaps_pass$transcript_id <- NULL
overlaps_pass$hit <- NULL

# Rename genes for consistency and update gene ranges
trans <- c(overlaps_pass$from, overlaps_pass$to)
trans_range_uncut <- trans_range[!(trans_range$transcript_id %in% trans)]
trans_range_cut <- trans_range[trans]
trans_range_cut <- psetdiff(x = trans_range_cut, y = c(overlaps_pass, overlaps_pass))
trans_range_cut$transcript_id <- names(trans_range_cut)
trans_range_cut <- trans_range_cut[!duplicated(trans_range_cut$transcript_id)]

trans_range_cut$gene_id <- mapping[trans_range_cut$transcript_id, 'gene_id']

trans_range_shrink <- c(trans_range_uncut, trans_range_cut)
trans_range_shrink <- sort(trans_range_shrink, by = ~seqnames + start + end)
loci_shrink <- getOverlapRange(trans_range_shrink)

# Rename genes and update final gene identifiers
hits <- findOverlaps(query = trans_range_shrink, subject = loci_shrink)
mapping <- data.frame(trans = trans_range_shrink[queryHits(hits)]$transcript_id,
                      new_gene = loci_shrink[subjectHits(hits)]$gene_id)
mapping <- unique(mapping)
rownames(mapping) <- mapping$trans

gr2 <- gr1
gr2$gene_id <- mapping[gr2$transcript_id, 'new_gene']

# Annotate intronic transcripts in the updated dataset
mapping <- data.frame(transcript_id = intronic$transcript_id, gene_id = intronic$gene_id)
mapping <- unique(mapping)
rownames(mapping) <- mapping$transcript_id

idx <- which(gr2$transcript_id %in% mapping$transcript_id)
gr2$note[idx] <- paste0(gr2$note[idx], ',intronic')
gr2$gene_id[idx] <- paste0(gr2$gene_id[idx], '_', mapping[gr2$transcript_id[idx], 'gene_id'])
gr2 <- sort(gr2, by = ~seqnames + start + end)

#####################
###---> Rename genes and transcripts

# Assign new gene names using a consistent naming pattern
mapping <- data.frame(seqnames = as.character(seqnames(gr2)), gene_id = gr2$gene_id)
mapping <- unique(mapping)

n <- 1:nrow(mapping)
n <- stringr::str_pad(string = n, width = 6, pad = '0')
mapping$gene_name <- paste0('EoRNA2_', mapping$seqnames, n)
rown

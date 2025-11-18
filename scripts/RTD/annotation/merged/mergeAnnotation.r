
#the input data files
trapid="../trapid/combinedOutput/EORNA2_RTD_combinedAnnotation_TRAPID_10Oct2024.txt"
ahrd="../AHRD/ahrd_output.tsv"
pannzer="../pannzer/output/EORNA2_RTD.transcriptAnno.txt"
proteinLengths="proteinLengths.txt"

##########################################
#read all the input files
message("read in trapid annotation")
trapid_df <- read.delim(trapid, header = TRUE)
colnames(trapid_df) <- c("transcript","GO_trapid","Interpro_trapid","queryLength_trapid","hit_trapid","lengthInfo_trapid","meta_trapid")
str(trapid_df)

message("read in protein lengths")
proteinLengths_df <- read.delim(proteinLengths,header = FALSE)
colnames(proteinLengths_df) <- c("transcript", "protein_length")
str(proteinLengths_df)

message("read in ahrd annotation")
ahrd_df <- read.delim(ahrd,header = FALSE)
colnames(ahrd_df) <- c("transcript", "hit_ahrd","description_ahrd")
str(ahrd_df)

message("read in pannzer annotation")
pannzer_df <- read.delim(pannzer, header = FALSE)
colnames(pannzer_df) <- c("transcript", "description_pannzer", "GO_ID_pannzer", "GO_terms_pannzer")
str(pannzer_df)

##########################################
#merge the data -- in steps

message("merge by transcript - step 1")
mergedDF1 <- merge(trapid_df, proteinLengths_df, by="transcript", all.x = TRUE)

message("merge by transcript - step 2")
mergedDF2 <- merge(mergedDF1, ahrd_df, by="transcript", all.x = TRUE)

message("merge by transcript - step 3")
mergedDF3 <- merge(mergedDF2, pannzer_df, by="transcript", all.x = TRUE)

message("output to file")
write.table(mergedDF3,file="EORNA2_RTD_mergedAnnotation_10Oct2024.txt",row.names = F,col.names = T,quote = F,sep='\t')

message("done")
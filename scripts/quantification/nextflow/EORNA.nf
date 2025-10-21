
/*
* Formats a string with one or more NCBI taxon identifiers so that it can be used as part of the project query against the REST API at the European Nucleoide Archive (ENA); takes as input a list of NCBI taxon IDs from file, one per line, to allow for complex taxonomy; expects in the base directory a file named NCBI_taxIDs.txt (example provided)
*/
process makeTaxonIDString {

    input:
    path taxonIDFile

    output:
    path "NCBI_taxIDs_formatted.txt"

    script:
    """
    awk 'NR==1 {printf "tax_eq(%s", \$0} NR>1 {printf ")%%20OR%%20tax_eq(%s", \$0} END {print ")"}' $taxonIDFile > NCBI_taxIDs_formatted.txt

    """
}

/*
*Formats a list of metadata field names so that it can be used as part of the run accession query against the REST API at the European Nucleoide Archive (ENA); takes as input a list of filed names from file, one per line; expects in the base directory a file named metadataFields.txt (provided)
*/
process makeMetadataFieldString {

    input:
    path metadataFieldsFile

    output:
    path "metadataFields_formatted.txt"

    script:
    """
    awk 'NR==1 {printf "%s", \$0} NR>1 {printf "%%2C%s", \$0} END {print ""}' $metadataFieldsFile > metadataFields_formatted.txt

    """
}

/*
*Executes the project query against the REST API at the European Nucleoide Archive (ENA); this returns a list of study/project accession identifiers (e.g. PRJNA974380)
*/
process executeProjectQuery {

    publishDir "results", mode: 'copy'

    input:
    path "NCBI_taxIDs_formatted.txt"
    
    output:
    path "listOfProjectAccessions.txt"

    script:
    """
    taxonIDString=`cat NCBI_taxIDs_formatted.txt`

    echo "retrieving study accessions"
    echo "using taxonIDString \$taxonIDString"

    curl \
    -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "result=read_study&query=\$taxonIDString%20AND%20library_layout%3D%22PAIRED%22%20AND%20instrument_platform%3D%22ILLUMINA%22%20AND%20library_source%3D%22TRANSCRIPTOMIC%22%20AND%20library_strategy%3D%22RNA-Seq%22&format=tsv" \
    "https://www.ebi.ac.uk/ena/portal/api/search" \
    | tail -n +2 \
    | cut -f 1,3 | sort | uniq \
    > allProjects.txt \
    2>curl_log.txt

    #extract from this file the list of accession numbers, minus the header
    cut -f 1 \
    allProjects.txt \
    | awk 'NF' \
    > listOfProjectAccessions.txt
    #the awk command removes empty lines

    echo "number of study accessions retrieved:"
    wc -l listOfProjectAccessions.txt | cut -f 1 -d " "

    """
}

/*
*Iterates over the list of project accessions and for each of these retrieves a list of all of the project's run accessions. Adds this to a combined metadata file which gets published in the results directory ("combinedMetadataFile.txt").
*/
process executeRunQueries{

    publishDir "results", mode: 'copy'

    input:
    path('NCBI_taxIDs_formatted.txt')
    path('metadataFields_formatted.txt')
    path('listOfProjectAccessions.txt')
    path metadataFieldsFile

    output:
    tuple path("combinedMetadataFile.txt"),path("allRunAccessions.txt"), path("accessionLookup.txt")

    script:
    """
    #!/bin/bash

    echo "run executeRunQueries"

    taxonIDString=`cat NCBI_taxIDs_formatted.txt`
    metadataFieldString=`cat metadataFields_formatted.txt`

    #read the file with the project accessions line by line
    while read projectAccession
    do
        echo "process project accession \$projectAccession"

        curl \
        -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "result=read_run&query=\$taxonIDString%20AND%20instrument_platform%3D%22ILLUMINA%22%20AND%20library_layout%3D%22PAIRED%22%20AND%20library_strategy%3D%22RNA-Seq%22%20AND%20study_accession%3D%22\$projectAccession%22&format=tsv&fields=\$metadataFieldString" \
        "https://www.ebi.ac.uk/ena/portal/api/search" \
        | tail -n +2 \
        >> combinedMetadataFile.txt

    done < listOfProjectAccessions.txt

    # this conditional gives us the opportunity to limit the number of run accessions processed for testing before setting off a large run
    # params.test_maxNumRuns is configured in nextflow.config 
    # if it is set to zero, we process all run accessions 
    if [ $params.test_maxNumRuns -eq 0 ]
    then
        echo "processing all run accessions"
        #extract the list of run accession IDs so we can easily use this for downtream processing
        cut -f1 combinedMetadataFile.txt \
        > allRunAccessions.txt

        #also extract a lookup table that maps run accession IDs to their parent project IDs
        cut -f1,100 combinedMetadataFile.txt \
        > accessionLookup.txt
    #this is what we do if we want to restrict run numbers for testing
    else
        echo "processing only subset of run accessions for testing -- n = $params.test_maxNumRuns"
        cut -f1 combinedMetadataFile.txt \
        | tail -n $params.test_maxNumRuns \
        > allRunAccessions.txt

        cut -f1,100 combinedMetadataFile.txt \
        | tail -n $params.test_maxNumRuns \
        > accessionLookup.txt
    fi
    
    echo "add a header to the metadata file - use the file with the metadata fields for this"
    cat $metadataFieldsFile | tr '\n' '\t' > header.txt
    # add newline char
    echo >> header.txt
    cat header.txt combinedMetadataFile.txt > tmp.txt
    mv tmp.txt combinedMetadataFile.txt
    rm header.txt

    """
}

/*
*Downloads from ENA the raw RNA-SeQ read files for a single run accession, given its ID and metadata which are provided in the combined metadata file.
*/
process downloadRunAccession {

    input:
    tuple val(runAccession),val(projectAccession), path(metadata_file)

    output:
    tuple path("${runAccession}_1.fastq.gz"), path("${runAccession}_2.fastq.gz"),val(runAccession),val(projectAccession)

    script:
    """

    # this code ensures that download retries from server failure are not executed immediately, so the server gets at least some time to recover as some server failures are short-lived (e.g. due to high demand)
    if [[ $task.attempt -gt 1 ]]
    then
        echo "Retry -- attempt $task.attempt — sleeping for 60 seconds..."
        sleep 60
    fi

    echo "Downloading data for run acession $runAccession"
    echo "projectAccession = $projectAccession" 
 
    #extract the URLs of the files for ftp from the combined metadata file
    fastq_ftp=`grep $runAccession $metadata_file | cut -f 2`

    #the ftp string is split with a ";" for paired end files
    IFS=\$";"
    #turn the string into an array
    ftpFiles=(\$fastq_ftp)

    # here we need a check for the correct number of URLs
    # we are currently only accepting paired end files, so this number is 2
    # any deviation and we need to fail the job
    if [ \${#ftpFiles[@]} -ne 2 ]
    then
        echo "Error: number of download URLs is not 2 -- found \${#ftpFiles[@]} URLs"
        exit 11
    else
        echo "correct number of download URLs found (n = 2)"
    fi

    echo "ftp paths found:"
    echo \${ftpFiles[0]}
    echo \${ftpFiles[1]}

    echo "download the R1 file"
    wget \${ftpFiles[0]}

    echo "download the R2 file"
    wget \${ftpFiles[1]}

    echo "download complete for run accession $runAccession"

    echo "check md5 sums"
    #extract the files' MD5 checksums from the metadata file
    md5sumsBoth=`grep $runAccession $metadata_file | cut -f 3`
    #the string is split with a ";" for paired end files
    IFS=\$';'
    #turn the string into an array
    md5sums=(\$md5sumsBoth)
    echo "md5 sums from metadata:"
    echo \${md5sums[0]}
    echo \${md5sums[1]}

    echo "compute actual MD5s"
    md5DownloadedR1=`md5sum ${runAccession}_1.fastq.gz | cut -f 1 -d " "`
    md5DownloadedR2=`md5sum ${runAccession}_2.fastq.gz | cut -f 1 -d " "`

    echo "md5 sums from downloaded files:"
    echo \$md5DownloadedR1
    echo \$md5DownloadedR2

    # Compare checksums
    #if they don't match up for both files, the process has to be terminated with an non-zero exit code so the job is recognised as failed
    if [[ "\$md5DownloadedR1" != "\${md5sums[0]}" ]]
    then
        echo "Checksum mismatch for ${runAccession}_1.fastq.gz"
        exit 22
    fi

    if [[ "\$md5DownloadedR2" != "\${md5sums[1]}" ]]
    then
        echo "Checksum mismatch for ${runAccession}_2.fastq.gz"
        exit 22
    fi

    echo "md5 check complete for run accession $runAccession"

    """
}

/*
* Trims a pair of FASTQ format read files using the tool fastp (end trimming, adapter trimming).
*/
process trimReads{

    container 'quay.io/biocontainers/fastp:0.26.0--heae3180_0'

    input:
    tuple path(read1), path(read2), val(runAccession),val(projectAccession)    

    output:
    tuple path("${runAccession}.trimmed.1.fastq.gz"), path("${runAccession}.trimmed.2.fastq.gz"), val(runAccession), val(projectAccession) 

    script:
    """
    echo "Trimming $read1 and $read2 with fastp"
    echo "runAccession = $runAccession"
    echo "projectAccession = $projectAccession"

	fastp \
	-i ${read1} \
	-I ${read2} \
	-o "${runAccession}.trimmed.1.fastq.gz" \
	-O "${runAccession}.trimmed.2.fastq.gz" \
	--html "${runAccession}.html" \
	--json "${runAccession}.json" \
	-q 20 \
	--cut_front \
	--cut_tail \
	--trim_poly_g \
	-l 30 \
	--detect_adapter_for_pe \
    --thread $task.cpus
    
    echo "fastp run complete"
     
    """
}

/*
*Builds a salmon index for a FASTA file with the reference transcriptome for our chosen species. Required for the actual quantification step with Salmon.
*/
process buildSalmonIndex {
 
    container 'quay.io/biocontainers/salmon:1.10.3--h45fbf2d_5'

    publishDir "results", mode: 'copy'

    input:
    path transcriptome

    output:
    path 'index'

    script:
    """
    echo "building salmon index"

    echo "salmon path:"
    which salmon

    salmon index --threads $task.cpus -t $transcriptome -i index

    echo "done building salmon index"

    """
}

/*
* Runs the actual quantification of gene expression for a single run accession, given a pair of quality-trimmed read files and the ID of the accession. 
*/
process quantify{
    
    container 'quay.io/biocontainers/salmon:1.10.3--h45fbf2d_5'

    publishDir "results/${projectAccession}/${runAccession}", mode: 'copy', overwrite: false

    input:
    path index
    tuple path(read1), path(read2), val(runAccession), val(projectAccession) 

    output:
    path 'quant.sf'

    script:
    """
    echo "quantify with salmon"

    salmon quant \
	-i $index \
	-l A \
	-1 $read1 \
	-2 $read2 \
	--threads $task.cpus \
	--seqBias \
	--gcBias \
	--posBias \
	--validateMappings \
	-o . 

    echo "salmon run complete"

    #emit a small file for tracking job completion
    echo "done" > ${runAccession}.done

    """
}


workflow {

    // parse the input file with the NCBI taxon ID(s) and format these for use in the query string
    makeTaxonIDString(Channel.fromPath('NCBI_taxIDs.txt'))

   // run the first query against the ENA REST API
    //this returns a list containing IDs of all relevant ENA project accessions
    executeProjectQuery(makeTaxonIDString.out)

    // parse the input file with the metadata fields we want returned, and format these for use in the query string
    makeMetadataFieldString(Channel.fromPath('metadataFields.txt'))

    // run the second query against the ENA REST API 
    // this is executed as a loop in bash for each project accession returned by the first query and returns for each project a list of its run accessions and associated metadata
    executeRunQueries(makeTaxonIDString.out,makeMetadataFieldString.out,executeProjectQuery.out, Channel.fromPath('metadataFields.txt'))

    // convert the lookup table (run->project) into a channel of tuples
    executeRunQueries.out.map{ it[2] }
        .splitCsv(sep: '\t')
        .map { row -> tuple(row[0], row[1]) }
        .set { kvTuples }

    //we need to make an input channel containing the metadata file only so we can use this downstream
    combinedMetadataFile_ch = executeRunQueries.out.map { it[0] }

    // Combine each run/project ID tuple with the metadata file
    paired_ch = kvTuples.combine(combinedMetadataFile_ch.map { file -> tuple(file) })

    // Invoke downloadRunAccession with both inputs
    downloadRunAccession(paired_ch)

    //trim the read pairs with fastp
    trimReads(downloadRunAccession.out)

    //this builds the required index files for salmon
    buildSalmonIndex(params.transcriptome)

    //run the actual quantification step with salmon
    quantify(buildSalmonIndex.out, trimReads.out)

}
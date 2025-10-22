# EORNA quantification workflow

This workflow features all the steps required to discover, download and quantify a set of paired end RNA-Seq files from the [European Nucleotide Archive (ENA)](https://www.ebi.ac.uk/ena/browser/home). 

It has been implemented as a single Nextflow file (EORNA.sf). Detailed information and training materials for the Nextflow workflow management system are available from the [main Nextflow website](https://www.nextflow.io/).

The ENA mirrors all short read data from the other [INSDC](https://www.insdc.org/) partners, NCBI and DDBJ, and so a query to any one of the three repositories will result in the same set of accessions. We chose the ENA for this workflow as it features the most comprehensive API for programmatic queries. 

The steps in the workflow are as follows:

1.	Given one or more NCBI taxon identifiers, send a programmatic query to the ENA’s REST API to retrieve a list of all project accessions that contain paired end RNA-Seq for our species of interest. 
2.	For each of the projects retrieved, send another programmatic query to the ENA’s REST API which retrieves a list of that project’s run accessions and their metadata. Add these to a combined metadata file. 
3.	For each run accession, download the raw FASTQ files from the ENA, given the URLs in its metadata. 
4.	For each pair of downloaded FASTQ files, remove poor quality bases and adapter sequences from the reads using the tool [fastp](https://github.com/OpenGene/fastp). This also produces a QC report. 
5.	For each pair of trimmed read files, conduct gene expression quantification using the tool [salmon](https://combine-lab.github.io/salmon/).

 ![Figure 1: workflow schema](/images/EORNA_nextflow.png)

The output data is deposited in a folder named “results”, in the working directory where the script has been executed. It is organised into top level directories which are named after project accessions, and subdirectories which are named after each project’s run accessions. Each run accession folder contains a file named “quant.sf”, the output of Salmon’s quantification step. The “results” folder also contains a file named “combinedMetadataFile.txt” which contains the metadata for all run accessions that have been discovered. 

Downloaded and trimmed data isn’t copied into the results folder – it only exists in the “work” folder which should be deleted after the run to free up disk space. The “work” folder contains Nextflow’s primary output and can grow to a substantial size very quickly. 

## Instructions for use

1.	Install Nextflow as per the instructions at [https://www.nextflow.io/](https://www.nextflow.io/). 
2.	Clone the EORNA repository. 
3.	Place file EORNA.nf (the main workflow script ) from scripts/quantification/nextflow into your working directory along with files nextflow.config, run-NF.sh, metadataFields.txt and NCBI_taxIDs.txt  (all from the same repo folder). 
4.	Edit NCBI_taxIDs.txt to contain one or more (one per line) NCBI taxon identifiers for the taxon/taxa you would like to find RNA-Seq for. These are simple integer numbers which can be looked up by searching for a scientific species name on the [NCBI website](https://www.ncbi.nlm.nih.gov/guide/taxonomy/). 
5.	Leave the metadataFields.txt file as it is – this is needed for formatting the programmatic query strings. 
6.	Place a FASTA file with reference transcripts of your species of interest into the working directory. This will be used for quantification of the RNA-Seq reads with Salmon. The required Salmon index will be built automatically from the FASTA file as part of the workflow.
7.	Modify the “transcriptome” parameter in the “params” section of nextflow.config to reflect the name of your FASTA file with the reference transcripts.
8.	If necessary, change the executor name in nextflow.config from “slurm” as appropriate (e.g. to “PBS” or whatever scheduling system you are using). 
9.	We have included a shell script wrapper, run-NF.sh, for submission of the actual Nextflow job to Slurm. Assuming Slurm is the executor, submit this script to Slurm with “sbatch” as normal. Once the script is submitted, Nextflow will spawn its process instances, each of which becomes a Slurm job itself. You will need to adapt this script as appropriate if your local scheduling system isn’t Slurm. 
10. It is advisable to run a small number of samples initially to ensure that the workflow executes correctly with the species of interest and the execution environment chosen. To this end the nextflow.config file contains the parameter "params.test_maxNumRuns", which is set to zero if all runs are to be processed but can be set to any positive integer number to limit the number of runs for testing.

## Software dependencies

Software required for individual processes is sourced at runtime by Nextflow itself, so users don’t need to install any software dependencies manually. We have opted for [Biocontainers](https://biocontainers-edu.readthedocs.io/en/latest/), the most lightweight solution, which means that Docker images of each tool are downloaded for workflow execution as required. In our config file we have assumed that the system where the code is executed supports Singularity, but this too is a modifiable parameter and can be changed to e.g. Docker or conda (if in doubt, contact your systems administrator):
```
singularity {
  enabled = true
}
```
The software itself is specified as part of individual process declarations in EORNA.nf, for example:
```
container 'quay.io/biocontainers/fastp:0.26.0--heae3180_0'
```

## Tuning of compute resource parameters

The error strategy chosen for the downloadRunAccession, trimReads and quantify processes is 'retry', which means if a job fails (e.g. due to resource limitations like insufficient memory), Nextflow will automatically rerun it. To account for out-of-memory (OOM) errors, it will increase the amount of memory requested with each attempt, using a formula such as “memory = { 2.GB * task.attempt }“, where 2.GB would be the amount of memory requested in the first instance. If you encounter issues of jobs still failing with OOM errors after the allotted retries, you will need to increase the initial amount of memory for the process in question. This is done by editing nextflow.config where parameters for individual processes are listed like in this example:
```
  withName: 'downloadRunAccession' {
    maxForks = 5
    errorStrategy = 'retry'
    maxRetries = 3
    memory = { 500.MB * task.attempt }
    cpus = 1
  }
```
In the case of the downloadRunAccession process we also have a parameter that limits the number of concurrently running instances for this process to five (maxForks = 5). This is meant to avoid bandwidth saturation of your network connection but if this is limiting and bandwidth isn’t an issue locally then this value can be increased. 

There is also a parameter in nextflow.config which limits the overall number of running jobs and which is currently set to 30:
```
executor {
    name = 'slurm'
    queueSize = 30
}
```
Again, this can be changed depending on the local setup. 

## Reporting

A trace file will be written to the working directory (“trace-\<timestamp\>-\<ID\>.txt”). This contains useful details about each of the process instances executed, such as the time submitted, the exit code and status, and compute resources consumed. 
A similar report is produced in the working directory in HTML format which includes interactive plots showing resource consumption and details about each process instance executed (“report.html”). 

## Troubleshooting

Nextflow organises the scripts, outputs and logs from each process instance into a separate folder located in the “work” folder. These are listed in the trace file (see above). The folder is named after the hash value in column 2 of the trace (this is abbreviated but the folder will be identifiable from this). The main log output in this folder is named “.command.log” and will contain both the stdout and stderr streams of the process. This should be the first port of call for troubleshooting any process-related problems. 
Error codes are emitted from individual process instances and are listed in the trace file (column 6). In most cases, these will be an immediate indication of the problem encountered:

| error code | cause of failure |
|------------|------------------|
| 11 | wrong number of FASTQ download URLs in metadata from ENA |
| 22 | one or both FASTQ files failed md5 checksum test |
| 137 | out of memory (OOM) |
| no error code | out of memory (OOM) or other cause (-> check log) |


## Resuming runs

Nextflow offers a command line option for resuming workflow runs if some processes have failed, for example due to temporary server outages or out-of-memory conditions. Transient errors such as running out of memory can be fixed by adjusting parameters in nextflow.config. The workflow can then be resumed by adding the “-resume” flag to the “nextflow run” command in the batch file for submission to the scheduling system (run-NF.sh). 

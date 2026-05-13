# EORNA v.2

We have released a major new version of the EORNA database, a gene expression database for barley based on public data (https://ics.hutton.ac.uk/eorna2/index.html). EORNA v.2 features an order of magnitude more samples than the previous version and is based on an automated workflow of sample discovery and processing which has enabled a major scale-up of the original database. EORNA v.2 features a total of 171 studies comprising 6,285 sample accessions. This represents the full complement of paired-end Illumina RNA-Seq from barley in the European Nucleotide Archive (ENA) (https://www.ebi.ac.uk/ena/browser/home) as of May 2024.

Discovering appropriate samples and generating the quantifications required a high degree of workflow automation. To this end we have developed a Nextflow workflow which uses the REST API at the European Nucleotide Archive (ENA) for the purpose of both study and sequencing run discovery (https://ena-docs.readthedocs.io/en/latest/retrieval/programmatic-access.html). The workflow and associated documentation can be found under scripts/quantification/nextflow. The workflow is generic and can be applied to any species with a few simple configuration steps. 

We have also automated the process of setting up a database and web frontend for the quantification data so that anyone can spin up their own instance of EORNA for their species of choice. However, the scripts and Docker image for this were too large for inclusion here and are instead provided at https://doi.org/10.5281/zenodo.18956827.

The quantification data and underlying reference transcriptome are available from Zenodo at https://zenodo.org/records/18466205. 

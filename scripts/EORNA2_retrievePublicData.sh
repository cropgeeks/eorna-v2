#!/bin/bash

#SBATCH -o slurm-%x_%A.out
#SBATCH --cpus-per-task=8
#SBATCH --mem=15G
#SBATCH --partition=long


##########################################################################
#Script for the automated retrieval and quantification of barley RNAseq accessions from the ENA (European Nucleotide Archive)
#@author Micha Bayer, James Hutton Institute, September 2021
##########################################################################


##########################################################################
#Variables
##########################################################################
#full path to the folder with the index files for Salmon - contains the RTD (reference transcript dataset)
salmonIndex=$1

#the URL at EBI for posting all API based queries - hosts the REST service
URL="https://www.ebi.ac.uk/ena/portal/api/search"

#===========================================

#check for the correct number of args
if [ $# -ne 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0  <path to Salmon index> "
    exit
fi


##########################################################################
# STEP 1: Retrieve barley RNAseq study accessions from the ENA
##########################################################################
#The following search query retrieves all barley projects with RNAseq and returns their study accession numbers in tab delimited format
echo "retrieving study accessions"
curl \
-X POST \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "result=read_study&query=tax_eq(112509)%20AND%20instrument_platform%3D%22ILLUMINA%22%20AND%20library_strategy%3D%22RNA-Seq%22&format=tsv" \
$URL \
> allBarleyRNAseqStudies.txt \
2>curl_log.txt

#extract from this file the list of accession numbers, minus the header
cut -f 1 \
allBarleyRNAseqStudies.txt \
| tail -n +2 \
> listOfStudyAccessions.txt

echo "number of study accessions retrieved:"
wc -l listOfStudyAccessions.txt | cut -f 1 -d " "


##########################################################################
# STEP 2: Check against existing study accessions in EORNA database

#In the final workflow we need to query the EORNA database for a list of existing study accessions and subtract this from the ENA's current list of study accessions we just retrieved.

#We then proceed with processing these new studies only, rather than the full list like here currently. 
##########################################################################


##########################################################################
# STEP 3: Iterate over all new study accessions
##########################################################################
#this list should only contain new accessions at this point (that we don;t have in the database already)
studyAccessions=`cat listOfStudyAccessions.txt`
for studyAccession in ${studyAccessions[*]}
do
	echo -e "\n\n============================"
	echo -e "processing study $studyAccession"
	
	#make a dedicated dir for each study accession
	mkdir $studyAccession
	cd $studyAccession
	
	#this query retrieves all run accessions and their metadata for a given study accession
	#output is one line per run, which in our case will include both (R1/R2) paired end FASTQ files
	#currently this script is designed to retrieve PE run accessions only
	curl \
	-X POST \
	-H "Content-Type: application/x-www-form-urlencoded" \
	-d "result=read_run&query=instrument_platform%3D%22ILLUMINA%22%20AND%20library_layout%3D%22PAIRED%22%20AND%20study_accession%3D%22PRJNA558196%22&fields=run_accession%2Cfastq_ftp%2Cfastq_md5%2Cfastq_bytes%2Csample_accession%2Csample_collection%2Csample_description%2Csample_material%2Csample_title%2Csampling_site%2Cscientific_name%2Ctissue_type%2Ccultivar%2Caccession%2Caltitude%2Cassembly_quality%2Cassembly_software%2Cbase_count%2Cbinning_software%2Cbio_material%2Cbroker_name%2Ccell_line%2Ccell_type%2Ccenter_name%2Cchecklist%2Ccollected_by%2Ccollection_date%2Ccollection_date_submitted%2Ccompleteness_score%2Ccontamination_score%2Ccountry%2Ccram_index_aspera%2Ccram_index_ftp%2Ccram_index_galaxy%2Cculture_collection%2Cdepth%2Cdescription%2Cdev_stage%2Cecotype%2Celevation%2Cenvironment_biome%2Cenvironment_feature%2Cenvironment_material%2Cenvironmental_package%2Cenvironmental_sample%2Cexperiment_accession%2Cexperiment_alias%2Cexperiment_title%2Cexperimental_factor%2Cfastq_aspera%2Cfastq_galaxy%2Cfirst_created%2Cfirst_public%2Cgermline%2Chost%2Chost_body_site%2Chost_genotype%2Chost_gravidity%2Chost_growth_conditions%2Chost_phenotype%2Chost_sex%2Chost_status%2Chost_tax_id%2Cidentified_by%2Cinstrument_model%2Cinstrument_platform%2Cinvestigation_type%2Cisolate%2Cisolation_source%2Clast_updated%2Clat%2Clibrary_layout%2Clibrary_name%2Clibrary_selection%2Clibrary_source%2Clibrary_strategy%2Clocation%2Clon%2Cmating_type%2Cnominal_length%2Cnominal_sdev%2Cparent_study%2Cph%2Cproject_name%2Cprotocol_label%2Cread_count%2Crun_alias%2Csalinity%2Csample_alias%2Csample_capture_status%2Csampling_campaign%2Csampling_platform%2Csecondary_sample_accession%2Csecondary_study_accession%2Csequencing_method%2Cserotype%2Cserovar%2Csex%2Cspecimen_voucher%2Csra_aspera%2Csra_bytes%2Csra_ftp%2Csra_galaxy%2Csra_md5%2Cstrain%2Cstudy_accession%2Cstudy_alias%2Cstudy_title%2Csub_species%2Csub_strain%2Csubmission_accession%2Csubmission_tool%2Csubmitted_aspera%2Csubmitted_bytes%2Csubmitted_format%2Csubmitted_ftp%2Csubmitted_galaxy%2Csubmitted_host_sex%2Csubmitted_md5%2Csubmitted_sex%2Ctarget_gene%2Ctax_id%2Ctaxonomic_classification%2Ctaxonomic_identity_marker%2Ctemperature%2Ctissue_lib%2Cvariety&format=tsv" \
	$URL \
	> $studyAccession.txt \
	2>$studyAccession.log
	
	##########################################################################
	#iterate over all the run accessions in this study
	##########################################################################

	echo "number of runs in this study:"
	tail -n +2 $studyAccession.txt | wc -l 
	
	#read the file with the run accessions, split it into lines and process each in turn
	#one run accession per line = two paired FASTQ files (PE)
	tail -n +2 $studyAccession.txt | while read line; 
	do
		#parse the line
		#the line is tab delimited
		IFS=$'\t'
		#this handy bit of code turns the line into an array
		tokens=($line)

		runAccession=${tokens[0]}
		echo -e "\nprocessing run accession $runAccession"
		
		#make a dedicated dir for each run accession
		mkdir $runAccession
		cd $runAccession
		
		fastq_ftp=${tokens[1]}
		#the ftp string is split with a ";" for paired end files
		IFS=$';'
		#turn the string into an array
		ftpFiles=($fastq_ftp)
		echo "ftp paths found:"
		echo ${ftpFiles[0]}
		echo ${ftpFiles[1]}
		
		echo "download the FASTQ files"
		R1_file=`basename ${ftpFiles[0]}`
		R2_file=`basename ${ftpFiles[1]}`
		curl ${ftpFiles[0]}	--output $R1_file >> curl.log 2>&1
		curl ${ftpFiles[1]}	--output $R2_file >> curl.log 2>&1
		
		#quality/adapter trim the reads
		echo -e "\nrunning fastp"
		source activate fastp
		fastp \
		-i $R1_file \
		-I $R2_file \
		-o $runAccession.out.R1.fq \
		-O $runAccession.out.R2.fq \
		--html $runAccession.html \
		--json $runAccession.json \
		-q 20 \
		--cut_front \
		--cut_tail \
		--trim_poly_g \
		-l 30 \
		--detect_adapter_for_pe \
		--thread $SLURM_CPUS_PER_TASK 

		conda deactivate


		###########################################################################
		#QUANTIFY
		###########################################################################
		echo -e "\nrunning Salmon"
		salmon quant \
		-i $salmonIndex \
		-l A \
		-1 $runAccession.out.R1.fq \
		-2 $runAccession.out.R2.fq \
		-p $SLURM_CPUS_PER_TASK \
		--seqBias \
		--gcBias \
		--validateMappings \
		-o .

		###########################################################################
		#CLEAN UP
		###########################################################################
		echo -e "\nclean up files"
		rm $runAccession.out.R1.fq
		rm $runAccession.out.R2.fq
		rm $R1_file
		rm $R2_file
		rm $runAccession.json
		#the following are files left behind by Salmon which we don't keep
		rm -rf aux_info
		rm -rf libParams
		rm -rf logs
		rm lib_format_counts.json
		rm cmd_info.json


		###########################################################################
		#TODO:
		#add the Salmon results (or a pointer to the quant.sf file) to the database
		###########################################################################


		#back up one level
		cd ../
		
	done
	
	#back up one level
	cd ../

done

echo "workflow complete"

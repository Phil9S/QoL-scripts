#!/bin/bash

#default output set to home directory of user
OUTPUT="${HOME}/"
#first provided argument is directory of BAM files for analysis
BAM_FOLDER=${1}

#make sure the required arguemnt is provided
if [[ $# -eq 0 ]]; then
	echo -e "## Sex Calculator ## - Input folder required (e.g. - ./sex_calc.sh /folder/containing/bams/)"
	exit
fi

# basic checks for the existence of the folder and bam files
if [[ ! -d ${BAM_FOLDER} ]]; then
	echo -e "## Sex Calculator ## - Input folder provided does not exist - Exiting Now"
	exit
fi
if [[ `ls ${BAM_FOLDER}*.bam | wc -l` < '1' ]]; then
	echo -e "## Sex Calculator ## - Input folder provided contains no BAM files - Exiting Now"
	exit
fi
#list all bam files present in folder
ls ${BAM_FOLDER}*.bam > bam_list_sexcalc.txt
#setup output file
echo -e "Sample\tX/Y_ratio\tPredicted_sex" > ${OUTPUT}sex_calc_results.tsv
#report script is running
echo -e "## Sex Calculator ## - Predicting biological sex using X/Y read ratio over $(cat bam_list_sexcalc.txt | wc -l) bam files..."

#for each bam file listed, do
#calculate total read numbers on chrX and chrY - calculate the ratio of reads on X compared to Y
#high ratio (e.g. more than 30) likely female - low ratio (e.g. less than 10) likely male - Inbetween values are deliberately left as unknown
COUNTER=0
echo -e "## Sex Calculator ## - Calculating predictive Sex - In progress... 0.0%"
for i in `cat bam_list_sexcalc.txt`; do
	## progress check
	let COUNTER=COUNTER+1
	FINAL_PROG=$(cat bam_list_sexcalc.txt | wc -l)
	COUNTER_PCT=$(( COUNTER * 100 ))
	PCT=$(bc <<< "scale=1; $COUNTER_PCT / $FINAL_PROG")
	
	## ratio calculator	
	X=$(samtools view -c ${i} chrX 2> /dev/null)
	Y=$(samtools view -c ${i} chrY 2> /dev/null) 
	ratio=$(( X / Y ))
	
	if [[ "$ratio" -le 10 ]]; then
		echo -e "${i}\t${ratio}\tM" >> ${OUTPUT}sex_calc_results.tsv
	elif [[ "$ratio" -ge 19 ]]; then
		echo -e "${i}\t${ratio}\tF" >> ${OUTPUT}sex_calc_results.tsv
	else
		echo -e "${i}\t${ratio}\t?" >> ${OUTPUT}sex_calc_results.tsv
	fi
	#progress reporting
	echo -e "## Sex Calculator ## - Calculating predictive Sex - In progress... ${PCT}%"
done

#trim the file names in the output to just the sample and not the entire file path
vim -c "%s%/\S\+/%%g|wq" ${OUTPUT}sex_calc_results.tsv
vim -c "%s%_hg38\S\+%%g|wq" ${OUTPUT}sex_calc_results.tsv

#remove temp files
rm bam_list_sexcalc.txt
echo -e "## Sex Calculator ## - Script finished - Results default to home folder"

#!/bin/bash
## input file variables
INPUT1=${1}
INPUT2=${2}

## Minor error catching
if [[ $# -eq 0 ]]; then
	echo -e "## Discordance Test ## - Arguments please!  Try ./discord_check.sh vcf1.vcf vcf2.vcf"
	exit
fi

if [[ $# -lt 2 ]]; then
        echo -e "## Discordance Test ## - More Arguments please!  Try ./discord_check.sh vcf1.vcf vcf2.vcf"
        exit
fi

## Environment setup and temp folder creation
if [[ ! -d .discord_temp ]]; then
	mkdir .discord_temp
fi

if [[ ! -f discord_results.txt ]]; then
	echo -e "Sample_1\tSample_2\tGT_discord\tGT_total\tPCT_discord(%)" > discord_results.txt
fi

## Move to working directory
cd .discord_temp

## Copy target files
cp ${INPUT1} INPUT_1.vcf
cp ${INPUT2} INPUT_2.vcf

## Compress and index for bcftools format
bgzip INPUT_1.vcf
tabix INPUT_1.vcf.gz

bgzip INPUT_2.vcf
tabix INPUT_2.vcf.gz

## Calculate discordance with bcftools
bcftools gtcheck -G 1 -g INPUT_1.vcf.gz INPUT_2.vcf.gz | tail -n1 | cut -f2,4 > discord_out

## Convert and calculate percentage of GTs discordant
SCI_NUMER=$(cut -f1 discord_out) # removes scientific notation for bc calculations
NUMER=$(printf "%.0f\n" ${SCI_NUMER})
DENOM=$(cut -f2 discord_out)
PCT=$(bc <<< "scale=4; $NUMER / $DENOM * 100" | sed -r 's/^(-?)\./\10./' | awk ' sub("\\.*0+$","") ') #awk and sed add leading and remove trailing zeros

## Convert target file paths to useable sample names
ECHO_1=$(echo ${INPUT1} | sed 's%\S\+/\(\S\+\)_\S\+%\1%')
ECHO_2=$(echo ${INPUT2} | sed 's%\S\+/\(\S\+\)_\S\+%\1%')

## leave working temp directory and print output to stdout and file
cd ../
echo -e "\n## Discordance Test ##"
echo -e "Sample_1\tSample_2\tGT_discord\tGT_total\tPCT_discord(%)"
echo -e "${ECHO_1}\t${ECHO_2}\t${NUMER}\t${DENOM}\t${PCT}" | tee -a discord_results.txt
echo -e ""
## Remove temp files/directory
rm -r .discord_temp

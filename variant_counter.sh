#!/bin/bash

SEARCH=${1}
FILE=${2}


echo -e "Searching for pattern ${SEARCH} in FILE ${FILE}..."
grep "${SEARCH}" ${FILE} > grep_outTEMP


if [[ $(wc -l grep_outTEMP | cut -d ' ' -f 1) == 0 ]]; then
	echo -e "No matches found"
	rm grep_outTEMP
	exit
elif [[ $(wc -l grep_outTEMP | cut -d ' ' -f 1) == 1 ]]; then
	POS=$(head -n 1 grep_outTEMP | cut -f 3)
	vim -c "%s/\t/\r/g|wq" grep_outTEMP > /dev/null 2>&1
	vim -c "1,9d|wq" grep_outTEMP > /dev/null 2>&1
	HET=$(grep -c "0/1" grep_outTEMP)	
	SAMP=$(wc -l grep_outTEMP | cut -d ' ' -f 1)
	ALL=$(($SAMP * 2))
	AF=$(echo "scale=3;($HET/$ALL)" | bc -l)
	echo -e "\nrsID ${POS} - ${HET} HET alleles out of $(($SAMP * 2)) alleles (${SAMP} samples)"
	echo -e "Allele Frequency of approximately ${AF}\n"
	rm grep_outTEMP
elif [[ $(wc -l grep_outTEMP | cut -d ' ' -f 1) > 1 ]]; then
	echo -e "More than 1 matching line for SEARCH term - Spliting by line"
	rm grep_outTEMP
	exit
fi


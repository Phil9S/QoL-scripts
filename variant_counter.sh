#!/bin/bash

SEARCH=${1}
FILE=${2}


echo -e "## Variant Counter ## - Searching for pattern ${SEARCH} in FILE ${FILE}..."
grep "${SEARCH}" ${FILE} > grep_outTEMP


if [[ $(wc -l grep_outTEMP | cut -d ' ' -f 1) == 0 ]]; then
	echo -e "## Variant Counter ## - No matches found"
	rm grep_outTEMP
	exit
elif [[ $(wc -l grep_outTEMP | cut -d ' ' -f 1) == 1 ]]; then
	POS=$(head -n 1 grep_outTEMP | cut -f 3)
	vim -c "%s/\t/\r/g|wq" grep_outTEMP > /dev/null 2>&1
	vim -c "1,9d|wq" grep_outTEMP > /dev/null 2>&1
	HET=$(grep -c "0/1" grep_outTEMP)	
	SAMP=$(wc -l grep_outTEMP | cut -d ' ' -f 1)
	ALL=$(($SAMP * 2))
	AF=$(echo "scale=4;($HET/$ALL)" | bc -l)
	echo -e "\n## Variant Counter ## - ${POS} - ${HET} HET alleles out of $(($SAMP * 2)) alleles (${SAMP} samples)"
	echo -e "## Variant Counter ## - Allele Frequency of approximately ${AF}\n"
	rm grep_outTEMP
elif [[ $(wc -l grep_outTEMP | cut -d ' ' -f 1) -gt 10 ]]; then
        echo -e "## Variant Counter ## - More than 10 matching line for SEARCH term - Too many results to calculate"
        rm grep_outTEMP
	exit
elif [[ $(wc -l grep_outTEMP | cut -d ' ' -f 1) -gt 1 ]]; then
	echo -e "## Variant Counter ## - More than 1 matching line for SEARCH term - Spliting by line"
	split -d1 --additional-suffix=.outSPLIT grep_outTEMP split
	ls *.outSPLIT > grep_list	
	for i in `cat grep_list`; do	
		POS=$(head -n 1 ${i} | cut -f 3)
	       	vim -c "%s/\t/\r/g|wq" ${i} > /dev/null 2>&1 
	 	vim -c "1,9d|wq" ${i} > /dev/null 2>&1
        	HET=$(grep -c "0/1" ${i})
   	    	SAMP=$(wc -l ${i} | cut -d ' ' -f 1)
        	ALL=$(($SAMP * 2))
        	AF=$(echo "scale=4;($HET/$ALL)" | bc -l)
        	echo -e "\n## Variant Counter ## - ${POS} - ${HET} HET alleles out of $(($SAMP * 2)) alleles (${SAMP} samples)"
        	echo -e "## Variant Counter ## - Allele Frequency of approximately ${AF}\n"
	done
	rm grep_list
	rm grep_outTEMP
	rm *.outSPLIT
	exit
fi


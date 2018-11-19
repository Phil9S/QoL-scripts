#!/bin/bash

PROG=1
TOTAL=$(cat FILE | wc -l)

for i in `cat FILE`; do

	PROG_PCT=$(echo "scale=2;($PROG/$TOTAL)*100" | bc | sed 's/\.[0-9][0-9]//')	
	FULL=100
	printf "PROGRESS BAR |"
	for ((done=0; done<${FULL}; done++)); do 
		if [[ "$done" -lt "$PROG_PCT" ]]; then
			printf "▊"
		else	
 			printf " "
		fi
	done
	printf "| ${PROG_PCT}%%(${PROG}/${TOTAL})\r"
	
	## LOOP FUNCTION HERE

	
	sleep 1
	let PROG++
done
echo -e "\r"

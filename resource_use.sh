#!/bin/bash

JOB=${1}

LOOP="TRUE"
USAGE=0

if [[ $# -eq 0 ]]; then
	echo -e "You need to provide a search term for the target process!"
	exit
fi

while [[ $LOOP = "TRUE" ]]; do

	if [[ $(ps aux | grep "$JOB" | grep -v "grep" | grep -v "resource_use" | awk -v OFS="\t" '$1=$1' | cut -f 6 | wc -l) -lt 1 ]]; then
		echo -e "No Processes Found"
		LOOP="FALSE"
		exit
	else
		RES=$(ps aux | grep "$JOB" | grep -v "grep" | grep -v "resource_use" | awk -v OFS="\t" '$1=$1' | cut -f 6 | sort -r | head -n 1)
		if [[ $RES -gt $USAGE ]]; then
			USAGE=${RES}
			echo -e `date +[%D-%R]` "Current max usage: $(( $USAGE / 1000 ))Mb / $(( $USAGE / 1000000 ))Gb" >> $HOME/resource_use.log
		fi	
		sleep 3
	fi
done

if [[ $USAGE -gt 0 ]]; then
	echo -e `date +[%D-%R]` "Final maximum usage: $(( $USAGE / 1000 ))Mb / $(( $USAGE / 1000000 ))Gb" >> $HOME/resource_use.log
fi

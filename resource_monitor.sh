#!/bin/bash

JOB=${1}

LOOP="TRUE"
USAGE=0

echo -e "Resource monitoring - ${JOB} - Started ${DATE}" > $HOME/resource_${JOB}_use.log
echo -e "TIME\tUSER\tPID\t%CPU\t%MEM\tVIRmem\tRESmem\tJOB" >> $HOME/resource_${JOB}_use.log

if [[ $# -eq 0 ]]; then
	echo -e "You need to provide a search term for the target process!"
	exit
fi

echo -e "Monitoring resource use for ${JOB}"

while [[ $LOOP = "TRUE" ]]; do

	if [[ $(ps aux | grep "$JOB" | grep -v "grep" | grep -v "resource_monitor" | wc -l) -lt 1 ]]; then
		echo -e "No Processes Found"
    rm $HOME/resource_${JOB}_use.log
		LOOP="FALSE"
	elif [[ $(ps aux | grep "$JOB" | grep -v "grep" | grep -v "resource_monitor" | wc -l) -gt 1 ]];  then
		echo -e "More than 1 job found to monitor"
		rm $HOME/resource_${JOB}_use.log
    LOOP="FALSE"
	else
		JOB_INFO=$(ps aux | grep "$JOB" | grep -v "grep" | grep -v "resource_monitor")
		USER=$(echo ${JOB_INFO} | awk -v OFS="\t" '$1=$1' | cut -f 1)
		PID=$(echo ${JOB_INFO} | awk -v OFS="\t" '$1=$1' | cut -f 2)
		CPU=$(echo ${JOB_INFO} | awk -v OFS="\t" '$1=$1' | cut -f 3)
		MEM=$(echo ${JOB_INFO} | awk -v OFS="\t" '$1=$1' | cut -f 4)
		VSZ=$(echo ${JOB_INFO} | awk -v OFS="\t" '$1=$1' | cut -f 5)
		RES=$(echo ${JOB_INFO} | awk -v OFS="\t" '$1=$1' | cut -f 6)
    PROC=$(echo ${JOB_INFO} | awk -v OFS="\t" '$1=$1' | cut -f 11 | cut -c1-10)
	  echo -e `date +[%D-%R]` "\t${USER}\t${PID}\t${CPU}\t${MEM}\t$(( $VSZ / 1000 ))Mb\t$(( $RES / 1000 ))Mb\t${PROC}..." | tee -a $HOME/resource_${JOB}_use.log
		sleep 5
	fi
done

echo -e "Finished monitoring resource use for ${JOB}"
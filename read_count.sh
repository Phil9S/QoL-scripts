#!/bin/bash

input=${1}
bedfile=${2}

for i in ${input}*.bam; do
	echo ${i}
	#filter by bed
	samtools view -c -L ${bedfile} -F 4 ${i} >> readtotal.txt
	#not filtered
	#samtools view -c -F 4 ${i} >> readtotal.txt
done

k=0
for i in `cat readtotal.txt`; do
	let k=k+i
done
echo Total Read Count for bam files in ${input}:
echo $k reads
echo Bed file used: ${bedfile}
rm readtotal.txt

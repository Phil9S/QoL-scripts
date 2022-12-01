#!/bin/bash

BAM_FOLDER=$1
OUT_DIR="/mnt/scratcha/fmlab/smith10/temp_qc/"

unset DISPLAY

if [ ! -d "${OUT_DIR}" ]; then
	mkdir ${OUT_DIR}
fi

for F in $@; do
	for I in ${F}*.bam; do
		#echo ${I}
		SAMPLE=$(basename ${I} | sed 's/\.bam//')
		echo -e "${SAMPLE}"
		mkdir ${OUT_DIR}${SAMPLE}/
		qualimap bamqc --java-mem-size=30G -nr 500 -nt 40 -bam ${I} -outdir ${OUT_DIR}${SAMPLE}/
		#fastqc -t 40 -o ${OUT_DIR}${SAMPLE}/ ${I}
	done
done

multiqc ${OUT_DIR}

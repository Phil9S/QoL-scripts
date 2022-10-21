#!/bin/bash

# As described - https://github.com/nanoporetech/ont-assembly-polish
VERSION="Purple Nickel Cord"
PROJECT="NEW_PROJECT"
OUTPUT_DIR=NULL
GEN_SIZE=NULL
INPUT_LR_READS=NULL
MIN_READ_LENGTH=1000
INPUT_SR_READS_1=NULL
INPUT_SR_READS_2=NULL
CORES=8
PILON="/home/pss41/resources/bin/pilon-1.23.jar"

for arg in "$@"; do
        if [[ "$arg" == "-h" ]] || [[ "$arg" == "--help" ]]; then
		echo -e `date +[%D-%R]`"[DNHA][MAIN] De Novo Hybrid Assembly pipeline - Help documentation - version: ${VERSION}\n"
		echo -e "A pipeline for hybrid de novo genome assembly of long read nanopore and paired short read sequencing data\n"
		echo -e "Usage: ./de_novo_assembly.sh [options]\n"
		echo -e "Options:\n"
		echo -e "	-i / --input			Single FASTQ file containing raw uncorrected nanopore reads"
		echo -e "	-o / --output_dir   		Path to a directory in which the pipeline will run"
		echo -e "	-p / --project   		String name for the project or analysis being run (default = ${PROJECT})"
		echo -e "	-g / --genome_size   		Estimated genome size (designated by a number followed by k,m or g - 1k, 10m, 100g, etc.)"
		echo -e "	-m / --min_read_length  	Minimal read length to use in the assembly (default = ${MIN_READ_LENGTH})"
		echo -e "	-sr1 / --short_reads_1   	FASTQ file containing the first pair (R1) of short read sequencing data"
		echo -e "	-sr2 / --short_reads_2   	FASTQ file containing the second pair (R2) of short read sequencing data"
		echo -e "	-t / --threads  		Number of CPU threads to use for non-canu steps (default = ${CORES})"
		echo -e "	--pilon  			Path to the Pilon software .jar file (default = ${PILON})\n"
		exit 
	fi
done

if [[ $# -eq 0 ]]; then
	echo -e `date +[%D-%R]`"[DNHA][MAIN] You need to provide at least SOME arguments! Try using -h / --help for documentation and examples"
	exit
fi

while [[ $# > 1 ]]
	do 
	key="$1"
	case $key in
		-i|--input)
		INPUT_LR_READS=$2
		shift
		;;
                -o|--output_dir)
                OUTPUT_DIR=$2
                shift
                ;;
                -p|--project)
                PROJECT=$2
                shift
                ;;
                -g|--genome_size)
                GEN_SIZE=$2
                shift
                ;;
                -m|--min_read_length)
                MIN_READ_LENGTH=$2
                shift
                ;;
                -sr1|--short_reads_1)
                INPUT_SR_READS_1=$2
                shift
                ;;
                -sr2|--short_reads_2)
                INPUT_SR_READS_2=$2
                shift
                ;;
                -t|--threads)
                CORES=$2
                shift
                ;;
                --pilon)
                PILON=$2
                shift
                ;;

	esac
	shift
done

## arg checks
if [[ ! -f "$INPUT_LR_READS" ]]; then
	echo -e `date +[%D-%R]`"[DNHA][INT] Input fastq file missing -------------------------------- FAILED"
	exit
else
	echo -e `date +[%D-%R]`"[DNHA][INT] Input fastq file found --------------------------------- SUCCESS"
	if [[ $(zgrep -c -m1 "^@" ${INPUT_LR_READS}) -lt 1 ]]; then
	echo -e `date +[%D-%R]`"[DNHA][INT] Input fastq file invalid -------------------------------- FAILED"
	exit
	else
	echo -e `date +[%D-%R]`"[DNHA][INT] Input fastq file is valid ------------------------------ SUCCESS"
	fi
fi
if [[ ! -d "$OUTPUT_DIR" ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] Output directory not found ------------------------------ FAILED"
	exit
else
        echo -e `date +[%D-%R]`"[DNHA][INT] OUTPUT FOLDER directory found -------------------------- SUCCESS"
        if [[ ! -w "$OUTPUT_DIR" ]]; then
       	echo -e `date +[%D-%R]`"[DNHA][INT] OUTPUT FOLDER not writable ------------------------------ FAILED"
	exit
	else
        echo -e `date +[%D-%R]`"[DNHA][INT] OUTPUT FOLDER writable --------------------------------- SUCCESS"
        fi
fi
if [[ ! -f "$INPUT_SR_READS_1" ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] Short read pair 1 fastq file missing -------------------- FAILED"
        exit
else
        echo -e `date +[%D-%R]`"[DNHA][INT] Short read pair 1 fastq file found --------------------- SUCCESS"
        if [[ $(zgrep -c -m1 "^@" ${INPUT_SR_READS_1}) -lt 1 ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] Short read pair 1 fastq file invalid -------------------- FAILED"
        exit
        else
        echo -e `date +[%D-%R]`"[DNHA][INT] Short read pair 1 fastq file is valid ------------------ SUCCESS"
        fi
fi
if [[ ! -f "$INPUT_SR_READS_2" ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] Short read pair 2 fastq file missing -------------------- FAILED"
        exit
else
        echo -e `date +[%D-%R]`"[DNHA][INT] Short read pair 2 fastq file found --------------------- SUCCESS"
        if [[ $(zgrep -c -m1 "^@" ${INPUT_SR_READS_2}) -lt 1 ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] Short read pair 2 fastq file invalid -------------------- FAILED"
        exit
        else
        echo -e `date +[%D-%R]`"[DNHA][INT] Short read pair 2 fastq file is valid ------------------ SUCCESS"
        fi
fi
if ! [[ "$CORES" =~ ^[0-9]+$ ]] || [[ "$CORES" -gt $(nproc --all) ]]; then
	echo -e `date +[%D-%R]`"[DNHA][INT] Number of threads invalid ------------------------------- FAILED"
	exit
else
	echo -e `date +[%D-%R]`"[DNHA][INT] Number of threads valid -------------------------------- SUCCESS"
fi
if ! [[ "$MIN_READ_LENGTH" =~ ^[0-9]+$ ]]; then
	echo -e `date +[%D-%R]`"[DNHA][INT] Minimum read length value invalid ----------------------- FAILED"
	exit
else
	echo -e `date +[%D-%R]`"[DNHA][INT] Minimum read length value valid ------------------------ SUCCESS"
fi
if ! [[ "$GEN_SIZE" =~ ^[0-9]+[gmk]$ ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] Estimated genome size value invalid --------------------- FAILED"
        exit
else
        echo -e `date +[%D-%R]`"[DNHA][INT] Estimated genome size value valid ---------------------- SUCCESS"
fi
if [[ ! -x $(command -v canu) ]]; then
	echo -e `date +[%D-%R]`"[DNHA][INT] CANU software executable -------------------------------- FAILED"
	exit
else
	echo -e `date +[%D-%R]`"[DNHA][INT] CANU software executable ------------------------------- SUCCESS"
fi
if [[ ! -x $(command -v racon) ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] RACON software executable ------------------------------- FAILED"
	exit
else
        echo -e `date +[%D-%R]`"[DNHA][INT] RACON software executable ------------------------------ SUCCESS"
fi
if [[ ! -x $(command -v bwa) ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] BWA software executable --------------------------------- FAILED"
	exit
else
        echo -e `date +[%D-%R]`"[DNHA][INT] BWA software executable -------------------------------- SUCCESS"
fi
if [[ ! -x $(command -v minimap2) ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] MINIMAP2 software executable ---------------------------- FAILED"
	exit
else
        echo -e `date +[%D-%R]`"[DNHA][INT] MINIMAP2 software executable --------------------------- SUCCESS"
fi
if [[ ! -x $(command -v samtools) ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] SAMTOOLS software executable ---------------------------- FAILED"
        exit
else
        echo -e `date +[%D-%R]`"[DNHA][INT] SAMTOOLS software executable --------------------------- SUCCESS"
fi
if [[ ! -x $(command -v samtools) ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] SAMTOOLS software executable ---------------------------- FAILED"
        exit
else
        echo -e `date +[%D-%R]`"[DNHA][INT] SAMTOOLS software executable --------------------------- SUCCESS"
fi
if [[ ! -x $(command -v java -jar ${PILON}) ]]; then
        echo -e `date +[%D-%R]`"[DNHA][INT] PILON software executable ------------------------------- FAILED"
        exit
else
        echo -e `date +[%D-%R]`"[DNHA][INT] PILON software executable ------------------------------ SUCCESS"
fi

echo -e `date +[%D-%R]`"[DNHA][INT] Generating log file" | tee -a ${OUTPUT_DIR}dnha.log
echo -e `date +[%D-%R]`"[DNHA][INT] Parameters and files:" | tee -a ${OUTPUT_DIR}dnha.log
echo -e `date +[%D-%R]`"[DNHA][INT] Long read input fastq: ${INPUT_LR_READS}" | tee -a ${OUTPUT_DIR}dnha.log
echo -e `date +[%D-%R]`"[DNHA][INT] Output directory: ${OUTPUT_DIR}" | tee -a ${OUTPUT_DIR}dnha.log
echo -e `date +[%D-%R]`"[DNHA][INT] Short read input (R1): ${INPUT_SR_READS_1}" | tee -a ${OUTPUT_DIR}dnha.log
echo -e `date +[%D-%R]`"[DNHA][INT] Short read input (R2): ${INPUT_SR_READS_2}" | tee -a ${OUTPUT_DIR}dnha.log
echo -e `date +[%D-%R]`"[DNHA][INT] Estimated genome size: ${GEN_SIZE}" | tee -a ${OUTPUT_DIR}dnha.log
echo -e `date +[%D-%R]`"[DNHA][INT] Minimum read length: ${MIN_READ_LENGTH}" | tee -a ${OUTPUT_DIR}dnha.log
echo -e `date +[%D-%R]`"[DNHA][INT] Project name: ${PROJECT}" | tee -a ${OUTPUT_DIR}dnha.log
echo -e `date +[%D-%R]`"[DNHA][INT] Number of threads (excluding canu steps): ${CORES}\n" | tee -a ${OUTPUT_DIR}dnha.log
echo -e `date +[%D-%R]`"[DNHA][MAIN] Starting De novo hybrid assembly pipeline" | tee -a ${OUTPUT_DIR}dnha.log

## CANU de novo draft genome assembly
echo -e `date +[%D-%R]`"[DNHA][MAIN] Performing Canu assembly using ${GEN_SIZE} estimated genome size" | tee -a ${OUTPUT_DIR}dnha.log
canu -d ${OUTPUT_DIR}canu/ \
	-p ${PROJECT} \
	genomeSize=${GEN_SIZE} \
	-nanopore-raw ${INPUT_LR_READS} \
	useGrid=false \
	minReadLength=${MIN_READ_LENGTH}

mkdir ${OUTPUT_DIR}racon/
cp ${OUTPUT_DIR}canu/${PROJECT}.contigs.fasta ${OUTPUT_DIR}racon/${PROJECT}.contigs.fasta

samtools faidx ${OUTPUT_DIR}canu/${PROJECT}.contigs.fasta
samtools dict ${OUTPUT_DIR}racon/${PROJECT}.contigs.fasta > ${OUTPUT_DIR}racon/${PROJECT}.contigs.dict
minimap2 -a -x map-ont ${OUTPUT_DIR}racon/${PROJECT}.contigs.fasta ${INPUT_LR_READS} > ${OUTPUT_DIR}racon/temp_overlaps.sam

## Racon contig error correction - Two iterative cycles
racon -m 8 -x -6 -g -8 -w 500 ${INPUT_LR_READS} ${OUTPUT_DIR}racon/temp_overlaps.sam ${OUTPUT_DIR}racon/${PROJECT}.contigs.fasta > ${OUTPUT_DIR}racon/${PROJECT}.raconP1.contigs.fasta

samtools faidx ${OUTPUT_DIR}racon/${PROJECT}.raconP1.contigs.fasta
samtools dict ${OUTPUT_DIR}racon/${PROJECT}.raconP1.contigs.fasta > ${OUTPUT_DIR}racon/${PROJECT}.raconP1.contigs.dict

minimap2 -a -x map-ont ${OUTPUT_DIR}racon/${PROJECT}.raconP1.contigs.fasta ${INPUT_LR_READS} > ${OUTPUT_DIR}racon/temp_overlaps2.sam

racon -m 8 -x -6 -g -8 \
	-w 500 ${INPUT_LR_READS} ${OUTPUT_DIR}racon/temp_overlaps2.sam ${OUTPUT_DIR}racon/${PROJECT}.raconP1.contigs.fasta > ${OUTPUT_DIR}racon/${PROJECT}.raconP2.contigs.fasta

mkdir ${OUTPUT_DIR}pilon/
cp ${OUTPUT_DIR}racon/${PROJECT}.raconP2.contigs.fasta ${OUTPUT_DIR}pilon/${PROJECT}.raconP2.contigs.fasta

samtools faidx ${OUTPUT_DIR}pilon/${PROJECT}.raconP2.contigs.fasta
samtools dict ${OUTPUT_DIR}pilon/${PROJECT}.raconP2.contigs.fasta > ${OUTPUT_DIR}pilon/${PROJECT}.raconP2.contigs.dict

bwa index ${OUTPUT_DIR}pilon/${PROJECT}.raconP2.contigs.fasta

bwa mem -R "@RG\tID:${PROJECT}\tLB:DE_NOVO\tSM:${PROJECT}\tPL:ILLUMINA" ${OUTPUT_DIR}pilon/${PROJECT}.raconP2.contigs.fasta ${INPUT_SR_READS_1} ${INPUT_SR_READS_2} | \
	samtools sort -O bam -l 0 -T . -o ${OUTPUT_DIR}pilon/${PROJECT}.SR.sorted.bam

samtools index ${OUTPUT_DIR}pilon/${PROJECT}.SR.sorted.bam

java -Xmx16G -jar ${PILON} --genome ${OUTPUT_DIR}pilon/${PROJECT}.raconP2.contigs.fasta \
	--bam ${OUTPUT_DIR}pilon/${PROJECT}.SR.sorted.bam \
	--output ${PROJECT} \
	--outdir ${OUTPUT_DIR}pilon/ \
	--vcf \
	--diploid \
	--threads ${CORES} \
	--changes

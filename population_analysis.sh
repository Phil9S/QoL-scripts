#!/bin/bash

VCF="/home/pss41/RCC_WES_master_hg38.recode.vcf"
REF_VCF="/home/pss41/G1K_vcf/ALL.WGS_GRCh38.genotypes.CHR.20170504.vcf.gz"
NAME="RCC"
GATK="/data/Resources/Software/Javas/GenomeAnalysisTK.jar"
REFERENCE="/data/Resources/References/hg38.bwa/hg38.bwa.fa"
ADMIXTURE="/home/pss41/admixture/admixture"

cat ${VCF} | grep -m 1 "#C" | tr '\t' '\n' | sed -e '1,9d' > sample_list_pop
bcftools view -h ${REF_VCF} | grep -m 1 "#C" | tr '\t' '\n' | sed -e '1,9d' >> sample_list_pop

bgzip -c ${VCF} > ${NAME}.vcf.gz 
tabix ${NAME}.vcf.gz

bcftools merge -Oz -o ${NAME}_REF.vcf.gz ${NAME}.vcf.gz ${REF_VCF} 
tabix ${NAME}_REF.vcf.gz

vcftools --gzvcf ${NAME}_REF.vcf.gz --thin 2000 --chr chr1 --chr chr2 --chr chr3 --chr chr4 --chr chr5 --chr chr6 --chr chr7 --chr chr8 --chr chr9 --chr chr10 --chr chr11 --chr chr12 --chr chr13 --chr chr14 --chr chr15 --chr chr16 --chr chr17 --chr chr18 --chr chr19 --chr chr20 --chr chr21 --chr chr22 --chr chrX --min-alleles 2 --max-alleles 2 --non-ref-ac 2 --recode --out ${NAME}_REF

plink1.90 --vcf ${NAME}_REF.recode.vcf --out ${NAME}_REF.maf0.05 --make-bed --maf 0.05 --vcf-half-call 'm' --const-fid --biallelic-only --geno 0.05

${ADMIXTURE} ${NAME}_REF.maf0.05.bed 5

Rscript admixture_plotting.R ${NAME}_REF.maf0.05.5.Q

Rscript PCA_data.R ${NAME}_REF.maf0.05


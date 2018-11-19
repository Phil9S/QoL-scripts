#!/bin/bash

file=${1}
min=${2}

vcftools --vcf ${file}.QC.vcf --plink --out ${file}
plink1.90 --allow-no-sex --file ${file} --make-bed --out ${file}
plink1.90 --allow-no-sex --bfile ${file} --geno 0.01 --make-bed --out ${file}.geno
plink1.90 --allow-no-sex --bfile ${file}.geno --hardy --hwe 0.000005 --make-bed --out ${file}.geno.hardy
plink1.90 --allow-no-sex --bfile ${file}.geno.hardy --maf 0.05 --make-bed --out ${file}.geno.hardy.maf
plink1.90 --allow-no-sex --bfile ${file}.geno.hardy.maf --genome --min ${2} --out ${file}.geno.hardy.maf

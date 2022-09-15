#!/bin/bash

export FILES=($(ls -1 *.vcf.gz | sed 's%.*/%%'))

NUM=${#FILES[@]}
ZNUM=$(($NUM - 1))

echo ${NUM}
echo ${ZNUM}

for i in ${FILES[*]}; do
	echo ${i}
done

if [[ "$ZNUM" -ge 0 ]]; then
	#sbatch --array=0-${ZNUM} sbatch_assoc_script
fi

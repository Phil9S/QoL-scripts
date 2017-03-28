#!/bin/bash

for i in `cat temp_bamlist`; do

	cp ${i}.bam /home/pss41/testbams/
	cp ${i}.bai /home/pss41/testbams/
done

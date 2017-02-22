#!/bin/bash


loc=${1}
gene=${2}

if [[ $# -eq 0 ]]; then
	echo -e "GeneSearch - Arguments please!  Try ./geneSearch /this/input/folder GENESYMBOL \nUse on BASS  annotated score files"
	exit
fi

if [[ $# -lt 2 ]]; then
        echo -e "GeneSearch - More Arguments please!  Try ./geneSearch /this/input/folder GENESYMBOL \nUse on BASS  annotated score files"
        exit
fi


if [ -d ".genesearch_temp" ]; then
	echo -e "GeneSearch - Temp folder exists - folder not generated\n"
else
	mkdir .genesearch_temp
fi

cd .genesearch_temp

ls ${loc}*.scores.txt > input.list
vim -c "%s/.scores.txt//g|wq" input.list
vim -c "%s#${loc}##g|wq" input.list 

echo -e "Sample	Chr	Start	End	cytoBand	Gene.refGene	Func.refGene	ExonicFunc.refGene	avsnp144	Ref	Alt	AA1	AA2	AA_Pos	Lenght	TranscriptID	Exon	Interpro_domain	X1000g2015aug_all	ExAC_ALL	esp6500siv2_all	GT	Q	PL	Depth	Score	TruncScore	HomozygScore	Polyphen2_HDIV_score	Polyphen2_HVAR_score	VEST3_score	MutationAssessor_score_Converted	GERP.._RS_Converted	phyloP7way_vertebrate_score	phyloP20way_mammalian_score	SIFT_scoreInv	fathmm.MKL_coding_score	LRT_score	MutationTaster_score	FATHMM_score_Converted	PROVEAN_score_Converted	CADD_raw_Converted	DANN_score	MetaSVM_score_Converted	MetaLR_score	integrated_fitCons_score_Converted	integrated_confidence_value_Converted	phastCons7way_vertebrate	phastCons20way_mammalian	SiPhy_29way_logOdds_Converted	dbscSNV_ADA_SCORE	dbscSNV_RF_SCORE	dpsi_max_tissue_Converted	X1000g2015aug_afr	X1000g2015aug_eas	X1000g2015aug_eur	X1000g2015aug_amr	X1000g2015aug_sas	ExAC_AFR	ExAC_AMR	ExAC_EAS	ExAC_FIN	ExAC_NFE	ExAC_OTH	ExAC_SAS	esp6500siv2_aa	esp6500siv2_ea	nci60	cosmic70	CLINSIG	CLNDBN	CLNACC	CLNDSDB	CLNDSDBID" > geneSearch_${gene}_results.txt

echo -e "GeneSearch - Searching for ${gene}..."
for i in `cat input.list`; do
	
	cat ${loc}${i}.scores.txt | grep "$gene" > grepfile.txt
	sed -i "s/\(.*\)/${i}\t\1/g" grepfile.txt
	cat grepfile.txt >> geneSearch_${gene}_results.txt

done
echo "GeneSearch - $(cat input.list | wc -l) total files searched..."
echo -e "GeneSearch - Search Complete"
mv geneSearch_${gene}_results.txt ../
cd ../
mv geneSearch_${gene}_results.txt gene_search_results/
rm -r .genesearch_temp

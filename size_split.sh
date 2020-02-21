#!/bin/bash

FILE=$1
SIZE=$2

if [[ $# -eq 0 ]]; then
	echo -e "Size split- No arguments given. Arg1 = File list with sizes in col. 6 - Arg2 = Size in Number of byte units up to Terabyte\n"
	exit
fi

integer_check='^[1-9]$|^[1-9][0-9]+$'
float_check='^[0][.][0-9]+[G,T,M,K]$|^[1][.][0]$'
SIZE_PATTERN="^(\d*\.?\d+)(?(?=[KMGT])([KMGT])(?:i?B)?|B?)$"

if ! grep -i -q -P ${SIZE_PATTERN} <(echo ${SIZE}); then
	echo -e "File size not recognised"
else
	if grep -i -q "T" <(echo ${SIZE}); then
		TERA=$(sed 's/[A-Za-z]*//g' <(echo ${SIZE}))
		#echo -e "${TERA}"
		SIZE=$(bc <<< "scale=0;($TERA*1*10^12)/1")
		#echo "${SIZE} bytes"
	elif grep -i -q "G" <(echo ${SIZE}); then
		GIGA=$(sed 's/[A-Za-z]*//g' <(echo ${SIZE}))
                #echo -e "${GIGA}"
                SIZE=$(bc <<< "scale=0;($GIGA*1*10^9)/1")
		#echo "${SIZE} bytes"
	elif grep -i -q "M" <(echo ${SIZE}); then
		MEGA=$(sed 's/[A-Za-z]*//g' <(echo ${SIZE}))
                #echo -e "${MEGA}"
                SIZE=$(bc <<< "scale=0;($MEGA*1*10^6)/1")
		#echo "${SIZE} bytes"
	elif grep -i -q "K" <(echo ${SIZE}); then
		KILO=$(sed 's/[A-Za-z]*//g' <(echo ${SIZE}))
                #echo -e "${KILO}"
                SIZE=$(bc <<< "scale=0;($KILO*1*10^3)/1")
		#echo "${SIZE} bytes"
	else
		echo "Bytes"
	fi
fi

LINE_C=1
LINE_START=1
LINE_MAX=$(cat ${MANIFEST_NOHEAD} | wc -l)
BYTES=0
CHUNK=1
echo ${LINE_MAX}
while read -r LINE; do
	LINE_BYTES=$(echo "${LINE}" | cut -f6)
	BYTES=$(( $BYTES + $LINE_BYTES ))
	if [ $(($BYTES + $LINE_BYTES )) -ge ${SIZE} ]; then
		sed -n "$LINE_START,$LINE_C p" ${MANIFEST_NOHEAD} > manifest.${CHUNK}.file
		LINE_START=$(( $LINE_C + 1 ))
		BYTES=0
		LINE_C=$(($LINE_C + 1))
		CHUNK=$(($CHUNK + 1))
	else
		BYTES=$(( $BYTES + $LINE_BYTES ))
		LINE_C=$(($LINE_C + 1))
	fi
	if [ ${LINE_C} == 20 ]; then
		sed -n "$LINE_START,$LINE_C p" ${MANIFEST_NOHEAD} > manifest.${CHUNK}.file
	fi
done < ${MANIFEST_NOHEAD}

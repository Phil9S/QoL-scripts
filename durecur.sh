#!/bin/bash

set -e
TARGET=$1
#echo ${TARGET}

echo -e "[$(basename ${0}) - recursive du]"
if [ -z "${TARGET}" ]; then
	ls | xargs -n 1 -P 1 -i{} du -sh {}/ 2>/dev/null | sort -hr
else
	#echo ${FULL_TARGET}
	FULL_TARGET=$(realpath ${TARGET})
	if [ -d "${FULL_TARGET}" ]; then
		#echo "recur"
		ls ${FULL_TARGET}/ | xargs -n 1 -P 1 -i{} du -sh ${FULL_TARGET}/{}/ 2>/dev/null | sort -hr
	else
		echo -e "[$0] ${FULL_TARGET}/ not a directory"
	fi
fi

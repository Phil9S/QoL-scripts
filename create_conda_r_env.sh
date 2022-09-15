#!/bin/bash

# args
RVERSION=$1
REMOVE=$2

#error catch
set -e

# Check args provided
if [[ $RVERSION == "" ]]; then
	echo -e "no r version provided"
	echo -e "make env: create_conda_r_env.sh 4.0.1"
	echo -e "remove env: create_conda_r_env.sh 4.0.1 remove"
	exit 1
fi

# Check conda available
if ! [ -x "$(command -v conda)" ]; then
	echo -e "[${script}] Error: conda has not been installed or is not available on PATH"
	exit 1
fi

# Set version regex
RX="^([0-9]+\.){1,2}([0-9]+)$"

# Install conda env
if [[ $REMOVE == "" ]]; then
	# test version regex
	if [[ $RVERSION =~ $RX ]]; then
		conda config --add channels conda-forge
		conda config --set channel_priority strict
		conda create --name r_${RVERSION} -y -c conda-forge r-base=${RVERSION} cairo xorg-libx11 gmp r-devtools
	else
		echo -e "incompatible version string"
		echo -e "Should be 2 or 3 digit version number (3.5,4.0.1,etc.)"
	fi
# Remove env if $2 provided
elif [[ $REMOVE == "remove" ]]; then
	conda remove --name r_${RVERSION} --all -y
	conda info --envs
	echo -e "conda env r_${RVERSION} removed"
else 
	echo -e "unknown arg"
	exit 1
fi

exit 0

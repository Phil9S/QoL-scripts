#!/bin/bash

ARCH="skylake"
SCRIPT=NULL
JOB=NULL
PROJECT="BRIDGE-MPMT-SL2-CPU"
NODES=1
TASKS=$(( $NODES*32 ))
WC="02:00:00"
MAIL="ALL" 		#NONE, BEGIN, END, FAIL, REQUEUE, ALL
REQUEUE=FALSE
MODULES=""
WD="/rds/user/$USER/"

for arg in "$@"; do
        if [[ "$arg" == "-h" ]] || [[ "$arg" == "--help" ]]; then
		echo -e "
[# SBATCH GEN #] - Help Documentation

Generates SBATCH scripts for job submission to SLURM on CSD3

Arguments:

ARGUMENT                        TYPE			DEFAULT			DESCRIPTION

-a 	--arch                  STRING       		skylake 	        Cluster platform to use (e.g. skylake,etc.)
-s 	--script                STRING  		NULL (Required)		Script to be run - quoted if providing CMD line args
-j 	--job_name		STRING			NULL (Required)		Name of submitted job
-p 	--project		STRING			BRIDGE-MPMT-SL2-CPU	Account to be charged CPU-hours
-n 	--nodes			INT			1			Number of nodes to request (1 node = 32 cores)
-t 	--n_tasks		INT			nodes*32		Number of tasks assigned to node
-m	--modules		STRING/FILE		NULL			List of modules to load (file or comma sep list)
-c 	--clock_time		TIME[HH:MM:SS]		02:00:00		Amount of wallclock hours for job to run
-mail 	--mail_type		STRING			ALL			Email updates for job submissions (See CSD3 docs)
-r	--requeue		BOOLEAN			FALSE			Whether to requeue jobs if cluster or node fails
-h 	--help			Argument		-			Shows this menu
"
                echo -e "\n"
                exit
        fi
done

while [[ $# > 1 ]]
	do 
	key="$1"
	case $key in
		-a|--arch)
                ARCH=$2
                shift
                ;;
		-s|--script)
		SCRIPT=$2
		shift
		;;
		-j|--job_name)
                JOB=$2
                shift
                ;;
		-p|--project)
                PROJECT=$2
                shift
                ;;
		-n|--nodes)
                NODES=$2
                shift
                ;;
		-t|--n_tasks)
                TASKS=$2
                shift
                ;;
		-c|--clock_time)
                WC=$2
                shift
                ;;
		-mail|--mail_type)
                MAIL=$2
                shift
                ;;
		-r|--requeue)
                REQUEUE=$2
                shift
                ;;
		-m|--modules)
                MODULES=$2
                shift
                ;;
	esac
	shift
done


echo -e "[# SBATCH GEN #] Cluster architecture - ${ARCH}" 
echo -e "[# SBATCH GEN #] Submitted script - ${SCRIPT}"
echo -e "[# SBATCH GEN #] Job name - ${JOB}"
echo -e "[# SBATCH GEN #] Account charged - ${PROJECT}"
echo -e "[# SBATCH GEN #] Nodes requested - ${NODES}"	
echo -e "[# SBATCH GEN #] Tasks submitted - ${TASKS}"
echo -e "[# SBATCH GEN #] Estimated wallclock hours -${WC}"
echo -e "[# SBATCH GEN #] Email updates set to - ${MAIL}"  
echo -e "[# SBATCH GEN #] Job requeue - ${REQUEUE}"
echo -e "[# SBATCH GEN #] Modules loaded - $(echo ${MODULES})"

if  [[ "$MODULES" !=  "" ]]; then
  if [[ -f ${MODULES} ]]; then
  	cat ${MODULES} | tr ',' '\n' > modules_temp
  else
  	echo ${MODULES} | tr ',' '\n' > modules_temp
  fi
fi

## Make SBATCH filet
#SBATCH command options
echo -e "#!/bin/bash" > sbatch_${JOB}_script
echo -e "#SBATCH -J ${JOB}" >> sbatch_${JOB}_script
echo -e "#SBATCH -A ${PROJECT}" >> sbatch_${JOB}_script
echo -e "#SBATCH -p ${ARCH}" >> sbatch_${JOB}_script
echo -e "#SBATCH --nodes=${NODES}" >> sbatch_${JOB}_script
echo -e "#SBATCH --ntasks=${TASKS}" >> sbatch_${JOB}_script
echo -e "#SBATCH --time=${WC}" >> sbatch_${JOB}_script
echo -e "#SBATCH --mail-type=${MAIL}" >> sbatch_${JOB}_script

if [[ "$REQUEUE" == "FALSE" ]]; then
	echo -e "#SBATCH --no-requeue" >> sbatch_${JOB}_script
fi

#Default module profile loading
echo -e "" >> sbatch_${JOB}_script
echo -e ". /etc/profile.d/modules.sh" >> sbatch_${JOB}_script
echo -e "module purge" >> sbatch_${JOB}_script
echo -e "module load rhel7/default-peta4" >> sbatch_${JOB}_script

if  [[ -f modules_temp ]]; then
	for m in `cat modules_temp`; do
		echo -e "module load ${m}" >> sbatch_${JOB}_script
	done
	rm modules_temp
fi

echo -e "${SCRIPT}" >> sbatch_${JOB}_script

while true; do
    read -p "[# User Input #] Run job file now? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "[# User Input #] Please answer yes (y) or no (n)";;
    esac
done

sbatch sbatch_${JOB}_script

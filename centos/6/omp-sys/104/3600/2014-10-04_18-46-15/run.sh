#!/bin/bash
#SBATCH --ntasks-per-node=8
#SBATCH --workdir=/chome/cluser/job_results/centos/6/omp-sys/104/3600/2014-10-04_18-46-15
#SBATCH --job-name=104_3600_omp-sys
#SBATCH --partition=cos6

. job.cfg

if [ $(cat /etc/issue|grep -c 'Ubuntu 12.04') -eq 1 ];then
    echo "On Ubuntu we do not choose..."
elif [[ ${MPI_VER} =~ omp ]];then
    if [ ${MPI_VER} == omp-sys ];then
        MPI_PATH=/usr/lib64/openmpi
    else
        MPI_NR=$(echo ${MPI_VER} |egrep -o "[0-9\.]+")
        MPI_PATH=/usr/local/openmpi/${MPI_NR}/
    fi
    # ENV
    echo "MPI_PATH=${MPI_PATH}" >> job.cfg
    BASE_PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
    export PATH=${MPI_PATH}/bin:${BASE_PATH}
    export LD_LIBRARY_PATH=${MPI_PATH}/lib:/usr/local/lib
    # \ENV
else 
    echo "unrecogniced mpi version '${MPI_VER}'"
    exit 1
fi
echo "SLURM_NODELIST=${SLURM_NODELIST}" >> job.cfg


START_TIME=$(date +%s)
echo "## $(date +'%F %H:%M:%S') Start mpirun with '${PROB_SIZE}^3 in ${JOB_TIME}sec'"
mpirun --mca btl "self,openib"  /chome/cluser/hpcg-2.4/${OS_BASE}${OS_VER}_${MPI_VER}/bin/xhpcg
EC=$?
echo "## $(date +'%F %H:%M:%S') Job ends"
if [ ${EC} -eq 0 ];then
    END_TIME=$(date +%s)
    WALL_CLOCK=$((${END_TIME}-${START_TIME}))
    echo "WALL_CLOCK=${WALL_CLOCK}" >> job.cfg
    eval_hpcg.py .
fi


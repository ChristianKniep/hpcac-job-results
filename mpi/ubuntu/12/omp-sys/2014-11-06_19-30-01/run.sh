#!/bin/bash
#SBATCH --ntasks-per-node=1
#SBATCH --workdir=/chome/cluser/job_results/mpi/ubuntu/12/omp-sys/2014-11-06_19-30-01
#SBATCH --job-name=mpi-bench_omp-sys
#SBATCH --partition=u12

. job.cfg

BASE_PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
export PATH=${BASE_PATH}
if [ $(cat /etc/issue|grep -c 'Ubuntu 12.04') -eq 1 ];then
    if [ ${MPI_VER} == omp-sys ];then
        BASE_PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
        export PATH=${BASE_PATH}
        export LD_LIBRARY_PATH=/usr/local/lib
    else
        MPI_NR=$(echo ${MPI_VER} |egrep -o "[0-9\.]+")
        MPI_PATH=/usr/local/openmpi/${MPI_NR}/
        echo "MPI_PATH=${MPI_PATH}" >> job.cfg
        BASE_PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
        export PATH=${MPI_PATH}/bin:${BASE_PATH}
        export LD_LIBRARY_PATH=${MPI_PATH}/lib:/usr/local/lib
    fi
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

# BUILD binary if neccessary

echo "START_DATE=$(date +'%F_%H:%M:%S')" >> job.cfg
echo "SLURM_NODELIST=${SLURM_NODELIST}" >> job.cfg
echo "SLURM_JOBID=${SLURM_JOBID}" >> job.cfg
BENCH_DIR=/chome/cluser/mpi_bench/${OS_BASE}${OS_VER}_${MPI_VER}/
if [ ! -d ${BENCH_DIR} ];then
    CWD=$(pwd)
    mkdir -p ${BENCH_DIR}
    cd ${BENCH_DIR}
    tar xf /chome/cluser/src/osu-micro-benchmarks-4.4.1.tar.gz
    cd osu-micro-benchmarks-4.4.1
    ./configure --prefix ${BENCH_DIR}
    make && make install
    cd ${CWD}
fi

BIN_PATH=${BENCH_DIR}/libexec/osu-micro-benchmarks/mpi/collective/


for JOB_BIN in osu_alltoall;do
    START_TIME=$(date +%s)
    echo "START_TIME=${START_TIME}"
    echo "## $(date +'%F %H:%M:%S') Start mpirun with mpi-benchmark"
    echo "mpirun --mca btl self,openib  ${BIN_PATH}/${JOB_BIN} > ${JOB_BIN}.out"
    mpirun --mca btl "self,openib"  ${BIN_PATH}/${JOB_BIN} > ${JOB_BIN}.out
    EC=$?
    echo "## $(date +'%F %H:%M:%S') Job ends"
    if [ ${EC} -eq 0 ];then
        END_TIME=$(date +%s)
        echo "END_TIME=${END_TIME}"
        WALL_CLOCK=$((${END_TIME}-${START_TIME}))
        echo "WALL_CLOCK=${WALL_CLOCK}" >> job.cfg
    else
        echo "!!! EXIT ${EC}"
        exit ${EC}
    fi
done

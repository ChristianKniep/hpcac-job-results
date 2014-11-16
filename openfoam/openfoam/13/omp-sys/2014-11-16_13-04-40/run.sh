#!/bin/bash
#SBATCH --ntasks-per-node=8
#SBATCH --workdir=/chome/cluser/job_results/openfoam/openfoam/13/omp-sys/2014-11-16_13-04-40
#SBATCH --job-name=SED_JOB_NAME
#SBATCH --partition=of13

. job.cfg

BASE_PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
export PATH=${BASE_PATH}
if [ $(cat /etc/issue|grep -c 'Ubuntu ') -eq 1 ];then
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

source /opt/openfoam230/etc/bashrc

sed -i -e "s/numberOfSubdomains.*/numberOfSubdomains ${SLURM_NPROCS};/" /chome/cluser/job_results/openfoam/openfoam/13/omp-sys/2014-11-16_13-04-40/system/decomposeParDict

# Updated by sub_of.sh if neccessary
OF_DECOMP="8 2 1"
if [ "X${OF_DECOMP}" != "X" ];then
    SED_DECOMP=${OF_DECOMP}
elif [ ${SLURM_NPROCS} -eq 24 ];then
    SED_DECOMP="12 2 1"
elif [ ${SLURM_NPROCS} -eq 16 ];then
    SED_DECOMP="8 2 1"
elif [ ${SLURM_NPROCS} -eq 8 ];then
    SED_DECOMP="8 1 1"
fi
sed -i -e "s/SED_DECOMP/(${SED_DECOMP})/" /chome/cluser/job_results/openfoam/openfoam/13/omp-sys/2014-11-16_13-04-40/system/decomposeParDict
echo "OF_DECOMP="8 2 1"
# BUILD binary if neccessary
rm -rf processor*
BLOCKMESH_START_TIME=$(date +%s)
echo "BLOCKMESH_START_TIME=${BLOCKMESH_START_TIME}"
blockMesh > blockmesh.log
BLOCKMESH_END_TIME=$(date +%s)
echo "BLOCKMESH_END_TIME=${BLOCKMESH_END_TIME}"
BLOCKMESH_WALL_CLOCK=$((${BLOCKMESH_END_TIME}-${BLOCKMESH_START_TIME}))
echo "BLOCKMESH_WALL_CLOCK=${BLOCKMESH_WALL_CLOCK}"

DECOMP_START_TIME=$(date +%s)
echo "DECOMP_START_TIME=${DECOMP_START_TIME}"
decomposePar > decomp.log
DECOMP_END_TIME=$(date +%s)
echo "DECOMP_END_TIME=${DECOMP_END_TIME}"
DECOMP_WALL_CLOCK=$((${DECOMP_END_TIME}-${DECOMP_START_TIME}))
echo "DECOMP_WALL_CLOCK=${DECOMP_WALL_CLOCK}"

echo "START_DATE=$(date +'%F_%H:%M:%S')" >> job.cfg
echo "SLURM_NODELIST=${SLURM_NODELIST}" >> job.cfg
echo "SLURM_JOBID=${SLURM_JOBID}" >> job.cfg
START_TIME=$(date +%s)
echo "START_TIME=${START_TIME}"
echo "## $(date +'%F %H:%M:%S') Start mpirun with mpi-benchmark"
echo "mpirun --mca btl \"self,sm,openib\" /opt/openfoam230/platforms/linux64GccDPOpt/bin/icoFoam -parallel"
mpirun --mca btl "self,sm,openib" /opt/openfoam230/platforms/linux64GccDPOpt/bin/icoFoam -parallel > of.out

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

RECON_START_TIME=$(date +%s)
echo "RECON_START_TIME=${RECON_START_TIME}"
reconstructPar > recon.log
RECON_END_TIME=$(date +%s)
echo "RECON_END_TIME=${RECON_END_TIME}"
RECON_WALL_CLOCK=$((${RECON_END_TIME}-${RECON_START_TIME}))
echo "RECON_WALL_CLOCK=${RECON_WALL_CLOCK}"

u_file=$(find . ! -regex ".*/processor.*" -name U|tail -n1)
u_md5=$(md5sum ${u_file})
echo "U_FILE=${u_file}"
echo "U_FILE=${u_file}" >> job.cfg
echo "U_MD5=${u_md5}" 
echo "U_MD5=${u_md5}" >> job.cfg

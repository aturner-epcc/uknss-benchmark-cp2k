#!/bin/bash
#SBATCH --job-name=H2O-ls
#SBATCH --nodes=32
#SBATCH --exclusive
#SBATCH --tasks-per-node=32
#SBATCH --cpus-per-task=9
#SBATCH --gpus-per-node=4
#SBATCH --hint=nomultithread
#SBATCH --time=2:0:0

module load craype-network-ofi
module load PrgEnv-gnu
module load gcc-native/13.2
module load cray-mpich
module load cuda/12.6
module load craype-accel-nvidia90
module load craype-arm-grace
module load cray-python
module load cray-fftw

source /projects/u6cb/software/CP2K/cp2k-2026.1/tools/toolchain/install/setup

CP2K_EXE=/projects/u6cb/software/CP2K/cp2k-2026.1/_build/build/bin/cp2k.psmp

cpn=${SLURM_NTASKS_PER_NODE}
threads=${SLURM_CPUS_PER_TASK}
nodes=$SLURM_JOB_NUM_NODES
casename="H2O-dft-ls.NREP6"
srunopts="--hint=nomultithread --distribution=block:block"

uuid=$(uuidgen)
rundir=${casename}_${uuid}

mkdir ${rundir}
cp input/* ${rundir}/

cd ${rundir}

cores=$(( nodes * cpn ))
timestamp=$(date '+%Y%m%d%H%M')
resfile="${casename}_${nodes}nodes_${cores}cores_${threads}threads_${SLURM_JOB_ID}_${timestamp}.log"
TMPDIR=$PWD

export CUDA_CACHE_PATH="/dev/shm/$USER/cuda_cache"
export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_MALLOC_FALLBACK=1
export OMP_NUM_THREADS=$((SLURM_CPUS_PER_TASK - 1))

ulimit -s unlimited

srun  --cpu-bind=socket \
     ../ismabard-mps-wrapper.sh $CP2K_EXE -i ${casename}.inp -o ${resfile}


mv ${resfile} ../
cd ..
echo "++++ Slurm JobID = ${SLURM_JOB_ID}" >> $resfile
cat slurm-${SLURM_JOB_ID}.out >> $resfile
rm -r ${rundir}



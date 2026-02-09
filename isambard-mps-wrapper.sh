#!/bin/bash
#
# MPS startup wrapper script originally developed for Daint
# system at CSCS:
# https://docs.cscs.ch/running/slurm/#multiple-ranks-per-gpu
#
# Example mps-wrapper.sh usage:
# > srun [srun args] isambard-mps-wrapper.sh [cmd] [cmd args]

# Only this path is supported by MPS
export CUDA_MPS_PIPE_DIRECTORY=/tmp/nvidia-mps
export CUDA_MPS_LOG_DIRECTORY=/tmp/nvidia-log-$(id -un)

# Launch MPS from a single rank per node
if [[ $SLURM_LOCALID -eq 0 ]]; then
    CUDA_VISIBLE_DEVICES=0,1,2,3 nvidia-cuda-mps-control -d
fi

# Set CUDA device. Disable HWLOC_KEEP_NVIDIA_GPU_NUMA_NODES to avoid GPU NUMA
# nodes appearing in the list of CUDA devices. They start appearing in hwloc
# version 2.11.
numa_nodes=$(HWLOC_KEEP_NVIDIA_GPU_NUMA_NODES=0 hwloc-calc --physical --intersect NUMAnode $(hwloc-bind --get --taskset))
export CUDA_VISIBLE_DEVICES=$numa_nodes

# Wait for MPS to start
sleep 1

# Run the command
numactl --membind=$numa_nodes "$@"
result=$?

# Quit MPS control daemon before exiting
if [[ $SLURM_LOCALID -eq 0 ]]; then
    echo quit | nvidia-cuda-mps-control
fi

exit $result


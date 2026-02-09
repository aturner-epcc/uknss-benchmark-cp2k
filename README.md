# UK NSS CP2K benchmark

**Important:** Please do not contact the benchmark maintainers directly with any questions.
All questions on the benchmark must be submitted via the procurement response mechanism.

This repository describes the CP2K benchmark for the UK NSS procurement.
CP2K is a quantum chemistry and solid state physics software package that
can perform atomistic simulations of solid state, liquid, molecular, periodic,
material, crystal, and biological systems. CP2K provides a general framework
for different modeling methods such as DFT using the mixed Gaussian and plane
waves approaches GPW and GAPW. Supported theory levels include DFTB, LDA, GGA,
MP2, RPA, semi-empirical methods (AM1, PM3, PM6, RM1, MNDO, …), and classical
force fields (AMBER, CHARMM, …). CP2K can do simulations of molecular dynamics,
metadynamics, Monte Carlo, Ehrenfest dynamics, vibrational analysis, core level
spectroscopy, energy minimization, and transition state optimization using NEB
or dimer method. CP2K is written in Fortran 2008

The specific benchmark used for this procurement is the H2O-DFT-LS benchmark available
in the main CP2K repository on Github. This is a large system that runs a single-point
energy calculation using linear scaling DFT.

CP2K stresses both the GPU and CPU simultaneously for this benchmark case.

## Status

Stable

## Maintainers

- Andrew Turner

## Overview

### Software

[CP2K](https://github.com/cp2k/cp2k)

### Architectures

- CPU: x86, arm
- GPU: NVIDIA, AMD

### Languages and programming models

- Programming languages: Fortran
- Parallel models: MPI, OpenMP
- Accelerator offload models: CUDA, HIP

## Building the benchmark

**Important:** All results submitted should be based on the following repository commits:

- CP2K repository: [release version 2026.1 (757bb76)](https://github.com/cp2k/cp2k/releases/tag/v2026.1)
- H2O-DFT-LS benchmark: [version from this repository ()]()

Any modifications made to the source code for the baseline build or the optimised build must be 
shared as part of the offerer submission.

### Permitted modifications

#### Baseline build

For the baseline run the only permitted modifications allowed are those that
modify the CP2K or its dependencies to resolve unavoidable compilation or
runtime errors.

#### Optimised build

Any modifications to the source code are allowed as long as they are able to be provided
back to the community under the same licence as is used for the software package that is
being modified.

### Manual build

As an example, we provide manual instructions for building CP2K on
[IsambardAI](https://docs.isambard.ac.uk/specs/#system-specifications-isambard-ai-phase-2).
It is also possible to install CP2K using Spack (we do not provide
instructions for this approach).

**Download and unpack source code**

```
wget https://github.com/cp2k/cp2k/archive/refs/tags/v2026.1.tar.gz
tar -xvf v2026.1.tar.gz
```

**Build dependencies**

```
cd cp2k-2026.1/tools/toolchain

module load craype-network-ofi
module load PrgEnv-gnu 
module load gcc-native/13.2 
module load cray-mpich
module load cuda/12.6
module load craype-accel-nvidia90
module load craype-arm-grace
module load cray-python
module load cray-fftw

export CUDA_PATH=/opt/nvidia/hpc_sdk/Linux_aarch64/24.11/math_libs/12.6

./install_cp2k_toolchain.sh \
   --enable-cuda --gpu-ver=H100 \
   --enable-cray \
   -j16
```

**Build CP2K**

```
cd cp2k-2026.1

module load craype-network-ofi
module load PrgEnv-gnu 
module load gcc-native/13.2 
module load cray-mpich
module load cuda/12.6
module load craype-accel-nvidia90
module load craype-arm-grace
module load cray-python
module load cray-fftw

builddir=_build

mkdir $builddir
cd $builddir

source /projects/u6cb/software/CP2K/cp2k-2026.1/tools/toolchain/install/setup

export LD_LIBRARY_PATH=/opt/nvidia/hpc_sdk/Linux_aarch64/24.11/math_libs/12.6/lib64:$LD_LIBRARY_PATH
export LDFLAGS="-L/opt/nvidia/hpc_sdk/Linux_aarch64/24.11/math_libs/12.6/lib64"
export CUDA_PATH=/opt/nvidia/hpc_sdk/Linux_aarch64/24.11/cuda/12.6
export CC=cc
export CXX=CC
export FC=ftn

cmake -S .. -B build \
    -DCP2K_USE_LIBXC=ON \
    -DCP2K_USE_LIBINT2=ON \
    -DCP2K_USE_SPGLIB=ON \
    -DCP2K_USE_ELPA=ON \
    -DCP2K_USE_SPLA=ON \
    -DCP2K_USE_SIRIUS=ON \
    -DCP2K_USE_COSMA=ON \
    -DCP2K_USE_MPI=ON \
    -DCP2K_USE_ACCEL=CUDA -DCP2K_WITH_GPU=H100 \
    -DCP2K_DBCSR_USE_CPU_ONLY=OFF \
    -DDBCSR_DIR=/projects/u6cb/software/CP2K/cp2k-2026.1/tools/toolchain/install/dbcsr-2.9.0-cuda/lib/cmake/dbcsr

cmake --build build -j 32 
```

## Running the benchmark

Input files for the CP2K H2O-dft-ls benchmark 
are provided in the [benchmark](./benchmark) directory. The directory also
contains example Slurm batch submission scripts from running the benchmark
on the 
[IsambardAI system](https://docs.isambard.ac.uk/specs/#system-specifications-isambard-ai-phase-2).

Example output from the running the benchmark on IsambardAI using 32 nodes
(128 GH200 superchip) with NVIDIA MPS (8 MPI processes per GPU) is also provided
in the "benchmark"  directory.

The parameter "NREP" in the "H2O-dft-ls.inp" file *must* be set to "6" for
submitted results. This parameter sets the problem size and can be
decreased to enable testing on smaller numbers of GPU/GCD if required. The
number of atoms in the model scales cubically with NREP.

**Note:** For best performance from key DBSCR routines a square number of MPI
processes may need to be used (e.g. 64, 256, 1024).

### Required Tests

**Important:** The `NREP` parameter in the "H2O-dft-ls.inp" input file *must* be 
set to "6" for the required tests.

- **Target configuration:** There is *no minimum GPU/GCD count* for the CP2K H2O-dft-ls NREP6 benchmark.
- **Reference FoM:** The reference FoM for the CP2K H2O-dft-ls NREP6 benchmark is from the IsambardAI system using 128 GPU (32 nodes) is *42 s*.

**Important:** For the both the baseline build and the optimised build, the projected FoM submitted 
must give at least the same performance as the reference value.

### Job submission

Make sure all the input files are in the working directory and use the
parallel launcher to run CP2K specifying the input and output file. 

**Note:** You may need to use a wrapper script to enable proper process
to GPU binding or to launch any multi-process per GPU services. 

For example, on IsambardAI, the launch line looks like:

```
srun  --cpu-bind=socket \
     ../isambard-mps-wrapper.sh $CP2K_EXE -i ${casename}.inp -o ${resfile}
```

Using bash variables for the input filename and output filename, Slurm `srun`
as the parallel launcher, and the `../isambard-mps-wrapper.sh` script to 
ensure that the multi-process per GPU service is launched correctly and 
processes are bound to the correct GPU.

The full example Slurm batch script and MPS wrapper script from IsambardAI
are available in this repository:

- [IsambardAI Slurm batch script](./benchmark/submit_isambard_mps.slurm)
- [IsambardAI MPS launch wrapper script](./benchmark/isambard-mps-wrapper.sh)

## Results

### Correctness & Timing 

Correctness can be verified using the [validate.py](./validate.py) script,
which compares the total energy to the expected value on computed on 
IsambardAI (-118874.30605090 hartree). 

Note: different values of NREP in the input file will produce different
total energies for the full system. The energy check in the validate.py
script is onlyvalid when NREP is set to 6.

For example:

```
> ./validate.py --help
| validate.py: test output correctness for the CP2K benchmark.
| Usage: validate.py <output_file>
|

> ./validate.py benchmark/sample_output_32nodes_isambard.log

# CP2K H2O-dft-ls benchmark validation

         Number of atoms: 20736
  Reference case # atoms: 20736

    Measured: -118874.30605090 hartree
   Reference: -118874.30605090 hartree
  Difference: 0.00000000 hartree
   Tolerance: 0.00000100 hartree
  Validation: PASSED

  BenchmarkTime: 42.5 s
```

In addition, `validate.py` will also print the BenchmarkTime,
which is the sole FoM for the benchmark.
The BenchmarkTime printed by `validate.py` corresponds to the
elapsed time reported in the CP2K output file.

### Reference Performance on IsambardAI

The sample data in the table below are measured BencharkTime from the IsambardAI GPU system.
IsambardAI's GPU nodes each have four NVIDIA GH200 superchips;
GPU jobs used 32 MPI processes per node, 8 MPI processes per GPU and 9 OpenMP CPU 
threads per MPI process. [NVIDIA MPS](https://docs.nvidia.com/deploy/mps/index.html)  
is used to support multiple MPI processes per node as this gives improved performance
over a single MPI process per GPU. The upper rows of the table describe
performance change as the problem size increases.
The lower two rows show the performance of the benchmark problem size (NREP 6) for
two different GPU counts CP2K. The final row corresponds to the reference configuration
that must be matched by the offerer.

| Size      | # Atoms | # GH200  | # MPI per GPU | # MPI | BenchmarkTime (s) |
| ----      | ------: | -------: | ------------: | ----: | ----------------: |
| NREP 1    |    96 |   1 |    8 |    8 |   2.3  |
| NREP 2    |   768 |   1 |    8 |    8 |   9.0  |
| NREP 3    |  2592 |   1 |    8 |    8 |  75.7  |
| NREP 4    |  6144 |   4 |    8 |   32 |  75.7  |
| NREP 5    | 12000 |   8 |    8 |   64 | 104.9  |
| NREP 6    | 20736 |  32 |    8 |  256 |  90.2  |
| NREP 6    | 20736 | 128 |    8 | 1024 |  42.0* |


The reference time was determined
by running the reference problem on 128 IsambardAI GH200 (32 GPU nodes)
with 8 MPI processes per GPU and 9 OpenMP CPU threads per MPI process.
and is marked by a *.
The projected BenchmarkTime for the target problem on the target system
must not exceed this value.

## Reporting Results

The offeror should provide copies of:

- Details of any modifications made to the CP2K or dependencies source code
- The compilation process and configuration settings used for the benchmark results - 
  including makefiles, compiler versions, dependencies used and their versions or
  Spack environment configuration and lock files if Spack is used
- The job submission scripts and launch wrapper scripts used (if any)
- The `H2O-dft-ls.inp` file used
- The output from the `validate.py` script
- All standard CP2K output files
- A list of options passed to CP2K (if any)

## License

This benchmark description and any associated files are released under the
MIT license.

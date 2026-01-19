# UK NSS GRID benchmark

Grid_Benchmark is the benchmarking package, available at [https://github.com/aportelli/grid-benchmark].
It is licensed under GPLv2, with a list of
contributors available at [https://github.com/aportelli/grid-benchmark/graphs/contributors].
The benchmark uses the underpinning Grid C++ 17 library for lattice QCD applications.

Note: the repository contains two benchmarks: Benchmark_Grid and Benchmark_IO. Only
Benchmark_Grid is in scope for this procurement.

- Benchmark_Grid: A sparse Dirac matrix performance benchmark which also performs
  independent memory and inter-process communication benchmarks, alongside a correctness
  check.

In summary, Benchmark_Grid benchmarks three discretisations of the Dirac matrix: "Wilson",
"domain-wall" (or DWF4), and "staggered". For benchmarking purposes, the only differences
between these discretisations is the flop count per Dirac matrix application and that domain-wall
has an additional local dimension of size Ls = 12, increasing its memory requirements. The sparse
Dirac matrix benchmark is ran for five problem sizes, each of which assigns a 4D array to each MPI
rank, referred to as the local lattice size or local volume. These are 8^4, 12^4, 16^4, 24^4, and
32^4. Since the local volumes are fixed, increasing the number of MPI ranks corresponds to a
weak scaling of the benchmark.

## Status

Stable

## Maintainers

- Antonin Portelli
- Ryan Hill

## Overview

### Software

[https://github.com/aportelli/grid-benchmark](https://github.com/aportelli/grid-benchmark)

### Architectures

- CPU: x86, Arm
- GPU: NVIDIA, AMD, Intel

### Languages and programming models

- Programming languages: C++
- Parallel models: MPI, OpenMP
- Accelerator offload models: CUDA, HIP

## Building the benchmark

### Permitted modifications

`grid-benchmark` has been written with the intention that no modifications to the source code
are required. It is also intended to be run without the need for additional CLI parameters beyond
`--json-out` and those required by Grid, although a full list of CLI options are provided in the
[grid-benchmark README](https://github.com/aportelli/grid-benchmark/) if required. Below is a list of permitted modifications:

- Only modify the source code to resolve unavoidable compilation or runtime errors. The
  [Grid systems directory](https://github.com/paboyle/Grid/tree/develop/systems) has many examples of configuration and run options known to work on a
  variety of systems in case of e.g. linking errors or runtime issues.
- For compilation on systems with only ROCm 7.x and greater available, it is permitted to use
  the workaround described below as a substitute for code modification. Workarounds
  of this nature are permitted if unresolvable compilation errors otherwise occur.

We place fewer restrictions on the dependencies of Grid, all of which are detailed in the [Grid README](https://github.com/paboyle/Grid/).

- The host-code compiler must support C++17. This limits the choice of host-code compilers to
reasonably recent versions.
- For NVIDIA GPUs, CUDA versions 11.x or 12.x are recommended.
- For AMD GPUs, ROCm version 6.x is recommended since Grid is incompatible with ROCm
  version 7.x without minor code modifications. If only ROCm 7.x is available, we provide
  a workaround below.

#### ROCm 7.x/hipBLAS 3.x workaround

Both the current develop branch of Grid and the selected Grid benchmarking commit explicitly use
the hipBLAS 2.x types hipblasComplex and hipblasDoubleComplex. As of hipBLAS 3.x, which
is the version of hipBLAS included with ROCm 7.x, these types have been deprecated in favour of
hipComplex and hipDoubleComplex. This will cause a compilation failure of the form
error: use of undeclared identifier 'hipblasComplex'.

This can be worked around by adding

```
-DhipblasComplex=hipComplex -DhipblasDoubleComplex=hipDoubleComplex
```

to the `CXXFLAGS` argument passed to the `configure` command for Grid. This can be automated
using a custom preset for the automatic deployment scripts for Grid and grid-benchmark as
documented in the [grid-benchmark README](https://github.com/aportelli/grid-benchmark/).

### Manual build

Detailed build instructions can be found in the benchmark source code
repository at:

- [https://github.com/aportelli/grid-benchmark/blob/main/Readme.md]

Example build configurations are provided for:

- Tursa: CUDA 11.4, GCC 9.3.0, OpenMPI 4.1.1, UCX 1.12.0
- Daint: CUDA 12.4, GCC 14.2, HPE Cray MPICH 8.1.32
- LUMI: ROCm 6.0.3, AMD clang 17.0.1, HPE Cray MPICH 8.1.23 (custom)
- Durham GPU testbed: ROCm 7.0.1, AMD clang 20.0.0, OpenMPI 5.0.9, UCX 1.19.0

## Running the benchmark

### Required Tests

- **Target configuration:** Grid_Benchmark should be run on a minimum of *128 GPU/GCD*.
- **Reference FoM:** from the Tursa system using 16 nodes (64 GPU) is *8614.535 Gflops/s*.
   + [JSON ("result.json") output from the reference run](https://github.com/aportelli/grid-benchmark/blob/main/results/251124/tursa/benchmark-grid-16.116878/result.json)

The projected FoM submitted must give at least the same performance 
as the reference value.

To aid in testing, we provide FoM values for varying problem sizes on
Tursa below. Tursa nodes have 2x AMD ?? EPYC CPU and 4x NVIDIA A100 GPU. 

| Tursa nodes | Total GPU | Parallel decomposition | FoM (Comparison Point Gflops/s) |
|--:|--:|--:|--:|
| 1 | 4 | 1.1.1.4 | 14465.465 |
| 2 | 8 | 1.1.2.4 | 12635.159 |
| 4 | 16 | 1.1.4.4 | 12480.005 |
| 8 | 32 | 1.2.4.4 | 10650.192 |
| 16 | 64 | 1.4.4.4 | 8614.535 |

### Benchmark execution

The submission scripts should be written to accurately allocate NUMA affinities,
GPU indices, CPU thread indices, and any necessary environment variables (such
as GPU-GPU communication settings, e.g. for UCX) for the specific system and software stack in
use, using a wrapper script if necessary (for which there are also examples in the
[grid-benchmark systems directory](https://github.com/aportelli/grid-benchmark/tree/main/systems)).
There are also run scripts for specific systems that may be closer to the target
architecture in the [Grid systems directory](https://github.com/paboyle/Grid/tree/develop/systems).

Grid has many command-line interface flags that control its runtime behaviour. Identify-
ing the optimal flags, as with the compilation options, is system-dependent and requires
experimentation. A list of Grid flags is given by passing `--help` to `grid-benchmark`, and a
full list is provided for both Grid and grid-benchmark in the [grid-benchmark README](https://github.com/aportelli/grid-benchmark/).
A critical flag is `--accelerator-threads`. This heavily influences the warp/wavefront occupancy by
multiplying Grid's default numbers of threads per thread block in a GPU kernel launch. Setting
`--accelerator-threads 8` is generally optimal, but this may vary between hardware and is one
of the first things that should be tested. CPU thread counts per rank are set separately with the
`--threads` flag.

The runtime performance is affected by the MPI rank distribution. MPI ranks are specified
with the `--mpi X.Y.Z.T` flag. To be representative of realistic workloads, the following algorithm
must be used as a guideline for setting the MPI decomposition:

1. Allocate ranks to T until it reaches 4, e.g. `--mpi 1.1.1.4`.
2. Allocate ranks to Z until it reaches 4, e.g. `--mpi 1.1.4.4`.
3. Allocate ranks to Y until it reaches 4, e.g. `--mpi 1.4.4.4`.
4. Allocate ranks to X until it reaches 4, e.g. `--mpi 4.4.4.4`.
5. If further ranks are required, continue to allocate evenly in powers of 2.

A single GPU should be allocated per MPI rank (or GCD in the case of e.g. MI250X).
The subdirectories in the [benchmark systems directory](https://github.com/aportelli/grid-benchmark/tree/main/systems)
have example wrapper scripts for how to do this.

While Grid options can be varied, the benchmarks themselves should be run with no additional
flags than `--json-out`, which will write the results of the benchmark to a JSON file.

## Reporting Results

Note that the benchmark will generate more output data than is
requested, the offeror needs only to report the benchmark values
requested. Additional data may be provided if desired.

The offeror should provide copies of:

- Details of any modifications made to the Grid or Grid_Benchmark source code
- The compilation process and configuration settings used for the benchmark results - 
  including compiler versions, dependencies used and their versions
- The job submission scripts used (if any)
- A list of options passed to the benchmark code
- The JSON results files from running the benchmarks

The benchmark should be compiled and run on the compiler and MPI
environment that will be provided on the proposed machine.

## License

This benchmark description and associated files are released under the
MIT license.

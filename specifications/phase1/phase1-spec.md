# Phase 1 Specification: Infrastructure and Baseline (M1-M4)

Precision-AMR, FAPESP APR 2026. This document turns Phase 1 of the proposal into an ordered, step-by-step execution roadmap.

| Item | Value |
|------|-------|
| Source of truth | `apr-fapesp-precision-amr-2026/src/en/mixed-precision-amr-en.tex`, section "Phase 1 --- Infrastructure and Baseline (M1--M4)" and the timeline table |
| Target application | Awave-3D with GPUZIP v2.0 (`/Users/sandro/Documents/work/projetos/gpuzip/awave3d`, GPUZIP as git submodule) |
| Duration | 4 months (M1-M4) |
| Status of this document | Draft roadmap. Nothing below has been executed yet. |

## 1. Objective

Before any precision change is attempted, reproduce the GPUZIP/Awave-3D baselines under the NVIDIA HPC SDK and prepare the code base so that every later phase can build on it. Phase 1 has four technical goals:

1. **Port and validate.** Build Awave-3D and GPUZIP with `nvc++` (HPC SDK), re-integrate nvCOMP/Bitcomp, and confirm numerical and performance parity with the V100 baselines.
2. **Tile decomposition with a precision tag.** Extend the existing checkpoint-block structure so each block (tile) can carry a precision tag. In Phase 1 the tag is only stored and propagated. It does not yet change any arithmetic.
3. **Roofline profiling.** Profile every kernel with Nsight Systems and Nsight Compute and confirm that the finite-difference stencils are memory-bandwidth-bound at tile granularity.
4. **HIP port of the decompose version.** Port the multi-GPU decompose solver (`src_decompose`) to HIP and validate it on the laboratory AMD MI210 GPU, so Awave-3D exists in two maintained backends, CUDA and HIP. The CUDA version stays the reference. This goal is an addition to the proposal text, see section 12.

### Deliverable (from the proposal)

> GPUZIP/Awave-3D ported and validated under the HPC SDK, with numerical parity confirmed against the V100 baselines and the block decomposition extended to carry precision tags; per-block roofline profiling report.

### Additional deliverable (not in the proposal text)

> A HIP build of the Awave-3D decompose version, validated on the laboratory AMD MI210 against the same reference outputs as the CUDA build, with both backends built from one source tree.

## 2. Execution environments and constraints

The development machine is a Mac without an NVIDIA GPU. CUDA code cannot be run here. Every step in this roadmap is therefore tagged with where it can run.

| Tag | Environment | What can be done there |
|-----|-------------|------------------------|
| `[LOCAL]` | Mac (this machine) | Reading code, writing specs, scripts, CMake changes, analysis tooling (Python), CPU-only builds and tests, documentation. No CUDA compilation or execution. |
| `[SD-V100]` | Santos Dumont, BullSequana X1000, 4x V100 nodes | Original GPUZIP hardware. Baseline reproduction. |
| `[SD-H100]` | Santos Dumont, BullSequana XH3000, 4x H100 SXM 80 GB | HPC SDK port validation on Hopper. |
| `[RTX5090]` | Dedicated RTX 5090 workstation (requested in the proposal) | Interactive debugging and roofline profiling. Depends on hardware procurement, see risk R1. |
| `[MI210]` | Laboratory machine with an AMD Instinct MI210 (CDNA2, `gfx90a`) | HIP port, build and correctness tests, rocprof profiling. Requires ROCm. Not a Santos Dumont partition, so it is not subject to queues. |

The laboratory GPU is an AMD Instinct MI210 (`gfx90a`, 64 GB HBM2e). Step 5.1 verifies this with `rocminfo`, since the architecture determines the compile target.

Rule of thumb: prepare everything `[LOCAL]`, then execute in batches on the GPU environments, so scarce GPU time is spent only on runs that are fully scripted and reviewed.

## 3. Reference baselines and datasets

- **Baselines to reproduce:** the V100 results reported for GPUZIP (up to 5.1x end-to-end speedup, up to 80x reduction in host-GPU transfer volume, image quality SSIM ~ 1 and near-zero relative error), using Bitcomp via nvCOMP, with the Revolve, zCut and Uniform checkpointing algorithms.
- **Datasets available in the repository** (`awave3d/tests/`): `small`, `medium`, `large`, `salt`, plus `h20` and `jesse`. Each has a modeling and a migration `.par` file and reference outputs (`*-good.su`, `*-mig-good.data`, `*-mig-chkpts-good.data`).
- **Larger data:** `awave3d/experiments/datasets.dvc` tracks about 31 GB (68 files), which presumably includes Marmousi3D. Retrieval requires DVC access, see step 0.3.
- **Phase 1 dataset subset:** `small` and `medium` for fast correctness loops, then `salt`, `large` and Marmousi3D for baseline reproduction. The remaining proposal datasets (Overthrust, Sigsbee 2A/2B) are needed from Phase 2 onward and are out of scope here.

## 4. Roadmap

Each step has an ID, an environment tag, a concrete output and an acceptance criterion. Steps within a workstream are sequential unless stated otherwise.

### WS0. Project setup and inventory (M1)

| ID | Env | Step | Output / acceptance |
|----|-----|------|---------------------|
| 0.1 | `[LOCAL]` | Record the exact state of the code base: Awave-3D commit, GPUZIP submodule commit (currently `765fa2b`), CMake options, CUDA version (13), compiler versions. | `specifications/phase1/baseline-inventory.md` listing every version and flag. |
| 0.2 | `[LOCAL]` | Read the existing build and run flow: `CMakeLists.txt` options (`USE_CUDA`, `GPUZIP`, `NVCOMP_BITCOMP`, `ZFP`, `USE_DOUBLE`, `USE_FASTMATH`), the `src_decompose` solver, `experiments/scripts/*` and `experiments/gpuzip_config/*.par`. | Short "how it runs today" section in the inventory file, including the exact command lines used for the V100 baselines. |
| 0.3 | `[LOCAL]` | Confirm access paths: Santos Dumont account and allocation, DVC remote for the datasets, nvCOMP and HPC SDK availability (modules or NGC containers) on Santos Dumont. | Checklist with each item marked available or blocked, with owner for each blocker. |
| 0.4 | `[LOCAL]` | Decide the repository strategy for the work: a Phase 1 branch in the Awave-3D repository and a pinned GPUZIP submodule commit. | Branch name and rules written in the inventory file. |

### WS1. Baseline capture with the current toolchain (M1-M2)

Goal: freeze the "before" numbers using the code that already builds with CUDA 13 and `nvcc`, so the port in WS2 has something exact to be compared against.

| ID | Env | Step | Output / acceptance |
|----|-----|------|---------------------|
| 1.1 | `[LOCAL]` | Write a single parameterised run script (Slurm and non-Slurm modes) that, given dataset, checkpoint algorithm, compressor and cache capacity, runs the migration and stores logs, timings and output image in a run directory named by configuration and commit. Reuse `experiments/scripts/awave3d-decom-ogbon.sh` and `run_experiments_decom.sh` as a starting point. | Script in the Awave-3D repo `experiments/scripts/`, dry-runnable on the Mac with `--dry-run`. |
| 1.2 | `[LOCAL]` | Write the comparison tool (Python) that takes two migrated images and reports PSNR, SSIM and mean relative error, and another that parses GPUZIP performance logs (`EnablePerformanceLog=1`) into a table. | `utils/compare_images.py` and `utils/parse_perf_log.py` with unit tests running on the existing `tests/*-good.data` files. |
| 1.3 | `[LOCAL]` | Define the baseline experiment matrix (see section 5). | Matrix file (CSV) listing every run: dataset x algorithm x compressor x cache size. |
| 1.4 | `[SD-V100]` | Build the current code with `nvcc` for `sm_70` and run `small` and `medium` correctness tests against the `*-good` references. | Tests pass. Build log archived. |
| 1.5 | `[SD-V100]` | Run the full baseline matrix on the V100 partition. Each configuration is repeated at least 3 times to estimate run-to-run variance. | Raw logs, images and timings stored per section 6. |
| 1.6 | `[LOCAL]` | Compare the V100 results with the published GPUZIP numbers and write down any gap. | Baseline report v1: a table of speedup, transfer volume, PSNR, SSIM, MRE per configuration, plus a note on whether the published numbers were reproduced. |

Acceptance for WS1: the published V100 behavior is reproduced within the tolerances in section 7, or the discrepancy is explained and signed off before moving on.

### WS2. HPC SDK (nvc++) port (M1-M3)

| ID | Env | Step | Output / acceptance |
|----|-----|------|---------------------|
| 2.1 | `[LOCAL]` | Audit the code for constructs that matter when `nvc++` is the host compiler: GCC/Clang-specific flags in `CMakeLists.txt` (`-march=native`, `-Xcompiler -fopenmp`, `--use_fast_math` handling, sanitizer and `clang-format` modules), OpenMP usage, C/C++ mix in `common/*.c`. List every change needed. | Port checklist in `specifications/phase1/nvcpp-port-checklist.md`. |
| 2.2 | `[LOCAL]` | Prepare the CMake changes: toolchain selection for NVHPC (`CC=nvc`, `CXX=nvc++`, `CUDA_HOST_COMPILER`), CUDA architecture list (`sm_70`, `sm_90`, `sm_120` for the RTX 5090), and a CMake preset per target. | Patch on the Phase 1 branch. Existing GCC/Clang builds must remain unaffected. |
| 2.3 | `[LOCAL]` | Prepare an NVIDIA HPC SDK container recipe (the repository already has an `hpccm` recipe) and the Santos Dumont module-load script. | Container recipe and `env/` scripts, reviewed. |
| 2.4 | `[SD-V100]` | Configure and build with nvc++ for `sm_70`. Fix compile and link errors. | Binaries for CPU, single-GPU and decompose versions build cleanly. |
| 2.5 | `[SD-V100]` | Re-integrate nvCOMP/Bitcomp under the HPC SDK (`-DGPUZIP=1 -DNVCOMP_BITCOMP=1`). Verify the nvCOMP version bundled with the HPC SDK against the one used by GPUZIP. Keep the cuZFP path building (`-DZFP=1`). | GPUZIP builds with both compressors. Any API differences documented. |
| 2.6 | `[SD-V100]` | Run `small` and `medium` correctness tests with the nvc++ build, no compression, against the `*-good` references. | Pass within tolerance (section 7). |
| 2.7 | `[SD-V100]` | Run the full baseline matrix with the nvc++ build and compare with the WS1 results (nvcc build). | Parity report: numerical and performance deltas per configuration. |
| 2.8 | `[SD-H100]` | Build for `sm_90`, run the correctness tests and a reduced matrix on H100. | Build and correctness pass on Hopper. H100 numbers recorded as a new reference. |
| 2.9 | `[LOCAL]` | Add a CI job (or documented manual procedure) that builds with nvc++ and runs the CPU tests, so the port does not regress. | Entry in `.gitlab-ci.yml` or a documented procedure. |

Acceptance for WS2: all builds succeed under the HPC SDK, correctness tests pass, and parity with WS1 is within the tolerances in section 7.

### WS3. Block/tile decomposition with a precision tag (M2-M4)

This workstream is mostly design and code that can be written and unit-tested on the Mac, then validated on GPU.

| ID | Env | Step | Output / acceptance |
|----|-----|------|---------------------|
| 3.1 | `[LOCAL]` | Study the current structures: `common/decompose_struct.h`, `common_cuda/decompose.cu` (`Decom_t`, `alloc_decom`, segments) and the checkpoint save and restore path in `src_decompose/afd3d_solver_decompose.cu` (`prefetch[d]->Save/Retrieve`, `Checkpointing`, `Prefetch`, compressor builders in GPUZIP). | Notes in `specifications/phase1/tile-design.md`: how a checkpoint is laid out in memory today, how it is split between GPUs and how it is handed to the compressor. |
| 3.2 | `[LOCAL]` | Write the design for the tile structure: tile shape and size (candidate sizes to be tested, e.g. 16^3, 32^3, 64^3 grid points plus halo), indexing, mapping tile to GPU segment and to checkpoint, and how to store a per-tile tag. | Design section with data layout, API sketch and rationale. |
| 3.3 | `[LOCAL]` | Keep the tile structure and the tag array independent of the GPU backend (plain data types, no CUDA types in the interface), so it works unchanged under CUDA and HIP. Define the tag. Minimum content: a precision enum (`FP64`, `FP32`, `FP16/BF16`, `FP8`, `OZAKI_FP64`) and a reserved field for criterion metadata (which of the four criteria set it). Default value: the precision currently used by the solver, so behavior is unchanged. | Tag specification in the design file. |
| 3.4 | `[LOCAL]` | Decide how the tag array is exposed to kernels and to GPUZIP (device array, one byte per tile, plus a host copy). Decide how checkpoint save and restore carry the tag together with the data, including the compressed path. | Interface decisions recorded, with the compatibility impact on GPUZIP's `Save`/`Retrieve` signatures. |
| 3.5 | `[LOCAL]` | Implement the tile index and tag container in plain C++ (host only) with unit tests that run on the Mac: index arithmetic, tag get/set, round trip to a byte buffer. | Tests pass locally. |
| 3.6 | `[SD-V100]` | Integrate the container into the decompose solver: tiles are built at setup, tags are default-initialised, saved and restored with each checkpoint. No change to arithmetic. | Migration output is identical to WS2 results (bit-exact when compression is off, same metrics when it is on). |
| 3.7 | `[SD-V100]` | Add a debug mode that writes a non-default tag pattern (for example boundary tiles tagged `FP32`) and verifies that the pattern survives save, compress, decompress and restore. | Test passes. Confirms the tag really is carried through the whole checkpoint path. |
| 3.8 | `[SD-V100]` | Measure the overhead of the tile layer (time and memory) against the WS2 build. | Overhead within the tolerance in section 7. |

Acceptance for WS3: the tag is stored and propagated end to end, results are unchanged with default tags, and the overhead is within tolerance.

### WS4. Instrumentation and profiling (M3-M4)

| ID | Env | Step | Output / acceptance |
|----|-----|------|---------------------|
| 4.1 | `[LOCAL]` | Enable and review the NVTX ranges (`common_cuda/nvtx.cuh`, `USE_NVTX` is currently commented out in `CMakeLists.txt`) so each stencil kernel, boundary kernel, compression, decompression and transfer is a named range. Decide kernel naming so that profiles can be attributed to tile-level work. | NVTX build option re-enabled and documented. |
| 4.2 | `[LOCAL]` | Write the profiling scripts: `nsys profile` for timelines and `ncu` for per-kernel metrics (DRAM throughput, achieved FLOP/s per precision, arithmetic intensity, SM and memory utilisation, roofline sections). Include a kernel-name filter and a limited number of kernel launches per run to keep `ncu` time bounded. | Scripts in `experiments/profiling/`. |
| 4.3 | `[LOCAL]` | Write the roofline post-processing (Python): read the `ncu` CSV export, compute arithmetic intensity and attained performance per kernel, plot against the hardware ceilings (peak bandwidth and peak FP32, FP64 for each GPU). | `utils/roofline.py` tested on a small hand-made CSV. |
| 4.4 | `[SD-V100]` | Run Nsight Systems on the baseline configurations to get the timeline (compute, transfer, compression overlap). | `.nsys-rep` files archived. |
| 4.5 | `[SD-V100]` `[SD-H100]` | Run Nsight Compute on every kernel for `small`, `medium` and `salt`. | `.ncu-rep` and CSV files archived. |
| 4.6 | `[RTX5090]` | Repeat 4.4 and 4.5 on the RTX 5090 once available. | Same artifacts for the Blackwell-class card. |
| 4.7 | `[LOCAL]` | Produce the per-block (per-tile) roofline report: kernel-level roofline for each GPU, a statement for each stencil kernel on whether it is memory-bandwidth-bound or compute-bound at tile granularity, and the list of dense sub-kernels that could be tensor-core candidates in later phases. | `report/roofline-report.md` (see section 6). The MI210 roofline comes from step 5.10. |

Acceptance for WS4: every kernel has a roofline position on each available GPU, and the report confirms (or refutes, with explanation) that the FDM stencils are memory-bandwidth-bound at tile granularity.

### WS5. HIP port of the decompose version (M2-M4)

Goal: one source tree that builds the decompose solver for CUDA (reference) and for HIP. A survey of `common_cuda/`, `src_decompose/` and `src_cuda/` shows what is involved: about 24 kernel launches with the `<<<>>>` syntax, no inline assembly, no warp shuffles and no texture or surface objects, and plain CUDA runtime API calls (`cudaMalloc`, `cudaMemcpyAsync`, streams, `cudaMallocHost`, `cudaMallocManaged`, peer access, device attributes). Most of this maps one to one to HIP. The parts that need real attention are listed in the steps.

| ID | Env | Step | Output / acceptance |
|----|-----|------|---------------------|
| 5.1 | `[MI210]` | Record the machine: `rocminfo`, ROCm version, `hipcc --version`, GPU architecture, host compiler, OS, MPI or OpenMP runtime. Confirm the target is `gfx90a`. | Section added to `baseline-inventory.md`. |
| 5.2 | `[LOCAL]` | Define the portability strategy and write it down in `specifications/phase1/hip-port-design.md`. Recommended approach: a thin compatibility header (for example `gpu_runtime.h`) that maps `gpu*` names to `cuda*` or `hip*` according to a build option, and keep a single set of `.cu` sources. Alternative: run `hipify-perl` once and maintain two trees. The single-tree option is preferred because it prevents the two backends from diverging. | Design note with the decision, the rationale and the mapping table. |
| 5.3 | `[LOCAL]` | Inventory every CUDA-specific construct and decide its HIP equivalent. Known items: (a) runtime API calls, (b) `cudaMallocManaged` with `cudaMemAdvise` and the `cudaMemLocation` structure used for prefetch hints (the CUDA 13 style API), which may behave differently or need a fallback to explicit transfers on ROCm, (c) peer access between GPUs (`cudaDeviceEnablePeerAccess`), (d) `cudaDeviceGetAttribute` with compute-capability queries, which have no HIP meaning, (e) NVTX ranges, replaced by roctx, (f) `cudaGetErrorEnum` and the `helper_cuda.h` style error checking, (g) CMake: `CudaDetect.cmake`, `enable_language(CUDA)` and `CMAKE_CUDA_ARCHITECTURES`, (h) launch configuration assumptions, notably warp size 32 on NVIDIA versus wavefront size 64 on CDNA, and shared memory sizes. | Table in the design note, one row per construct, with the chosen mapping and a risk rating. |
| 5.4 | `[LOCAL]` | Implement the compatibility header and the CMake changes (`-DUSE_HIP=ON`, `enable_language(HIP)`, `CMAKE_HIP_ARCHITECTURES=gfx90a`, ROCm package discovery). The CUDA build must be unchanged and still pass on the NVIDIA machines. | Patch on a dedicated branch, for example `hip-port`, reviewed. A CUDA configure on the Mac side is not possible, so review is by reading plus the GPU runs in 2.6 and 5.11. |
| 5.5 | `[MI210]` | Build the CPU-independent pieces and the decompose solver with `hipcc`. Fix compile and link errors in small commits, one construct at a time. | `awave3d-decompose` (HIP) builds. |
| 5.6 | `[MI210]` | Run the unit tests for the decomposition (`unit_test_vel_decom`, `unit_test_field_decom`) and the `small` and `medium` modeling tests against `*-good.su`. | Pass within the tolerance in section 7. |
| 5.7 | `[MI210]` | Run the `small` and `medium` migration tests without compression and without prefetch, then with prefetch and Uniform or Revolve checkpointing (host-side logic, no compressor). | Images match the references. |
| 5.8 | `[MI210]` | Resolve wavefront-size and tuning issues: verify every kernel's block dimensions are valid for wavefront 64, check occupancy and shared memory use, and replace any CUDA-only intrinsics found. Measure which kernels are slower than expected. | List of fixes. No kernel left with a known correctness issue. |
| 5.9 | `[MI210]` | Run `salt` and `large` migration, uncompressed, with the three checkpointing algorithms. Record timings and compare images against the CUDA results. | Cross-backend table: MI210 vs V100/H100 time, and image difference (PSNR, SSIM, mean relative error). |
| 5.10 | `[MI210]` | Profile with `rocprof` (timeline and counters) and `omniperf` if installed. Produce a roofline for the stencil kernels on MI210, using the same tooling as WS4 (`utils/roofline.py` extended for rocprof CSV). | Roofline of the MI210 stencil kernels, with a statement on whether they are memory-bandwidth-bound. |
| 5.11 | `[SD-V100]` | Rebuild the CUDA version from the refactored single tree and rerun `small` and `medium`, to prove the portability layer did not change the CUDA results. | CUDA results identical to the WS2 results. |
| 5.12 | `[LOCAL]` | Decide the GPUZIP compression strategy for AMD, as a design note only: nvCOMP/Bitcomp is NVIDIA-only. Candidates are ZFP with HIP support (to be checked against the ZFP version used by GPUZIP), a ROCm-native compressor, or leaving AMD uncompressed in Phase 1. Implementation is not part of Phase 1. | Short note in `hip-port-design.md`, linked to the proposal's cross-architecture phase. |
| 5.13 | `[LOCAL]` | Document the build and run instructions for both backends, and add the HIP build to CI or to the manual procedure. | README section and CI entry or procedure. |

Acceptance for WS5: the HIP build of the decompose version produces migrated images consistent with the CUDA build on `small`, `medium`, `salt` and `large` (uncompressed), the CUDA build is unaffected by the refactor, and the stencil roofline on MI210 is documented.

### WS6. Closing the phase (M4)

| ID | Env | Step | Output / acceptance |
|----|-----|------|---------------------|
| 6.1 | `[LOCAL]` | Consolidate: baseline report, parity report, tile design, HIP port report, profiling report, build instructions. | `specifications/phase1/report/` populated, including `hip-report.md`. |
| 6.2 | `[LOCAL]` | Tag a release of the Awave-3D Phase 1 branch (for example `precision-amr-phase1`), including the HIP-capable tree, and pin the GPUZIP submodule commit. | Git tag. |
| 6.3 | `[LOCAL]` | Review against the exit criteria in section 8 and record the decision to start Phase 2. | Signed-off checklist. |

## 5. Baseline experiment matrix

| Dimension | Values |
|-----------|--------|
| Dataset | `small`, `medium` (correctness only); `salt`, `large`, Marmousi3D (baselines) |
| Checkpoint algorithm | Revolve, zCut, Uniform (GPUZIP `Algorithm` setting: trace-based or Revolve, see `experiments/gpuzip_config/template.par`) |
| Compressor | none, Bitcomp (nvCOMP); cuZFP for cross-checking. On MI210 only the uncompressed path is required in Phase 1, see WS5. |
| Cache capacity | 0 (no prefetch), 2, and larger values as used in the original study |
| Build | nvcc (WS1), nvc++ (WS2), hipcc on AMD (WS5) |
| GPU | V100, H100, RTX 5090 (where available), MI210 (HIP) |

Not every combination is required. The first version of the matrix should be restricted to what the original GPUZIP study ran, and then extended only if time allows. The exact original values must be extracted from the GPUZIP paper (`maltempi-et-al-2025`, available in `apr-fapesp-precision-amr-2026/assets/`) and from the old experiment logs, which is step 1.3.

## 6. Artifacts and layout

Proposed layout, to be created as steps are executed:

```
specifications/phase1/
├── phase1-spec.md              # this document
├── baseline-inventory.md       # step 0.1, 0.2, 0.4
├── nvcpp-port-checklist.md     # step 2.1
├── tile-design.md              # steps 3.1 to 3.4
├── hip-port-design.md          # steps 5.2, 5.3, 5.12
└── report/                     # step 6.1
    ├── baseline-report.md
    ├── parity-report.md
    ├── hip-report.md
    └── roofline-report.md
```

Raw data (images, logs, `.nsys-rep`, `.ncu-rep`) is large and must not be committed to this repository. Store it on Santos Dumont and track it with DVC or a manifest of paths and checksums. Each run directory name encodes dataset, algorithm, compressor, cache capacity, build, GPU and commit hash.

## 7. Acceptance tolerances (proposed)

These values are proposals and must be confirmed against the original GPUZIP results before use.

| Check | Tolerance |
|-------|-----------|
| nvc++ vs nvcc, no compression, same GPU | Migrated image mean relative error <= 1e-6 (FP32 build). Bit-exact is not required because compilers may reorder floating-point operations. |
| nvc++ vs nvcc, with Bitcomp | PSNR and SSIM within the run-to-run variance of the baseline. SSIM >= 0.999. |
| Performance parity (nvc++ vs nvcc) | End-to-end time within +/- 5% on the same GPU and configuration. |
| Reproduction of published V100 numbers | Speedup and transfer reduction within +/- 10% of the published values, or the gap explained. |
| Tile layer overhead (default tags) | <= 2% end-to-end time and no change in peak device memory beyond the tag array. |
| HIP (MI210) vs CUDA, uncompressed | Migrated image mean relative error <= 1e-5 and SSIM >= 0.999 against the CUDA result on the same dataset. The looser bound allows for different floating-point contraction and math library behavior on AMD. To be tightened if the observed difference is much smaller. |
| Correctness tests | `small` and `medium` match `*-good` references to the existing test tolerance. |

## 8. Exit criteria for Phase 1

Phase 1 is complete when all of the following hold:

1. Awave-3D and GPUZIP build under the HPC SDK (nvc++) for `sm_70` and `sm_90`, with nvCOMP/Bitcomp integrated.
2. Numerical parity against the V100 baselines is confirmed within section 7 on the Phase 1 datasets and the three checkpointing algorithms.
3. The tile decomposition carries a per-tile precision tag through the full checkpoint path (save, compress, decompress, restore), with unchanged results under default tags.
4. A per-block roofline report exists for every kernel on Santos Dumont, and on the RTX 5090 when available, stating for each stencil kernel whether it is memory-bandwidth-bound.
5. The decompose version builds with HIP from the same source tree as the CUDA build, runs on the MI210 and matches the CUDA results within section 7 on `small`, `medium`, `salt` and `large` (uncompressed), and the CUDA build is unchanged.
6. The Phase 1 branch is tagged and the baseline artifacts are archived with checksums.

## 9. Milestones

| Month | Milestone | Steps |
|-------|-----------|-------|
| M1 | Inventory done, run and comparison tooling ready, baseline matrix defined, MI210 environment recorded | 0.1-0.4, 1.1-1.3, 5.1 |
| M2 | nvcc baselines captured, nvc++ builds on V100, tile design approved, HIP design and compatibility layer written | 1.4-1.6, 2.1-2.5, 3.1-3.4, 5.2-5.4 |
| M3 | nvc++ parity confirmed on V100 and H100, tile layer integrated, profiling scripts ready, HIP build running small and medium tests on MI210 | 2.6-2.9, 3.5-3.8, 4.1-4.3, 5.5-5.8 |
| M4 | Profiling executed, HIP validated on salt and large, roofline and HIP reports written, phase closed | 4.4-4.7, 5.9-5.13, 6.1-6.3 |

## 10. What can start today on the Mac

The following steps need no GPU and can start immediately, in this order:

1. 0.1 and 0.2: inventory and understanding of the current build and run flow.
2. 1.2: image comparison and log parsing tools, tested on the existing `tests/*-good.*` files.
3. 1.1 and 1.3: run script and experiment matrix.
4. 2.1 to 2.3: nvc++ audit, CMake changes and container recipe.
5. 3.1 to 3.5: tile design and host-only implementation with unit tests.
6. 4.1 to 4.3: NVTX review, profiling scripts and roofline tooling.
7. 5.2 and 5.3: HIP portability strategy and construct inventory. The MI210 machine can be used right away for 5.1 and, once 5.4 is written, for 5.5 onward, since it does not depend on the Santos Dumont queue.

## 11. Risks and open questions

| ID | Item | Impact and mitigation |
|----|------|-----------------------|
| R1 | The RTX 5090 is requested hardware and may not exist during Phase 1. | Roofline on Blackwell-class hardware would be delayed. Phase 1 can close with Santos Dumont profiles only, and the RTX 5090 profile is added when the card arrives. |
| R2 | Santos Dumont queue times and allocation limits. | Fully script runs on the Mac, batch them, and request allocation early (step 0.3). |
| R3 | nvc++ may not accept parts of the current CUDA/C++ code or CMake setup (it already compiles with CUDA 13, but the host compiler is unknown to this document). | Step 2.1 audit before any GPU time is spent. Fallback: keep `nvcc` with GCC as host compiler and use the HPC SDK for libraries and profilers only, then record this as a deviation from the proposal. |
| R4 | nvCOMP version in the HPC SDK may differ from the version GPUZIP was built against, and Bitcomp behavior or API may have changed. | Step 2.5 records versions, and the baseline matrix includes a Bitcomp rerun to detect compression-ratio changes. |
| R5 | The original GPUZIP experiment configurations may not be fully documented. | Reconstruct from the paper and from `experiments/` scripts, ask the GPUZIP authors, and write the reconstructed matrix into the inventory file. |
| R6 | Marmousi3D and large datasets may be unavailable without DVC credentials. | Step 0.3. Until then, run the matrix on `salt` and `large` from `tests/`. |
| R7 | The proposal says the port targets nvc++ and the FP32 solver is the default build (`USE_DOUBLE` is OFF). The FP64 reference needed by Phase 2 requires `USE_DOUBLE=ON`. | Decide in step 0.2 whether Phase 1 also validates the FP64 build, and if so add it to the matrix. This is likely cheap and prevents a Phase 2 surprise. |

| R8 | The HIP port adds a fifth goal to a 4-month phase and competes for the same person-time as the nvc++ port and the tile layer. | The HIP work is mostly independent of WS2 and WS3 and runs on a local machine without queues. If time is short, WS5 can be reduced to steps 5.1 to 5.7, with 5.8 to 5.13 moved to the start of the cross-architecture phase. |
| R9 | `cudaMallocManaged` with `cudaMemAdvise` and the `cudaMemLocation` prefetch hints may not behave as on NVIDIA, which could change prefetch performance and correctness assumptions. | Step 5.3 identifies each use. Fallback: explicit device buffers and `hipMemcpyAsync` on AMD, behind the compatibility header. |
| R10 | GPUZIP compression (Bitcomp) has no AMD counterpart, so the MI210 path is uncompressed and GPUZIP's main benefit cannot be measured there in Phase 1. | Accepted for Phase 1. Strategy decided in 5.12 and implemented later. |
| R11 | ROCm version or driver on the laboratory machine may not support the required HIP features or may be outdated. | Record versions in 5.1 before writing code. Upgrade ROCm if needed, which is within lab control. |
| R12 | Wavefront size 64 and different memory hierarchy on CDNA2 may expose latent assumptions in kernel launch configurations, giving wrong results rather than only slow ones. | Step 5.8 reviews launch configurations explicitly, and the unit tests in 5.6 run before any full migration. |

Open questions for the project lead:

1. Which exact V100 configurations and numbers from the GPUZIP paper are the official baselines?
2. Is falling back to `nvcc` with GCC acceptable if nvc++ cannot build the code (R3)?
3. Should Phase 1 include validation of the FP64 build (R7)?
4. Is the target tile size already fixed, or should WS3 evaluate several?
5. Which ROCm version is installed on the laboratory machine?
6. Should the HIP port keep a single source tree with a compatibility header (recommended), or a separate hipified tree?
7. Is it acceptable that the MI210 runs are uncompressed in Phase 1?

## 12. Relation to the proposal

The proposal text places AMD work in a later, dedicated cross-architecture phase, targeting the MI300A on Santos Dumont, with an exploratory HIP port of the compression path. Pulling the HIP port of the decompose solver into Phase 1 is a scope addition. It does not contradict the proposal, and it de-risks the later phase, but it should be reflected in the Phase 1 description of the timeline (and in the Portuguese and English texts, following the repository's pt-first approval flow) if the team wants the submitted document to match the execution plan. No change to the LaTeX sources has been made.

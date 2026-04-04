# u_core Architecture Freeze

## Scope

This document is the normalized architecture freeze note for the current `u_core`
project. It complements the original Word-format architecture specification and
captures the architecture decisions that are already considered frozen for ongoing
design work.

Primary source document:

- [`异构处理器总体规格与总体架构设计说明书_V1_5_整合增强版.docx`](/root/Project/docs/异构处理器总体规格与总体架构设计说明书_V1_5_整合增强版.docx)

Detailed interface supplement:

- [`u_core_interface_definition.md`](/root/Project/docs/u_core_interface_definition.md)

CPU integration study note:

- [`picorv32_integration_notes.md`](/root/Project/docs/picorv32_integration_notes.md)

## Architecture Freeze Statement

The current `u_core` architecture is frozen at the architectural-boundary level.
This freeze applies to:

- system partitioning
- module responsibilities
- control-plane and data-plane ownership
- first-version command model
- first-version compute model
- first-version inter-module interface direction

This freeze does not yet imply that all CSR offsets, bitfields, or RTL state
machines are fully detailed.

## Frozen System Composition

The first-version system is composed of:

- `cpu_subsys`
- `dma_top`
- `spm_subsys`
- `npu_top`
- external shared storage model

The target system shape is:

- `32-bit` CPU
- independent DMA engine
- independent SPM subsystem
- `16x16` systolic-array NPU

## Frozen Module Responsibilities

### `cpu_subsys`

- uses `picorv32_axi`
- CPU core RTL is not modified
- owns the control plane
- performs boot, configuration, status polling, and result checking
- does not perform burst data movement
- does not perform array compute

### `dma_top`

- is the only AXI4 Full master in first version
- performs tile movement between external shared storage and `spm_subsys`
- performs output write-back from `out_spm` to external shared storage
- does not perform matrix multiply
- does not directly drive the NPU cycle by cycle

### `spm_subsys`

- is the only data-intersection layer between DMA and NPU
- contains `act_spm`, `wgt_spm`, and `out_spm`
- is not treated as a CPU-oriented general-purpose peripheral
- exists as an independent subsystem and not as an internal NPU-only block

### `npu_top`

- is a fixed-function compute engine
- receives local data from `spm_subsys`
- writes local output back into `out_spm`
- does not implement AXI4 Full master access
- does not implement a first-version descriptor queue

## Frozen Control/Data Plane Split

The first-version plane split is fixed as follows:

- control plane: `AXI4-Lite`
- data plane: `AXI4 Full`

Architectural ownership is fixed as:

- CPU owns AXI4-Lite control transactions
- DMA owns AXI4 Full bulk data transfers

This split is not to be relaxed in first-version implementation.

## Frozen DMA Command Model

The first-version DMA command model is frozen as:

- `LOAD_ACT`
- `LOAD_WGT`
- `STORE_OUT`

No additional first-version DMA command types are assumed by default.

Each descriptor represents exactly one of the above operations.

The DMA command-flow architecture is frozen as:

- descriptor staging registers
- pending descriptor FIFO
- scheduler-mediated execution

## Frozen SPM Positioning

The following points are frozen:

- DMA and NPU do not exchange bulk compute data directly
- all such data must cross through `spm_subsys`
- `act_spm` and `wgt_spm` are first-version dual-buffer resources
- `out_spm` is first-version single-buffer

This means:

- `LOAD_ACT` targets `act_spm`
- `LOAD_WGT` targets `wgt_spm`
- NPU reads from `act_spm` and `wgt_spm`
- NPU writes into `out_spm`
- `STORE_OUT` reads from `out_spm`

## Frozen NPU Execution Model

The first-version NPU launch model is frozen as:

- CPU programs `npu_csr`
- CPU writes `START`
- NPU waits for required local resources
- NPU computes the tile
- NPU writes the output tile into `out_spm`

The following are explicitly frozen:

- no first-version NPU descriptor queue
- no first-version NPU-managed external bulk movement
- first-version software flow is polling-oriented

## Frozen Numeric And Array Baseline

The first-version compute baseline is frozen as:

- systolic array size: `16x16`
- compute precision: `INT8 x INT8`
- accumulation precision: `INT32`
- preferred first-version `Ktile`: `32`
- dataflow: `output-stationary`

First-version task focus is:

- GEMM
- FC

Convolution is expected to map through software-side transform into GEMM-style execution.

## Frozen `buf_sel` Interpretation

The architectural meaning of `buf_sel[1:0]` is frozen as:

- it indicates only a local buffer index
- it does not encode storage class
- storage class is derived from `op_type`

First-version legality:

- `LOAD_ACT`: `buf_sel=0/1`
- `LOAD_WGT`: `buf_sel=0/1`
- `STORE_OUT`: `buf_sel=0` only

## Frozen CPU Address Map

The current first-version control-side address map is frozen as:

| Address Range | Target |
| --- | --- |
| `0x0000_0000 ~ 0x0000_3FFF` | `boot_rom` |
| `0x0001_0000 ~ 0x0001_7FFF` | `local_ram_wrapper` |
| `0x1000_0000 ~ 0x1000_0FFF` | `npu_csr` |
| `0x1000_1000 ~ 0x1000_1FFF` | `dma_csr_if` |
| `0x1000_2000 ~ 0x1000_2FFF` | `sys_perf_error` |
| `0x2000_0000 ~ ...` | external shared storage |

## Frozen Project-Level Guidance

The following project guidance is now considered standard:

- architecture decisions should be captured under `docs/`
- interface contracts should be documented before large RTL expansion
- imported CPU source is currently maintained under `u_core_module_cpu/rtl/`
- new module-level notes should align to `cpu_subsys`, `dma_top`, `spm_subsys`, `npu_top`, and top-level integration

## Relationship To Interface Definition

The architecture freeze note defines:

- what the blocks are
- what each block is allowed to do
- how the top-level responsibilities are split

The interface-definition note defines:

- how blocks communicate
- what signal groups exist
- what architectural fields and status classes are exposed

Both documents should be read together before RTL implementation begins.

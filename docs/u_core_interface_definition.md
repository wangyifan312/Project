# u_core Interface Definition

## Scope

This document fills in the reserved interface-definition chapter for the current
`u_core` architecture baseline and is intended to support RTL decomposition for:

- `cpu_subsys`
- `dma_top`
- `spm_subsys`
- `npu_top`
- top-level integration and verification

Primary architecture reference:

- [`异构处理器总体规格与总体架构设计说明书_V1_5_整合增强版.docx`](/root/Project/docs/异构处理器总体规格与总体架构设计说明书_V1_5_整合增强版.docx)

Supporting study note:

- [`picorv32_integration_notes.md`](/root/Project/docs/picorv32_integration_notes.md)

## Frozen Architectural Assumptions

The following assumptions are treated as frozen for this interface definition:

- CPU core is `picorv32_axi` and CPU core RTL is not modified.
- CPU owns the control plane and uses a `32-bit AXI4-Lite` master interface.
- DMA is the only AXI4 Full master on the external shared-memory data plane.
- SPM is the only data-intersection layer between DMA and NPU.
- DMA first-version command set is limited to `LOAD_ACT`, `LOAD_WGT`, and `STORE_OUT`.
- `buf_sel[1:0]` indicates only a buffer index, not a storage type.
- `op_type` determines whether the target storage type is `act_spm`, `wgt_spm`, or `out_spm`.
- `act_spm` and `wgt_spm` are dual-buffer in the first version.
- `out_spm` is single-buffer in the first version, so only `buf_sel=0` is legal for `STORE_OUT`.
- NPU first version uses `CSR + START` and does not implement a descriptor queue.

## Signal Conventions

Unless a section explicitly states otherwise:

- clock: `clk`
- active-low reset: `rst_n`
- all status and control signals are synchronous to `clk`
- all multi-bit addresses are byte addresses unless marked as local row indices
- `valid/ready` means a transfer completes on the cycle both are high
- `*_en` means a level-style enable
- `*_pulse` means a one-cycle trigger
- widths are written as `MSB:LSB` or by total bit count

Recommended shared local parameters for RTL packages or header files:

```systemverilog
localparam int AXIL_ADDR_W   = 32;
localparam int AXIL_DATA_W   = 32;
localparam int AXI_DATA_W    = 512;
localparam int AXI_STRB_W    = AXI_DATA_W / 8;
localparam int ARRAY_M       = 16;
localparam int ARRAY_N       = 16;
localparam int ARRAY_K_TILE  = 32;
localparam int ACT_ELEM_W    = 8;
localparam int WGT_ELEM_W    = 8;
localparam int PSUM_ELEM_W   = 32;
localparam int OUT_ELEM_W    = 16;
localparam int BUF_SEL_W     = 2;
```

`OUT_ELEM_W=16` is recommended as the fixed physical write width for first-version
`out_spm` ingress. When the quantization result is `INT8`, the valid payload uses
the low `8` bits of each lane.

## Top-Level Module Connectivity

The intended top-level connectivity is:

- `cpu_subsys` to top-level control interconnect: AXI4-Lite master
- `boot_rom`: AXI4-Lite slave
- `local_ram_wrapper`: AXI4-Lite slave
- `dma_top` CSR front-end: AXI4-Lite slave
- `npu_top` CSR front-end: AXI4-Lite slave
- `sys_perf_error` block: AXI4-Lite slave
- `dma_top` to external shared memory: AXI4 Full master
- `dma_top` to `spm_subsys`: local row-based data interface
- `npu_top` to `spm_subsys`: local vector-stream read interface plus local output-write interface

## 2.1 Top-Level AXI4-Lite Control Plane Interface

### 2.1.1 Interface Role

The CPU master interface is used for:

- boot ROM instruction fetch
- local RAM load/store
- DMA CSR programming
- NPU CSR programming
- system status, error, and performance register access

### 2.1.2 AXI4-Lite Master/Slave Signal Set

All control-plane slaves use a standard 32-bit AXI4-Lite signal set:

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `awvalid` | M->S | 1 | Write address valid |
| `awready` | S->M | 1 | Write address ready |
| `awaddr` | M->S | 32 | Write address |
| `awprot` | M->S | 3 | AXI protection attribute |
| `wvalid` | M->S | 1 | Write data valid |
| `wready` | S->M | 1 | Write data ready |
| `wdata` | M->S | 32 | Write data |
| `wstrb` | M->S | 4 | Write strobes |
| `bvalid` | S->M | 1 | Write response valid |
| `bready` | M->S | 1 | Write response ready |
| `bresp` | S->M | 2 | Write response |
| `arvalid` | M->S | 1 | Read address valid |
| `arready` | S->M | 1 | Read address ready |
| `araddr` | M->S | 32 | Read address |
| `arprot` | M->S | 3 | Read protection attribute |
| `rvalid` | S->M | 1 | Read data valid |
| `rready` | M->S | 1 | Read data ready |
| `rdata` | S->M | 32 | Read data |
| `rresp` | S->M | 2 | Read response |

### 2.1.3 Control-Plane Address Map

| Address Range | Target | Role |
| --- | --- | --- |
| `0x0000_0000 ~ 0x0000_3FFF` | `boot_rom` | Reset vector and boot code |
| `0x0001_0000 ~ 0x0001_7FFF` | `local_ram_wrapper` | Stack, globals, runtime data |
| `0x1000_0000 ~ 0x1000_0FFF` | `npu_csr` | NPU configuration and status |
| `0x1000_1000 ~ 0x1000_1FFF` | `dma_csr_if` | DMA descriptor staging and status |
| `0x1000_2000 ~ 0x1000_2FFF` | `sys_perf_error` | System status, counters, error reporting |

### 2.1.4 CPU Reset and Stack Constants

The following constants are recommended for first-version integration:

- `PROGADDR_RESET = 32'h0000_0000`
- `PROGADDR_IRQ   = 32'h0000_0010`
- `STACKADDR      = 32'h0001_8000`

`STACKADDR` should point to the top boundary just above the first-version local
RAM range, so software uses descending stack growth inside local RAM.

## 2.2 DMA CSR And Status Interface

### 2.2.1 Interface Role

The DMA CSR block is the CPU-visible staging and observability interface for:

- building a DMA descriptor in software
- submitting a descriptor into the DMA pending queue
- checking DMA queue occupancy and execution status
- reading basic performance and error information

### 2.2.2 Descriptor Model

One descriptor represents exactly one DMA operation:

- `LOAD_ACT`
- `LOAD_WGT`
- `STORE_OUT`

The CPU writes descriptor fields into a staging register set and then issues a
`submit` write pulse. The staging registers do not become an executable pending
entry until the `submit` operation is accepted.

### 2.2.3 Descriptor Fields

Recommended first-version architectural descriptor fields:

| Field | Width | Meaning |
| --- | --- | --- |
| `op_type` | 2 | `00=LOAD_ACT`, `01=LOAD_WGT`, `10=STORE_OUT`, `11=reserved` |
| `src_addr` | 32 | External-memory source byte address |
| `dst_addr` | 32 | External-memory destination byte address |
| `row_len` | 16 | Number of bytes per row |
| `row_cnt` | 16 | Number of rows in this descriptor |
| `src_stride` | 16 | Source row stride in bytes |
| `dst_stride` | 16 | Destination row stride in bytes |
| `buf_sel` | 2 | Local buffer index only |
| `spm_row_base` | 16 | Starting row index inside the selected local storage |
| `tile_id` | 16 | Optional software-visible tag |
| `flags` | 16 | Reserved for future policy bits |

Architectural usage rule:

- for `LOAD_ACT` and `LOAD_WGT`, `src_addr` is used and `dst_addr` is ignored
- for `STORE_OUT`, `dst_addr` is used and `src_addr` is ignored
- `buf_sel` does not encode `act/wgt/out`
- storage type is derived only from `op_type`

### 2.2.4 `buf_sel` Rule

`buf_sel[1:0]` is frozen as:

- `LOAD_ACT`: `0` and `1` are legal
- `LOAD_WGT`: `0` and `1` are legal
- `STORE_OUT`: only `0` is legal in first version
- other values are reserved and must be reported as illegal configuration

### 2.2.5 Recommended DMA Status Signals

These signals may be physically implemented as CSR bits and counters:

| Signal | Width | Meaning |
| --- | --- | --- |
| `dma_busy` | 1 | DMA currently executing at least one descriptor |
| `dma_done` | 1 | Last submitted/retired descriptor completed |
| `dma_error` | 1 | DMA has a sticky error condition |
| `dma_fifo_empty` | 1 | Pending FIFO empty |
| `dma_fifo_full` | 1 | Pending FIFO full |
| `dma_fifo_level` | 3 | Number of pending descriptors |
| `dma_done_count` | 32 | Number of completed descriptors |
| `dma_rd_beat_count` | 32 | AXI read beats completed |
| `dma_wr_beat_count` | 32 | AXI write beats completed |
| `dma_error_code` | 8 | Encoded first-version error cause |

Recommended architectural error classes:

- illegal `op_type`
- illegal `buf_sel`
- zero `row_len`
- zero `row_cnt`
- misaligned external address
- submit while staging content is invalid
- local buffer not available for the requested operation

## 2.3 DMA <-> External Shared Memory AXI4 Full Interface

### 2.4.1 Interface Role

This interface is the only first-version high-throughput external data-plane interface.
It is owned exclusively by `dma_top`.

Architectural scope:

- `LOAD_ACT`: AXI read from external shared storage
- `LOAD_WGT`: AXI read from external shared storage
- `STORE_OUT`: AXI write to external shared storage

The external shared storage can be implemented by:

- an AXI slave VIP plus memory model during verification
- a real memory controller or equivalent target in later integration

### 2.3.2 AXI4 Full Data Width Baseline

The first-version external DMA interface is frozen as:

- `AXI_ADDR_W = 32`
- `AXI_DATA_W = 512`
- `AXI_STRB_W = 64`

DMA is the only block allowed to originate these AXI4 Full bursts.

### 2.3.3 Write Address Channel

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `m_axi_awvalid` | DMA->MEM | 1 | Write address valid |
| `m_axi_awready` | MEM->DMA | 1 | Write address accepted |
| `m_axi_awaddr` | DMA->MEM | 32 | Write burst start byte address |
| `m_axi_awlen` | DMA->MEM | 8 | Burst length minus 1 |
| `m_axi_awsize` | DMA->MEM | 3 | Beat size, fixed to `64B` in first version |
| `m_axi_awburst` | DMA->MEM | 2 | Burst type, first version uses `INCR` |
| `m_axi_awid` | DMA->MEM | 4 | Optional transaction tag, may be fixed |

### 2.3.4 Write Data Channel

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `m_axi_wvalid` | DMA->MEM | 1 | Write data valid |
| `m_axi_wready` | MEM->DMA | 1 | Write data accepted |
| `m_axi_wdata` | DMA->MEM | 512 | Write beat payload |
| `m_axi_wstrb` | DMA->MEM | 64 | Write byte enables |
| `m_axi_wlast` | DMA->MEM | 1 | Last beat of burst |

### 2.3.5 Write Response Channel

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `m_axi_bvalid` | MEM->DMA | 1 | Write response valid |
| `m_axi_bready` | DMA->MEM | 1 | DMA accepts write response |
| `m_axi_bresp` | MEM->DMA | 2 | AXI write response |
| `m_axi_bid` | MEM->DMA | 4 | Optional response tag |

### 2.3.6 Read Address Channel

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `m_axi_arvalid` | DMA->MEM | 1 | Read address valid |
| `m_axi_arready` | MEM->DMA | 1 | Read address accepted |
| `m_axi_araddr` | DMA->MEM | 32 | Read burst start byte address |
| `m_axi_arlen` | DMA->MEM | 8 | Burst length minus 1 |
| `m_axi_arsize` | DMA->MEM | 3 | Beat size, fixed to `64B` in first version |
| `m_axi_arburst` | DMA->MEM | 2 | Burst type, first version uses `INCR` |
| `m_axi_arid` | DMA->MEM | 4 | Optional transaction tag, may be fixed |

### 2.3.7 Read Data Channel

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `m_axi_rvalid` | MEM->DMA | 1 | Read data valid |
| `m_axi_rready` | DMA->MEM | 1 | DMA accepts read data |
| `m_axi_rdata` | MEM->DMA | 512 | Read beat payload |
| `m_axi_rresp` | MEM->DMA | 2 | AXI read response |
| `m_axi_rlast` | MEM->DMA | 1 | Last beat of burst |
| `m_axi_rid` | MEM->DMA | 4 | Optional read-response tag |

### 2.3.8 Architectural Usage Rules

First-version architectural rules:

- DMA uses AXI reads for `LOAD_ACT` and `LOAD_WGT`
- DMA uses AXI writes for `STORE_OUT`
- only one first-version DMA read engine is assumed by default
- act and weight loads are not required to execute in parallel
- burst type is `INCR`
- external burst generation is derived from:
  - `src_addr` or `dst_addr`
  - `row_len`
  - `row_cnt`
  - `src_stride`
  - `dst_stride`

### 2.3.9 Alignment Guidance

First-version architectural guidance:

- external addresses should be aligned to the `512-bit` beat boundary when possible
- `row_len` is expressed in bytes
- `stride` is expressed in bytes
- partial first or last beat handling is permitted architecturally
- unsupported alignment patterns should be surfaced through `dma_error`

### 2.3.10 External-Memory Error Visibility

The following external-interface-related conditions should feed DMA status:

- AXI read response error
- AXI write response error
- unsupported address alignment
- illegal or unsupported burst shape

These conditions should ultimately be observable from:

- `dma_error`
- `dma_error_code`
- system-level summary error reporting

## 2.4 DMA <-> SPM Local Data Interface

### 2.3.1 Interface Role

This interface carries bulk local row transfers between `dma_top` and `spm_subsys`.
It is intentionally local and storage-oriented, not AXI-based.

The first-version architecture assumes:

- DMA writes `act_spm` and `wgt_spm`
- DMA reads `out_spm`
- transfer granularity is a local row
- row payload matches one external `512-bit` AXI data beat

### 2.4.2 Local Row Write Channel

Used for `LOAD_ACT` and `LOAD_WGT`.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `dma_spm_wr_valid` | DMA->SPM | 1 | Local write request valid |
| `dma_spm_wr_ready` | SPM->DMA | 1 | Local write request accepted |
| `dma_spm_wr_type` | DMA->SPM | 2 | `00=act`, `01=wgt`, other reserved |
| `dma_spm_wr_buf_sel` | DMA->SPM | 2 | Local target buffer index |
| `dma_spm_wr_row_idx` | DMA->SPM | 3 | Local `64B` row index within selected buffer |
| `dma_spm_wr_data` | DMA->SPM | 512 | Row payload |
| `dma_spm_wr_strb` | DMA->SPM | 64 | Byte enables for partial last row |
| `dma_spm_wr_last` | DMA->SPM | 1 | Last row of this descriptor |

Architectural rule:

- `dma_spm_wr_type` selects `act_spm` or `wgt_spm`
- `dma_spm_wr_buf_sel` selects buffer `0` or `1`
- `dma_spm_wr_row_idx` is relative to `spm_row_base`

### 2.4.3 Local Row Read Channel

Used for `STORE_OUT`.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `dma_spm_rd_req_valid` | DMA->SPM | 1 | Local read request valid |
| `dma_spm_rd_req_ready` | SPM->DMA | 1 | Read request accepted |
| `dma_spm_rd_buf_sel` | DMA->SPM | 2 | `out_spm` buffer index |
| `dma_spm_rd_row_idx` | DMA->SPM | 3 | Local `64B` row index within selected buffer |
| `dma_spm_rd_data_valid` | SPM->DMA | 1 | Read payload valid |
| `dma_spm_rd_data_ready` | DMA->SPM | 1 | DMA accepts payload |
| `dma_spm_rd_data` | SPM->DMA | 512 | Row payload |
| `dma_spm_rd_last` | SPM->DMA | 1 | Last row of this descriptor |

Architectural rule:

- first version only allows `dma_spm_rd_buf_sel=0`
- `out_spm` is read only after NPU has completed the corresponding output tile

### 2.4.4 Local Availability And Error Signals

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `act_buf_writable[1:0]` | SPM->DMA | 2 | Act buffers available for DMA write |
| `wgt_buf_writable[1:0]` | SPM->DMA | 2 | Wgt buffers available for DMA write |
| `out_buf_readable[1:0]` | SPM->DMA | 2 | Out buffers available for DMA read |
| `spm_dma_error` | SPM->DMA | 1 | Local-access protocol or protection error |
| `spm_dma_error_code` | SPM->DMA | 8 | Encoded local-access error cause |

These signals expose architecture-level resource availability without forcing a
specific internal ownership-state implementation.

## 2.5 NPU <-> SPM Local Interface

### 2.4.1 Interface Role

This interface serves two functions:

- `spm_subsys` provides activation and weight vectors to the NPU array path
- `npu_top` writes final output vectors into `out_spm`

The architecture treats this as a compute-local streaming interface, not as a
memory-mapped bus.

### 2.4.2 NPU Input Vector Interface

`spm_subsys` provides one activation vector and one weight vector per accepted cycle.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `spm_npu_vec_valid` | SPM->NPU | 1 | Input vector pair valid |
| `spm_npu_vec_ready` | NPU->SPM | 1 | NPU accepts input vector pair |
| `spm_npu_act_buf_sel` | NPU->SPM | 2 | Selected activation buffer |
| `spm_npu_wgt_buf_sel` | NPU->SPM | 2 | Selected weight buffer |
| `spm_npu_k_idx` | NPU->SPM | 6 | Local K-step index, first version supports `0..31` |
| `spm_npu_act_vec` | SPM->NPU | 128 | `16 x INT8` activation vector |
| `spm_npu_wgt_vec` | SPM->NPU | 128 | `16 x INT8` weight vector |

Architectural rule:

- each accepted vector pair corresponds to one K-step of the active tile
- vector ordering must be documented consistently between `spm_subsys` and `array_frontend`
- first version assumes direct support for `Ktile=32`

### 2.4.3 NPU Output Write Interface

`npu_top` writes final quantized output vectors into `out_spm`.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `npu_spm_out_valid` | NPU->SPM | 1 | Output write valid |
| `npu_spm_out_ready` | SPM->NPU | 1 | Output write accepted |
| `npu_spm_out_buf_sel` | NPU->SPM | 2 | Output buffer index |
| `npu_spm_out_row_idx` | NPU->SPM | 4 | Output row within current tile |
| `npu_spm_out_col_mask` | NPU->SPM | 16 | Per-lane validity mask |
| `npu_spm_out_data` | NPU->SPM | 256 | `16 x OUT_ELEM_W` output vector |
| `npu_spm_out_last` | NPU->SPM | 1 | Last output row of the tile |

Architectural rule:

- first version only allows `npu_spm_out_buf_sel=0`
- one output write transfers one logical output row of up to `16` elements
- for `INT8` output mode, each lane uses the low `8` bits of its `16-bit` slot
- `npu_spm_out_col_mask[15:0]` maps one-to-one to the `16` output lanes

### 2.4.4 Buffer-Availability Signals For NPU

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `act_buf_ready[1:0]` | SPM->NPU | 2 | Activation buffer contains valid tile data |
| `wgt_buf_ready[1:0]` | SPM->NPU | 2 | Weight buffer contains valid tile data |
| `out_buf_free[1:0]` | SPM->NPU | 2 | Output buffer may accept a new tile result |
| `spm_npu_error` | SPM->NPU | 1 | Local-access contract violation |
| `spm_npu_error_code` | SPM->NPU | 8 | Encoded local-access error cause |

These signals are sufficient for the first-version `CSR + START` NPU model:

- CPU programs `npu_csr`
- CPU writes `START`
- NPU enters an armed/waiting state
- NPU begins execution only when selected act/wgt buffers are ready and the output buffer is free

## 2.6 NPU CSR And Status Interface

### 2.5.1 Interface Role

The NPU CSR block is the CPU-visible configuration and observability interface for:

- selecting buffer indices
- selecting mode and quantization parameters
- defining tile-local compute shape within the first-version architecture
- issuing a `START` pulse
- observing progress and completion

### 2.5.2 Recommended First-Version NPU CSR Fields

| Field | Width | Meaning |
| --- | --- | --- |
| `npu_mode` | 4 | First-version compute mode, GEMM/FC-oriented |
| `ktile_cfg` | 8 | Recommended legal value is `32` |
| `act_buf_sel` | 2 | Activation buffer index |
| `wgt_buf_sel` | 2 | Weight buffer index |
| `out_buf_sel` | 2 | Output buffer index, first version only `0` legal |
| `quant_shift` | 8 | Quantization right shift |
| `quant_zero_point` | 16 | Output zero point |
| `relu_en` | 1 | Optional ReLU enable |
| `start_pulse` | 1 | Launch trigger |

### 2.5.3 Recommended First-Version NPU Status Signals

| Signal | Width | Meaning |
| --- | --- | --- |
| `npu_armed` | 1 | Start accepted, waiting for resources |
| `npu_busy` | 1 | NPU is actively computing |
| `npu_done` | 1 | Current tile compute and local output write are complete |
| `npu_error` | 1 | NPU has a sticky error condition |
| `npu_stall_cycles` | 32 | Cycles spent waiting for local resources |
| `npu_busy_cycles` | 32 | Cycles spent computing |
| `npu_error_code` | 8 | Encoded first-version error cause |

Recommended architectural error classes:

- illegal output buffer selection
- start issued while NPU is busy or armed
- activation buffer not ready
- weight buffer not ready
- output buffer not free
- local output write contract violation

## 2.7 System Status And Completion Interface

### 2.6.1 System-Level Completion Rule

A first-version tile job is considered fully complete only when:

- NPU has completed compute and local output write
- `out_spm` for the target tile is readable by DMA
- DMA has completed `STORE_OUT`
- no DMA or NPU error remains uncleared

### 2.6.2 Recommended System-Visible Summary Signals

| Signal | Width | Meaning |
| --- | --- | --- |
| `sys_job_done` | 1 | One full tile pipeline has completed |
| `sys_job_error` | 1 | Either DMA or NPU has reported an error |
| `sys_dma_busy` | 1 | Mirrored DMA busy summary |
| `sys_npu_busy` | 1 | Mirrored NPU busy summary |
| `sys_out_valid` | 1 | Output tile is present in local output storage |
| `sys_out_committed` | 1 | Output tile has been written back externally |

These summary signals may be exported through the `SYS/PERF/ERROR` CSR block.

## 2.8 Open Items Explicitly Left Outside This Document

This document intentionally does not freeze:

- internal RTL state machines
- exact FIFO depth implementation beyond first-version recommendations
- exact SPM banking micro-architecture
- exact quantization arithmetic implementation
- detailed CSR register offsets and bit slicing
- detailed AXI4 Full burst parameterization for DMA

Those topics should remain in module-level design notes or RTL implementation documents.

## Recommended Next Use

This interface-definition document is intended to be used as the direct input for:

- `cpu_subsys` top-level port definition
- `dma_top` CSR and local-interface port definition
- `spm_subsys` top-level port definition
- `npu_top` CSR and local-interface port definition
- block-level verification plan and interface assertions

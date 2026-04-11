# dma_top FS

## Scope

This file captures the current first RTL-facing functional spec of `dma_top`.

## Role

`dma_top` is the first-version data-plane mover between external shared storage
and `spm_subsys`.

First-version command scope:

- `LOAD_ACT`
- `LOAD_WGT`
- `STORE_OUT`

## RTL Partition

The current DMA RTL is intentionally split into small modules:

- `dma_csr_if.sv`
- `dma_desc_stage.sv`
- `dma_desc_fifo.sv`
- `dma_scheduler.sv`
- `dma_addr_gen.sv`
- `dma_rd_engine.sv`
- `dma_wr_engine.sv`
- `dma_local_if.sv`
- `dma_status_perf.sv`
- `dma_top.sv`

Partition rule:

- `dma_csr_if` handles AXI-Lite slave protocol and CPU-visible register access
- `dma_desc_stage` stores one software-visible staging descriptor
- `dma_desc_fifo` stores pending descriptors, first version `4-entry`
- `dma_scheduler` decides whether the FIFO head can issue
- `dma_addr_gen` computes external and local row addresses
- `dma_rd_engine` handles `LOAD_ACT/LOAD_WGT` execution sequencing
- `dma_wr_engine` handles `STORE_OUT` execution sequencing
- `dma_local_if` bridges DMA-local row transactions to the SPM local interface
- `dma_status_perf` keeps busy/done/error/counter state
- `dma_top` performs only top-level integration

## Current RTL Scope

Current first RTL scope is:

- CSR path
- descriptor staging
- pending FIFO
- descriptor issue decision
- AXI4 Full single-beat read execution for `LOAD_ACT/LOAD_WGT`
- AXI4 Full single-beat write execution for `STORE_OUT`
- local-interface sequencing toward `spm_subsys`
- status and performance counter plumbing

Current first RTL supported subset:

- one descriptor row maps to one `512-bit / 64B` AXI beat
- `row_len` is supported only in the range `1..64`
- `src_addr` / `dst_addr` must be `64B` aligned
- `src_stride` / `dst_stride` must be `64B` aligned
- `spm_row_base + row_cnt` must stay within the DMA-visible local row space
  of one buffer, which is `8` rows in the current first RTL

This means the current DMA RTL is now a real external-memory mover, but only
for the current first-version single-beat-per-row contract.

## Descriptor Layout

Current first-version staging register layout is compacted for CPU programming
efficiency. A software-visible descriptor now needs only:

- `DMA_DESC_CFG0`
- `DMA_SRC_ADDR`
- `DMA_DST_ADDR`
- `DMA_DESC_CFG1`
- `DMA_CMD`

Packed field rule:

- `DMA_DESC_CFG0[1:0]`: `op_type`
- `DMA_DESC_CFG0[3:2]`: `buf_sel`
- `DMA_DESC_CFG0[6:4]`: `spm_row_base`
- `DMA_DESC_CFG0[13:7]`: `row_len`
- `DMA_DESC_CFG0[17:14]`: `row_cnt`
- `DMA_DESC_CFG1[9:0]`: `ext_stride_units`

Where:

- `ext_stride_units` uses `64B` units
- `LOAD_ACT / LOAD_WGT` expand this field into `src_stride`
- `STORE_OUT` expands this field into `dst_stride`

Internally, the packed descriptor bus still expands into the full execution
shape expected by `dma_addr_gen`, `dma_rd_engine`, and `dma_wr_engine`.

## Validation Policy In `dma_desc_stage`

Current descriptor validation checks:

- `op_type` must be one of `LOAD_ACT/LOAD_WGT/STORE_OUT`
- `row_len != 0`
- `row_cnt != 0`
- `row_len <= 64`
- `spm_row_base + row_cnt <= 8`
- `LOAD_ACT/LOAD_WGT` allow `buf_sel=0/1`
- `STORE_OUT` allows only `buf_sel=0`
- `LOAD_ACT/LOAD_WGT` currently require `src_addr[5:0] == 0`
- `LOAD_ACT/LOAD_WGT` currently require `ext_stride_units << 6` as the effective aligned source stride
- `STORE_OUT` currently requires `dst_addr[5:0] == 0`
- `STORE_OUT` currently requires `ext_stride_units << 6` as the effective aligned destination stride

## Scheduling Policy

Current `dma_scheduler` policy:

- FIFO head is examined only
- `LOAD_ACT` requires target `act` buffer writable and read engine idle
- `LOAD_WGT` requires target `wgt` buffer writable and read engine idle
- `STORE_OUT` requires `out` buffer readable and write engine idle

No act/wgt dual-read parallel issue is implemented in the current first RTL.

## Local-Interface Execution Policy

### `LOAD_ACT / LOAD_WGT`

Current `dma_rd_engine` behavior:

- consumes one descriptor
- iterates row-by-row
- issues one AXI `AR` request per row
- accepts one AXI `R` beat per row
- emits `dma_spm_wr_*`
- writes returned AXI payload into SPM
- checks `RRESP` and `RLAST`
- updates `dma_rd_beat_count`

### `STORE_OUT`

Current `dma_wr_engine` behavior:

- consumes one descriptor
- iterates row-by-row
- emits `dma_spm_rd_*`
- accepts returned row payload
- issues one AXI `AW/W/B` transaction per row
- applies byte-enable from `row_len`
- checks `BRESP`
- updates `dma_wr_beat_count`

## Status Policy

Current `dma_status_perf` maintains:

- `dma_busy`
- `dma_done`
- `dma_error`
- `dma_fifo_empty`
- `dma_fifo_full`
- `dma_fifo_level`
- `dma_done_count`
- `dma_rd_beat_count`
- `dma_wr_beat_count`
- `dma_error_code`

Sticky policy:

- `dma_done` is cleared by a new `submit`
- `dma_error` is sticky after the first error
- `dma_error_code` keeps the first latched error code

## Error Code Summary

- `0x01`: illegal `op_type`
- `0x02`: illegal `buf_sel`
- `0x03`: zero `row_len`
- `0x04`: zero `row_cnt`
- `0x05`: alignment error
- `0x06`: FIFO full on submit
- `0x07`: unsupported descriptor shape in the current first RTL
- `0x08`: local row range overflow
- `0x09`: AXI read response error
- `0x0A`: AXI write response error

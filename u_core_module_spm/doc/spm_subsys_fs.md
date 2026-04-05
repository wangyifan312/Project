# spm_subsys FS

## Scope

This file captures the first RTL-facing functional spec of `spm_subsys` for the
current `u_core` baseline.

## Role

`spm_subsys` is the only local data-intersection layer between `dma_top` and
`npu_top`.

It contains:

- `act_spm`
- `wgt_spm`
- `out_spm`

It does not expose a CPU-side data path in the first version.

## RTL Partition

For debug and incremental verification, the current RTL is split into:

- `act_spm.sv`
- `wgt_spm.sv`
- `out_spm.sv`
- `spm_subsys.sv`

Partition rule:

- `act_spm.sv` implements activation local SRAM storage
- `wgt_spm.sv` implements weight local SRAM storage
- `out_spm.sv` implements output local SRAM storage
- `spm_subsys.sv` only performs top-level integration, status tracking, and
  interface/error coordination

## Capacity

- `act_spm`: `2 x 512B`
- `wgt_spm`: `2 x 512B`
- `out_spm`: `1 x 512B`

Total effective local storage:

- `2.5KB`

## First RTL Storage Organization

### `act_spm`

- buffer count: `2`
- each buffer: `8` local rows
- each local row: `512-bit`

Interpretation:

- one `512-bit` local row packs `4` activation vectors
- each activation vector is `128-bit`
- `spm_npu_k_idx[4:2]` selects the `512-bit` row
- `spm_npu_k_idx[1:0]` selects one of the `4` vector slots inside that row

### `wgt_spm`

- buffer count: `2`
- each buffer: `8` local rows
- each local row: `512-bit`

Interpretation is identical to `act_spm`:

- one `512-bit` local row packs `4` weight vectors
- each weight vector is `128-bit`
- `spm_npu_k_idx[4:2]` selects the row
- `spm_npu_k_idx[1:0]` selects the vector slot

### `out_spm`

- buffer count: `1`
- each buffer: `16` local rows
- each local row: `256-bit`

Interpretation:

- one `256-bit` local row stores `16` output lanes
- each output lane uses a fixed `16-bit` physical slot
- `npu_spm_out_row_idx[3:0]` selects the local output row

## Interface Mapping

### DMA write -> `act_spm` / `wgt_spm`

- `dma_spm_wr_type=2'b00` writes `act_spm`
- `dma_spm_wr_type=2'b01` writes `wgt_spm`
- `dma_spm_wr_buf_sel` selects local buffer `0/1`
- `dma_spm_wr_row_idx[2:0]` selects the `512-bit` local row
- `dma_spm_wr_strb[63:0]` is applied as byte write enable

When `dma_spm_wr_last` is accepted:

- the corresponding `act_buf_ready` or `wgt_buf_ready` bit is set

### SPM -> NPU vector read

`spm_subsys` outputs:

- `spm_npu_act_vec[127:0]`
- `spm_npu_wgt_vec[127:0]`

Valid rule:

- selected act buffer must be ready
- selected wgt buffer must be ready
- `spm_npu_k_idx < 32`

### NPU write -> `out_spm`

- `npu_spm_out_buf_sel`: first version only `0`
- `npu_spm_out_row_idx[3:0]`: selects one `256-bit` output row
- `npu_spm_out_col_mask[15:0]`: one bit per output lane
- `npu_spm_out_data[255:0]`: `16 x 16-bit` physical output slots

Lane write rule:

- if `col_mask[i]=1`, lane `i` writes incoming data
- if `col_mask[i]=0`, lane `i` is explicitly written as zero

When `npu_spm_out_last` is accepted:

- `out_buf_readable[0]` is set

## DMA Readout Packing From `out_spm`

`dma_top` reads `out_spm` in `512-bit` granularity, while `out_spm` stores
physical rows as `256-bit`.

Packing rule:

- one DMA read row returns two adjacent `out_spm` rows
- `dma_spm_rd_row_idx = i`
- returned payload = `{out_row[2*i+1], out_row[2*i]}`

This means:

- `out_spm` rows `0` and `1` become DMA row `0`
- `out_spm` rows `2` and `3` become DMA row `1`
- ...
- `out_spm` rows `14` and `15` become DMA row `7`

## First RTL Status Policy

Current first implementation uses a simple sticky-ready policy:

- `act_buf_ready[x]` is asserted after DMA finishes a write sequence to that buffer
- `wgt_buf_ready[x]` is asserted after DMA finishes a write sequence to that buffer
- `out_buf_readable[0]` is asserted after NPU completes output write-back
- `out_buf_free[0]` is the inverse of `out_buf_readable[0]`

This policy is sufficient for the current top-level RTL bring-up skeleton and
can be refined later without changing the top-level interfaces.

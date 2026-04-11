# npu_top FS

## Scope

This file captures the current first RTL-facing functional spec of `npu_top`.

## Role

`npu_top` is the first-version compute block in `u_core`.

Current first-version role:

- accept CPU-side configuration through AXI4-Lite CSR
- wait for SPM resource readiness after `START`
- fetch activation and weight vectors from `spm_subsys`
- perform `16x16`, `INT8 x INT8 -> INT32` tile accumulation
- quantize one output row at a time
- write the output tile back into `out_spm`

## Current RTL Partition

The current NPU RTL is intentionally split into small modules:

- `npu_csr_if.sv`
- `npu_controller.sv`
- `npu_mac_array.sv`
- `npu_quantizer.sv`
- `npu_datapath.sv`
- `npu_status_perf.sv`
- `npu_top.sv`

Partition rule:

- `npu_csr_if` handles AXI-Lite slave protocol and CSR storage
- `npu_controller` handles `START`, resource wait, fetch sequencing, and output write sequencing
- `npu_mac_array` computes one `16x16` outer-product update for one accepted K-step
- `npu_quantizer` converts one `INT32` output row into `16 x 16-bit` physical output lanes
- `npu_datapath` stores psum state and provides row-wise quantized output
- `npu_status_perf` keeps sticky done/error state and counters
- `npu_top` performs only top-level integration

## Current RTL Execution Model

Current first RTL model is:

1. CPU programs CSR fields
2. CPU writes `START`
3. NPU validates the current configuration
4. NPU enters `armed` if SPM resources are not ready yet
5. NPU clears internal psum state once resources are ready
6. NPU accepts one activation/weight vector pair per K-step
7. Each accepted vector pair updates the whole `16x16` psum matrix
8. After `ktile` accepted K-steps, NPU writes `16` output rows into `out_spm`
9. `npu_done` is raised after the last local output row write is accepted

## Supported First-Version Scope

Current supported subset:

- `Ktile` must satisfy `1 <= ktile_cfg <= 32`
- `act_buf_sel` and `wgt_buf_sel` must be `0` or `1`
- `out_buf_sel` must be `0`
- output format is physically `16 x 16-bit`
- `quant_shift` is applied as arithmetic right shift before zero-point add
- optional ReLU is applied after zero-point add

Current non-goals of this first RTL:

- no descriptor queue
- no direct AXI access inside NPU
- no partial-lane output packing policy beyond `col_mask = 16'hffff`
- no performance-optimized systolic timing model

## SPM Interaction Model

Input side:

- `spm_npu_vec_valid/ready` handshake defines one accepted K-step
- `spm_npu_act_buf_sel`, `spm_npu_wgt_buf_sel`, and `spm_npu_k_idx` identify the vector pair
- `spm_npu_act_vec` and `spm_npu_wgt_vec` each carry `16 x INT8`

Output side:

- `npu_spm_out_valid/ready` handshake defines one accepted output row write
- `npu_spm_out_row_idx[3:0]` selects one of the `16` output rows
- `npu_spm_out_data[255:0]` carries `16 x 16-bit` lanes
- `npu_spm_out_col_mask[15:0]` is currently all ones in the first RTL
- `npu_spm_out_last` is asserted on output row `15`

## Status Policy

Current `npu_status_perf` maintains:

- `npu_armed`
- `npu_busy`
- `npu_done`
- `npu_error`
- `npu_stall_cycles`
- `npu_busy_cycles`
- `npu_error_code`

Sticky policy:

- `npu_done` is cleared by a new `START`
- `npu_error` is sticky after the first error
- `npu_error_code` keeps the first latched error code

## Error Code Summary

- `0x01`: `START` issued while NPU is already armed or busy
- `0x02`: illegal `act_buf_sel`
- `0x03`: illegal `wgt_buf_sel`
- `0x04`: illegal `out_buf_sel`
- `0x05`: illegal `ktile_cfg`
- `0x06`: propagated `spm_npu_error`

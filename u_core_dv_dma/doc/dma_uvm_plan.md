# DMA UVM Plan

## Scope

This directory holds the dedicated UVM verification environment for
[`dma_top`](/root/Project/u_core_module_dma/rtl/dma_top.sv).

The environment targets the current first RTL scope:

- AXI-Lite CSR programming and status readback
- descriptor staging and FIFO submission
- `LOAD_ACT`
- `LOAD_WGT`
- `STORE_OUT`
- AXI4 Full read/write execution
- local SPM write/read interaction
- error handling and sticky status/counter behavior

## UVM Structure

Top-level files:

- [`dma_tb_top.sv`](/root/Project/u_core_dv_dma/tb/dma_tb_top.sv)
- [`dma_dv_pkg.sv`](/root/Project/u_core_dv_dma/tb/dma_dv_pkg.sv)

Interface layer:

- [`dma_axil_if.sv`](/root/Project/u_core_dv_dma/tb/dma_axil_if.sv)
- [`dma_axi_mem_if.sv`](/root/Project/u_core_dv_dma/tb/dma_axi_mem_if.sv)
- [`dma_spm_if.sv`](/root/Project/u_core_dv_dma/tb/dma_spm_if.sv)
- [`dma_status_if.sv`](/root/Project/u_core_dv_dma/tb/dma_status_if.sv)

Agents and models:

- AXI-Lite active master agent for CPU-side CSR access
- AXI memory reactive slave agent for external storage behavior
- SPM reactive slave agent for local buffer behavior
- status monitor for sticky state and counter observation

Environment:

- env config with preload and error-injection knobs
- virtual sequencer
- scoreboard
- coverage collector
- reusable environment wrapper

Sequences and tests:

- descriptor programming base sequence
- smoke sequence
- invalid descriptor sequence
- FIFO stress sequence
- base, smoke, error, and FIFO stress tests

## Functional Coverage Intent

Planned functional coverage includes:

- command type coverage:
  - `LOAD_ACT`
  - `LOAD_WGT`
  - `STORE_OUT`
- `buf_sel` usage coverage
- `row_len` and `row_cnt` shape coverage inside current first RTL limits
- done/error status coverage
- error-code coverage
- CSR access coverage

## Scoreboard Intent

Current scoreboard hooks are designed to check:

- AXI-Lite descriptor programming sequence
- ordering from submit to issued data movement
- `LOAD_*`: AXI read data matches SPM write data
- `STORE_OUT`: SPM read data matches AXI write data
- status transition visibility

This gives the environment a usable first correctness backbone, while still
leaving room to add deeper checks such as exact FIFO occupancy timing, latency
windows, and protocol assertions.

## Recommended First Test List

- `dma_smoke_test`
- `dma_invalid_desc_test`
- `dma_error_test`
- `dma_fifo_stress_test`

## Simulation Note

This environment is intentionally prepared for `vcs`/UVM flow.

- no `iverilog` compile is required for this DV tree
- current compile/run entry is:
  - [`run_vcs.sh`](/root/Project/u_core_dv_dma/sim/run_vcs.sh)
  - [`vcs_dma_uvm.f`](/root/Project/u_core_dv_dma/sim/vcs_dma_uvm.f)

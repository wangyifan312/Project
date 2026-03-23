# AXI4 Master Notes

## Module scope

`rtl/axi4_master.sv` implements a synthesizable AXI4 master bridge with:

- One outstanding write transaction at a time
- One outstanding read transaction at a time
- Independent read and write channels
- AXI4 burst control pass-through for `AxLEN`, `AxSIZE`, `AxBURST`, `AxLOCK`, `AxCACHE`, `AxPROT`, and `AxQOS`
- Single-beat internal buffering on `W` and `R` paths so outgoing `VALID` does not depend combinationally on `READY`

## Local-side interface

The module exposes a simple command/data interface:

- `wr_cmd_*` issues one write burst command
- `wr_data_*` streams exactly `wr_cmd_len + 1` beats for that burst
- `wr_resp_*` returns either slave `BRESP` or a locally generated `DECERR`
- `rd_cmd_*` issues one read burst command
- `rd_data_*` returns slave `RDATA/RRESP/RLAST` or a locally generated one-beat `DECERR`

## Protocol checks inside the module

The master blocks illegal commands from reaching the AXI bus and generates a local error response instead. The checks cover:

- Burst type must be `FIXED`, `INCR`, or `WRAP`
- `WRAP` length must be 2/4/8/16 beats
- Transfer size must not exceed the master data bus width
- Burst window must remain inside one 4 KB region

## Current assumptions

- `ADDR_WIDTH >= 12`
- Upstream logic only provides exactly the requested number of write data beats
- AXI slave behavior is protocol-correct
- There is no support yet for multiple outstanding transactions, reordering, or out-of-order IDs

## Suggested next step

Pair this RTL with a small self-checking testbench that covers:

- Single-beat read/write
- INCR burst read/write
- WRAP burst legality checks
- 4 KB boundary violation
- Backpressure on `AW/W/B/AR/R`

#!/usr/bin/env bash
set -euo pipefail

ROOT=/root/Project
UVM_TESTNAME=${UVM_TESTNAME:-dma_smoke_test}

vcs -full64 -sverilog -ntb_opts uvm-1.2 \
  -timescale=1ns/1ps \
  -f "${ROOT}/u_core_dv_dma/sim/vcs_dma_uvm.f" \
  -top dma_tb_top \
  -l "${ROOT}/u_core_dv_dma/sim/compile.log"

./simv +UVM_TESTNAME="${UVM_TESTNAME}" \
  -l "${ROOT}/u_core_dv_dma/sim/${UVM_TESTNAME}.log"

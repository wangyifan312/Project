package dma_dv_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import u_core_pkg::*;

  `uvm_analysis_imp_decl(_axil)
  `uvm_analysis_imp_decl(_axi_mem)
  `uvm_analysis_imp_decl(_spm)
  `uvm_analysis_imp_decl(_status)
  `uvm_analysis_imp_decl(_axil_cov)
  `uvm_analysis_imp_decl(_status_cov)

  `include "../agent/dma_axil_item.svh"
  `include "../agent/dma_axil_sequencer.svh"
  `include "../agent/dma_axil_driver.svh"
  `include "../agent/dma_axil_monitor.svh"
  `include "../agent/dma_axil_agent.svh"
  `include "../agent/dma_axi_mem_item.svh"
  `include "../agent/dma_spm_item.svh"
  `include "../agent/dma_status_item.svh"
  `include "../env/dma_env_cfg.svh"
  `include "../agent/dma_axi_mem_driver.svh"
  `include "../agent/dma_axi_mem_monitor.svh"
  `include "../agent/dma_axi_mem_agent.svh"
  `include "../agent/dma_spm_driver.svh"
  `include "../agent/dma_spm_monitor.svh"
  `include "../agent/dma_spm_agent.svh"
  `include "../agent/dma_status_monitor.svh"
  `include "../env/dma_virtual_sequencer.svh"
  `include "../seq/dma_desc_cfg.svh"
  `include "../env/dma_scoreboard.svh"
  `include "../env/dma_coverage.svh"
  `include "../env/dma_env.svh"
  `include "../seq/dma_base_seq.svh"
  `include "../seq/dma_smoke_seq.svh"
  `include "../seq/dma_invalid_desc_seq.svh"
  `include "../seq/dma_fifo_full_seq.svh"
  `include "../seq/dma_reg_access_seq.svh"
  `include "../test/dma_base_test.svh"
  `include "../test/dma_smoke_test.svh"
  `include "../test/dma_error_test.svh"
  `include "../test/dma_invalid_desc_test.svh"
  `include "../test/dma_fifo_stress_test.svh"
endpackage

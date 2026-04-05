class dma_mem_init_item extends uvm_object;
  rand bit [31:0]  addr;
  rand bit [511:0] data;
  `uvm_object_utils_begin(dma_mem_init_item)
    `uvm_field_int(addr, UVM_HEX)
    `uvm_field_int(data, UVM_HEX)
  `uvm_object_utils_end
  function new(string name = "dma_mem_init_item");
    super.new(name);
  endfunction
endclass

class dma_spm_init_item extends uvm_object;
  rand bit [2:0]   row_idx;
  rand bit [511:0] data;
  `uvm_object_utils_begin(dma_spm_init_item)
    `uvm_field_int(row_idx, UVM_DEC)
    `uvm_field_int(data, UVM_HEX)
  `uvm_object_utils_end
  function new(string name = "dma_spm_init_item");
    super.new(name);
  endfunction
endclass

class dma_env_cfg extends uvm_object;
  `uvm_object_utils(dma_env_cfg)

  virtual dma_axil_if      axil_vif;
  virtual dma_axi_mem_if   axi_mem_vif;
  virtual dma_spm_if       spm_vif;
  virtual dma_status_if    status_vif;

  bit enable_scoreboard = 1'b1;
  bit enable_coverage   = 1'b1;
  int unsigned axi_mem_r_latency = 1;
  int unsigned axi_mem_b_latency = 1;
  int unsigned spm_rd_data_latency = 1;
  bit spm_wr_ready_default = 1'b1;
  bit spm_rd_ready_default = 1'b1;
  bit [u_core_pkg::BUF_SEL_W-1:0] act_buf_writable_init = 2'b11;
  bit [u_core_pkg::BUF_SEL_W-1:0] wgt_buf_writable_init = 2'b11;
  bit [u_core_pkg::BUF_SEL_W-1:0] out_buf_readable_init = 2'b01;
  bit inject_rd_error = 1'b0;
  bit inject_wr_error = 1'b0;
  bit inject_spm_error = 1'b0;
  bit [u_core_pkg::DMA_ERROR_CODE_W-1:0] inject_spm_error_code = 8'h20;

  dma_mem_init_item mem_init_q[$];
  dma_spm_init_item spm_out_init_q[$];

  function new(string name = "dma_env_cfg");
    super.new(name);
  endfunction
endclass

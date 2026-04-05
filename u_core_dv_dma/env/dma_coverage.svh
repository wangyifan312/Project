class dma_coverage extends uvm_component;
  `uvm_component_utils(dma_coverage)

  uvm_analysis_imp_axil_cov   #(dma_axil_item, dma_coverage) axil_imp;
  uvm_analysis_imp_status_cov #(dma_status_item, dma_coverage) status_imp;

  bit [1:0] sampled_op_type;
  bit [1:0] sampled_buf_sel;
  bit [15:0] sampled_row_len;
  bit [15:0] sampled_row_cnt;
  bit [1:0] shadow_op_type;
  bit [1:0] shadow_buf_sel;
  bit [15:0] shadow_row_len;
  bit [15:0] shadow_row_cnt;
  bit sampled_done;
  bit sampled_error;
  bit [7:0] sampled_error_code;

  covergroup dma_desc_cg;
    option.per_instance = 1;
    cp_op: coverpoint sampled_op_type {
      bins load_act  = {u_core_pkg::DMA_OP_LOAD_ACT};
      bins load_wgt  = {u_core_pkg::DMA_OP_LOAD_WGT};
      bins store_out = {u_core_pkg::DMA_OP_STORE_OUT};
    }
    cp_buf: coverpoint sampled_buf_sel {
      bins buf0 = {0};
      bins buf1 = {1};
    }
    cp_len: coverpoint sampled_row_len {
      bins small = {[1:16]};
      bins beat  = {64};
    }
    cp_cnt: coverpoint sampled_row_cnt {
      bins single = {1};
      bins multi  = {[2:8]};
    }
    op_x_buf: cross cp_op, cp_buf;
  endgroup

  covergroup dma_status_cg;
    option.per_instance = 1;
    cp_done: coverpoint sampled_done;
    cp_error: coverpoint sampled_error;
    cp_error_code: coverpoint sampled_error_code {
      bins none = {8'h00};
      bins csr_error[] = {[8'h01:8'h08]};
      bins bus_error[] = {[8'h09:8'h0a]};
    }
  endgroup

  function new(string name = "dma_coverage", uvm_component parent = null);
    super.new(name, parent);
    axil_imp = new("axil_imp", this);
    status_imp = new("status_imp", this);
    dma_desc_cg = new();
    dma_status_cg = new();
  endfunction

  function void write_axil_cov(dma_axil_item t);
    if (t.kind == dma_axil_item::DMA_AXIL_WRITE && t.addr[7:0] == 8'h18 && t.data[0]) begin
      sampled_op_type = shadow_op_type;
      sampled_buf_sel = shadow_buf_sel;
      sampled_row_len = shadow_row_len;
      sampled_row_cnt = shadow_row_cnt;
      dma_desc_cg.sample();
    end else if (t.kind == dma_axil_item::DMA_AXIL_WRITE) begin
      if (t.addr[7:0] == 8'h00) begin
        shadow_op_type = t.data[1:0];
        shadow_buf_sel = t.data[3:2];
      end
      if (t.addr[7:0] == 8'h0c) begin
        shadow_row_len = t.data[15:0];
        shadow_row_cnt = t.data[31:16];
      end
    end
  endfunction

  function void write_status_cov(dma_status_item t);
    sampled_done = t.dma_done;
    sampled_error = t.dma_error;
    sampled_error_code = t.dma_error_code;
    dma_status_cg.sample();
  endfunction
endclass

class dma_desc_cfg extends uvm_object;
  `uvm_object_utils(dma_desc_cfg)

  rand bit [1:0]  op_type;
  rand bit [1:0]  buf_sel;
  rand bit [15:0] flags;
  rand bit [31:0] src_addr;
  rand bit [31:0] dst_addr;
  rand bit [15:0] row_len;
  rand bit [15:0] row_cnt;
  rand bit [15:0] src_stride;
  rand bit [15:0] dst_stride;
  rand bit [15:0] spm_row_base;
  rand bit [15:0] tile_id;

  constraint c_first_rtl {
    row_len inside {[1:64]};
    row_cnt inside {[1:8]};
    (spm_row_base + row_cnt) <= 8;
  }

  function new(string name = "dma_desc_cfg");
    super.new(name);
  endfunction
endclass

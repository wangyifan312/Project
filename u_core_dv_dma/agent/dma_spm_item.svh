class dma_spm_item extends uvm_sequence_item;
  typedef enum int {DMA_SPM_WR, DMA_SPM_RD_REQ, DMA_SPM_RD_DATA} kind_e;

  kind_e                    kind;
  bit [1:0]                 spm_type;
  bit [u_core_pkg::BUF_SEL_W-1:0] buf_sel;
  bit [u_core_pkg::DMA_SPM_ROW_W-1:0] row_idx;
  bit [u_core_pkg::AXI_DATA_W-1:0] data;
  bit [u_core_pkg::AXI_STRB_W-1:0] strb;
  bit                       last;

  `uvm_object_utils_begin(dma_spm_item)
    `uvm_field_enum(kind_e, kind, UVM_DEFAULT)
    `uvm_field_int(spm_type, UVM_BIN)
    `uvm_field_int(buf_sel, UVM_BIN)
    `uvm_field_int(row_idx, UVM_DEC)
    `uvm_field_int(data, UVM_HEX)
    `uvm_field_int(strb, UVM_HEX)
    `uvm_field_int(last, UVM_BIN)
  `uvm_object_utils_end

  function new(string name = "dma_spm_item");
    super.new(name);
  endfunction
endclass

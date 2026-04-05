class dma_status_item extends uvm_sequence_item;
  bit                       dma_busy;
  bit                       dma_done;
  bit                       dma_error;
  bit                       dma_fifo_empty;
  bit                       dma_fifo_full;
  bit [u_core_pkg::DMA_FIFO_LEVEL_W-1:0] dma_fifo_level;
  bit [31:0]                dma_done_count;
  bit [31:0]                dma_rd_beat_count;
  bit [31:0]                dma_wr_beat_count;
  bit [u_core_pkg::DMA_ERROR_CODE_W-1:0] dma_error_code;

  `uvm_object_utils_begin(dma_status_item)
    `uvm_field_int(dma_busy, UVM_BIN)
    `uvm_field_int(dma_done, UVM_BIN)
    `uvm_field_int(dma_error, UVM_BIN)
    `uvm_field_int(dma_fifo_empty, UVM_BIN)
    `uvm_field_int(dma_fifo_full, UVM_BIN)
    `uvm_field_int(dma_fifo_level, UVM_DEC)
    `uvm_field_int(dma_done_count, UVM_DEC)
    `uvm_field_int(dma_rd_beat_count, UVM_DEC)
    `uvm_field_int(dma_wr_beat_count, UVM_DEC)
    `uvm_field_int(dma_error_code, UVM_HEX)
  `uvm_object_utils_end

  function new(string name = "dma_status_item");
    super.new(name);
  endfunction
endclass

class dma_axi_mem_item extends uvm_sequence_item;
  typedef enum int {DMA_AXI_MEM_AR, DMA_AXI_MEM_R, DMA_AXI_MEM_AW, DMA_AXI_MEM_W, DMA_AXI_MEM_B} kind_e;

  kind_e                  kind;
  bit [31:0]              addr;
  bit [7:0]               len;
  bit [2:0]               size;
  bit [1:0]               burst;
  bit [511:0]             data;
  bit [63:0]              strb;
  bit [1:0]               resp;
  bit                     last;

  `uvm_object_utils_begin(dma_axi_mem_item)
    `uvm_field_enum(kind_e, kind, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_HEX)
    `uvm_field_int(len, UVM_DEC)
    `uvm_field_int(size, UVM_DEC)
    `uvm_field_int(burst, UVM_DEC)
    `uvm_field_int(data, UVM_HEX)
    `uvm_field_int(strb, UVM_HEX)
    `uvm_field_int(resp, UVM_DEC)
    `uvm_field_int(last, UVM_BIN)
  `uvm_object_utils_end

  function new(string name = "dma_axi_mem_item");
    super.new(name);
  endfunction
endclass

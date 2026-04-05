class dma_axil_item extends uvm_sequence_item;
  typedef enum bit [0:0] {DMA_AXIL_READ, DMA_AXIL_WRITE} kind_e;

  rand kind_e                kind;
  rand bit [31:0]            addr;
  rand bit [31:0]            data;
  rand bit [3:0]             strb;
       bit [31:0]            rdata;
       bit [1:0]             resp;

  `uvm_object_utils_begin(dma_axil_item)
    `uvm_field_enum(kind_e, kind, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_HEX)
    `uvm_field_int(data, UVM_HEX)
    `uvm_field_int(strb, UVM_HEX)
    `uvm_field_int(rdata, UVM_HEX | UVM_NOCOMPARE)
    `uvm_field_int(resp, UVM_HEX | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name = "dma_axil_item");
    super.new(name);
    strb = 4'hf;
  endfunction
endclass

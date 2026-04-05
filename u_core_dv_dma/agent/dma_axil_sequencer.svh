class dma_axil_sequencer extends uvm_sequencer #(dma_axil_item);
  `uvm_component_utils(dma_axil_sequencer)

  function new(string name = "dma_axil_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass

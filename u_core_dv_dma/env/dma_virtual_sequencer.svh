class dma_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(dma_virtual_sequencer)

  dma_axil_sequencer axil_sqr;

  function new(string name = "dma_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass

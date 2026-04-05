class dma_axi_mem_agent extends uvm_component;
  `uvm_component_utils(dma_axi_mem_agent)

  dma_axi_mem_driver  drv;
  dma_axi_mem_monitor mon;

  function new(string name = "dma_axi_mem_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = dma_axi_mem_driver::type_id::create("drv", this);
    mon = dma_axi_mem_monitor::type_id::create("mon", this);
  endfunction
endclass

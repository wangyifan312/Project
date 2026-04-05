class dma_spm_agent extends uvm_component;
  `uvm_component_utils(dma_spm_agent)

  dma_spm_driver  drv;
  dma_spm_monitor mon;

  function new(string name = "dma_spm_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = dma_spm_driver::type_id::create("drv", this);
    mon = dma_spm_monitor::type_id::create("mon", this);
  endfunction
endclass

class dma_axil_agent extends uvm_component;
  `uvm_component_utils(dma_axil_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  dma_axil_sequencer sqr;
  dma_axil_driver    drv;
  dma_axil_monitor   mon;

  function new(string name = "dma_axil_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = dma_axil_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      sqr = dma_axil_sequencer::type_id::create("sqr", this);
      drv = dma_axil_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction
endclass

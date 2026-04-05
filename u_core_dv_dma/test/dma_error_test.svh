class dma_error_test extends dma_base_test;
  `uvm_component_utils(dma_error_test)

  function new(string name = "dma_error_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void configure_env();
    super.configure_env();
    cfg.inject_rd_error = 1'b1;
  endfunction

  task run_phase(uvm_phase phase);
    dma_smoke_seq seq;
    phase.raise_objection(this);
    seq = dma_smoke_seq::type_id::create("seq");
    seq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass

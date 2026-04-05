class dma_fifo_stress_test extends dma_base_test;
  `uvm_component_utils(dma_fifo_stress_test)

  function new(string name = "dma_fifo_stress_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_fifo_full_seq seq;
    phase.raise_objection(this);
    seq = dma_fifo_full_seq::type_id::create("seq");
    seq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass

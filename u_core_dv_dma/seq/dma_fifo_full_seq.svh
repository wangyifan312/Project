class dma_fifo_full_seq extends dma_base_seq;
  `uvm_object_utils(dma_fifo_full_seq)

  function new(string name = "dma_fifo_full_seq");
    super.new(name);
  endfunction

  task body();
    dma_desc_cfg desc;
    super.body();
    repeat (6) begin
      desc = dma_desc_cfg::type_id::create("fifo_desc");
      assert(desc.randomize() with {
        op_type      == u_core_pkg::DMA_OP_LOAD_ACT;
        buf_sel      == 0;
        src_addr     == 32'h2000_0000;
        row_len      == 16'd64;
        row_cnt      == 16'd1;
        src_stride   == 16'd64;
        spm_row_base == 16'd0;
      });
      program_desc(desc);
      submit_desc();
    end
  endtask
endclass

class dma_smoke_seq extends dma_base_seq;
  `uvm_object_utils(dma_smoke_seq)

  function new(string name = "dma_smoke_seq");
    super.new(name);
  endfunction

  task body();
    dma_desc_cfg desc;
    bit [31:0] status_word;
    super.body();

    desc = dma_desc_cfg::type_id::create("load_act_desc");
    assert(desc.randomize() with {
      op_type      == u_core_pkg::DMA_OP_LOAD_ACT;
      buf_sel      == 0;
      src_addr     == 32'h2000_0000;
      dst_addr     == 32'h0000_0000;
      row_len      == 16'd64;
      row_cnt      == 16'd4;
      src_stride   == 16'd64;
      dst_stride   == 16'd64;
      spm_row_base == 16'd0;
    });
    program_desc(desc);
    submit_desc();
    poll_done(status_word);

    desc = dma_desc_cfg::type_id::create("load_wgt_desc");
    assert(desc.randomize() with {
      op_type      == u_core_pkg::DMA_OP_LOAD_WGT;
      buf_sel      == 1;
      src_addr     == 32'h2000_1000;
      row_len      == 16'd64;
      row_cnt      == 16'd4;
      src_stride   == 16'd64;
      spm_row_base == 16'd0;
    });
    program_desc(desc);
    submit_desc();
    poll_done(status_word);

    desc = dma_desc_cfg::type_id::create("store_out_desc");
    assert(desc.randomize() with {
      op_type      == u_core_pkg::DMA_OP_STORE_OUT;
      buf_sel      == 0;
      dst_addr     == 32'h2000_2000;
      row_len      == 16'd64;
      row_cnt      == 16'd4;
      dst_stride   == 16'd64;
      spm_row_base == 16'd0;
    });
    program_desc(desc);
    submit_desc();
    poll_done(status_word);
  endtask
endclass

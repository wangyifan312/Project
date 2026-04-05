class dma_invalid_desc_seq extends dma_base_seq;
  `uvm_object_utils(dma_invalid_desc_seq)

  function new(string name = "dma_invalid_desc_seq");
    super.new(name);
  endfunction

  task body();
    dma_desc_cfg desc;
    bit [31:0] status_word;
    super.body();
    desc = dma_desc_cfg::type_id::create("bad_desc");
    desc.op_type      = u_core_pkg::DMA_OP_LOAD_ACT;
    desc.buf_sel      = 0;
    desc.flags        = '0;
    desc.src_addr     = 32'h2000_0004;
    desc.dst_addr     = 32'h0;
    desc.row_len      = 16'd64;
    desc.row_cnt      = 16'd2;
    desc.src_stride   = 16'd64;
    desc.dst_stride   = 16'd64;
    desc.spm_row_base = 16'd0;
    desc.tile_id      = '0;
    program_desc(desc);
    submit_desc();
    poll_done(status_word);
  endtask
endclass

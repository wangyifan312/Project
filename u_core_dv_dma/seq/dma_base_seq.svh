class dma_base_seq extends uvm_sequence;
  `uvm_object_utils(dma_base_seq)

  dma_virtual_sequencer vseqr;

  function new(string name = "dma_base_seq");
    super.new(name);
  endfunction

  task body();
    if (!$cast(vseqr, m_sequencer)) begin
      `uvm_fatal(get_type_name(), "dma_base_seq requires dma_virtual_sequencer")
    end
  endtask

  task axil_write(bit [31:0] addr, bit [31:0] data, bit [3:0] strb = 4'hf);
    dma_axil_item req;
    req = dma_axil_item::type_id::create("req");
    req.kind = dma_axil_item::DMA_AXIL_WRITE;
    req.addr = addr;
    req.data = data;
    req.strb = strb;
    start_item_on(req, vseqr.axil_sqr);
  endtask

  task axil_read(bit [31:0] addr, output bit [31:0] data);
    dma_axil_item req;
    req = dma_axil_item::type_id::create("req");
    req.kind = dma_axil_item::DMA_AXIL_READ;
    req.addr = addr;
    start_item_on(req, vseqr.axil_sqr);
    data = req.rdata;
  endtask

  task automatic start_item_on(ref dma_axil_item req, dma_axil_sequencer sqr);
    start_item(req, -1, sqr);
    finish_item(req);
  endtask

  task program_desc(dma_desc_cfg desc);
    axil_write(u_core_pkg::DMA_CSR_BASE + 'h00, {12'h0, desc.flags, desc.buf_sel, desc.op_type});
    axil_write(u_core_pkg::DMA_CSR_BASE + 'h04, desc.src_addr);
    axil_write(u_core_pkg::DMA_CSR_BASE + 'h08, desc.dst_addr);
    axil_write(u_core_pkg::DMA_CSR_BASE + 'h0c, {desc.row_cnt, desc.row_len});
    axil_write(u_core_pkg::DMA_CSR_BASE + 'h10, {desc.dst_stride, desc.src_stride});
    axil_write(u_core_pkg::DMA_CSR_BASE + 'h14, {desc.tile_id, desc.spm_row_base});
  endtask

  task submit_desc();
    axil_write(u_core_pkg::DMA_CSR_BASE + 'h18, 32'h0000_0001);
  endtask

  task poll_done(output bit [31:0] status_word, int unsigned max_poll = 256);
    int unsigned i;
    for (i = 0; i < max_poll; i++) begin
      axil_read(u_core_pkg::DMA_CSR_BASE + 'h1c, status_word);
      if (status_word[1] || status_word[2]) begin
        return;
      end
    end
    `uvm_error(get_type_name(), "DMA poll_done timeout")
  endtask
endclass

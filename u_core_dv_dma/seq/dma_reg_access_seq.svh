class dma_reg_access_seq extends dma_base_seq;
  `uvm_object_utils(dma_reg_access_seq)

  function new(string name = "dma_reg_access_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] data;
    super.body();
    axil_write(u_core_pkg::DMA_CSR_BASE + 'h00, 32'h0000_0000);
    axil_read(u_core_pkg::DMA_CSR_BASE + 'h00, data);
    axil_read(u_core_pkg::DMA_CSR_BASE + 'h1c, data);
    axil_read(u_core_pkg::DMA_CSR_BASE + 'h20, data);
    axil_read(u_core_pkg::DMA_CSR_BASE + 'h30, data);
  endtask
endclass

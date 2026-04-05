class dma_axi_mem_driver extends uvm_component;
  `uvm_component_utils(dma_axi_mem_driver)

  virtual dma_axi_mem_if vif;
  dma_env_cfg cfg;
  bit [u_core_pkg::AXI_DATA_W-1:0] mem [bit [u_core_pkg::AXI_ADDR_W-1:0]];

  function new(string name = "dma_axi_mem_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_axi_mem_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "dma_axi_mem_if handle is not set")
    end
    if (!uvm_config_db#(dma_env_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "dma_env_cfg is not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    preload_memory();
    vif.init_slave();
    fork
      serve_reads();
      serve_writes();
    join
  endtask

  task preload_memory();
    foreach (cfg.mem_init_q[idx]) begin
      mem[cfg.mem_init_q[idx].addr] = cfg.mem_init_q[idx].data;
    end
  endtask

  function bit [u_core_pkg::AXI_DATA_W-1:0] get_mem_word(bit [u_core_pkg::AXI_ADDR_W-1:0] addr);
    if (mem.exists(addr)) begin
      return mem[addr];
    end
    return '0;
  endfunction

  task serve_reads();
    bit [u_core_pkg::AXI_ADDR_W-1:0] rd_addr;
    forever begin
      @(vif.drv_cb);
      vif.drv_cb.arready <= 1'b1;
      if (vif.drv_cb.arvalid && vif.drv_cb.arready) begin
        rd_addr = vif.drv_cb.araddr;
        repeat (cfg.axi_mem_r_latency) @(vif.drv_cb);
        vif.drv_cb.rdata  <= get_mem_word(rd_addr);
        vif.drv_cb.rresp  <= cfg.inject_rd_error ? 2'b10 : 2'b00;
        vif.drv_cb.rlast  <= 1'b1;
        vif.drv_cb.rvalid <= 1'b1;
        do @(vif.drv_cb); while (!vif.drv_cb.rready);
        vif.drv_cb.rvalid <= 1'b0;
      end
    end
  endtask

  task serve_writes();
    bit [u_core_pkg::AXI_ADDR_W-1:0] wr_addr;
    forever begin
      @(vif.drv_cb);
      vif.drv_cb.awready <= 1'b1;
      vif.drv_cb.wready  <= 1'b1;
      if (vif.drv_cb.awvalid && vif.drv_cb.awready) begin
        wr_addr = vif.drv_cb.awaddr;
        do @(vif.drv_cb); while (!(vif.drv_cb.wvalid && vif.drv_cb.wready));
        mem[wr_addr] = vif.drv_cb.wdata;
        repeat (cfg.axi_mem_b_latency) @(vif.drv_cb);
        vif.drv_cb.bresp  <= cfg.inject_wr_error ? 2'b10 : 2'b00;
        vif.drv_cb.bvalid <= 1'b1;
        do @(vif.drv_cb); while (!vif.drv_cb.bready);
        vif.drv_cb.bvalid <= 1'b0;
      end
    end
  endtask
endclass

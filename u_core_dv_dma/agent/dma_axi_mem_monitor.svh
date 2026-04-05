class dma_axi_mem_monitor extends uvm_component;
  `uvm_component_utils(dma_axi_mem_monitor)

  virtual dma_axi_mem_if vif;
  uvm_analysis_port #(dma_axi_mem_item) ap;
  bit [u_core_pkg::AXI_ADDR_W-1:0] rd_addr_q[$];
  bit [u_core_pkg::AXI_ADDR_W-1:0] wr_addr_q[$];

  function new(string name = "dma_axi_mem_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_axi_mem_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "dma_axi_mem_if handle is not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    dma_axi_mem_item tr;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.arvalid && vif.mon_cb.arready) begin
        tr = dma_axi_mem_item::type_id::create("ar_tr", this);
        tr.kind  = dma_axi_mem_item::DMA_AXI_MEM_AR;
        tr.addr  = vif.mon_cb.araddr;
        tr.len   = vif.mon_cb.arlen;
        tr.size  = vif.mon_cb.arsize;
        tr.burst = vif.mon_cb.arburst;
        rd_addr_q.push_back(vif.mon_cb.araddr);
        ap.write(tr);
      end
      if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
        tr = dma_axi_mem_item::type_id::create("r_tr", this);
        tr.kind = dma_axi_mem_item::DMA_AXI_MEM_R;
        tr.addr = (rd_addr_q.size() != 0) ? rd_addr_q[0] : '0;
        tr.data = vif.mon_cb.rdata;
        tr.resp = vif.mon_cb.rresp;
        tr.last = vif.mon_cb.rlast;
        if (tr.last && rd_addr_q.size() != 0) void'(rd_addr_q.pop_front());
        ap.write(tr);
      end
      if (vif.mon_cb.awvalid && vif.mon_cb.awready) begin
        tr = dma_axi_mem_item::type_id::create("aw_tr", this);
        tr.kind  = dma_axi_mem_item::DMA_AXI_MEM_AW;
        tr.addr  = vif.mon_cb.awaddr;
        tr.len   = vif.mon_cb.awlen;
        tr.size  = vif.mon_cb.awsize;
        tr.burst = vif.mon_cb.awburst;
        wr_addr_q.push_back(vif.mon_cb.awaddr);
        ap.write(tr);
      end
      if (vif.mon_cb.wvalid && vif.mon_cb.wready) begin
        tr = dma_axi_mem_item::type_id::create("w_tr", this);
        tr.kind = dma_axi_mem_item::DMA_AXI_MEM_W;
        tr.addr = (wr_addr_q.size() != 0) ? wr_addr_q[0] : '0;
        tr.data = vif.mon_cb.wdata;
        tr.strb = vif.mon_cb.wstrb;
        tr.last = vif.mon_cb.wlast;
        ap.write(tr);
      end
      if (vif.mon_cb.bvalid && vif.mon_cb.bready) begin
        tr = dma_axi_mem_item::type_id::create("b_tr", this);
        tr.kind = dma_axi_mem_item::DMA_AXI_MEM_B;
        tr.addr = (wr_addr_q.size() != 0) ? wr_addr_q.pop_front() : '0;
        tr.resp = vif.mon_cb.bresp;
        ap.write(tr);
      end
    end
  endtask
endclass

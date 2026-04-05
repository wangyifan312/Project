class dma_axil_monitor extends uvm_component;
  `uvm_component_utils(dma_axil_monitor)

  virtual dma_axil_if vif;
  uvm_analysis_port #(dma_axil_item) ap;

  function new(string name = "dma_axil_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_axil_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "dma_axil_if handle is not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    dma_axil_item wr_tr;
    dma_axil_item rd_tr;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.awvalid && vif.mon_cb.awready &&
          vif.mon_cb.wvalid && vif.mon_cb.wready) begin
        wr_tr = dma_axil_item::type_id::create("wr_tr", this);
        wr_tr.kind = dma_axil_item::DMA_AXIL_WRITE;
        wr_tr.addr = vif.mon_cb.awaddr;
        wr_tr.data = vif.mon_cb.wdata;
        wr_tr.strb = vif.mon_cb.wstrb;
        ap.write(wr_tr);
      end
      if (vif.mon_cb.arvalid && vif.mon_cb.arready) begin
        rd_tr = dma_axil_item::type_id::create("rd_tr", this);
        rd_tr.kind = dma_axil_item::DMA_AXIL_READ;
        rd_tr.addr = vif.mon_cb.araddr;
        do @(vif.mon_cb); while (!(vif.mon_cb.rvalid && vif.mon_cb.rready));
        rd_tr.rdata = vif.mon_cb.rdata;
        rd_tr.resp  = vif.mon_cb.rresp;
        ap.write(rd_tr);
      end
    end
  endtask
endclass

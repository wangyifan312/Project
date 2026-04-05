class dma_axil_driver extends uvm_driver #(dma_axil_item);
  `uvm_component_utils(dma_axil_driver)

  virtual dma_axil_if vif;

  function new(string name = "dma_axil_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_axil_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "dma_axil_if handle is not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    dma_axil_item req;
    vif.init_master();
    forever begin
      seq_item_port.get_next_item(req);
      case (req.kind)
        dma_axil_item::DMA_AXIL_WRITE: drive_write(req);
        dma_axil_item::DMA_AXIL_READ:  drive_read(req);
      endcase
      seq_item_port.item_done();
    end
  endtask

  task drive_write(ref dma_axil_item tr);
    @(vif.drv_cb);
    vif.drv_cb.awaddr  <= tr.addr;
    vif.drv_cb.awprot  <= '0;
    vif.drv_cb.awvalid <= 1'b1;
    vif.drv_cb.wdata   <= tr.data;
    vif.drv_cb.wstrb   <= tr.strb;
    vif.drv_cb.wvalid  <= 1'b1;
    do @(vif.drv_cb); while (!(vif.drv_cb.awready && vif.drv_cb.wready));
    vif.drv_cb.awvalid <= 1'b0;
    vif.drv_cb.wvalid  <= 1'b0;
    vif.drv_cb.bready  <= 1'b1;
    do @(vif.drv_cb); while (!vif.drv_cb.bvalid);
    tr.resp = vif.drv_cb.bresp;
    vif.drv_cb.bready  <= 1'b0;
  endtask

  task drive_read(ref dma_axil_item tr);
    @(vif.drv_cb);
    vif.drv_cb.araddr  <= tr.addr;
    vif.drv_cb.arprot  <= '0;
    vif.drv_cb.arvalid <= 1'b1;
    do @(vif.drv_cb); while (!vif.drv_cb.arready);
    vif.drv_cb.arvalid <= 1'b0;
    vif.drv_cb.rready  <= 1'b1;
    do @(vif.drv_cb); while (!vif.drv_cb.rvalid);
    tr.rdata = vif.drv_cb.rdata;
    tr.resp  = vif.drv_cb.rresp;
    vif.drv_cb.rready  <= 1'b0;
  endtask
endclass

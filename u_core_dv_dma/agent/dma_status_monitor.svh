class dma_status_monitor extends uvm_component;
  `uvm_component_utils(dma_status_monitor)

  virtual dma_status_if vif;
  uvm_analysis_port #(dma_status_item) ap;
  dma_status_item last_item;

  function new(string name = "dma_status_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_status_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "dma_status_if handle is not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    dma_status_item tr;
    forever begin
      @(vif.mon_cb);
      tr = dma_status_item::type_id::create("tr", this);
      tr.dma_busy         = vif.mon_cb.dma_busy;
      tr.dma_done         = vif.mon_cb.dma_done;
      tr.dma_error        = vif.mon_cb.dma_error;
      tr.dma_fifo_empty   = vif.mon_cb.dma_fifo_empty;
      tr.dma_fifo_full    = vif.mon_cb.dma_fifo_full;
      tr.dma_fifo_level   = vif.mon_cb.dma_fifo_level;
      tr.dma_done_count   = vif.mon_cb.dma_done_count;
      tr.dma_rd_beat_count = vif.mon_cb.dma_rd_beat_count;
      tr.dma_wr_beat_count = vif.mon_cb.dma_wr_beat_count;
      tr.dma_error_code   = vif.mon_cb.dma_error_code;
      if ((last_item == null) || !tr.compare(last_item)) begin
        ap.write(tr);
        last_item = tr;
      end
    end
  endtask
endclass

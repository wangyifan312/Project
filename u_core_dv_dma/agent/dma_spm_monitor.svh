class dma_spm_monitor extends uvm_component;
  `uvm_component_utils(dma_spm_monitor)

  virtual dma_spm_if vif;
  uvm_analysis_port #(dma_spm_item) ap;

  function new(string name = "dma_spm_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_spm_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "dma_spm_if handle is not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    dma_spm_item tr;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.wr_valid && vif.mon_cb.wr_ready) begin
        tr = dma_spm_item::type_id::create("wr_tr", this);
        tr.kind     = dma_spm_item::DMA_SPM_WR;
        tr.spm_type = vif.mon_cb.wr_type;
        tr.buf_sel  = vif.mon_cb.wr_buf_sel;
        tr.row_idx  = vif.mon_cb.wr_row_idx;
        tr.data     = vif.mon_cb.wr_data;
        tr.strb     = vif.mon_cb.wr_strb;
        tr.last     = vif.mon_cb.wr_last;
        ap.write(tr);
      end
      if (vif.mon_cb.rd_req_valid && vif.mon_cb.rd_req_ready) begin
        tr = dma_spm_item::type_id::create("rd_req_tr", this);
        tr.kind    = dma_spm_item::DMA_SPM_RD_REQ;
        tr.buf_sel = vif.mon_cb.rd_buf_sel;
        tr.row_idx = vif.mon_cb.rd_row_idx;
        ap.write(tr);
      end
      if (vif.mon_cb.rd_data_valid && vif.mon_cb.rd_data_ready) begin
        tr = dma_spm_item::type_id::create("rd_data_tr", this);
        tr.kind    = dma_spm_item::DMA_SPM_RD_DATA;
        tr.data    = vif.mon_cb.rd_data;
        tr.last    = vif.mon_cb.rd_last;
        ap.write(tr);
      end
    end
  endtask
endclass

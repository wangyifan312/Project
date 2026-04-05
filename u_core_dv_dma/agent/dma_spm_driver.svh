class dma_spm_driver extends uvm_component;
  `uvm_component_utils(dma_spm_driver)

  virtual dma_spm_if vif;
  dma_env_cfg cfg;

  bit [u_core_pkg::AXI_DATA_W-1:0] act_mem [0:1][0:u_core_pkg::DMA_SPM_ROW_COUNT-1];
  bit [u_core_pkg::AXI_DATA_W-1:0] wgt_mem [0:1][0:u_core_pkg::DMA_SPM_ROW_COUNT-1];
  bit [u_core_pkg::AXI_DATA_W-1:0] out_mem [0:u_core_pkg::DMA_SPM_ROW_COUNT-1];

  function new(string name = "dma_spm_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_spm_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "dma_spm_if handle is not set")
    end
    if (!uvm_config_db#(dma_env_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "dma_env_cfg is not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    preload_out_mem();
    vif.init_slave();
    forever begin
      @(vif.drv_cb);
      vif.drv_cb.wr_ready         <= cfg.spm_wr_ready_default;
      vif.drv_cb.rd_req_ready     <= cfg.spm_rd_ready_default;
      vif.drv_cb.act_buf_writable <= cfg.act_buf_writable_init;
      vif.drv_cb.wgt_buf_writable <= cfg.wgt_buf_writable_init;
      vif.drv_cb.out_buf_readable <= cfg.out_buf_readable_init;
      vif.drv_cb.spm_dma_error    <= cfg.inject_spm_error;
      vif.drv_cb.spm_dma_error_code <= cfg.inject_spm_error_code;

      if (vif.drv_cb.wr_valid && vif.drv_cb.wr_ready) begin
        if (vif.drv_cb.wr_type == u_core_pkg::DMA_SPM_TYPE_ACT) begin
          act_mem[vif.drv_cb.wr_buf_sel][vif.drv_cb.wr_row_idx] = vif.drv_cb.wr_data;
        end else begin
          wgt_mem[vif.drv_cb.wr_buf_sel][vif.drv_cb.wr_row_idx] = vif.drv_cb.wr_data;
        end
      end

      if (vif.drv_cb.rd_req_valid && vif.drv_cb.rd_req_ready) begin
        repeat (cfg.spm_rd_data_latency) @(vif.drv_cb);
        vif.drv_cb.rd_data      <= out_mem[vif.drv_cb.rd_row_idx];
        vif.drv_cb.rd_last      <= (vif.drv_cb.rd_row_idx == (u_core_pkg::DMA_SPM_ROW_COUNT-1));
        vif.drv_cb.rd_data_valid <= 1'b1;
        do @(vif.drv_cb); while (!vif.drv_cb.rd_data_ready);
        vif.drv_cb.rd_data_valid <= 1'b0;
      end
    end
  endtask

  task preload_out_mem();
    foreach (cfg.spm_out_init_q[idx]) begin
      out_mem[cfg.spm_out_init_q[idx].row_idx] = cfg.spm_out_init_q[idx].data;
    end
  endtask
endclass

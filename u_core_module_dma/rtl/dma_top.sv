module dma_top (
  input  logic                                clk,
  input  logic                                rst_n,

  input  logic                                dma_axil_awvalid,
  output logic                                dma_axil_awready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  dma_axil_awaddr,
  input  logic [2:0]                          dma_axil_awprot,
  input  logic                                dma_axil_wvalid,
  output logic                                dma_axil_wready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  dma_axil_wdata,
  input  logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] dma_axil_wstrb,
  output logic                                dma_axil_bvalid,
  input  logic                                dma_axil_bready,
  output logic [1:0]                          dma_axil_bresp,
  input  logic                                dma_axil_arvalid,
  output logic                                dma_axil_arready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  dma_axil_araddr,
  input  logic [2:0]                          dma_axil_arprot,
  output logic                                dma_axil_rvalid,
  input  logic                                dma_axil_rready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  dma_axil_rdata,
  output logic [1:0]                          dma_axil_rresp,

  output logic                                dma_m_axi_awvalid,
  input  logic                                dma_m_axi_awready,
  output logic [u_core_pkg::AXI_ADDR_W-1:0]   dma_m_axi_awaddr,
  output logic [7:0]                          dma_m_axi_awlen,
  output logic [2:0]                          dma_m_axi_awsize,
  output logic [1:0]                          dma_m_axi_awburst,
  output logic                                dma_m_axi_wvalid,
  input  logic                                dma_m_axi_wready,
  output logic [u_core_pkg::AXI_DATA_W-1:0]   dma_m_axi_wdata,
  output logic [u_core_pkg::AXI_STRB_W-1:0]   dma_m_axi_wstrb,
  output logic                                dma_m_axi_wlast,
  input  logic                                dma_m_axi_bvalid,
  output logic                                dma_m_axi_bready,
  input  logic [1:0]                          dma_m_axi_bresp,
  output logic                                dma_m_axi_arvalid,
  input  logic                                dma_m_axi_arready,
  output logic [u_core_pkg::AXI_ADDR_W-1:0]   dma_m_axi_araddr,
  output logic [7:0]                          dma_m_axi_arlen,
  output logic [2:0]                          dma_m_axi_arsize,
  output logic [1:0]                          dma_m_axi_arburst,
  input  logic                                dma_m_axi_rvalid,
  output logic                                dma_m_axi_rready,
  input  logic [u_core_pkg::AXI_DATA_W-1:0]   dma_m_axi_rdata,
  input  logic [1:0]                          dma_m_axi_rresp,
  input  logic                                dma_m_axi_rlast,

  output logic                                dma_spm_wr_valid,
  input  logic                                dma_spm_wr_ready,
  output logic [1:0]                          dma_spm_wr_type,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    dma_spm_wr_buf_sel,
  output logic [u_core_pkg::DMA_SPM_ROW_W-1:0] dma_spm_wr_row_idx,
  output logic [u_core_pkg::AXI_DATA_W-1:0]   dma_spm_wr_data,
  output logic [u_core_pkg::AXI_STRB_W-1:0]   dma_spm_wr_strb,
  output logic                                dma_spm_wr_last,

  output logic                                dma_spm_rd_req_valid,
  input  logic                                dma_spm_rd_req_ready,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    dma_spm_rd_buf_sel,
  output logic [u_core_pkg::DMA_SPM_ROW_W-1:0] dma_spm_rd_row_idx,
  input  logic                                dma_spm_rd_data_valid,
  output logic                                dma_spm_rd_data_ready,
  input  logic [u_core_pkg::AXI_DATA_W-1:0]   dma_spm_rd_data,
  input  logic                                dma_spm_rd_last,

  input  logic [u_core_pkg::BUF_SEL_W-1:0]    act_buf_writable,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    wgt_buf_writable,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    out_buf_readable,
  input  logic                                spm_dma_error,
  input  logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] spm_dma_error_code,

  output logic                                dma_busy,
  output logic                                dma_done,
  output logic                                dma_error,
  output logic                                dma_fifo_empty,
  output logic                                dma_fifo_full,
  output logic [u_core_pkg::DMA_FIFO_LEVEL_W-1:0] dma_fifo_level,
  output logic [31:0]                         dma_done_count,
  output logic [31:0]                         dma_rd_beat_count,
  output logic [31:0]                         dma_wr_beat_count,
  output logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] dma_error_code
);

  import u_core_pkg::*;

  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_FIFO_FULL = 8'h06;

  logic                                   stage_we;
  logic [3:0]                             stage_addr;
  logic [AXIL_DATA_W-1:0]                 stage_wdata;
  logic                                   submit_pulse;
  logic [AXIL_DATA_W-1:0]                 cfg0_word;
  logic [AXIL_DATA_W-1:0]                 src_addr_word;
  logic [AXIL_DATA_W-1:0]                 dst_addr_word;
  logic [AXIL_DATA_W-1:0]                 row_cfg_word;
  logic [AXIL_DATA_W-1:0]                 stride_cfg_word;
  logic [AXIL_DATA_W-1:0]                 local_cfg_word;
  logic [DMA_DESC_W-1:0]                  stage_desc_bus;
  logic                                   stage_desc_valid;
  logic [DMA_ERROR_CODE_W-1:0]            stage_desc_error_code;

  logic [DMA_DESC_W-1:0]                  fifo_head_desc;
  logic                                   fifo_push_valid;
  logic                                   fifo_pop_valid;

  logic                                   sched_issue_rd_valid;
  logic                                   sched_issue_wr_valid;
  logic [DMA_DESC_W-1:0]                  sched_issue_desc;

  logic                                   rd_engine_busy;
  logic                                   rd_engine_ready;
  logic                                   rd_done_pulse;
  logic                                   rd_beat_pulse;
  logic                                   rd_error_pulse;
  logic [DMA_ERROR_CODE_W-1:0]            rd_error_code;
  logic                                   rd_local_wr_valid;
  logic [1:0]                             rd_local_wr_type;
  logic [BUF_SEL_W-1:0]                   rd_local_wr_buf_sel;
  logic [DMA_SPM_ROW_W-1:0]               rd_local_wr_row_idx;
  logic [AXI_DATA_W-1:0]                  rd_local_wr_data;
  logic [AXI_STRB_W-1:0]                  rd_local_wr_strb;
  logic                                   rd_local_wr_last;
  logic                                   rd_local_wr_ready;

  logic                                   wr_engine_busy;
  logic                                   wr_engine_ready;
  logic                                   wr_done_pulse;
  logic                                   wr_beat_pulse;
  logic                                   wr_error_pulse;
  logic [DMA_ERROR_CODE_W-1:0]            wr_error_code;
  logic                                   wr_local_rd_req_valid;
  logic                                   wr_local_rd_req_ready;
  logic [BUF_SEL_W-1:0]                   wr_local_rd_buf_sel;
  logic [DMA_SPM_ROW_W-1:0]               wr_local_rd_row_idx;
  logic                                   wr_local_rd_data_valid;
  logic                                   wr_local_rd_data_ready;
  logic [AXI_DATA_W-1:0]                  wr_local_rd_data;
  logic                                   wr_local_rd_last;

  logic                                   status_error_pulse;
  logic [DMA_ERROR_CODE_W-1:0]            status_error_code;

  dma_csr_if u_dma_csr_if (
    .clk              (clk),
    .rst_n            (rst_n),
    .dma_axil_awvalid (dma_axil_awvalid),
    .dma_axil_awready (dma_axil_awready),
    .dma_axil_awaddr  (dma_axil_awaddr),
    .dma_axil_awprot  (dma_axil_awprot),
    .dma_axil_wvalid  (dma_axil_wvalid),
    .dma_axil_wready  (dma_axil_wready),
    .dma_axil_wdata   (dma_axil_wdata),
    .dma_axil_wstrb   (dma_axil_wstrb),
    .dma_axil_bvalid  (dma_axil_bvalid),
    .dma_axil_bready  (dma_axil_bready),
    .dma_axil_bresp   (dma_axil_bresp),
    .dma_axil_arvalid (dma_axil_arvalid),
    .dma_axil_arready (dma_axil_arready),
    .dma_axil_araddr  (dma_axil_araddr),
    .dma_axil_arprot  (dma_axil_arprot),
    .dma_axil_rvalid  (dma_axil_rvalid),
    .dma_axil_rready  (dma_axil_rready),
    .dma_axil_rdata   (dma_axil_rdata),
    .dma_axil_rresp   (dma_axil_rresp),
    .stage_we         (stage_we),
    .stage_addr       (stage_addr),
    .stage_wdata      (stage_wdata),
    .submit_pulse     (submit_pulse),
    .cfg0_word        (cfg0_word),
    .src_addr_word    (src_addr_word),
    .dst_addr_word    (dst_addr_word),
    .row_cfg_word     (row_cfg_word),
    .stride_cfg_word  (stride_cfg_word),
    .local_cfg_word   (local_cfg_word),
    .dma_busy         (dma_busy),
    .dma_done         (dma_done),
    .dma_error        (dma_error),
    .dma_fifo_empty   (dma_fifo_empty),
    .dma_fifo_full    (dma_fifo_full),
    .dma_fifo_level   (dma_fifo_level),
    .dma_done_count   (dma_done_count),
    .dma_rd_beat_count(dma_rd_beat_count),
    .dma_wr_beat_count(dma_wr_beat_count),
    .dma_error_code   (dma_error_code)
  );

  dma_desc_stage u_dma_desc_stage (
    .clk            (clk),
    .rst_n          (rst_n),
    .stage_we       (stage_we),
    .stage_addr     (stage_addr),
    .stage_wdata    (stage_wdata),
    .cfg0_word      (cfg0_word),
    .src_addr_word  (src_addr_word),
    .dst_addr_word  (dst_addr_word),
    .row_cfg_word   (row_cfg_word),
    .stride_cfg_word(stride_cfg_word),
    .local_cfg_word (local_cfg_word),
    .desc_bus       (stage_desc_bus),
    .desc_valid     (stage_desc_valid),
    .desc_error_code(stage_desc_error_code)
  );

  assign fifo_push_valid = submit_pulse && stage_desc_valid && !dma_fifo_full;

  dma_desc_fifo u_dma_desc_fifo (
    .clk       (clk),
    .rst_n     (rst_n),
    .push_valid(fifo_push_valid),
    .push_desc (stage_desc_bus),
    .pop_valid (fifo_pop_valid),
    .head_desc (fifo_head_desc),
    .fifo_empty(dma_fifo_empty),
    .fifo_full (dma_fifo_full),
    .fifo_level(dma_fifo_level)
  );

  dma_scheduler u_dma_scheduler (
    .fifo_empty      (dma_fifo_empty),
    .head_desc       (fifo_head_desc),
    .act_buf_writable(act_buf_writable),
    .wgt_buf_writable(wgt_buf_writable),
    .out_buf_readable(out_buf_readable),
    .rd_engine_ready (rd_engine_ready),
    .wr_engine_ready (wr_engine_ready),
    .issue_rd_valid  (sched_issue_rd_valid),
    .issue_wr_valid  (sched_issue_wr_valid),
    .pop_desc        (fifo_pop_valid),
    .issue_desc      (sched_issue_desc)
  );

  dma_rd_engine u_dma_rd_engine (
    .clk            (clk),
    .rst_n          (rst_n),
    .start_valid    (sched_issue_rd_valid),
    .start_desc     (sched_issue_desc),
    .m_axi_arvalid  (dma_m_axi_arvalid),
    .m_axi_arready  (dma_m_axi_arready),
    .m_axi_araddr   (dma_m_axi_araddr),
    .m_axi_arlen    (dma_m_axi_arlen),
    .m_axi_arsize   (dma_m_axi_arsize),
    .m_axi_arburst  (dma_m_axi_arburst),
    .m_axi_rvalid   (dma_m_axi_rvalid),
    .m_axi_rready   (dma_m_axi_rready),
    .m_axi_rdata    (dma_m_axi_rdata),
    .m_axi_rresp    (dma_m_axi_rresp),
    .m_axi_rlast    (dma_m_axi_rlast),
    .local_wr_ready (rd_local_wr_ready),
    .engine_busy    (rd_engine_busy),
    .engine_ready   (rd_engine_ready),
    .done_pulse     (rd_done_pulse),
    .beat_pulse     (rd_beat_pulse),
    .error_pulse    (rd_error_pulse),
    .error_code     (rd_error_code),
    .local_wr_valid (rd_local_wr_valid),
    .local_wr_type  (rd_local_wr_type),
    .local_wr_buf_sel(rd_local_wr_buf_sel),
    .local_wr_row_idx(rd_local_wr_row_idx),
    .local_wr_data  (rd_local_wr_data),
    .local_wr_strb  (rd_local_wr_strb),
    .local_wr_last  (rd_local_wr_last)
  );

  dma_wr_engine u_dma_wr_engine (
    .clk              (clk),
    .rst_n            (rst_n),
    .start_valid      (sched_issue_wr_valid),
    .start_desc       (sched_issue_desc),
    .local_rd_req_ready(wr_local_rd_req_ready),
    .local_rd_data_valid(wr_local_rd_data_valid),
    .local_rd_data_ready(wr_local_rd_data_ready),
    .local_rd_data    (wr_local_rd_data),
    .local_rd_last    (wr_local_rd_last),
    .m_axi_awvalid    (dma_m_axi_awvalid),
    .m_axi_awready    (dma_m_axi_awready),
    .m_axi_awaddr     (dma_m_axi_awaddr),
    .m_axi_awlen      (dma_m_axi_awlen),
    .m_axi_awsize     (dma_m_axi_awsize),
    .m_axi_awburst    (dma_m_axi_awburst),
    .m_axi_wvalid     (dma_m_axi_wvalid),
    .m_axi_wready     (dma_m_axi_wready),
    .m_axi_wdata      (dma_m_axi_wdata),
    .m_axi_wstrb      (dma_m_axi_wstrb),
    .m_axi_wlast      (dma_m_axi_wlast),
    .m_axi_bvalid     (dma_m_axi_bvalid),
    .m_axi_bready     (dma_m_axi_bready),
    .m_axi_bresp      (dma_m_axi_bresp),
    .engine_busy      (wr_engine_busy),
    .engine_ready     (wr_engine_ready),
    .done_pulse       (wr_done_pulse),
    .beat_pulse       (wr_beat_pulse),
    .error_pulse      (wr_error_pulse),
    .error_code       (wr_error_code),
    .local_rd_req_valid(wr_local_rd_req_valid),
    .local_rd_buf_sel (wr_local_rd_buf_sel),
    .local_rd_row_idx (wr_local_rd_row_idx)
  );

  dma_local_if u_dma_local_if (
    .rd_local_wr_valid(rd_local_wr_valid),
    .rd_local_wr_ready(rd_local_wr_ready),
    .rd_local_wr_type (rd_local_wr_type),
    .rd_local_wr_buf_sel(rd_local_wr_buf_sel),
    .rd_local_wr_row_idx(rd_local_wr_row_idx),
    .rd_local_wr_data (rd_local_wr_data),
    .rd_local_wr_strb (rd_local_wr_strb),
    .rd_local_wr_last (rd_local_wr_last),
    .wr_local_rd_req_valid(wr_local_rd_req_valid),
    .wr_local_rd_req_ready(wr_local_rd_req_ready),
    .wr_local_rd_buf_sel(wr_local_rd_buf_sel),
    .wr_local_rd_row_idx(wr_local_rd_row_idx),
    .wr_local_rd_data_valid(wr_local_rd_data_valid),
    .wr_local_rd_data_ready(wr_local_rd_data_ready),
    .wr_local_rd_data(wr_local_rd_data),
    .wr_local_rd_last(wr_local_rd_last),
    .dma_spm_wr_valid(dma_spm_wr_valid),
    .dma_spm_wr_ready(dma_spm_wr_ready),
    .dma_spm_wr_type (dma_spm_wr_type),
    .dma_spm_wr_buf_sel(dma_spm_wr_buf_sel),
    .dma_spm_wr_row_idx(dma_spm_wr_row_idx),
    .dma_spm_wr_data (dma_spm_wr_data),
    .dma_spm_wr_strb (dma_spm_wr_strb),
    .dma_spm_wr_last (dma_spm_wr_last),
    .dma_spm_rd_req_valid(dma_spm_rd_req_valid),
    .dma_spm_rd_req_ready(dma_spm_rd_req_ready),
    .dma_spm_rd_buf_sel(dma_spm_rd_buf_sel),
    .dma_spm_rd_row_idx(dma_spm_rd_row_idx),
    .dma_spm_rd_data_valid(dma_spm_rd_data_valid),
    .dma_spm_rd_data_ready(dma_spm_rd_data_ready),
    .dma_spm_rd_data (dma_spm_rd_data),
    .dma_spm_rd_last (dma_spm_rd_last)
  );

  assign status_error_pulse = rd_error_pulse || wr_error_pulse ||
                              (submit_pulse && (!stage_desc_valid || dma_fifo_full)) ||
                              spm_dma_error;
  assign status_error_code  = rd_error_pulse ? rd_error_code :
                              (wr_error_pulse ? wr_error_code :
                              (spm_dma_error ? spm_dma_error_code :
                              (stage_desc_valid ? DMA_ERR_FIFO_FULL : stage_desc_error_code)));

  dma_status_perf u_dma_status_perf (
    .clk             (clk),
    .rst_n           (rst_n),
    .submit_pulse    (submit_pulse),
    .exec_busy       (rd_engine_busy || wr_engine_busy),
    .fifo_empty_in   (dma_fifo_empty),
    .fifo_full_in    (dma_fifo_full),
    .fifo_level_in   (dma_fifo_level),
    .done_pulse_in   (rd_done_pulse || wr_done_pulse),
    .error_pulse_in  (status_error_pulse),
    .error_code_in   (status_error_code),
    .rd_beat_pulse_in(rd_beat_pulse),
    .wr_beat_pulse_in(wr_beat_pulse),
    .dma_busy        (dma_busy),
    .dma_done        (dma_done),
    .dma_error       (dma_error),
    .dma_fifo_empty  (),
    .dma_fifo_full   (),
    .dma_fifo_level  (),
    .dma_done_count  (dma_done_count),
    .dma_rd_beat_count(dma_rd_beat_count),
    .dma_wr_beat_count(dma_wr_beat_count),
    .dma_error_code  (dma_error_code)
  );

endmodule

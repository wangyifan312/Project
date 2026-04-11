`timescale 1ns/1ps

module u_core_dataflow_tb;

  import u_core_pkg::*;

  localparam logic [31:0] ACT_SRC_BASE_ADDR = 32'h2000_0000;
  localparam logic [31:0] WGT_SRC_BASE_ADDR = 32'h2000_0100;
  localparam logic [31:0] OUT_DST_BASE_ADDR = 32'h2000_1000;
  localparam logic [OUT_VEC_W-1:0] EXPECTED_NPU_ROW = {
    16'h000e, 16'h000e, 16'h000e, 16'h000e,
    16'h000e, 16'h000e, 16'h000e, 16'h000e,
    16'h000e, 16'h000e, 16'h000e, 16'h000e,
    16'h000e, 16'h000e, 16'h000e, 16'h000e
  };

  logic                               clk;
  logic                               rst_n;
  integer                             log_fd;
  integer                             idx;
  integer                             npu_handshake_count;
  integer                             npu_out_row_count;

  logic                               dma_axil_awvalid;
  logic                               dma_axil_awready;
  logic [AXIL_ADDR_W-1:0]             dma_axil_awaddr;
  logic [2:0]                         dma_axil_awprot;
  logic                               dma_axil_wvalid;
  logic                               dma_axil_wready;
  logic [AXIL_DATA_W-1:0]             dma_axil_wdata;
  logic [(AXIL_DATA_W/8)-1:0]         dma_axil_wstrb;
  logic                               dma_axil_bvalid;
  logic                               dma_axil_bready;
  logic [1:0]                         dma_axil_bresp;
  logic                               dma_axil_arvalid;
  logic                               dma_axil_arready;
  logic [AXIL_ADDR_W-1:0]             dma_axil_araddr;
  logic [2:0]                         dma_axil_arprot;
  logic                               dma_axil_rvalid;
  logic                               dma_axil_rready;
  logic [AXIL_DATA_W-1:0]             dma_axil_rdata;
  logic [1:0]                         dma_axil_rresp;

  logic                               npu_axil_awvalid;
  logic                               npu_axil_awready;
  logic [AXIL_ADDR_W-1:0]             npu_axil_awaddr;
  logic [2:0]                         npu_axil_awprot;
  logic                               npu_axil_wvalid;
  logic                               npu_axil_wready;
  logic [AXIL_DATA_W-1:0]             npu_axil_wdata;
  logic [(AXIL_DATA_W/8)-1:0]         npu_axil_wstrb;
  logic                               npu_axil_bvalid;
  logic                               npu_axil_bready;
  logic [1:0]                         npu_axil_bresp;
  logic                               npu_axil_arvalid;
  logic                               npu_axil_arready;
  logic [AXIL_ADDR_W-1:0]             npu_axil_araddr;
  logic [2:0]                         npu_axil_arprot;
  logic                               npu_axil_rvalid;
  logic                               npu_axil_rready;
  logic [AXIL_DATA_W-1:0]             npu_axil_rdata;
  logic [1:0]                         npu_axil_rresp;

  logic                               dma_m_axi_awvalid;
  logic                               dma_m_axi_awready;
  logic [AXI_ADDR_W-1:0]              dma_m_axi_awaddr;
  logic [7:0]                         dma_m_axi_awlen;
  logic [2:0]                         dma_m_axi_awsize;
  logic [1:0]                         dma_m_axi_awburst;
  logic                               dma_m_axi_wvalid;
  logic                               dma_m_axi_wready;
  logic [AXI_DATA_W-1:0]              dma_m_axi_wdata;
  logic [AXI_STRB_W-1:0]              dma_m_axi_wstrb;
  logic                               dma_m_axi_wlast;
  logic                               dma_m_axi_bvalid;
  logic                               dma_m_axi_bready;
  logic [1:0]                         dma_m_axi_bresp;
  logic                               dma_m_axi_arvalid;
  logic                               dma_m_axi_arready;
  logic [AXI_ADDR_W-1:0]              dma_m_axi_araddr;
  logic [7:0]                         dma_m_axi_arlen;
  logic [2:0]                         dma_m_axi_arsize;
  logic [1:0]                         dma_m_axi_arburst;
  logic                               dma_m_axi_rvalid;
  logic                               dma_m_axi_rready;
  logic [AXI_DATA_W-1:0]              dma_m_axi_rdata;
  logic [1:0]                         dma_m_axi_rresp;
  logic                               dma_m_axi_rlast;

  logic                               dma_spm_wr_valid;
  logic                               dma_spm_wr_ready;
  logic [1:0]                         dma_spm_wr_type;
  logic [BUF_SEL_W-1:0]               dma_spm_wr_buf_sel;
  logic [DMA_SPM_ROW_W-1:0]           dma_spm_wr_row_idx;
  logic [AXI_DATA_W-1:0]              dma_spm_wr_data;
  logic [AXI_STRB_W-1:0]              dma_spm_wr_strb;
  logic                               dma_spm_wr_last;

  logic                               dma_spm_rd_req_valid;
  logic                               dma_spm_rd_req_ready;
  logic [BUF_SEL_W-1:0]               dma_spm_rd_buf_sel;
  logic [DMA_SPM_ROW_W-1:0]           dma_spm_rd_row_idx;
  logic                               dma_spm_rd_data_valid;
  logic                               dma_spm_rd_data_ready;
  logic [AXI_DATA_W-1:0]              dma_spm_rd_data;
  logic                               dma_spm_rd_last;

  logic                               spm_npu_vec_valid;
  logic                               spm_npu_vec_ready;
  logic [BUF_SEL_W-1:0]               spm_npu_act_buf_sel;
  logic [BUF_SEL_W-1:0]               spm_npu_wgt_buf_sel;
  logic [NPU_K_IDX_W-1:0]             spm_npu_k_idx;
  logic [ACT_VEC_W-1:0]               spm_npu_act_vec;
  logic [WGT_VEC_W-1:0]               spm_npu_wgt_vec;

  logic                               npu_spm_out_valid;
  logic                               npu_spm_out_ready;
  logic [BUF_SEL_W-1:0]               npu_spm_out_buf_sel;
  logic [NPU_OUT_ROW_W-1:0]           npu_spm_out_row_idx;
  logic [ARRAY_N-1:0]                 npu_spm_out_col_mask;
  logic [OUT_VEC_W-1:0]               npu_spm_out_data;
  logic                               npu_spm_out_last;

  logic [BUF_SEL_W-1:0]               act_buf_writable;
  logic [BUF_SEL_W-1:0]               wgt_buf_writable;
  logic [BUF_SEL_W-1:0]               out_buf_readable;
  logic                               spm_dma_error;
  logic [DMA_ERROR_CODE_W-1:0]        spm_dma_error_code;

  logic [BUF_SEL_W-1:0]               act_buf_ready;
  logic [BUF_SEL_W-1:0]               wgt_buf_ready;
  logic [BUF_SEL_W-1:0]               out_buf_free;
  logic                               spm_npu_error;
  logic [NPU_ERROR_CODE_W-1:0]        spm_npu_error_code;

  logic                               dma_busy;
  logic                               dma_done;
  logic                               dma_error;
  logic                               dma_fifo_empty;
  logic                               dma_fifo_full;
  logic [DMA_FIFO_LEVEL_W-1:0]        dma_fifo_level;
  logic [31:0]                        dma_done_count;
  logic [31:0]                        dma_rd_beat_count;
  logic [31:0]                        dma_wr_beat_count;
  logic [DMA_ERROR_CODE_W-1:0]        dma_error_code;

  logic                               npu_armed;
  logic                               npu_busy;
  logic                               npu_done;
  logic                               npu_error;
  logic [31:0]                        npu_stall_cycles;
  logic [NPU_ERROR_CODE_W-1:0]        npu_error_code;

  logic [AXI_DATA_W-1:0]              ext_act_mem [0:0];
  logic [AXI_DATA_W-1:0]              ext_wgt_mem [0:0];
  logic [AXI_DATA_W-1:0]              ext_dst_mem [0:7];
  logic [AXI_ADDR_W-1:0]              axi_wr_addr_pending_r;
  logic                               axi_wr_addr_valid_r;

  logic [31:0]                        dma_status_word;
  logic [31:0]                        dma_rd_count_word;
  logic [31:0]                        dma_wr_count_word;
  logic [31:0]                        npu_status_word;
  logic [31:0]                        npu_busy_cycles_word;
  logic [AXI_DATA_W-1:0]              expected_dst_row;

  dma_top u_dma_top (
    .clk                (clk),
    .rst_n              (rst_n),
    .dma_axil_awvalid   (dma_axil_awvalid),
    .dma_axil_awready   (dma_axil_awready),
    .dma_axil_awaddr    (dma_axil_awaddr),
    .dma_axil_awprot    (dma_axil_awprot),
    .dma_axil_wvalid    (dma_axil_wvalid),
    .dma_axil_wready    (dma_axil_wready),
    .dma_axil_wdata     (dma_axil_wdata),
    .dma_axil_wstrb     (dma_axil_wstrb),
    .dma_axil_bvalid    (dma_axil_bvalid),
    .dma_axil_bready    (dma_axil_bready),
    .dma_axil_bresp     (dma_axil_bresp),
    .dma_axil_arvalid   (dma_axil_arvalid),
    .dma_axil_arready   (dma_axil_arready),
    .dma_axil_araddr    (dma_axil_araddr),
    .dma_axil_arprot    (dma_axil_arprot),
    .dma_axil_rvalid    (dma_axil_rvalid),
    .dma_axil_rready    (dma_axil_rready),
    .dma_axil_rdata     (dma_axil_rdata),
    .dma_axil_rresp     (dma_axil_rresp),
    .dma_m_axi_awvalid  (dma_m_axi_awvalid),
    .dma_m_axi_awready  (dma_m_axi_awready),
    .dma_m_axi_awaddr   (dma_m_axi_awaddr),
    .dma_m_axi_awlen    (dma_m_axi_awlen),
    .dma_m_axi_awsize   (dma_m_axi_awsize),
    .dma_m_axi_awburst  (dma_m_axi_awburst),
    .dma_m_axi_wvalid   (dma_m_axi_wvalid),
    .dma_m_axi_wready   (dma_m_axi_wready),
    .dma_m_axi_wdata    (dma_m_axi_wdata),
    .dma_m_axi_wstrb    (dma_m_axi_wstrb),
    .dma_m_axi_wlast    (dma_m_axi_wlast),
    .dma_m_axi_bvalid   (dma_m_axi_bvalid),
    .dma_m_axi_bready   (dma_m_axi_bready),
    .dma_m_axi_bresp    (dma_m_axi_bresp),
    .dma_m_axi_arvalid  (dma_m_axi_arvalid),
    .dma_m_axi_arready  (dma_m_axi_arready),
    .dma_m_axi_araddr   (dma_m_axi_araddr),
    .dma_m_axi_arlen    (dma_m_axi_arlen),
    .dma_m_axi_arsize   (dma_m_axi_arsize),
    .dma_m_axi_arburst  (dma_m_axi_arburst),
    .dma_m_axi_rvalid   (dma_m_axi_rvalid),
    .dma_m_axi_rready   (dma_m_axi_rready),
    .dma_m_axi_rdata    (dma_m_axi_rdata),
    .dma_m_axi_rresp    (dma_m_axi_rresp),
    .dma_m_axi_rlast    (dma_m_axi_rlast),
    .dma_spm_wr_valid   (dma_spm_wr_valid),
    .dma_spm_wr_ready   (dma_spm_wr_ready),
    .dma_spm_wr_type    (dma_spm_wr_type),
    .dma_spm_wr_buf_sel (dma_spm_wr_buf_sel),
    .dma_spm_wr_row_idx (dma_spm_wr_row_idx),
    .dma_spm_wr_data    (dma_spm_wr_data),
    .dma_spm_wr_strb    (dma_spm_wr_strb),
    .dma_spm_wr_last    (dma_spm_wr_last),
    .dma_spm_rd_req_valid(dma_spm_rd_req_valid),
    .dma_spm_rd_req_ready(dma_spm_rd_req_ready),
    .dma_spm_rd_buf_sel (dma_spm_rd_buf_sel),
    .dma_spm_rd_row_idx (dma_spm_rd_row_idx),
    .dma_spm_rd_data_valid(dma_spm_rd_data_valid),
    .dma_spm_rd_data_ready(dma_spm_rd_data_ready),
    .dma_spm_rd_data    (dma_spm_rd_data),
    .dma_spm_rd_last    (dma_spm_rd_last),
    .act_buf_writable   (act_buf_writable),
    .wgt_buf_writable   (wgt_buf_writable),
    .out_buf_readable   (out_buf_readable),
    .spm_dma_error      (spm_dma_error),
    .spm_dma_error_code (spm_dma_error_code),
    .dma_busy           (dma_busy),
    .dma_done           (dma_done),
    .dma_error          (dma_error),
    .dma_fifo_empty     (dma_fifo_empty),
    .dma_fifo_full      (dma_fifo_full),
    .dma_fifo_level     (dma_fifo_level),
    .dma_done_count     (dma_done_count),
    .dma_rd_beat_count  (dma_rd_beat_count),
    .dma_wr_beat_count  (dma_wr_beat_count),
    .dma_error_code     (dma_error_code)
  );

  spm_subsys u_spm_subsys (
    .clk                (clk),
    .rst_n              (rst_n),
    .dma_spm_wr_valid   (dma_spm_wr_valid),
    .dma_spm_wr_ready   (dma_spm_wr_ready),
    .dma_spm_wr_type    (dma_spm_wr_type),
    .dma_spm_wr_buf_sel (dma_spm_wr_buf_sel),
    .dma_spm_wr_row_idx (dma_spm_wr_row_idx),
    .dma_spm_wr_data    (dma_spm_wr_data),
    .dma_spm_wr_strb    (dma_spm_wr_strb),
    .dma_spm_wr_last    (dma_spm_wr_last),
    .dma_spm_rd_req_valid(dma_spm_rd_req_valid),
    .dma_spm_rd_req_ready(dma_spm_rd_req_ready),
    .dma_spm_rd_buf_sel (dma_spm_rd_buf_sel),
    .dma_spm_rd_row_idx (dma_spm_rd_row_idx),
    .dma_spm_rd_data_valid(dma_spm_rd_data_valid),
    .dma_spm_rd_data_ready(dma_spm_rd_data_ready),
    .dma_spm_rd_data    (dma_spm_rd_data),
    .dma_spm_rd_last    (dma_spm_rd_last),
    .spm_npu_vec_valid  (spm_npu_vec_valid),
    .spm_npu_vec_ready  (spm_npu_vec_ready),
    .spm_npu_act_buf_sel(spm_npu_act_buf_sel),
    .spm_npu_wgt_buf_sel(spm_npu_wgt_buf_sel),
    .spm_npu_k_idx      (spm_npu_k_idx),
    .spm_npu_act_vec    (spm_npu_act_vec),
    .spm_npu_wgt_vec    (spm_npu_wgt_vec),
    .npu_spm_out_valid  (npu_spm_out_valid),
    .npu_spm_out_ready  (npu_spm_out_ready),
    .npu_spm_out_buf_sel(npu_spm_out_buf_sel),
    .npu_spm_out_row_idx(npu_spm_out_row_idx),
    .npu_spm_out_col_mask(npu_spm_out_col_mask),
    .npu_spm_out_data   (npu_spm_out_data),
    .npu_spm_out_last   (npu_spm_out_last),
    .act_buf_writable   (act_buf_writable),
    .wgt_buf_writable   (wgt_buf_writable),
    .out_buf_readable   (out_buf_readable),
    .spm_dma_error      (spm_dma_error),
    .spm_dma_error_code (spm_dma_error_code),
    .act_buf_ready      (act_buf_ready),
    .wgt_buf_ready      (wgt_buf_ready),
    .out_buf_free       (out_buf_free),
    .spm_npu_error      (spm_npu_error),
    .spm_npu_error_code (spm_npu_error_code)
  );

  npu_top u_npu_top (
    .clk                (clk),
    .rst_n              (rst_n),
    .npu_axil_awvalid   (npu_axil_awvalid),
    .npu_axil_awready   (npu_axil_awready),
    .npu_axil_awaddr    (npu_axil_awaddr),
    .npu_axil_awprot    (npu_axil_awprot),
    .npu_axil_wvalid    (npu_axil_wvalid),
    .npu_axil_wready    (npu_axil_wready),
    .npu_axil_wdata     (npu_axil_wdata),
    .npu_axil_wstrb     (npu_axil_wstrb),
    .npu_axil_bvalid    (npu_axil_bvalid),
    .npu_axil_bready    (npu_axil_bready),
    .npu_axil_bresp     (npu_axil_bresp),
    .npu_axil_arvalid   (npu_axil_arvalid),
    .npu_axil_arready   (npu_axil_arready),
    .npu_axil_araddr    (npu_axil_araddr),
    .npu_axil_arprot    (npu_axil_arprot),
    .npu_axil_rvalid    (npu_axil_rvalid),
    .npu_axil_rready    (npu_axil_rready),
    .npu_axil_rdata     (npu_axil_rdata),
    .npu_axil_rresp     (npu_axil_rresp),
    .spm_npu_vec_valid  (spm_npu_vec_valid),
    .spm_npu_vec_ready  (spm_npu_vec_ready),
    .spm_npu_act_buf_sel(spm_npu_act_buf_sel),
    .spm_npu_wgt_buf_sel(spm_npu_wgt_buf_sel),
    .spm_npu_k_idx      (spm_npu_k_idx),
    .spm_npu_act_vec    (spm_npu_act_vec),
    .spm_npu_wgt_vec    (spm_npu_wgt_vec),
    .npu_spm_out_valid  (npu_spm_out_valid),
    .npu_spm_out_ready  (npu_spm_out_ready),
    .npu_spm_out_buf_sel(npu_spm_out_buf_sel),
    .npu_spm_out_row_idx(npu_spm_out_row_idx),
    .npu_spm_out_col_mask(npu_spm_out_col_mask),
    .npu_spm_out_data   (npu_spm_out_data),
    .npu_spm_out_last   (npu_spm_out_last),
    .act_buf_ready      (act_buf_ready),
    .wgt_buf_ready      (wgt_buf_ready),
    .out_buf_free       (out_buf_free),
    .spm_npu_error      (spm_npu_error),
    .spm_npu_error_code (spm_npu_error_code),
    .npu_armed          (npu_armed),
    .npu_busy           (npu_busy),
    .npu_done           (npu_done),
    .npu_error          (npu_error),
    .npu_stall_cycles   (npu_stall_cycles),
    .npu_error_code     (npu_error_code)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    log_fd = $fopen("/root/Project/u_core_top_soc/tb/u_core_dataflow_tb.log", "w");
    if (log_fd == 0) begin
      $fatal(1, "Failed to open integration TB log file");
    end
    log_msg("u_core dataflow TB log opened");

    rst_n = 1'b0;
    dma_axil_awvalid = 1'b0;
    dma_axil_awaddr  = '0;
    dma_axil_awprot  = '0;
    dma_axil_wvalid  = 1'b0;
    dma_axil_wdata   = '0;
    dma_axil_wstrb   = '0;
    dma_axil_bready  = 1'b0;
    dma_axil_arvalid = 1'b0;
    dma_axil_araddr  = '0;
    dma_axil_arprot  = '0;
    dma_axil_rready  = 1'b0;

    npu_axil_awvalid = 1'b0;
    npu_axil_awaddr  = '0;
    npu_axil_awprot  = '0;
    npu_axil_wvalid  = 1'b0;
    npu_axil_wdata   = '0;
    npu_axil_wstrb   = '0;
    npu_axil_bready  = 1'b0;
    npu_axil_arvalid = 1'b0;
    npu_axil_araddr  = '0;
    npu_axil_arprot  = '0;
    npu_axil_rready  = 1'b0;

    dma_m_axi_awready = 1'b0;
    dma_m_axi_wready  = 1'b0;
    dma_m_axi_bvalid  = 1'b0;
    dma_m_axi_bresp   = 2'b00;
    dma_m_axi_arready = 1'b0;
    dma_m_axi_rvalid  = 1'b0;
    dma_m_axi_rdata   = '0;
    dma_m_axi_rresp   = 2'b00;
    dma_m_axi_rlast   = 1'b0;
    axi_wr_addr_pending_r = '0;
    axi_wr_addr_valid_r   = 1'b0;
    npu_handshake_count   = 0;
    npu_out_row_count     = 0;

    preload_memory();

    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    log_msg("Released reset");
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      dma_m_axi_arready <= 1'b0;
      dma_m_axi_rvalid  <= 1'b0;
      dma_m_axi_rdata   <= '0;
      dma_m_axi_rresp   <= 2'b00;
      dma_m_axi_rlast   <= 1'b0;
    end else begin
      dma_m_axi_arready <= 1'b1;

      if (dma_m_axi_arvalid && dma_m_axi_arready) begin
        dma_m_axi_rdata  <= read_ext_mem_word(dma_m_axi_araddr);
        dma_m_axi_rresp  <= 2'b00;
        dma_m_axi_rlast  <= 1'b1;
        dma_m_axi_rvalid <= 1'b1;
        log_msg($sformatf(
          "EXT->DMA AXI READ addr=0x%08x data=0x%0h",
          dma_m_axi_araddr, read_ext_mem_word(dma_m_axi_araddr)
        ));
      end else if (dma_m_axi_rvalid && dma_m_axi_rready) begin
        dma_m_axi_rvalid <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      dma_m_axi_awready <= 1'b0;
      dma_m_axi_wready  <= 1'b0;
      dma_m_axi_bvalid  <= 1'b0;
      dma_m_axi_bresp   <= 2'b00;
      axi_wr_addr_pending_r <= '0;
      axi_wr_addr_valid_r   <= 1'b0;
    end else begin
      dma_m_axi_awready <= 1'b1;
      dma_m_axi_wready  <= 1'b1;

      if (dma_m_axi_awvalid && dma_m_axi_awready) begin
        axi_wr_addr_pending_r <= dma_m_axi_awaddr;
        axi_wr_addr_valid_r   <= 1'b1;
        log_msg($sformatf("DMA->EXT AXI WRITE addr accepted addr=0x%08x", dma_m_axi_awaddr));
      end

      if (dma_m_axi_wvalid && dma_m_axi_wready) begin
        if (dma_m_axi_awvalid && dma_m_axi_awready) begin
          write_ext_mem_word(dma_m_axi_awaddr, dma_m_axi_wdata);
          axi_wr_addr_valid_r <= 1'b0;
        end else if (axi_wr_addr_valid_r) begin
          write_ext_mem_word(axi_wr_addr_pending_r, dma_m_axi_wdata);
          axi_wr_addr_valid_r <= 1'b0;
        end
        dma_m_axi_bresp  <= 2'b00;
        dma_m_axi_bvalid <= 1'b1;
        log_msg($sformatf(
          "DMA->EXT AXI WRITE data=0x%0h strb=0x%0h last=%0b",
          dma_m_axi_wdata, dma_m_axi_wstrb, dma_m_axi_wlast
        ));
      end else if (dma_m_axi_bvalid && dma_m_axi_bready) begin
        dma_m_axi_bvalid <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (rst_n && dma_spm_wr_valid && dma_spm_wr_ready) begin
      log_msg($sformatf(
        "DMA->SPM write type=%0d buf=%0d row=%0d data=0x%0h last=%0b",
        dma_spm_wr_type, dma_spm_wr_buf_sel, dma_spm_wr_row_idx, dma_spm_wr_data, dma_spm_wr_last
      ));
    end
  end

  always @(posedge clk) begin
    if (rst_n && spm_npu_vec_valid && spm_npu_vec_ready) begin
      npu_handshake_count <= npu_handshake_count + 1;
      log_msg($sformatf(
        "SPM->NPU vec handshake #%0d act_buf=%0d wgt_buf=%0d k_idx=%0d act_vec=0x%0h wgt_vec=0x%0h",
        npu_handshake_count, spm_npu_act_buf_sel, spm_npu_wgt_buf_sel, spm_npu_k_idx,
        spm_npu_act_vec, spm_npu_wgt_vec
      ));

      case (spm_npu_k_idx)
        6'd0: begin
          if ((spm_npu_act_vec !== fill_vec(8'sd1)) || (spm_npu_wgt_vec !== fill_vec(8'sd2))) begin
            $fatal(1, "Unexpected k0 vectors observed by NPU");
          end
        end
        6'd1: begin
          if ((spm_npu_act_vec !== fill_vec(8'sd3)) || (spm_npu_wgt_vec !== fill_vec(8'sd4))) begin
            $fatal(1, "Unexpected k1 vectors observed by NPU");
          end
        end
        default: begin
          $fatal(1, "Unexpected k_idx observed in integration TB: %0d", spm_npu_k_idx);
        end
      endcase
      log_msg($sformatf("CHECK PASS: NPU consumed expected vectors for k_idx=%0d", spm_npu_k_idx));
    end
  end

  always @(posedge clk) begin
    if (rst_n && npu_spm_out_valid && npu_spm_out_ready) begin
      log_msg($sformatf(
        "NPU->SPM row write row=%0d data=0x%0h mask=0x%0h last=%0b",
        npu_spm_out_row_idx, npu_spm_out_data, npu_spm_out_col_mask, npu_spm_out_last
      ));
      if (npu_spm_out_data !== EXPECTED_NPU_ROW) begin
        $fatal(1, "Unexpected NPU output row data at row %0d", npu_spm_out_row_idx);
      end
      if (npu_spm_out_col_mask !== {ARRAY_N{1'b1}}) begin
        $fatal(1, "Unexpected NPU output row mask at row %0d", npu_spm_out_row_idx);
      end
      npu_out_row_count <= npu_out_row_count + 1;
      log_msg($sformatf("CHECK PASS: output row %0d matched expected value 14", npu_spm_out_row_idx));
    end
  end

  initial begin
    wait(rst_n === 1'b1);

    log_msg("Starting end-to-end dataflow case: LOAD_ACT -> LOAD_WGT -> NPU -> STORE_OUT");

    program_dma_desc(DMA_OP_LOAD_ACT, 2'd1, ACT_SRC_BASE_ADDR, 32'h0000_0000, 16'd64, 16'd1, 16'd64, 16'd64, 16'd0);
    poll_dma_done_or_error(dma_status_word);
    if (dma_status_word[2]) begin
      $fatal(1, "LOAD_ACT failed in integration TB status=0x%08x code=0x%0h", dma_status_word, dma_error_code);
    end
    log_msg($sformatf("CHECK PASS: LOAD_ACT done status=0x%08x act_buf_ready=0x%0h", dma_status_word, act_buf_ready));

    program_dma_desc(DMA_OP_LOAD_WGT, 2'd0, WGT_SRC_BASE_ADDR, 32'h0000_0000, 16'd64, 16'd1, 16'd64, 16'd64, 16'd0);
    poll_dma_done_or_error(dma_status_word);
    if (dma_status_word[2]) begin
      $fatal(1, "LOAD_WGT failed in integration TB status=0x%08x code=0x%0h", dma_status_word, dma_error_code);
    end
    log_msg($sformatf("CHECK PASS: LOAD_WGT done status=0x%08x wgt_buf_ready=0x%0h", dma_status_word, wgt_buf_ready));

    program_npu_cfg(2'd1, 2'd0, 2'd0, 8'd2, 8'd0, 16'd0, 1'b0);
    wait(npu_done === 1'b1);
    log_msg("Observed npu_done after DMA-fed computation");

    if (npu_handshake_count != 2) begin
      $fatal(1, "Expected 2 NPU vector handshakes, got %0d", npu_handshake_count);
    end
    if (npu_out_row_count != ARRAY_M) begin
      $fatal(1, "Expected %0d NPU output rows, got %0d", ARRAY_M, npu_out_row_count);
    end

    axil_read_npu(NPU_CSR_BASE + 32'h14, npu_status_word);
    if (npu_status_word[3:0] !== 4'b0100) begin
      $fatal(1, "Unexpected NPU_STATUS in integration TB: 0x%08x", npu_status_word);
    end
    log_msg($sformatf("CHECK PASS: NPU_STATUS=0x%08x", npu_status_word));

    axil_read_npu(NPU_CSR_BASE + 32'h1c, npu_busy_cycles_word);
    if (npu_busy_cycles_word == 32'h0) begin
      $fatal(1, "NPU busy cycle counter should be non-zero in integration TB");
    end
    log_msg($sformatf("CHECK PASS: NPU busy cycles=%0d", npu_busy_cycles_word));

    program_dma_desc(DMA_OP_STORE_OUT, 2'd0, 32'h0000_0000, OUT_DST_BASE_ADDR, 16'd64, 16'd8, 16'd64, 16'd64, 16'd0);
    poll_dma_done_or_error(dma_status_word);
    if (dma_status_word[2]) begin
      $fatal(1, "STORE_OUT failed in integration TB status=0x%08x code=0x%0h", dma_status_word, dma_error_code);
    end
    log_msg($sformatf("CHECK PASS: STORE_OUT done status=0x%08x", dma_status_word));

    for (idx = 0; idx < 8; idx = idx + 1) begin
      expected_dst_row = {EXPECTED_NPU_ROW, EXPECTED_NPU_ROW};
      if (ext_dst_mem[idx] !== expected_dst_row) begin
        $fatal(1, "Output memory mismatch at packed row %0d got=0x%0h exp=0x%0h", idx, ext_dst_mem[idx], expected_dst_row);
      end
      log_msg($sformatf(
        "CHECK PASS: external output row %0d matched expected packed result 0x%0h",
        idx, ext_dst_mem[idx]
      ));
    end

    axil_read_dma(DMA_CSR_BASE + 32'h28, dma_rd_count_word);
    axil_read_dma(DMA_CSR_BASE + 32'h2c, dma_wr_count_word);
    if (dma_rd_count_word != 2) begin
      $fatal(1, "Unexpected DMA read beat count in integration TB: %0d", dma_rd_count_word);
    end
    if (dma_wr_count_word != 8) begin
      $fatal(1, "Unexpected DMA write beat count in integration TB: %0d", dma_wr_count_word);
    end
    log_msg($sformatf(
      "CHECK PASS: DMA beat counts rd=%0d wr=%0d",
      dma_rd_count_word, dma_wr_count_word
    ));

    $display("U_CORE DATAFLOW TB PASS: DMA->SPM->NPU->SPM->DMA full chain passed");
    log_msg("U_CORE DATAFLOW TB PASS: DMA->SPM->NPU->SPM->DMA full chain passed");
    #20;
    $fclose(log_fd);
    $finish;
  end

  task automatic preload_memory();
    begin
      ext_act_mem[0] = make_segmented_row(8'h01, 8'h03, 8'h00, 8'h00);
      ext_wgt_mem[0] = make_segmented_row(8'h02, 8'h04, 8'h00, 8'h00);
      for (idx = 0; idx < 8; idx = idx + 1) begin
        ext_dst_mem[idx] = '0;
      end
      log_msg($sformatf("INIT act row0 = 0x%0h", ext_act_mem[0]));
      log_msg($sformatf("INIT wgt row0 = 0x%0h", ext_wgt_mem[0]));
    end
  endtask

  task automatic program_dma_desc(
    input logic [1:0]              op_type,
    input logic [BUF_SEL_W-1:0]    buf_sel,
    input logic [31:0]             src_addr,
    input logic [31:0]             dst_addr,
    input logic [15:0]             row_len,
    input logic [15:0]             row_cnt,
    input logic [15:0]             src_stride,
    input logic [15:0]             dst_stride,
    input logic [15:0]             spm_row_base
  );
    begin
      log_msg($sformatf(
        "Programming DMA desc op=%0d buf=%0d src=0x%08x dst=0x%08x row_len=%0d row_cnt=%0d spm_row_base=%0d",
        op_type, buf_sel, src_addr, dst_addr, row_len, row_cnt, spm_row_base
      ));
      axil_write_dma(
        DMA_CSR_BASE + 32'h00,
        {14'h0000, row_cnt[3:0], row_len[6:0], spm_row_base[2:0], buf_sel, op_type}
      );
      axil_write_dma(DMA_CSR_BASE + 32'h04, src_addr);
      axil_write_dma(DMA_CSR_BASE + 32'h08, dst_addr);
      axil_write_dma(DMA_CSR_BASE + 32'h0c, src_stride >> 6);
      axil_write_dma(DMA_CSR_BASE + 32'h18, 32'h0000_0001);
    end
  endtask

  task automatic program_npu_cfg(
    input logic [BUF_SEL_W-1:0] act_buf_sel,
    input logic [BUF_SEL_W-1:0] wgt_buf_sel,
    input logic [BUF_SEL_W-1:0] out_buf_sel,
    input logic [7:0]           ktile,
    input logic [7:0]           quant_shift,
    input logic [15:0]          zero_point,
    input logic                 relu_en
  );
    begin
      log_msg($sformatf(
        "Programming NPU cfg act_buf=%0d wgt_buf=%0d out_buf=%0d ktile=%0d",
        act_buf_sel, wgt_buf_sel, out_buf_sel, ktile
      ));
      axil_write_npu(NPU_CSR_BASE + 32'h00, {27'h0, relu_en, 4'h0});
      axil_write_npu(NPU_CSR_BASE + 32'h04, {26'h0, out_buf_sel, wgt_buf_sel, act_buf_sel});
      axil_write_npu(NPU_CSR_BASE + 32'h08, {24'h0, ktile});
      axil_write_npu(NPU_CSR_BASE + 32'h0c, {8'h0, zero_point, quant_shift});
      axil_write_npu(NPU_CSR_BASE + 32'h10, 32'h0000_0001);
    end
  endtask

  task automatic axil_write_dma(
    input logic [AXIL_ADDR_W-1:0] addr,
    input logic [AXIL_DATA_W-1:0] data
  );
    begin
      log_msg($sformatf("DMA AXI-Lite WRITE addr=0x%08x data=0x%08x", addr, data));
      @(posedge clk);
      dma_axil_awvalid <= 1'b1;
      dma_axil_awaddr  <= addr;
      dma_axil_wvalid  <= 1'b1;
      dma_axil_wdata   <= data;
      dma_axil_wstrb   <= {(AXIL_DATA_W/8){1'b1}};
      @(posedge clk);
      dma_axil_awvalid <= 1'b0;
      dma_axil_wvalid  <= 1'b0;
      dma_axil_bready  <= 1'b1;
      wait(dma_axil_bvalid === 1'b1);
      @(posedge clk);
      dma_axil_bready  <= 1'b0;
    end
  endtask

  task automatic axil_read_dma(
    input  logic [AXIL_ADDR_W-1:0] addr,
    output logic [AXIL_DATA_W-1:0] data
  );
    begin
      @(posedge clk);
      dma_axil_arvalid <= 1'b1;
      dma_axil_araddr  <= addr;
      @(posedge clk);
      dma_axil_arvalid <= 1'b0;
      dma_axil_rready  <= 1'b1;
      wait(dma_axil_rvalid === 1'b1);
      data = dma_axil_rdata;
      @(posedge clk);
      dma_axil_rready  <= 1'b0;
      log_msg($sformatf("DMA AXI-Lite READ addr=0x%08x data=0x%08x", addr, data));
    end
  endtask

  task automatic poll_dma_done_or_error(output logic [31:0] status);
    integer poll_idx;
    begin
      status = '0;
      for (poll_idx = 0; poll_idx < 512; poll_idx = poll_idx + 1) begin
        axil_read_dma(DMA_CSR_BASE + 32'h1c, status);
        if (status[1] || status[2]) begin
          return;
        end
      end
      $fatal(1, "DMA poll timeout in integration TB");
    end
  endtask

  task automatic axil_write_npu(
    input logic [AXIL_ADDR_W-1:0] addr,
    input logic [AXIL_DATA_W-1:0] data
  );
    begin
      log_msg($sformatf("NPU AXI-Lite WRITE addr=0x%08x data=0x%08x", addr, data));
      @(posedge clk);
      npu_axil_awvalid <= 1'b1;
      npu_axil_awaddr  <= addr;
      npu_axil_wvalid  <= 1'b1;
      npu_axil_wdata   <= data;
      npu_axil_wstrb   <= {(AXIL_DATA_W/8){1'b1}};
      @(posedge clk);
      npu_axil_awvalid <= 1'b0;
      npu_axil_wvalid  <= 1'b0;
      npu_axil_bready  <= 1'b1;
      wait(npu_axil_bvalid === 1'b1);
      @(posedge clk);
      npu_axil_bready  <= 1'b0;
    end
  endtask

  task automatic axil_read_npu(
    input  logic [AXIL_ADDR_W-1:0] addr,
    output logic [AXIL_DATA_W-1:0] data
  );
    begin
      @(posedge clk);
      npu_axil_arvalid <= 1'b1;
      npu_axil_araddr  <= addr;
      @(posedge clk);
      npu_axil_arvalid <= 1'b0;
      npu_axil_rready  <= 1'b1;
      wait(npu_axil_rvalid === 1'b1);
      data = npu_axil_rdata;
      @(posedge clk);
      npu_axil_rready  <= 1'b0;
      log_msg($sformatf("NPU AXI-Lite READ addr=0x%08x data=0x%08x", addr, data));
    end
  endtask

  function automatic [AXI_DATA_W-1:0] read_ext_mem_word(input logic [AXI_ADDR_W-1:0] byte_addr);
    begin
      case (byte_addr)
        ACT_SRC_BASE_ADDR: read_ext_mem_word = ext_act_mem[0];
        WGT_SRC_BASE_ADDR: read_ext_mem_word = ext_wgt_mem[0];
        OUT_DST_BASE_ADDR + 32'h000: read_ext_mem_word = ext_dst_mem[0];
        OUT_DST_BASE_ADDR + 32'h040: read_ext_mem_word = ext_dst_mem[1];
        OUT_DST_BASE_ADDR + 32'h080: read_ext_mem_word = ext_dst_mem[2];
        OUT_DST_BASE_ADDR + 32'h0c0: read_ext_mem_word = ext_dst_mem[3];
        OUT_DST_BASE_ADDR + 32'h100: read_ext_mem_word = ext_dst_mem[4];
        OUT_DST_BASE_ADDR + 32'h140: read_ext_mem_word = ext_dst_mem[5];
        OUT_DST_BASE_ADDR + 32'h180: read_ext_mem_word = ext_dst_mem[6];
        OUT_DST_BASE_ADDR + 32'h1c0: read_ext_mem_word = ext_dst_mem[7];
        default: read_ext_mem_word = '0;
      endcase
    end
  endfunction

  task automatic write_ext_mem_word(
    input logic [AXI_ADDR_W-1:0] byte_addr,
    input logic [AXI_DATA_W-1:0] data
  );
    begin
      case (byte_addr)
        OUT_DST_BASE_ADDR + 32'h000: ext_dst_mem[0] = data;
        OUT_DST_BASE_ADDR + 32'h040: ext_dst_mem[1] = data;
        OUT_DST_BASE_ADDR + 32'h080: ext_dst_mem[2] = data;
        OUT_DST_BASE_ADDR + 32'h0c0: ext_dst_mem[3] = data;
        OUT_DST_BASE_ADDR + 32'h100: ext_dst_mem[4] = data;
        OUT_DST_BASE_ADDR + 32'h140: ext_dst_mem[5] = data;
        OUT_DST_BASE_ADDR + 32'h180: ext_dst_mem[6] = data;
        OUT_DST_BASE_ADDR + 32'h1c0: ext_dst_mem[7] = data;
        default: $fatal(1, "Unexpected external write address in integration TB: 0x%08x", byte_addr);
      endcase
    end
  endtask

  function automatic [AXI_DATA_W-1:0] make_segmented_row(
    input logic [7:0] seg0_val,
    input logic [7:0] seg1_val,
    input logic [7:0] seg2_val,
    input logic [7:0] seg3_val
  );
    integer byte_idx;
    begin
      make_segmented_row = '0;
      for (byte_idx = 0; byte_idx < AXI_STRB_W; byte_idx = byte_idx + 1) begin
        case (byte_idx / 16)
          0: make_segmented_row[byte_idx*8 +: 8] = seg0_val;
          1: make_segmented_row[byte_idx*8 +: 8] = seg1_val;
          2: make_segmented_row[byte_idx*8 +: 8] = seg2_val;
          default: make_segmented_row[byte_idx*8 +: 8] = seg3_val;
        endcase
      end
    end
  endfunction

  function automatic [ACT_VEC_W-1:0] fill_vec(input logic signed [7:0] value);
    integer vec_idx;
    begin
      fill_vec = '0;
      for (vec_idx = 0; vec_idx < ARRAY_N; vec_idx = vec_idx + 1) begin
        fill_vec[vec_idx*8 +: 8] = value[7:0];
      end
    end
  endfunction

  task automatic log_msg(input string msg);
    begin
      $display("[%0t][DATAFLOW_TB] %s", $time, msg);
      $fdisplay(log_fd, "[%0t][DATAFLOW_TB] %s", $time, msg);
    end
  endtask

endmodule

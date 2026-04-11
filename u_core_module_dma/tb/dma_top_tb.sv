`timescale 1ns/1ps

module dma_top_tb;

  import u_core_pkg::*;

  localparam int TEST_ROW_CNT = 4;
  localparam logic [31:0] SRC_BASE_ADDR = 32'h2000_0000;
  localparam logic [31:0] DST_BASE_ADDR = 32'h2000_1000;

  logic                               clk;
  logic                               rst_n;

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

  logic [BUF_SEL_W-1:0]               act_buf_writable;
  logic [BUF_SEL_W-1:0]               wgt_buf_writable;
  logic [BUF_SEL_W-1:0]               out_buf_readable;
  logic                               spm_dma_error;
  logic [DMA_ERROR_CODE_W-1:0]        spm_dma_error_code;

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

  logic [AXI_DATA_W-1:0] ext_src_mem [0:TEST_ROW_CNT-1];
  logic [AXI_DATA_W-1:0] ext_dst_mem [0:TEST_ROW_CNT-1];
  logic [AXI_DATA_W-1:0] act_spm_mem [0:1][0:DMA_SPM_ROW_COUNT-1];
  logic [AXI_DATA_W-1:0] out_spm_mem [0:DMA_SPM_ROW_COUNT-1];

  logic [AXI_ADDR_W-1:0] axi_wr_addr_pending_r;
  logic                  axi_wr_addr_valid_r;

  integer wr_seen_count;
  integer rd_req_seen_count;
  integer idx;
  integer log_fd;
  logic [31:0] status_word;
  logic [31:0] rd_beat_count_word;
  logic [31:0] wr_beat_count_word;

  dma_top dut (
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

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    log_fd = $fopen("/root/Project/u_core_module_dma/tb/dma_top_tb.log", "w");
    if (log_fd == 0) begin
      $fatal(1, "Failed to open DMA TB log file");
    end
    log_msg("DMA TB log opened");

    rst_n = 1'b0;
    dma_axil_awvalid  = 1'b0;
    dma_axil_awaddr   = '0;
    dma_axil_awprot   = '0;
    dma_axil_wvalid   = 1'b0;
    dma_axil_wdata    = '0;
    dma_axil_wstrb    = '0;
    dma_axil_bready   = 1'b0;
    dma_axil_arvalid  = 1'b0;
    dma_axil_araddr   = '0;
    dma_axil_arprot   = '0;
    dma_axil_rready   = 1'b0;

    dma_m_axi_awready = 1'b0;
    dma_m_axi_wready  = 1'b0;
    dma_m_axi_bvalid  = 1'b0;
    dma_m_axi_bresp   = 2'b00;
    dma_m_axi_arready = 1'b0;
    dma_m_axi_rvalid  = 1'b0;
    dma_m_axi_rdata   = '0;
    dma_m_axi_rresp   = 2'b00;
    dma_m_axi_rlast   = 1'b0;

    dma_spm_wr_ready      = 1'b1;
    dma_spm_rd_req_ready  = 1'b1;
    dma_spm_rd_data_valid = 1'b0;
    dma_spm_rd_data       = '0;
    dma_spm_rd_last       = 1'b0;
    act_buf_writable      = 2'b11;
    wgt_buf_writable      = 2'b11;
    out_buf_readable      = 2'b01;
    spm_dma_error         = 1'b0;
    spm_dma_error_code    = '0;
    axi_wr_addr_pending_r = '0;
    axi_wr_addr_valid_r   = 1'b0;
    wr_seen_count         = 0;
    rd_req_seen_count     = 0;

    for (idx = 0; idx < DMA_SPM_ROW_COUNT; idx = idx + 1) begin
      act_spm_mem[0][idx] = '0;
      act_spm_mem[1][idx] = '0;
      out_spm_mem[idx]    = '0;
      if (idx < TEST_ROW_CNT) begin
        ext_src_mem[idx]  = '0;
        ext_dst_mem[idx]  = '0;
      end
    end

    preload_test_data();
    log_msg("Preloaded external source rows and output rows");

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
        log_msg($sformatf(
          "AXI READ req addr=0x%08x len=%0d size=%0d burst=%0d data=0x%0h",
          dma_m_axi_araddr, dma_m_axi_arlen, dma_m_axi_arsize, dma_m_axi_arburst,
          get_ext_mem_word(dma_m_axi_araddr)
        ));
        dma_m_axi_rdata  <= get_ext_mem_word(dma_m_axi_araddr);
        dma_m_axi_rresp  <= 2'b00;
        dma_m_axi_rlast  <= 1'b1;
        dma_m_axi_rvalid <= 1'b1;
      end else if (dma_m_axi_rvalid && dma_m_axi_rready) begin
        dma_m_axi_rvalid <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      dma_m_axi_awready    <= 1'b0;
      dma_m_axi_wready     <= 1'b0;
      dma_m_axi_bvalid     <= 1'b0;
      dma_m_axi_bresp      <= 2'b00;
      axi_wr_addr_pending_r <= '0;
      axi_wr_addr_valid_r  <= 1'b0;
    end else begin
      dma_m_axi_awready <= 1'b1;
      dma_m_axi_wready  <= 1'b1;

      if (dma_m_axi_awvalid && dma_m_axi_awready) begin
        log_msg($sformatf(
          "AXI WRITE addr accepted addr=0x%08x len=%0d size=%0d burst=%0d",
          dma_m_axi_awaddr, dma_m_axi_awlen, dma_m_axi_awsize, dma_m_axi_awburst
        ));
        axi_wr_addr_pending_r <= dma_m_axi_awaddr;
        axi_wr_addr_valid_r   <= 1'b1;
      end

      if (dma_m_axi_wvalid && dma_m_axi_wready) begin
        log_msg($sformatf(
          "AXI WRITE data accepted data=0x%0h strb=0x%0h last=%0b",
          dma_m_axi_wdata, dma_m_axi_wstrb, dma_m_axi_wlast
        ));
        if (dma_m_axi_awvalid && dma_m_axi_awready) begin
          write_ext_mem_word(dma_m_axi_awaddr, dma_m_axi_wdata);
          axi_wr_addr_valid_r            <= 1'b0;
          dma_m_axi_bresp                <= 2'b00;
          dma_m_axi_bvalid               <= 1'b1;
        end else if (axi_wr_addr_valid_r) begin
          write_ext_mem_word(axi_wr_addr_pending_r, dma_m_axi_wdata);
          axi_wr_addr_valid_r                 <= 1'b0;
          dma_m_axi_bresp                     <= 2'b00;
          dma_m_axi_bvalid                    <= 1'b1;
        end
      end else if (dma_m_axi_bvalid && dma_m_axi_bready) begin
        dma_m_axi_bvalid <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      wr_seen_count <= 0;
    end else if (dma_spm_wr_valid && dma_spm_wr_ready) begin
      log_msg($sformatf(
        "DMA->SPM write type=%0d buf=%0d row=%0d data=0x%0h last=%0b",
        dma_spm_wr_type, dma_spm_wr_buf_sel, dma_spm_wr_row_idx, dma_spm_wr_data, dma_spm_wr_last
      ));
      if (dma_spm_wr_type !== 2'b00) begin
        $fatal(1, "Expected ACT write, got type=%0d", dma_spm_wr_type);
      end
      if (dma_spm_wr_buf_sel !== 2'd1) begin
        $fatal(1, "Expected ACT buf_sel=1, got %0d", dma_spm_wr_buf_sel);
      end
      if (dma_spm_wr_row_idx !== wr_seen_count[DMA_SPM_ROW_W-1:0]) begin
        $fatal(1, "Unexpected ACT row_idx: got %0d exp %0d",
               dma_spm_wr_row_idx, wr_seen_count);
      end
      if (dma_spm_wr_data !== ext_src_mem[wr_seen_count]) begin
        $fatal(1, "SPM write data mismatch on row %0d", wr_seen_count);
      end
      if (dma_spm_wr_strb !== {AXI_STRB_W{1'b1}}) begin
        $fatal(1, "Unexpected full-row strb on LOAD_ACT");
      end
      if (dma_spm_wr_last !== (wr_seen_count == (TEST_ROW_CNT-1))) begin
        $fatal(1, "Unexpected wr_last on row %0d", wr_seen_count);
      end
      log_msg($sformatf("CHECK PASS: LOAD_ACT row %0d matched expected source payload", wr_seen_count));
      act_spm_mem[dma_spm_wr_buf_sel][dma_spm_wr_row_idx] <= dma_spm_wr_data;
      wr_seen_count <= wr_seen_count + 1;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      dma_spm_rd_data_valid <= 1'b0;
      dma_spm_rd_data       <= '0;
      dma_spm_rd_last       <= 1'b0;
      rd_req_seen_count     <= 0;
    end else begin
      if (dma_spm_rd_data_valid && dma_spm_rd_data_ready) begin
        dma_spm_rd_data_valid <= 1'b0;
      end

      if (dma_spm_rd_req_valid && dma_spm_rd_req_ready) begin
        log_msg($sformatf(
          "DMA<-SPM read req buf=%0d row=%0d exp_data=0x%0h",
          dma_spm_rd_buf_sel, dma_spm_rd_row_idx, out_spm_mem[dma_spm_rd_row_idx]
        ));
        if (dma_spm_rd_buf_sel !== 2'd0) begin
          $fatal(1, "Expected STORE_OUT buf_sel=0, got %0d", dma_spm_rd_buf_sel);
        end
        if (dma_spm_rd_row_idx !== rd_req_seen_count[DMA_SPM_ROW_W-1:0]) begin
          $fatal(1, "Unexpected out_spm row request: got %0d exp %0d",
                 dma_spm_rd_row_idx, rd_req_seen_count);
        end
        dma_spm_rd_data       <= out_spm_mem[dma_spm_rd_row_idx];
        dma_spm_rd_last       <= (rd_req_seen_count == (TEST_ROW_CNT-1));
        dma_spm_rd_data_valid <= 1'b1;
        log_msg($sformatf("CHECK PASS: STORE_OUT source row %0d prepared for AXI writeback", rd_req_seen_count));
        rd_req_seen_count     <= rd_req_seen_count + 1;
      end
    end
  end

  initial begin
    wait(rst_n === 1'b1);

    // LOAD_ACT into act buffer 1, rows 0..3.
    log_msg("Starting LOAD_ACT descriptor programming");
    axil_write(DMA_CSR_BASE + 32'h00, {14'h0000, 4'd4, 7'd64, 3'd0, 2'd1, 2'd0}); // op=LOAD_ACT, buf_sel=1
    axil_write(DMA_CSR_BASE + 32'h04, SRC_BASE_ADDR);
    axil_write(DMA_CSR_BASE + 32'h08, 32'h0000_0000);
    axil_write(DMA_CSR_BASE + 32'h0c, 32'd1); // ext_stride_units = 64B / 64B
    axil_write(DMA_CSR_BASE + 32'h18, 32'h0000_0001);

    poll_done_or_error(status_word);
    log_msg($sformatf("LOAD_ACT completed with status=0x%08x", status_word));
    if (status_word[2]) begin
      $fatal(1, "LOAD_ACT reported error, status=0x%08x code=0x%0h", status_word, dma_error_code);
    end
    if (wr_seen_count != TEST_ROW_CNT) begin
      $fatal(1, "Expected %0d ACT writes, got %0d", TEST_ROW_CNT, wr_seen_count);
    end
    log_msg("CHECK PASS: LOAD_ACT moved all expected rows into act_spm");

    // STORE_OUT from out buffer 0, rows 0..3.
    log_msg("Starting STORE_OUT descriptor programming");
    axil_write(DMA_CSR_BASE + 32'h00, {14'h0000, 4'd4, 7'd64, 3'd0, 2'd0, 2'd2}); // op=STORE_OUT, buf_sel=0
    axil_write(DMA_CSR_BASE + 32'h04, 32'h0000_0000);
    axil_write(DMA_CSR_BASE + 32'h08, DST_BASE_ADDR);
    axil_write(DMA_CSR_BASE + 32'h0c, 32'd1); // ext_stride_units = 64B / 64B
    axil_write(DMA_CSR_BASE + 32'h18, 32'h0000_0001);

    poll_done_or_error(status_word);
    log_msg($sformatf("STORE_OUT completed with status=0x%08x", status_word));
    if (status_word[2]) begin
      $fatal(1, "STORE_OUT reported error, status=0x%08x code=0x%0h", status_word, dma_error_code);
    end
    if (rd_req_seen_count != TEST_ROW_CNT) begin
      $fatal(1, "Expected %0d out_spm read requests, got %0d", TEST_ROW_CNT, rd_req_seen_count);
    end

    for (idx = 0; idx < TEST_ROW_CNT; idx = idx + 1) begin
      if (ext_dst_mem[idx] !== out_spm_mem[idx]) begin
        $fatal(1, "External memory writeback mismatch on row %0d got=0x%0h exp=0x%0h",
               idx, ext_dst_mem[idx], out_spm_mem[idx]);
      end
      log_msg($sformatf(
        "CHECK PASS: external dst row %0d matched out_spm payload 0x%0h",
        idx, ext_dst_mem[idx]
      ));
    end

    axil_read(DMA_CSR_BASE + 32'h1c, status_word);
    axil_read(DMA_CSR_BASE + 32'h28, rd_beat_count_word);
    axil_read(DMA_CSR_BASE + 32'h2c, wr_beat_count_word);

    if (status_word[2]) begin
      $fatal(1, "Final DMA_STATUS indicates error: 0x%08x", status_word);
    end
    if (rd_beat_count_word != TEST_ROW_CNT) begin
      $fatal(1, "Unexpected DMA_RD_BEAT_COUNT=%0d", rd_beat_count_word);
    end
    if (wr_beat_count_word != TEST_ROW_CNT) begin
      $fatal(1, "Unexpected DMA_WR_BEAT_COUNT=%0d", wr_beat_count_word);
    end

    $display("DMA TB PASS: rd_beats=%0d wr_beats=%0d status=0x%08x",
             rd_beat_count_word, wr_beat_count_word, status_word);
    log_msg($sformatf(
      "DMA TB PASS: rd_beats=%0d wr_beats=%0d status=0x%08x",
      rd_beat_count_word, wr_beat_count_word, status_word
    ));
    #20;
    $fclose(log_fd);
    $finish;
  end

  task automatic preload_test_data();
    begin
      for (idx = 0; idx < TEST_ROW_CNT; idx = idx + 1) begin
        ext_src_mem[idx] = make_mem_word(8'h10 + idx[7:0]);
        ext_dst_mem[idx] = '0;
        out_spm_mem[idx] = make_mem_word(8'h80 + idx[7:0]);
        log_msg($sformatf(
          "INIT row=%0d src=0x%0h out_spm=0x%0h",
          idx, ext_src_mem[idx], out_spm_mem[idx]
        ));
      end
    end
  endtask

  task automatic axil_write(
    input logic [AXIL_ADDR_W-1:0] addr,
    input logic [AXIL_DATA_W-1:0] data
  );
    begin
      log_msg($sformatf("AXI-Lite WRITE addr=0x%08x data=0x%08x", addr, data));
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
      log_msg($sformatf("AXI-Lite WRITE done addr=0x%08x", addr));
    end
  endtask

  task automatic axil_read(
    input  logic [AXIL_ADDR_W-1:0] addr,
    output logic [AXIL_DATA_W-1:0] data
  );
    begin
      log_msg($sformatf("AXI-Lite READ addr=0x%08x", addr));
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
      log_msg($sformatf("AXI-Lite READ data addr=0x%08x data=0x%08x", addr, data));
    end
  endtask

  task automatic poll_done_or_error(output logic [31:0] status);
    integer poll_idx;
    begin
      status = '0;
      for (poll_idx = 0; poll_idx < 256; poll_idx = poll_idx + 1) begin
        axil_read(DMA_CSR_BASE + 32'h1c, status);
        if (status[1] || status[2]) begin
          return;
        end
      end
      $fatal(1, "DMA poll timeout");
    end
  endtask

  function automatic [AXI_DATA_W-1:0] make_mem_word(input logic [7:0] seed);
    integer byte_idx;
    begin
      make_mem_word = '0;
      for (byte_idx = 0; byte_idx < AXI_STRB_W; byte_idx = byte_idx + 1) begin
        make_mem_word[byte_idx*8 +: 8] = seed + byte_idx[7:0];
      end
    end
  endfunction

  function automatic [AXI_DATA_W-1:0] get_ext_mem_word(input logic [AXI_ADDR_W-1:0] byte_addr);
    integer mem_idx;
    begin
      if ((byte_addr >= SRC_BASE_ADDR) &&
          (byte_addr < (SRC_BASE_ADDR + (TEST_ROW_CNT * AXI_BEAT_BYTES)))) begin
        mem_idx = (byte_addr - SRC_BASE_ADDR) / AXI_BEAT_BYTES;
        get_ext_mem_word = ext_src_mem[mem_idx];
      end else if ((byte_addr >= DST_BASE_ADDR) &&
                   (byte_addr < (DST_BASE_ADDR + (TEST_ROW_CNT * AXI_BEAT_BYTES)))) begin
        mem_idx = (byte_addr - DST_BASE_ADDR) / AXI_BEAT_BYTES;
        get_ext_mem_word = ext_dst_mem[mem_idx];
      end else begin
        get_ext_mem_word = '0;
      end
    end
  endfunction

  task automatic write_ext_mem_word(
    input logic [AXI_ADDR_W-1:0]   byte_addr,
    input logic [AXI_DATA_W-1:0]   data
  );
    integer mem_idx;
    begin
      if ((byte_addr >= DST_BASE_ADDR) &&
          (byte_addr < (DST_BASE_ADDR + (TEST_ROW_CNT * AXI_BEAT_BYTES)))) begin
        mem_idx = (byte_addr - DST_BASE_ADDR) / AXI_BEAT_BYTES;
        ext_dst_mem[mem_idx] = data;
        log_msg($sformatf("EXT MEM WRITE dst row=%0d addr=0x%08x data=0x%0h", mem_idx, byte_addr, data));
      end else if ((byte_addr >= SRC_BASE_ADDR) &&
                   (byte_addr < (SRC_BASE_ADDR + (TEST_ROW_CNT * AXI_BEAT_BYTES)))) begin
        mem_idx = (byte_addr - SRC_BASE_ADDR) / AXI_BEAT_BYTES;
        ext_src_mem[mem_idx] = data;
        log_msg($sformatf("EXT MEM WRITE src row=%0d addr=0x%08x data=0x%0h", mem_idx, byte_addr, data));
      end else begin
        $fatal(1, "Unexpected external write address 0x%08x", byte_addr);
      end
    end
  endtask

  task automatic log_msg(input string msg);
    begin
      $display("[%0t][DMA_TB] %s", $time, msg);
      $fdisplay(log_fd, "[%0t][DMA_TB] %s", $time, msg);
    end
  endtask

endmodule

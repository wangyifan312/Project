`timescale 1ns/1ps

module dma_desc_pack_tb;

  import u_core_pkg::*;

  localparam int TEST_LOAD_ROW_CNT = 4;
  localparam int TEST_STORE_ROW_CNT = 3;
  localparam logic [31:0] SRC_BASE_ADDR = 32'h2000_0000;
  localparam logic [31:0] DST_BASE_ADDR = 32'h2000_1000;
  localparam logic [15:0] LOAD_ROW_LEN = 16'd64;
  localparam logic [15:0] STORE_ROW_LEN = 16'd32;
  localparam logic [15:0] LOAD_STRIDE = 16'd128;
  localparam logic [15:0] STORE_STRIDE = 16'd128;
  localparam logic [2:0]  LOAD_SPM_ROW_BASE = 3'd3;
  localparam logic [2:0]  STORE_SPM_ROW_BASE = 3'd2;

  logic                               clk;
  logic                               rst_n;
  integer                             log_fd;
  integer                             idx;
  integer                             load_wr_seen_count;
  integer                             store_rd_req_seen_count;

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

  logic [AXI_DATA_W-1:0] ext_src_mem [0:TEST_LOAD_ROW_CNT-1];
  logic [AXI_DATA_W-1:0] ext_dst_mem [0:TEST_STORE_ROW_CNT-1];
  logic [AXI_DATA_W-1:0] out_spm_mem [0:DMA_SPM_ROW_COUNT-1];
  logic [AXI_ADDR_W-1:0] axi_wr_addr_pending_r;
  logic                  axi_wr_addr_valid_r;

  logic [31:0] cfg0_word;
  logic [31:0] cfg1_word;
  logic [31:0] src_word;
  logic [31:0] dst_word;
  logic [31:0] status_word;

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
    log_fd = $fopen("/root/Project/u_core_module_dma/tb/dma_desc_pack_tb.log", "w");
    if (log_fd == 0) begin
      $fatal(1, "Failed to open DMA desc-pack TB log file");
    end
    log_msg("DMA desc-pack TB log opened");

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
    load_wr_seen_count    = 0;
    store_rd_req_seen_count = 0;

    preload_test_data();

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
        log_msg($sformatf("AXI READ req addr=0x%08x data=0x%0h", dma_m_axi_araddr, read_ext_mem_word(dma_m_axi_araddr)));
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
        log_msg($sformatf("AXI WRITE addr accepted addr=0x%08x", dma_m_axi_awaddr));
      end

      if (dma_m_axi_wvalid && dma_m_axi_wready) begin
        if (dma_m_axi_awvalid && dma_m_axi_awready) begin
          write_ext_mem_word(dma_m_axi_awaddr, dma_m_axi_wdata, dma_m_axi_wstrb);
          axi_wr_addr_valid_r <= 1'b0;
        end else if (axi_wr_addr_valid_r) begin
          write_ext_mem_word(axi_wr_addr_pending_r, dma_m_axi_wdata, dma_m_axi_wstrb);
          axi_wr_addr_valid_r <= 1'b0;
        end
        dma_m_axi_bresp  <= 2'b00;
        dma_m_axi_bvalid <= 1'b1;
        log_msg($sformatf(
          "AXI WRITE data accepted data=0x%0h strb=0x%0h last=%0b",
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
      if (dma_spm_wr_type !== DMA_SPM_TYPE_ACT) begin
        $fatal(1, "Expected ACT write in desc-pack TB");
      end
      if (dma_spm_wr_buf_sel !== 2'd1) begin
        $fatal(1, "Expected buf_sel=1 for LOAD_ACT");
      end
      if (dma_spm_wr_row_idx !== (LOAD_SPM_ROW_BASE + load_wr_seen_count[2:0])) begin
        $fatal(1, "Unexpected local row index from packed descriptor");
      end
      if (dma_spm_wr_data !== ext_src_mem[load_wr_seen_count]) begin
        $fatal(1, "Unexpected LOAD_ACT data at row %0d", load_wr_seen_count);
      end
      if (dma_spm_wr_last !== (load_wr_seen_count == (TEST_LOAD_ROW_CNT-1))) begin
        $fatal(1, "Unexpected LOAD_ACT last flag at row %0d", load_wr_seen_count);
      end
      load_wr_seen_count <= load_wr_seen_count + 1;
      log_msg($sformatf("CHECK PASS: packed LOAD_ACT row %0d executed with correct local row/address expansion", load_wr_seen_count));
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      dma_spm_rd_data_valid <= 1'b0;
      dma_spm_rd_data       <= '0;
      dma_spm_rd_last       <= 1'b0;
    end else begin
      if (dma_spm_rd_data_valid && dma_spm_rd_data_ready) begin
        dma_spm_rd_data_valid <= 1'b0;
      end

      if (dma_spm_rd_req_valid && dma_spm_rd_req_ready) begin
        if (dma_spm_rd_buf_sel !== 2'd0) begin
          $fatal(1, "Expected out_buf0 on STORE_OUT");
        end
        if (dma_spm_rd_row_idx !== (STORE_SPM_ROW_BASE + store_rd_req_seen_count[2:0])) begin
          $fatal(1, "Unexpected STORE_OUT local row index from packed descriptor");
        end
        dma_spm_rd_data       <= out_spm_mem[dma_spm_rd_row_idx];
        dma_spm_rd_last       <= (store_rd_req_seen_count == (TEST_STORE_ROW_CNT-1));
        dma_spm_rd_data_valid <= 1'b1;
        log_msg($sformatf(
          "DMA<-SPM read req row=%0d data=0x%0h last=%0b",
          dma_spm_rd_row_idx, out_spm_mem[dma_spm_rd_row_idx], dma_spm_rd_last
        ));
        store_rd_req_seen_count <= store_rd_req_seen_count + 1;
      end
    end
  end

  initial begin
    wait(rst_n === 1'b1);

    run_load_act_pack_check();
    run_store_out_pack_check();

    $display("DMA DESC PACK TB PASS: compact CSR writes were correctly expanded into descriptor fields and execution behavior");
    log_msg("DMA DESC PACK TB PASS: compact CSR writes were correctly expanded into descriptor fields and execution behavior");
    #20;
    $fclose(log_fd);
    $finish;
  end

  task automatic run_load_act_pack_check();
    begin
      log_msg("Starting compact LOAD_ACT descriptor pack test");

      axil_write(DMA_CSR_BASE + 32'h00, pack_dma_cfg0(DMA_OP_LOAD_ACT, 2'd1, LOAD_SPM_ROW_BASE, LOAD_ROW_LEN, TEST_LOAD_ROW_CNT));
      axil_write(DMA_CSR_BASE + 32'h04, SRC_BASE_ADDR);
      axil_write(DMA_CSR_BASE + 32'h08, 32'h0000_0000);
      axil_write(DMA_CSR_BASE + 32'h0c, (LOAD_STRIDE >> 6));

      axil_read(DMA_CSR_BASE + 32'h00, cfg0_word);
      axil_read(DMA_CSR_BASE + 32'h04, src_word);
      axil_read(DMA_CSR_BASE + 32'h08, dst_word);
      axil_read(DMA_CSR_BASE + 32'h0c, cfg1_word);

      if (cfg0_word !== pack_dma_cfg0(DMA_OP_LOAD_ACT, 2'd1, LOAD_SPM_ROW_BASE, LOAD_ROW_LEN, TEST_LOAD_ROW_CNT)) begin
        $fatal(1, "DMA_DESC_CFG0 readback mismatch for compact LOAD_ACT");
      end
      if (src_word !== SRC_BASE_ADDR) begin
        $fatal(1, "DMA_SRC_ADDR readback mismatch");
      end
      if (dst_word !== 32'h0000_0000) begin
        $fatal(1, "DMA_DST_ADDR readback mismatch");
      end
      if (cfg1_word !== (LOAD_STRIDE >> 6)) begin
        $fatal(1, "DMA_DESC_CFG1 readback mismatch");
      end
      log_msg("CHECK PASS: compact LOAD_ACT CSR words read back correctly");

      if (dut.u_dma_desc_stage.op_type_r !== DMA_OP_LOAD_ACT) begin
        $fatal(1, "Packed op_type did not expand correctly");
      end
      if (dut.u_dma_desc_stage.buf_sel_r !== 2'd1) begin
        $fatal(1, "Packed buf_sel did not expand correctly");
      end
      if (dut.u_dma_desc_stage.spm_row_base_r !== LOAD_SPM_ROW_BASE) begin
        $fatal(1, "Packed spm_row_base did not expand correctly");
      end
      if (dut.u_dma_desc_stage.row_len_r !== LOAD_ROW_LEN) begin
        $fatal(1, "Packed row_len did not expand correctly");
      end
      if (dut.u_dma_desc_stage.row_cnt_r !== TEST_LOAD_ROW_CNT) begin
        $fatal(1, "Packed row_cnt did not expand correctly");
      end
      if (dut.u_dma_desc_stage.ext_stride_units_r !== (LOAD_STRIDE >> 6)) begin
        $fatal(1, "Packed ext_stride_units did not expand correctly");
      end
      if (dut.u_dma_desc_stage.ext_stride_r !== LOAD_STRIDE) begin
        $fatal(1, "Expanded ext_stride bytes mismatch");
      end
      if (dut.u_dma_desc_stage.desc_bus[147:132] !== LOAD_SPM_ROW_BASE) begin
        $fatal(1, "Descriptor bus spm_row_base packing mismatch");
      end
      if (dut.u_dma_desc_stage.desc_bus[131:130] !== 2'd1) begin
        $fatal(1, "Descriptor bus buf_sel packing mismatch");
      end
      if (dut.u_dma_desc_stage.desc_bus[113:98] !== LOAD_STRIDE) begin
        $fatal(1, "Descriptor bus src_stride packing mismatch");
      end
      if (dut.u_dma_desc_stage.desc_bus[97:82] !== TEST_LOAD_ROW_CNT) begin
        $fatal(1, "Descriptor bus row_cnt packing mismatch");
      end
      if (dut.u_dma_desc_stage.desc_bus[81:66] !== LOAD_ROW_LEN) begin
        $fatal(1, "Descriptor bus row_len packing mismatch");
      end
      log_msg("CHECK PASS: DMA internal descriptor expansion matched compact CSR encoding");

      axil_write(DMA_CSR_BASE + 32'h18, 32'h0000_0001);
      poll_done_or_error(status_word);
      if (status_word[2]) begin
        $fatal(1, "LOAD_ACT compact descriptor execution failed");
      end
      if (load_wr_seen_count != TEST_LOAD_ROW_CNT) begin
        $fatal(1, "Expected %0d packed LOAD_ACT writes, got %0d", TEST_LOAD_ROW_CNT, load_wr_seen_count);
      end
      log_msg("CHECK PASS: compact LOAD_ACT descriptor executed correctly");
    end
  endtask

  task automatic run_store_out_pack_check();
    integer store_idx;
    logic [AXI_DATA_W-1:0] expected_dst;
    begin
      log_msg("Starting compact STORE_OUT descriptor pack test");

      axil_write(DMA_CSR_BASE + 32'h00, pack_dma_cfg0(DMA_OP_STORE_OUT, 2'd0, STORE_SPM_ROW_BASE, STORE_ROW_LEN, TEST_STORE_ROW_CNT));
      axil_write(DMA_CSR_BASE + 32'h04, 32'h0000_0000);
      axil_write(DMA_CSR_BASE + 32'h08, DST_BASE_ADDR);
      axil_write(DMA_CSR_BASE + 32'h0c, (STORE_STRIDE >> 6));

      axil_read(DMA_CSR_BASE + 32'h00, cfg0_word);
      axil_read(DMA_CSR_BASE + 32'h08, dst_word);
      axil_read(DMA_CSR_BASE + 32'h0c, cfg1_word);

      if (cfg0_word !== pack_dma_cfg0(DMA_OP_STORE_OUT, 2'd0, STORE_SPM_ROW_BASE, STORE_ROW_LEN, TEST_STORE_ROW_CNT)) begin
        $fatal(1, "DMA_DESC_CFG0 readback mismatch for compact STORE_OUT");
      end
      if (dst_word !== DST_BASE_ADDR) begin
        $fatal(1, "DMA_DST_ADDR readback mismatch for compact STORE_OUT");
      end
      if (cfg1_word !== (STORE_STRIDE >> 6)) begin
        $fatal(1, "DMA_DESC_CFG1 readback mismatch for compact STORE_OUT");
      end
      log_msg("CHECK PASS: compact STORE_OUT CSR words read back correctly");

      if (dut.u_dma_desc_stage.desc_bus[129:114] !== STORE_STRIDE) begin
        $fatal(1, "Descriptor bus dst_stride packing mismatch");
      end
      if (dut.u_dma_desc_stage.desc_bus[147:132] !== STORE_SPM_ROW_BASE) begin
        $fatal(1, "Descriptor bus STORE_OUT spm_row_base mismatch");
      end
      log_msg("CHECK PASS: compact STORE_OUT internal descriptor expansion matched expectation");

      axil_write(DMA_CSR_BASE + 32'h18, 32'h0000_0001);
      poll_done_or_error(status_word);
      if (status_word[2]) begin
        $fatal(1, "STORE_OUT compact descriptor execution failed");
      end
      if (store_rd_req_seen_count != TEST_STORE_ROW_CNT) begin
        $fatal(1, "Expected %0d compact STORE_OUT local reads, got %0d", TEST_STORE_ROW_CNT, store_rd_req_seen_count);
      end

      for (store_idx = 0; store_idx < TEST_STORE_ROW_CNT; store_idx = store_idx + 1) begin
        expected_dst = apply_strb_to_word('0, out_spm_mem[STORE_SPM_ROW_BASE + store_idx], {32'h0000_0000, 32'hffff_ffff});
        if (ext_dst_mem[store_idx] !== expected_dst) begin
          $fatal(1, "STORE_OUT compact destination mismatch on row %0d got=0x%0h exp=0x%0h",
                 store_idx, ext_dst_mem[store_idx], expected_dst);
        end
        log_msg($sformatf("CHECK PASS: compact STORE_OUT row %0d matched expected partial-byte writeback", store_idx));
      end
    end
  endtask

  task automatic preload_test_data();
    begin
      for (idx = 0; idx < TEST_LOAD_ROW_CNT; idx = idx + 1) begin
        ext_src_mem[idx] = make_mem_word(8'h10 + idx[7:0]);
        log_msg($sformatf("INIT ext_src_mem[%0d] = 0x%0h", idx, ext_src_mem[idx]));
      end
      for (idx = 0; idx < TEST_STORE_ROW_CNT; idx = idx + 1) begin
        ext_dst_mem[idx] = '0;
      end
      for (idx = 0; idx < DMA_SPM_ROW_COUNT; idx = idx + 1) begin
        out_spm_mem[idx] = '0;
      end
      out_spm_mem[STORE_SPM_ROW_BASE + 0] = make_mem_word(8'h80);
      out_spm_mem[STORE_SPM_ROW_BASE + 1] = make_mem_word(8'h90);
      out_spm_mem[STORE_SPM_ROW_BASE + 2] = make_mem_word(8'ha0);
      log_msg($sformatf("INIT out_spm_mem[%0d] = 0x%0h", STORE_SPM_ROW_BASE + 0, out_spm_mem[STORE_SPM_ROW_BASE + 0]));
      log_msg($sformatf("INIT out_spm_mem[%0d] = 0x%0h", STORE_SPM_ROW_BASE + 1, out_spm_mem[STORE_SPM_ROW_BASE + 1]));
      log_msg($sformatf("INIT out_spm_mem[%0d] = 0x%0h", STORE_SPM_ROW_BASE + 2, out_spm_mem[STORE_SPM_ROW_BASE + 2]));
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
    end
  endtask

  task automatic axil_read(
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
      log_msg($sformatf("AXI-Lite READ addr=0x%08x data=0x%08x", addr, data));
    end
  endtask

  task automatic poll_done_or_error(output logic [31:0] status);
    integer poll_idx;
    begin
      status = '0;
      for (poll_idx = 0; poll_idx < 512; poll_idx = poll_idx + 1) begin
        axil_read(DMA_CSR_BASE + 32'h1c, status);
        if (status[1] || status[2]) begin
          return;
        end
      end
      $fatal(1, "DMA compact descriptor poll timeout");
    end
  endtask

  function automatic [AXIL_DATA_W-1:0] pack_dma_cfg0(
    input logic [1:0]           op_type,
    input logic [BUF_SEL_W-1:0] buf_sel,
    input logic [2:0]           spm_row_base,
    input logic [15:0]          row_len,
    input integer               row_cnt
  );
    begin
      pack_dma_cfg0 = {14'h0000, row_cnt[3:0], row_len[6:0], spm_row_base, buf_sel, op_type};
    end
  endfunction

  function automatic [AXI_DATA_W-1:0] make_mem_word(input logic [7:0] seed);
    integer byte_idx;
    begin
      make_mem_word = '0;
      for (byte_idx = 0; byte_idx < AXI_STRB_W; byte_idx = byte_idx + 1) begin
        make_mem_word[byte_idx*8 +: 8] = seed + byte_idx[7:0];
      end
    end
  endfunction

  function automatic [AXI_DATA_W-1:0] read_ext_mem_word(input logic [AXI_ADDR_W-1:0] byte_addr);
    begin
      case (byte_addr)
        SRC_BASE_ADDR + 32'h000: read_ext_mem_word = ext_src_mem[0];
        SRC_BASE_ADDR + 32'h080: read_ext_mem_word = ext_src_mem[1];
        SRC_BASE_ADDR + 32'h100: read_ext_mem_word = ext_src_mem[2];
        SRC_BASE_ADDR + 32'h180: read_ext_mem_word = ext_src_mem[3];
        DST_BASE_ADDR + 32'h000: read_ext_mem_word = ext_dst_mem[0];
        DST_BASE_ADDR + 32'h080: read_ext_mem_word = ext_dst_mem[1];
        DST_BASE_ADDR + 32'h100: read_ext_mem_word = ext_dst_mem[2];
        default: read_ext_mem_word = '0;
      endcase
    end
  endfunction

  task automatic write_ext_mem_word(
    input logic [AXI_ADDR_W-1:0]   byte_addr,
    input logic [AXI_DATA_W-1:0]   data,
    input logic [AXI_STRB_W-1:0]   strb
  );
    begin
      case (byte_addr)
        DST_BASE_ADDR + 32'h000: ext_dst_mem[0] = apply_strb_to_word(ext_dst_mem[0], data, strb);
        DST_BASE_ADDR + 32'h080: ext_dst_mem[1] = apply_strb_to_word(ext_dst_mem[1], data, strb);
        DST_BASE_ADDR + 32'h100: ext_dst_mem[2] = apply_strb_to_word(ext_dst_mem[2], data, strb);
        default: $fatal(1, "Unexpected writeback address in compact descriptor TB: 0x%08x", byte_addr);
      endcase
      log_msg($sformatf("EXT MEM WRITE addr=0x%08x data=0x%0h strb=0x%0h", byte_addr, data, strb));
    end
  endtask

  function automatic [AXI_DATA_W-1:0] apply_strb_to_word(
    input logic [AXI_DATA_W-1:0] curr,
    input logic [AXI_DATA_W-1:0] data,
    input logic [AXI_STRB_W-1:0] strb
  );
    integer byte_idx;
    begin
      apply_strb_to_word = curr;
      for (byte_idx = 0; byte_idx < AXI_STRB_W; byte_idx = byte_idx + 1) begin
        if (strb[byte_idx]) begin
          apply_strb_to_word[byte_idx*8 +: 8] = data[byte_idx*8 +: 8];
        end
      end
    end
  endfunction

  task automatic log_msg(input string msg);
    begin
      $display("[%0t][DMA_PACK_TB] %s", $time, msg);
      $fdisplay(log_fd, "[%0t][DMA_PACK_TB] %s", $time, msg);
    end
  endtask

endmodule

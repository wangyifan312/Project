`timescale 1ns/1ps

module spm_subsys_tb;

  import u_core_pkg::*;

  logic                                clk;
  logic                                rst_n;

  logic                                dma_spm_wr_valid;
  logic                                dma_spm_wr_ready;
  logic [1:0]                          dma_spm_wr_type;
  logic [BUF_SEL_W-1:0]                dma_spm_wr_buf_sel;
  logic [DMA_SPM_ROW_W-1:0]            dma_spm_wr_row_idx;
  logic [AXI_DATA_W-1:0]               dma_spm_wr_data;
  logic [AXI_STRB_W-1:0]               dma_spm_wr_strb;
  logic                                dma_spm_wr_last;

  logic                                dma_spm_rd_req_valid;
  logic                                dma_spm_rd_req_ready;
  logic [BUF_SEL_W-1:0]                dma_spm_rd_buf_sel;
  logic [DMA_SPM_ROW_W-1:0]            dma_spm_rd_row_idx;
  logic                                dma_spm_rd_data_valid;
  logic                                dma_spm_rd_data_ready;
  logic [AXI_DATA_W-1:0]               dma_spm_rd_data;
  logic                                dma_spm_rd_last;

  logic                                spm_npu_vec_valid;
  logic                                spm_npu_vec_ready;
  logic [BUF_SEL_W-1:0]                spm_npu_act_buf_sel;
  logic [BUF_SEL_W-1:0]                spm_npu_wgt_buf_sel;
  logic [NPU_K_IDX_W-1:0]              spm_npu_k_idx;
  logic [ACT_VEC_W-1:0]                spm_npu_act_vec;
  logic [WGT_VEC_W-1:0]                spm_npu_wgt_vec;

  logic                                npu_spm_out_valid;
  logic                                npu_spm_out_ready;
  logic [BUF_SEL_W-1:0]                npu_spm_out_buf_sel;
  logic [NPU_OUT_ROW_W-1:0]            npu_spm_out_row_idx;
  logic [ARRAY_N-1:0]                  npu_spm_out_col_mask;
  logic [OUT_VEC_W-1:0]                npu_spm_out_data;
  logic                                npu_spm_out_last;

  logic [BUF_SEL_W-1:0]                act_buf_writable;
  logic [BUF_SEL_W-1:0]                wgt_buf_writable;
  logic [BUF_SEL_W-1:0]                out_buf_readable;
  logic                                spm_dma_error;
  logic [DMA_ERROR_CODE_W-1:0]         spm_dma_error_code;

  logic [BUF_SEL_W-1:0]                act_buf_ready;
  logic [BUF_SEL_W-1:0]                wgt_buf_ready;
  logic [BUF_SEL_W-1:0]                out_buf_free;
  logic                                spm_npu_error;
  logic [NPU_ERROR_CODE_W-1:0]         spm_npu_error_code;

  integer                              row_idx;
  integer                              log_fd;
  logic [ACT_VEC_W-1:0]                exp_act_vec;
  logic [WGT_VEC_W-1:0]                exp_wgt_vec;
  logic [AXI_DATA_W-1:0]               exp_packed_row;

  spm_subsys dut (
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

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    log_fd = $fopen("/root/Project/u_core_module_spm/tb/spm_subsys_tb.log", "w");
    if (log_fd == 0) begin
      $fatal(1, "Failed to open SPM TB log file");
    end
    log_msg("SPM TB log opened");

    rst_n               = 1'b0;
    dma_spm_wr_valid    = 1'b0;
    dma_spm_wr_type     = '0;
    dma_spm_wr_buf_sel  = '0;
    dma_spm_wr_row_idx  = '0;
    dma_spm_wr_data     = '0;
    dma_spm_wr_strb     = '0;
    dma_spm_wr_last     = 1'b0;
    dma_spm_rd_req_valid = 1'b0;
    dma_spm_rd_buf_sel  = '0;
    dma_spm_rd_row_idx  = '0;
    dma_spm_rd_data_ready = 1'b0;
    spm_npu_vec_ready   = 1'b0;
    spm_npu_act_buf_sel = '0;
    spm_npu_wgt_buf_sel = '0;
    spm_npu_k_idx       = '0;
    npu_spm_out_valid   = 1'b0;
    npu_spm_out_buf_sel = '0;
    npu_spm_out_row_idx = '0;
    npu_spm_out_col_mask = '0;
    npu_spm_out_data    = '0;
    npu_spm_out_last    = 1'b0;

    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    log_msg("Released reset");
  end

  initial begin
    wait(rst_n === 1'b1);

    if (act_buf_ready != 2'b00 || wgt_buf_ready != 2'b00 || out_buf_readable != 2'b00) begin
      $fatal(1, "Unexpected reset buffer status");
    end
    if (out_buf_free != 2'b01) begin
      $fatal(1, "Unexpected reset out_buf_free=0x%0h", out_buf_free);
    end
    log_msg("CHECK PASS: reset buffer status matched expectation");

    // DMA writes activation tile into act buffer 1.
    log_msg("Starting DMA -> act_spm write sequence");
    dma_write_row(2'b00, 2'd1, 3'd0, make_dma_row(8'h10), 1'b0);
    dma_write_row(2'b00, 2'd1, 3'd1, make_dma_row(8'h20), 1'b1);
    @(posedge clk);
    if (act_buf_ready != 2'b10) begin
      $fatal(1, "act_buf_ready mismatch after DMA write: 0x%0h", act_buf_ready);
    end
    log_msg($sformatf("CHECK PASS: act_buf_ready=0x%0h after DMA writes", act_buf_ready));

    // DMA writes weight tile into wgt buffer 0.
    log_msg("Starting DMA -> wgt_spm write sequence");
    dma_write_row(2'b01, 2'd0, 3'd0, make_dma_row(8'h30), 1'b0);
    dma_write_row(2'b01, 2'd0, 3'd1, make_dma_row(8'h40), 1'b1);
    @(posedge clk);
    if (wgt_buf_ready != 2'b01) begin
      $fatal(1, "wgt_buf_ready mismatch after DMA write: 0x%0h", wgt_buf_ready);
    end
    log_msg($sformatf("CHECK PASS: wgt_buf_ready=0x%0h after DMA writes", wgt_buf_ready));

    // NPU reads one activation / weight vector pair from slot 0 of row 0.
    spm_npu_act_buf_sel = 2'd1;
    spm_npu_wgt_buf_sel = 2'd0;
    spm_npu_k_idx       = 6'd0;
    #1;
    if (spm_npu_vec_valid !== 1'b1) begin
      $fatal(1, "Expected spm_npu_vec_valid to be high");
    end
    exp_act_vec = make_vec(8'h10);
    exp_wgt_vec = make_vec(8'h30);
    log_msg($sformatf(
      "NPU read request act_buf=%0d wgt_buf=%0d k_idx=%0d",
      spm_npu_act_buf_sel, spm_npu_wgt_buf_sel, spm_npu_k_idx
    ));
    log_msg($sformatf("Observed act_vec=0x%0h exp_act_vec=0x%0h", spm_npu_act_vec, exp_act_vec));
    log_msg($sformatf("Observed wgt_vec=0x%0h exp_wgt_vec=0x%0h", spm_npu_wgt_vec, exp_wgt_vec));
    if (spm_npu_act_vec !== exp_act_vec) begin
      $fatal(1, "Activation vector mismatch");
    end
    if (spm_npu_wgt_vec !== exp_wgt_vec) begin
      $fatal(1, "Weight vector mismatch");
    end
    log_msg("CHECK PASS: NPU saw expected act/wgt vectors from SPM");

    // Accept the vector once to make sure the ready path itself is legal.
    @(posedge clk);
    spm_npu_vec_ready <= 1'b1;
    @(posedge clk);
    spm_npu_vec_ready <= 1'b0;
    if (spm_npu_error !== 1'b0) begin
      $fatal(1, "Unexpected spm_npu_error after legal vector read");
    end
    log_msg("CHECK PASS: legal vector handshake completed without SPM NPU-side error");

    // NPU fills the output tile and marks the last row.
    log_msg("Starting NPU -> out_spm write sequence");
    for (row_idx = 0; row_idx < 16; row_idx = row_idx + 1) begin
      npu_write_out_row(row_idx[3:0], make_out_row(8'h80 + row_idx[7:0]), (row_idx == 15));
    end
    @(posedge clk);
    if (out_buf_readable != 2'b01) begin
      $fatal(1, "out_buf_readable mismatch after NPU writes: 0x%0h", out_buf_readable);
    end
    if (out_buf_free != 2'b00) begin
      $fatal(1, "out_buf_free mismatch after NPU writes: 0x%0h", out_buf_free);
    end
    log_msg($sformatf(
      "CHECK PASS: out_buf_readable=0x%0h out_buf_free=0x%0h after NPU writes",
      out_buf_readable, out_buf_free
    ));

    // DMA reads all 8 packed rows back from out_spm.
    dma_spm_rd_data_ready <= 1'b1;
    log_msg("Starting DMA <- out_spm packed readback");
    for (row_idx = 0; row_idx < 8; row_idx = row_idx + 1) begin
      dma_read_out_row(row_idx[2:0], exp_packed_row);
      log_msg($sformatf(
        "Observed packed row=%0d data=0x%0h exp=0x%0h last=%0b",
        row_idx, dma_spm_rd_data, exp_packed_row, dma_spm_rd_last
      ));
      if (dma_spm_rd_data !== exp_packed_row) begin
        $fatal(1, "Packed out_spm row mismatch at packed row %0d", row_idx);
      end
      if (dma_spm_rd_last !== (row_idx == 7)) begin
        $fatal(1, "Unexpected dma_spm_rd_last at packed row %0d", row_idx);
      end
      log_msg($sformatf("CHECK PASS: packed out_spm row %0d matched expectation", row_idx));
    end
    dma_spm_rd_data_ready <= 1'b0;

    // After the last DMA read handshake, the single output buffer becomes free again.
    @(posedge clk);
    if (out_buf_readable != 2'b00) begin
      $fatal(1, "out_buf_readable should clear after final DMA read");
    end
    if (out_buf_free != 2'b01) begin
      $fatal(1, "out_buf_free should return after final DMA read");
    end
    if (spm_dma_error !== 1'b0 || spm_npu_error !== 1'b0) begin
      $fatal(1, "Unexpected SPM error: dma=%0b npu=%0b", spm_dma_error, spm_npu_error);
    end

    $display("SPM TB PASS: act/wgt write, vector read, out write, and DMA readback all passed");
    log_msg("SPM TB PASS: act/wgt write, vector read, out write, and DMA readback all passed");
    #20;
    $fclose(log_fd);
    $finish;
  end

  task automatic dma_write_row(
    input logic [1:0]                 wr_type,
    input logic [BUF_SEL_W-1:0]       buf_sel,
    input logic [DMA_SPM_ROW_W-1:0]   row_sel,
    input logic [AXI_DATA_W-1:0]      row_data,
    input logic                       row_last
  );
    begin
      log_msg($sformatf(
        "DMA write req type=%0d buf=%0d row=%0d data=0x%0h last=%0b",
        wr_type, buf_sel, row_sel, row_data, row_last
      ));
      @(posedge clk);
      dma_spm_wr_valid   <= 1'b1;
      dma_spm_wr_type    <= wr_type;
      dma_spm_wr_buf_sel <= buf_sel;
      dma_spm_wr_row_idx <= row_sel;
      dma_spm_wr_data    <= row_data;
      dma_spm_wr_strb    <= {AXI_STRB_W{1'b1}};
      dma_spm_wr_last    <= row_last;
      @(posedge clk);
      dma_spm_wr_valid   <= 1'b0;
      dma_spm_wr_last    <= 1'b0;
      log_msg($sformatf("DMA write accepted for buf=%0d row=%0d", buf_sel, row_sel));
    end
  endtask

  task automatic npu_write_out_row(
    input logic [NPU_OUT_ROW_W-1:0] row_sel,
    input logic [OUT_VEC_W-1:0]     row_data,
    input logic                     row_last
  );
    begin
      log_msg($sformatf(
        "NPU write req out_buf=0 row=%0d mask=0x%0h data=0x%0h last=%0b",
        row_sel, {ARRAY_N{1'b1}}, row_data, row_last
      ));
      @(posedge clk);
      npu_spm_out_valid    <= 1'b1;
      npu_spm_out_buf_sel  <= 2'd0;
      npu_spm_out_row_idx  <= row_sel;
      npu_spm_out_col_mask <= {ARRAY_N{1'b1}};
      npu_spm_out_data     <= row_data;
      npu_spm_out_last     <= row_last;
      @(posedge clk);
      npu_spm_out_valid    <= 1'b0;
      npu_spm_out_last     <= 1'b0;
      log_msg($sformatf("NPU write accepted for output row=%0d", row_sel));
    end
  endtask

  task automatic dma_read_out_row(
    input  logic [DMA_SPM_ROW_W-1:0] row_sel,
    output logic [AXI_DATA_W-1:0]    exp_data
  );
    begin
      exp_data = {make_out_row(8'h80 + ((row_sel << 1) + 1)),
                  make_out_row(8'h80 + (row_sel << 1))};
      log_msg($sformatf("DMA read req out_buf=0 packed_row=%0d", row_sel));
      @(posedge clk);
      dma_spm_rd_req_valid <= 1'b1;
      dma_spm_rd_buf_sel   <= 2'd0;
      dma_spm_rd_row_idx   <= row_sel;
      @(posedge clk);
      dma_spm_rd_req_valid <= 1'b0;
      wait(dma_spm_rd_data_valid === 1'b1);
      @(posedge clk);
      log_msg($sformatf("DMA read data valid for packed_row=%0d", row_sel));
    end
  endtask

  function automatic [AXI_DATA_W-1:0] make_dma_row(input logic [7:0] base);
    integer byte_idx;
    begin
      make_dma_row = '0;
      for (byte_idx = 0; byte_idx < AXI_STRB_W; byte_idx = byte_idx + 1) begin
        make_dma_row[byte_idx*8 +: 8] = base + byte_idx[7:0];
      end
    end
  endfunction

  function automatic [ACT_VEC_W-1:0] make_vec(input logic [7:0] base);
    integer byte_idx;
    begin
      make_vec = '0;
      for (byte_idx = 0; byte_idx < (ACT_VEC_W/8); byte_idx = byte_idx + 1) begin
        make_vec[byte_idx*8 +: 8] = base + byte_idx[7:0];
      end
    end
  endfunction

  function automatic [OUT_VEC_W-1:0] make_out_row(input logic [7:0] base);
    integer lane_idx;
    begin
      make_out_row = '0;
      for (lane_idx = 0; lane_idx < ARRAY_N; lane_idx = lane_idx + 1) begin
        make_out_row[lane_idx*OUT_ELEM_W +: OUT_ELEM_W] = {8'h00, (base + lane_idx[7:0])};
      end
    end
  endfunction

  task automatic log_msg(input string msg);
    begin
      $display("[%0t][SPM_TB] %s", $time, msg);
      $fdisplay(log_fd, "[%0t][SPM_TB] %s", $time, msg);
    end
  endtask

endmodule

`timescale 1ns/1ps

module npu_top_tb;

  import u_core_pkg::*;

  localparam logic [OUT_VEC_W-1:0] EXPECTED_ROW_DATA = {
    16'h000e, 16'h000e, 16'h000e, 16'h000e,
    16'h000e, 16'h000e, 16'h000e, 16'h000e,
    16'h000e, 16'h000e, 16'h000e, 16'h000e,
    16'h000e, 16'h000e, 16'h000e, 16'h000e
  };

  logic clk;
  logic rst_n;

  logic                                npu_axil_awvalid;
  logic                                npu_axil_awready;
  logic [AXIL_ADDR_W-1:0]              npu_axil_awaddr;
  logic [2:0]                          npu_axil_awprot;
  logic                                npu_axil_wvalid;
  logic                                npu_axil_wready;
  logic [AXIL_DATA_W-1:0]              npu_axil_wdata;
  logic [(AXIL_DATA_W/8)-1:0]          npu_axil_wstrb;
  logic                                npu_axil_bvalid;
  logic                                npu_axil_bready;
  logic [1:0]                          npu_axil_bresp;
  logic                                npu_axil_arvalid;
  logic                                npu_axil_arready;
  logic [AXIL_ADDR_W-1:0]              npu_axil_araddr;
  logic [2:0]                          npu_axil_arprot;
  logic                                npu_axil_rvalid;
  logic                                npu_axil_rready;
  logic [AXIL_DATA_W-1:0]              npu_axil_rdata;
  logic [1:0]                          npu_axil_rresp;

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

  logic [BUF_SEL_W-1:0]                act_buf_ready;
  logic [BUF_SEL_W-1:0]                wgt_buf_ready;
  logic [BUF_SEL_W-1:0]                out_buf_free;
  logic                                spm_npu_error;
  logic [NPU_ERROR_CODE_W-1:0]         spm_npu_error_code;

  logic                                npu_armed;
  logic                                npu_busy;
  logic                                npu_done;
  logic                                npu_error;
  logic [31:0]                         npu_stall_cycles;
  logic [NPU_ERROR_CODE_W-1:0]         npu_error_code;

  integer out_write_count;
  integer log_fd;
  integer row_idx;
  logic [31:0] status_word;
  logic [31:0] busy_cycles_word;

  npu_top dut (
    .clk               (clk),
    .rst_n             (rst_n),
    .npu_axil_awvalid  (npu_axil_awvalid),
    .npu_axil_awready  (npu_axil_awready),
    .npu_axil_awaddr   (npu_axil_awaddr),
    .npu_axil_awprot   (npu_axil_awprot),
    .npu_axil_wvalid   (npu_axil_wvalid),
    .npu_axil_wready   (npu_axil_wready),
    .npu_axil_wdata    (npu_axil_wdata),
    .npu_axil_wstrb    (npu_axil_wstrb),
    .npu_axil_bvalid   (npu_axil_bvalid),
    .npu_axil_bready   (npu_axil_bready),
    .npu_axil_bresp    (npu_axil_bresp),
    .npu_axil_arvalid  (npu_axil_arvalid),
    .npu_axil_arready  (npu_axil_arready),
    .npu_axil_araddr   (npu_axil_araddr),
    .npu_axil_arprot   (npu_axil_arprot),
    .npu_axil_rvalid   (npu_axil_rvalid),
    .npu_axil_rready   (npu_axil_rready),
    .npu_axil_rdata    (npu_axil_rdata),
    .npu_axil_rresp    (npu_axil_rresp),
    .spm_npu_vec_valid (spm_npu_vec_valid),
    .spm_npu_vec_ready (spm_npu_vec_ready),
    .spm_npu_act_buf_sel(spm_npu_act_buf_sel),
    .spm_npu_wgt_buf_sel(spm_npu_wgt_buf_sel),
    .spm_npu_k_idx     (spm_npu_k_idx),
    .spm_npu_act_vec   (spm_npu_act_vec),
    .spm_npu_wgt_vec   (spm_npu_wgt_vec),
    .npu_spm_out_valid (npu_spm_out_valid),
    .npu_spm_out_ready (npu_spm_out_ready),
    .npu_spm_out_buf_sel(npu_spm_out_buf_sel),
    .npu_spm_out_row_idx(npu_spm_out_row_idx),
    .npu_spm_out_col_mask(npu_spm_out_col_mask),
    .npu_spm_out_data  (npu_spm_out_data),
    .npu_spm_out_last  (npu_spm_out_last),
    .act_buf_ready     (act_buf_ready),
    .wgt_buf_ready     (wgt_buf_ready),
    .out_buf_free      (out_buf_free),
    .spm_npu_error     (spm_npu_error),
    .spm_npu_error_code(spm_npu_error_code),
    .npu_armed         (npu_armed),
    .npu_busy          (npu_busy),
    .npu_done          (npu_done),
    .npu_error         (npu_error),
    .npu_stall_cycles  (npu_stall_cycles),
    .npu_error_code    (npu_error_code)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    log_fd = $fopen("/root/Project/u_core_module_npu/tb/npu_top_tb.log", "w");
    if (log_fd == 0) begin
      $fatal(1, "Failed to open NPU TB log file");
    end
    log_msg("NPU TB log opened");

    rst_n = 1'b0;
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

    spm_npu_vec_valid    = 1'b1;
    npu_spm_out_ready    = 1'b1;
    act_buf_ready        = 2'b11;
    wgt_buf_ready        = 2'b11;
    out_buf_free         = 2'b01;
    spm_npu_error        = 1'b0;
    spm_npu_error_code   = '0;
    out_write_count      = 0;

    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    log_msg("Released reset");
  end

  always @* begin
    case (spm_npu_k_idx)
      6'd0: begin
        spm_npu_act_vec = fill_act_vec(8'sd1);
        spm_npu_wgt_vec = fill_wgt_vec(8'sd2);
      end
      6'd1: begin
        spm_npu_act_vec = fill_act_vec(8'sd3);
        spm_npu_wgt_vec = fill_wgt_vec(8'sd4);
      end
      default: begin
        spm_npu_act_vec = '0;
        spm_npu_wgt_vec = '0;
      end
    endcase
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      out_write_count <= 0;
    end else if (npu_spm_out_valid && npu_spm_out_ready) begin
      log_msg($sformatf(
        "NPU->SPM row write buf=%0d row=%0d mask=0x%0h data=0x%0h last=%0b",
        npu_spm_out_buf_sel, npu_spm_out_row_idx, npu_spm_out_col_mask,
        npu_spm_out_data, npu_spm_out_last
      ));
      if (npu_spm_out_buf_sel !== 2'd0) begin
        $fatal(1, "Unexpected out buffer select: %0d", npu_spm_out_buf_sel);
      end
      if (npu_spm_out_row_idx !== out_write_count[NPU_OUT_ROW_W-1:0]) begin
        $fatal(1, "Unexpected output row idx: got %0d exp %0d",
               npu_spm_out_row_idx, out_write_count);
      end
      if (npu_spm_out_col_mask !== {ARRAY_N{1'b1}}) begin
        $fatal(1, "Unexpected output col mask: 0x%0h", npu_spm_out_col_mask);
      end
      if (npu_spm_out_data !== EXPECTED_ROW_DATA) begin
        $fatal(1, "Unexpected output row data: got 0x%0h exp 0x%0h",
               npu_spm_out_data, EXPECTED_ROW_DATA);
      end
      if (npu_spm_out_last !== (out_write_count == (ARRAY_M-1))) begin
        $fatal(1, "Unexpected last flag on output row %0d", out_write_count);
      end
      log_msg($sformatf("CHECK PASS: output row %0d matched expected quantized result", out_write_count));
      out_write_count <= out_write_count + 1;
    end
  end

  always @(posedge clk) begin
    if (rst_n && spm_npu_vec_valid && spm_npu_vec_ready) begin
      log_msg($sformatf(
        "SPM->NPU vec handshake act_buf=%0d wgt_buf=%0d k_idx=%0d act_vec=0x%0h wgt_vec=0x%0h",
        spm_npu_act_buf_sel, spm_npu_wgt_buf_sel, spm_npu_k_idx, spm_npu_act_vec, spm_npu_wgt_vec
      ));
    end
  end

  initial begin
    wait(rst_n === 1'b1);

    log_msg("Programming NPU registers for ktile=2 smoke case");
    axil_write(NPU_CSR_BASE + 32'h0, 32'h0000_0000);
    axil_write(NPU_CSR_BASE + 32'h4, 32'h0000_0000);
    axil_write(NPU_CSR_BASE + 32'h8, 32'h0000_0002);
    axil_write(NPU_CSR_BASE + 32'hc, 32'h0000_0000);
    axil_write(NPU_CSR_BASE + 32'h10, 32'h0000_0001);

    wait(npu_done === 1'b1);
    log_msg("Observed npu_done");

    if (out_write_count != ARRAY_M) begin
      $fatal(1, "Expected %0d output rows, got %0d", ARRAY_M, out_write_count);
    end
    if (npu_error !== 1'b0) begin
      $fatal(1, "Unexpected npu_error asserted with code 0x%0h", npu_error_code);
    end

    axil_read(NPU_CSR_BASE + 32'h14, status_word);
    if (status_word[3:0] !== 4'b0100) begin
      $fatal(1, "Unexpected NPU_STATUS=0x%08x", status_word);
    end
    log_msg($sformatf("CHECK PASS: NPU_STATUS=0x%08x", status_word));

    axil_read(NPU_CSR_BASE + 32'h1c, busy_cycles_word);
    if (busy_cycles_word == 32'h0000_0000) begin
      $fatal(1, "Busy cycle counter should be non-zero");
    end
    log_msg($sformatf("CHECK PASS: busy_cycles=%0d", busy_cycles_word));

    $display("NPU TB PASS: wrote %0d rows, status=0x%08x, busy_cycles=%0d",
             out_write_count, status_word, busy_cycles_word);
    log_msg($sformatf(
      "NPU TB PASS: wrote %0d rows, status=0x%08x, busy_cycles=%0d",
      out_write_count, status_word, busy_cycles_word
    ));
    #20;
    $fclose(log_fd);
    $finish;
  end

  task automatic axil_write(
    input logic [AXIL_ADDR_W-1:0] addr,
    input logic [AXIL_DATA_W-1:0] data
  );
    begin
      log_msg($sformatf("AXI-Lite WRITE addr=0x%08x data=0x%08x", addr, data));
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
      npu_axil_arvalid <= 1'b1;
      npu_axil_araddr  <= addr;
      @(posedge clk);
      npu_axil_arvalid <= 1'b0;
      npu_axil_rready  <= 1'b1;
      wait(npu_axil_rvalid === 1'b1);
      data = npu_axil_rdata;
      @(posedge clk);
      npu_axil_rready  <= 1'b0;
      log_msg($sformatf("AXI-Lite READ data addr=0x%08x data=0x%08x", addr, data));
    end
  endtask

  function automatic [ACT_VEC_W-1:0] fill_act_vec(input logic signed [7:0] value);
    integer idx;
    begin
      fill_act_vec = '0;
      for (idx = 0; idx < ARRAY_M; idx = idx + 1) begin
        fill_act_vec[idx*ACT_ELEM_W +: ACT_ELEM_W] = value[ACT_ELEM_W-1:0];
      end
    end
  endfunction

  function automatic [WGT_VEC_W-1:0] fill_wgt_vec(input logic signed [7:0] value);
    integer idx;
    begin
      fill_wgt_vec = '0;
      for (idx = 0; idx < ARRAY_N; idx = idx + 1) begin
        fill_wgt_vec[idx*WGT_ELEM_W +: WGT_ELEM_W] = value[WGT_ELEM_W-1:0];
      end
    end
  endfunction

  task automatic log_msg(input string msg);
    begin
      $display("[%0t][NPU_TB] %s", $time, msg);
      $fdisplay(log_fd, "[%0t][NPU_TB] %s", $time, msg);
    end
  endtask

endmodule

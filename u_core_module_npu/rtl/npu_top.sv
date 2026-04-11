module npu_top (
  input  logic                                clk,
  input  logic                                rst_n,

  input  logic                                npu_axil_awvalid,
  output logic                                npu_axil_awready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  npu_axil_awaddr,
  input  logic [2:0]                          npu_axil_awprot,
  input  logic                                npu_axil_wvalid,
  output logic                                npu_axil_wready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  npu_axil_wdata,
  input  logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] npu_axil_wstrb,
  output logic                                npu_axil_bvalid,
  input  logic                                npu_axil_bready,
  output logic [1:0]                          npu_axil_bresp,
  input  logic                                npu_axil_arvalid,
  output logic                                npu_axil_arready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  npu_axil_araddr,
  input  logic [2:0]                          npu_axil_arprot,
  output logic                                npu_axil_rvalid,
  input  logic                                npu_axil_rready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  npu_axil_rdata,
  output logic [1:0]                          npu_axil_rresp,

  input  logic                                spm_npu_vec_valid,
  output logic                                spm_npu_vec_ready,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    spm_npu_act_buf_sel,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    spm_npu_wgt_buf_sel,
  output logic [u_core_pkg::NPU_K_IDX_W-1:0]  spm_npu_k_idx,
  input  logic [u_core_pkg::ACT_VEC_W-1:0]    spm_npu_act_vec,
  input  logic [u_core_pkg::WGT_VEC_W-1:0]    spm_npu_wgt_vec,

  output logic                                npu_spm_out_valid,
  input  logic                                npu_spm_out_ready,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    npu_spm_out_buf_sel,
  output logic [u_core_pkg::NPU_OUT_ROW_W-1:0] npu_spm_out_row_idx,
  output logic [u_core_pkg::ARRAY_N-1:0]      npu_spm_out_col_mask,
  output logic [u_core_pkg::OUT_VEC_W-1:0]    npu_spm_out_data,
  output logic                                npu_spm_out_last,

  input  logic [u_core_pkg::BUF_SEL_W-1:0]    act_buf_ready,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    wgt_buf_ready,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    out_buf_free,
  input  logic                                spm_npu_error,
  input  logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] spm_npu_error_code,

  output logic                                npu_armed,
  output logic                                npu_busy,
  output logic                                npu_done,
  output logic                                npu_error,
  output logic [31:0]                         npu_stall_cycles,
  output logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] npu_error_code
);

  import u_core_pkg::*;

  logic [3:0]                       npu_mode;
  logic [7:0]                       ktile_cfg;
  logic [BUF_SEL_W-1:0]             act_buf_sel_cfg;
  logic [BUF_SEL_W-1:0]             wgt_buf_sel_cfg;
  logic [BUF_SEL_W-1:0]             out_buf_sel_cfg;
  logic [7:0]                       quant_shift;
  logic [15:0]                      quant_zero_point;
  logic                             relu_en;
  logic                             start_pulse;
  logic [ACT_VEC_W-1:0]             act_vec_hold_r;
  logic [WGT_VEC_W-1:0]             wgt_vec_hold_r;

  logic                             clear_psum;
  logic                             accum_valid;
  logic [NPU_OUT_ROW_W-1:0]         quant_row_idx;
  logic [OUT_VEC_W-1:0]             quant_row_data;
  logic [ARRAY_N-1:0]               quant_row_mask;

  logic                             ctrl_armed_level;
  logic                             ctrl_busy_level;
  logic                             ctrl_done_pulse;
  logic                             ctrl_error_pulse;
  logic [NPU_ERROR_CODE_W-1:0]      ctrl_error_code;
  logic                             ctrl_stall_cycle_pulse;
  logic                             ctrl_busy_cycle_pulse;
  logic [31:0]                      npu_busy_cycles;

  npu_csr_if u_npu_csr_if (
    .clk              (clk),
    .rst_n            (rst_n),
    .npu_axil_awvalid (npu_axil_awvalid),
    .npu_axil_awready (npu_axil_awready),
    .npu_axil_awaddr  (npu_axil_awaddr),
    .npu_axil_awprot  (npu_axil_awprot),
    .npu_axil_wvalid  (npu_axil_wvalid),
    .npu_axil_wready  (npu_axil_wready),
    .npu_axil_wdata   (npu_axil_wdata),
    .npu_axil_wstrb   (npu_axil_wstrb),
    .npu_axil_bvalid  (npu_axil_bvalid),
    .npu_axil_bready  (npu_axil_bready),
    .npu_axil_bresp   (npu_axil_bresp),
    .npu_axil_arvalid (npu_axil_arvalid),
    .npu_axil_arready (npu_axil_arready),
    .npu_axil_araddr  (npu_axil_araddr),
    .npu_axil_arprot  (npu_axil_arprot),
    .npu_axil_rvalid  (npu_axil_rvalid),
    .npu_axil_rready  (npu_axil_rready),
    .npu_axil_rdata   (npu_axil_rdata),
    .npu_axil_rresp   (npu_axil_rresp),
    .npu_mode         (npu_mode),
    .ktile_cfg        (ktile_cfg),
    .act_buf_sel      (act_buf_sel_cfg),
    .wgt_buf_sel      (wgt_buf_sel_cfg),
    .out_buf_sel      (out_buf_sel_cfg),
    .quant_shift      (quant_shift),
    .quant_zero_point (quant_zero_point),
    .relu_en          (relu_en),
    .start_pulse      (start_pulse),
    .npu_armed        (npu_armed),
    .npu_busy         (npu_busy),
    .npu_done         (npu_done),
    .npu_error        (npu_error),
    .npu_stall_cycles (npu_stall_cycles),
    .npu_busy_cycles  (npu_busy_cycles),
    .npu_error_code   (npu_error_code)
  );

  npu_controller u_npu_controller (
    .clk               (clk),
    .rst_n             (rst_n),
    .start_pulse       (start_pulse),
    .cfg_mode          (npu_mode),
    .cfg_ktile         (ktile_cfg),
    .cfg_act_buf_sel   (act_buf_sel_cfg),
    .cfg_wgt_buf_sel   (wgt_buf_sel_cfg),
    .cfg_out_buf_sel   (out_buf_sel_cfg),
    .spm_npu_vec_valid (spm_npu_vec_valid),
    .spm_npu_vec_ready (spm_npu_vec_ready),
    .spm_npu_act_buf_sel(spm_npu_act_buf_sel),
    .spm_npu_wgt_buf_sel(spm_npu_wgt_buf_sel),
    .spm_npu_k_idx     (spm_npu_k_idx),
    .npu_spm_out_valid (npu_spm_out_valid),
    .npu_spm_out_ready (npu_spm_out_ready),
    .npu_spm_out_buf_sel(npu_spm_out_buf_sel),
    .npu_spm_out_row_idx(npu_spm_out_row_idx),
    .npu_spm_out_last  (npu_spm_out_last),
    .act_buf_ready     (act_buf_ready),
    .wgt_buf_ready     (wgt_buf_ready),
    .out_buf_free      (out_buf_free),
    .spm_npu_error     (spm_npu_error),
    .spm_npu_error_code(spm_npu_error_code),
    .clear_psum        (clear_psum),
    .accum_valid       (accum_valid),
    .quant_row_idx     (quant_row_idx),
    .armed_level       (ctrl_armed_level),
    .busy_level        (ctrl_busy_level),
    .done_pulse        (ctrl_done_pulse),
    .error_pulse       (ctrl_error_pulse),
    .error_code        (ctrl_error_code),
    .stall_cycle_pulse (ctrl_stall_cycle_pulse),
    .busy_cycle_pulse  (ctrl_busy_cycle_pulse)
  );

  npu_datapath u_npu_datapath (
    .clk              (clk),
    .rst_n            (rst_n),
    .clear_psum       (clear_psum),
    .accum_valid      (accum_valid),
    .act_vec          (act_vec_hold_r),
    .wgt_vec          (wgt_vec_hold_r),
    .quant_row_idx    (quant_row_idx),
    .quant_shift      (quant_shift),
    .quant_zero_point (quant_zero_point),
    .relu_en          (relu_en),
    .quant_row_data   (quant_row_data),
    .quant_row_mask   (quant_row_mask)
  );

  npu_status_perf u_npu_status_perf (
    .clk                 (clk),
    .rst_n               (rst_n),
    .start_pulse         (start_pulse),
    .armed_in            (ctrl_armed_level),
    .busy_in             (ctrl_busy_level),
    .done_pulse_in       (ctrl_done_pulse),
    .error_pulse_in      (ctrl_error_pulse),
    .error_code_in       (ctrl_error_code),
    .stall_cycle_pulse_in(ctrl_stall_cycle_pulse),
    .busy_cycle_pulse_in (ctrl_busy_cycle_pulse),
    .npu_armed           (npu_armed),
    .npu_busy            (npu_busy),
    .npu_done            (npu_done),
    .npu_error           (npu_error),
    .npu_stall_cycles    (npu_stall_cycles),
    .npu_busy_cycles     (npu_busy_cycles),
    .npu_error_code      (npu_error_code)
  );

  // The first-version output path always writes one logical row at a time,
  // with all 16 lanes emitted together into the 256-bit out_spm ingress path.
  assign npu_spm_out_data     = quant_row_data;
  assign npu_spm_out_col_mask = quant_row_mask;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      act_vec_hold_r <= '0;
      wgt_vec_hold_r <= '0;
    end else if (spm_npu_vec_valid && spm_npu_vec_ready) begin
      // The controller raises accum_valid one cycle after the vector-pair
      // handshake, so we latch the accepted SPM vectors here and feed the
      // datapath from these registers on the following cycle.
      act_vec_hold_r <= spm_npu_act_vec;
      wgt_vec_hold_r <= spm_npu_wgt_vec;
    end
  end

endmodule

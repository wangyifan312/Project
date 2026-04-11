module npu_datapath (
  input  logic                                clk,
  input  logic                                rst_n,
  input  logic                                clear_psum,
  input  logic                                accum_valid,
  input  logic [u_core_pkg::ACT_VEC_W-1:0]    act_vec,
  input  logic [u_core_pkg::WGT_VEC_W-1:0]    wgt_vec,
  input  logic [u_core_pkg::NPU_OUT_ROW_W-1:0] quant_row_idx,
  input  logic [7:0]                          quant_shift,
  input  logic [15:0]                         quant_zero_point,
  input  logic                                relu_en,
  output logic [u_core_pkg::OUT_VEC_W-1:0]    quant_row_data,
  output logic [u_core_pkg::ARRAY_N-1:0]      quant_row_mask
);

  import u_core_pkg::*;

  localparam integer PSUM_MATRIX_W = ARRAY_M * ARRAY_N * PSUM_ELEM_W;
  localparam integer PSUM_ROW_W    = ARRAY_N * PSUM_ELEM_W;

  logic [PSUM_MATRIX_W-1:0] psum_matrix_r;
  logic [PSUM_MATRIX_W-1:0] psum_matrix_next_w;
  logic [PSUM_ROW_W-1:0]    psum_row_w;

  integer lane_idx;
  integer flat_idx;

  npu_mac_array u_npu_mac_array (
    .psum_in  (psum_matrix_r),
    .act_vec  (act_vec),
    .wgt_vec  (wgt_vec),
    .psum_out (psum_matrix_next_w)
  );

  always @* begin
    psum_row_w = '0;
    for (lane_idx = 0; lane_idx < ARRAY_N; lane_idx = lane_idx + 1) begin
      flat_idx = ((quant_row_idx * ARRAY_N) + lane_idx) * PSUM_ELEM_W;
      psum_row_w[lane_idx*PSUM_ELEM_W +: PSUM_ELEM_W] = psum_matrix_r[flat_idx +: PSUM_ELEM_W];
    end
  end

  npu_quantizer u_npu_quantizer (
    .psum_row         (psum_row_w),
    .quant_shift      (quant_shift),
    .quant_zero_point (quant_zero_point),
    .relu_en          (relu_en),
    .out_row_data     (quant_row_data),
    .out_row_mask     (quant_row_mask)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      psum_matrix_r <= '0;
    end else if (clear_psum) begin
      psum_matrix_r <= '0;
    end else if (accum_valid) begin
      psum_matrix_r <= psum_matrix_next_w;
    end
  end

endmodule

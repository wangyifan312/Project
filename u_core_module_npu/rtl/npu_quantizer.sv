module npu_quantizer (
  input  logic [u_core_pkg::ARRAY_N*u_core_pkg::PSUM_ELEM_W-1:0] psum_row,
  input  logic [7:0]                          quant_shift,
  input  logic [15:0]                         quant_zero_point,
  input  logic                                relu_en,
  output logic [u_core_pkg::OUT_VEC_W-1:0]    out_row_data,
  output logic [u_core_pkg::ARRAY_N-1:0]      out_row_mask
);

  import u_core_pkg::*;

  integer lane_idx;
  integer shift_amt;
  logic signed [PSUM_ELEM_W-1:0] psum_lane;
  logic signed [PSUM_ELEM_W-1:0] shifted_lane;
  logic signed [PSUM_ELEM_W-1:0] biased_lane;
  logic signed [OUT_ELEM_W-1:0]  clipped_lane;

  function automatic signed [OUT_ELEM_W-1:0] sat16(
    input signed [PSUM_ELEM_W-1:0] value
  );
    localparam signed [PSUM_ELEM_W-1:0] SAT_MAX = (1 <<< (OUT_ELEM_W-1)) - 1;
    localparam signed [PSUM_ELEM_W-1:0] SAT_MIN = -(1 <<< (OUT_ELEM_W-1));
    begin
      if (value > SAT_MAX) begin
        sat16 = SAT_MAX[OUT_ELEM_W-1:0];
      end else if (value < SAT_MIN) begin
        sat16 = SAT_MIN[OUT_ELEM_W-1:0];
      end else begin
        sat16 = value[OUT_ELEM_W-1:0];
      end
    end
  endfunction

  always @* begin
    out_row_data = '0;
    out_row_mask = {ARRAY_N{1'b1}};
    shift_amt    = (quant_shift > (PSUM_ELEM_W-1)) ? (PSUM_ELEM_W-1) : quant_shift;

    for (lane_idx = 0; lane_idx < ARRAY_N; lane_idx = lane_idx + 1) begin
      psum_lane    = $signed(psum_row[lane_idx*PSUM_ELEM_W +: PSUM_ELEM_W]);
      shifted_lane = psum_lane >>> shift_amt;
      biased_lane  = shifted_lane + $signed({{(PSUM_ELEM_W-16){quant_zero_point[15]}}, quant_zero_point});

      // ReLU is applied after quant shift and zero-point add, so software sees
      // a final tensor-like output rather than raw psum.
      if (relu_en && biased_lane < 0) begin
        clipped_lane = '0;
      end else begin
        clipped_lane = sat16(biased_lane);
      end

      out_row_data[lane_idx*OUT_ELEM_W +: OUT_ELEM_W] = clipped_lane;
    end
  end

endmodule

module npu_mac_array (
  input  logic [u_core_pkg::ARRAY_M*u_core_pkg::ARRAY_N*u_core_pkg::PSUM_ELEM_W-1:0] psum_in,
  input  logic [u_core_pkg::ACT_VEC_W-1:0]    act_vec,
  input  logic [u_core_pkg::WGT_VEC_W-1:0]    wgt_vec,
  output logic [u_core_pkg::ARRAY_M*u_core_pkg::ARRAY_N*u_core_pkg::PSUM_ELEM_W-1:0] psum_out
);

  import u_core_pkg::*;

  integer row_idx;
  integer col_idx;
  integer flat_idx;
  logic signed [ACT_ELEM_W-1:0]  act_lane;
  logic signed [WGT_ELEM_W-1:0]  wgt_lane;
  logic signed [PSUM_ELEM_W-1:0] psum_lane;
  logic signed [PSUM_ELEM_W-1:0] next_lane;

  always @* begin
    psum_out = psum_in;

    // One accepted SPM vector pair represents one K-step. The first-version
    // compute model therefore accumulates a 16x16 outer-product per beat.
    for (row_idx = 0; row_idx < ARRAY_M; row_idx = row_idx + 1) begin
      for (col_idx = 0; col_idx < ARRAY_N; col_idx = col_idx + 1) begin
        flat_idx  = ((row_idx * ARRAY_N) + col_idx) * PSUM_ELEM_W;
        act_lane  = $signed(act_vec[row_idx*ACT_ELEM_W +: ACT_ELEM_W]);
        wgt_lane  = $signed(wgt_vec[col_idx*WGT_ELEM_W +: WGT_ELEM_W]);
        psum_lane = $signed(psum_in[flat_idx +: PSUM_ELEM_W]);
        next_lane = psum_lane + (act_lane * wgt_lane);
        psum_out[flat_idx +: PSUM_ELEM_W] = next_lane;
      end
    end
  end

endmodule

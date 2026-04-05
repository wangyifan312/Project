module out_spm (
  input  logic                                clk,
  input  logic                                rst_n,
  input  logic                                clear_en,
  input  logic                                wr_en,
  input  logic [u_core_pkg::NPU_OUT_ROW_W-1:0] wr_row_idx,
  input  logic [u_core_pkg::ARRAY_N-1:0]      wr_col_mask,
  input  logic [u_core_pkg::OUT_VEC_W-1:0]    wr_data,
  input  logic [u_core_pkg::DMA_SPM_ROW_W-1:0] rd_row_idx,
  output logic [u_core_pkg::AXI_DATA_W-1:0]   rd_data
);

  import u_core_pkg::*;

  localparam integer ROW_COUNT = 16;

  logic [OUT_VEC_W-1:0] mem [0:ROW_COUNT-1];

  integer row_idx;
  integer lane_idx;

  function automatic [AXI_DATA_W-1:0] pack_out_pair(
    input logic [OUT_VEC_W-1:0] upper_row,
    input logic [OUT_VEC_W-1:0] lower_row
  );
    begin
      pack_out_pair = {upper_row, lower_row};
    end
  endfunction

  always @* begin
    rd_data = pack_out_pair(mem[{rd_row_idx, 1'b1}], mem[{rd_row_idx, 1'b0}]);
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (row_idx = 0; row_idx < ROW_COUNT; row_idx = row_idx + 1) begin
        mem[row_idx] <= '0;
      end
    end else begin
      if (clear_en) begin
        for (row_idx = 0; row_idx < ROW_COUNT; row_idx = row_idx + 1) begin
          mem[row_idx] <= '0;
        end
      end

      if (wr_en) begin
        for (lane_idx = 0; lane_idx < ARRAY_N; lane_idx = lane_idx + 1) begin
          if (wr_col_mask[lane_idx]) begin
            mem[wr_row_idx][lane_idx*OUT_ELEM_W +: OUT_ELEM_W]
              <= wr_data[lane_idx*OUT_ELEM_W +: OUT_ELEM_W];
          end else begin
            mem[wr_row_idx][lane_idx*OUT_ELEM_W +: OUT_ELEM_W] <= {OUT_ELEM_W{1'b0}};
          end
        end
      end
    end
  end

endmodule

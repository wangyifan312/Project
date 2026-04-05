module wgt_spm (
  input  logic                                clk,
  input  logic                                rst_n,
  input  logic                                wr_en,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    wr_buf_sel,
  input  logic [u_core_pkg::DMA_SPM_ROW_W-1:0] wr_row_idx,
  input  logic [u_core_pkg::AXI_DATA_W-1:0]   wr_data,
  input  logic [u_core_pkg::AXI_STRB_W-1:0]   wr_strb,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    rd_buf_sel,
  input  logic [u_core_pkg::NPU_K_IDX_W-1:0]  rd_k_idx,
  output logic [u_core_pkg::WGT_VEC_W-1:0]    rd_vec
);

  import u_core_pkg::*;

  localparam integer BUF_COUNT = 2;
  localparam integer ROW_COUNT = 8;

  logic [AXI_DATA_W-1:0] mem [0:BUF_COUNT-1][0:ROW_COUNT-1];

  integer buf_idx;
  integer row_idx;
  integer byte_idx;

  function automatic [WGT_VEC_W-1:0] unpack_vec(
    input logic [AXI_DATA_W-1:0] row_data,
    input logic [1:0]            slot_idx
  );
    begin
      case (slot_idx)
        2'd0: unpack_vec = row_data[127:0];
        2'd1: unpack_vec = row_data[255:128];
        2'd2: unpack_vec = row_data[383:256];
        default: unpack_vec = row_data[511:384];
      endcase
    end
  endfunction

  always @* begin
    rd_vec = unpack_vec(mem[rd_buf_sel][rd_k_idx[4:2]], rd_k_idx[1:0]);
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (buf_idx = 0; buf_idx < BUF_COUNT; buf_idx = buf_idx + 1) begin
        for (row_idx = 0; row_idx < ROW_COUNT; row_idx = row_idx + 1) begin
          mem[buf_idx][row_idx] <= '0;
        end
      end
    end else if (wr_en) begin
      for (byte_idx = 0; byte_idx < AXI_STRB_W; byte_idx = byte_idx + 1) begin
        if (wr_strb[byte_idx]) begin
          mem[wr_buf_sel][wr_row_idx][byte_idx*8 +: 8] <= wr_data[byte_idx*8 +: 8];
        end
      end
    end
  end

endmodule

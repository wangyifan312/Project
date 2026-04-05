module dma_desc_fifo #(
  parameter integer DEPTH = u_core_pkg::DMA_FIFO_DEPTH
) (
  input  logic                              clk,
  input  logic                              rst_n,
  input  logic                              push_valid,
  input  logic [u_core_pkg::DMA_DESC_W-1:0] push_desc,
  input  logic                              pop_valid,
  output logic [u_core_pkg::DMA_DESC_W-1:0] head_desc,
  output logic                              fifo_empty,
  output logic                              fifo_full,
  output logic [u_core_pkg::DMA_FIFO_LEVEL_W-1:0] fifo_level
);

  import u_core_pkg::*;

  localparam integer PTR_W = 2;

  logic [DMA_DESC_W-1:0] fifo_mem [0:DEPTH-1];
  logic [PTR_W-1:0] wr_ptr_r;
  logic [PTR_W-1:0] rd_ptr_r;
  logic [DMA_FIFO_LEVEL_W-1:0] level_r;

  integer idx;

  assign fifo_empty = (level_r == '0);
  assign fifo_full  = (level_r == DEPTH[DMA_FIFO_LEVEL_W-1:0]);
  assign fifo_level = level_r;
  assign head_desc  = fifo_empty ? '0 : fifo_mem[rd_ptr_r];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_r <= '0;
      rd_ptr_r <= '0;
      level_r  <= '0;
      for (idx = 0; idx < DEPTH; idx = idx + 1) begin
        fifo_mem[idx] <= '0;
      end
    end else begin
      case ({push_valid && !fifo_full, pop_valid && !fifo_empty})
        2'b10: begin
          fifo_mem[wr_ptr_r] <= push_desc;
          wr_ptr_r <= wr_ptr_r + 1'b1;
          level_r  <= level_r + 1'b1;
        end
        2'b01: begin
          rd_ptr_r <= rd_ptr_r + 1'b1;
          level_r  <= level_r - 1'b1;
        end
        2'b11: begin
          fifo_mem[wr_ptr_r] <= push_desc;
          wr_ptr_r <= wr_ptr_r + 1'b1;
          rd_ptr_r <= rd_ptr_r + 1'b1;
        end
        default: begin end
      endcase
    end
  end

endmodule

interface dma_status_if (
  input logic clk,
  input logic rst_n
);

  import u_core_pkg::*;

  logic                       dma_busy;
  logic                       dma_done;
  logic                       dma_error;
  logic                       dma_fifo_empty;
  logic                       dma_fifo_full;
  logic [DMA_FIFO_LEVEL_W-1:0] dma_fifo_level;
  logic [31:0]                dma_done_count;
  logic [31:0]                dma_rd_beat_count;
  logic [31:0]                dma_wr_beat_count;
  logic [DMA_ERROR_CODE_W-1:0] dma_error_code;

  clocking mon_cb @(posedge clk);
    default input #1step output #1step;
    input dma_busy, dma_done, dma_error, dma_fifo_empty, dma_fifo_full;
    input dma_fifo_level, dma_done_count, dma_rd_beat_count, dma_wr_beat_count;
    input dma_error_code;
  endclocking

endinterface

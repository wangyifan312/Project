module dma_status_perf (
  input  logic                                clk,
  input  logic                                rst_n,
  input  logic                                submit_pulse,
  input  logic                                exec_busy,
  input  logic                                fifo_empty_in,
  input  logic                                fifo_full_in,
  input  logic [u_core_pkg::DMA_FIFO_LEVEL_W-1:0] fifo_level_in,
  input  logic                                done_pulse_in,
  input  logic                                error_pulse_in,
  input  logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] error_code_in,
  input  logic                                rd_beat_pulse_in,
  input  logic                                wr_beat_pulse_in,
  output logic                                dma_busy,
  output logic                                dma_done,
  output logic                                dma_error,
  output logic                                dma_fifo_empty,
  output logic                                dma_fifo_full,
  output logic [u_core_pkg::DMA_FIFO_LEVEL_W-1:0] dma_fifo_level,
  output logic [31:0]                         dma_done_count,
  output logic [31:0]                         dma_rd_beat_count,
  output logic [31:0]                         dma_wr_beat_count,
  output logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] dma_error_code
);

  import u_core_pkg::*;

  assign dma_busy       = exec_busy || !fifo_empty_in;
  assign dma_fifo_empty = fifo_empty_in;
  assign dma_fifo_full  = fifo_full_in;
  assign dma_fifo_level = fifo_level_in;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dma_done         <= 1'b0;
      dma_error        <= 1'b0;
      dma_done_count   <= 32'h0000_0000;
      dma_rd_beat_count <= 32'h0000_0000;
      dma_wr_beat_count <= 32'h0000_0000;
      dma_error_code   <= '0;
    end else begin
      if (submit_pulse) begin
        dma_done <= 1'b0;
      end

      if (done_pulse_in) begin
        dma_done       <= 1'b1;
        dma_done_count <= dma_done_count + 1'b1;
      end

      if (rd_beat_pulse_in) begin
        dma_rd_beat_count <= dma_rd_beat_count + 1'b1;
      end

      if (wr_beat_pulse_in) begin
        dma_wr_beat_count <= dma_wr_beat_count + 1'b1;
      end

      if (error_pulse_in) begin
        dma_error <= 1'b1;
        if (!dma_error) begin
          dma_error_code <= error_code_in;
        end
      end
    end
  end

endmodule

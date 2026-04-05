module dma_scheduler (
  input  logic                              fifo_empty,
  input  logic [u_core_pkg::DMA_DESC_W-1:0] head_desc,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]  act_buf_writable,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]  wgt_buf_writable,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]  out_buf_readable,
  input  logic                              rd_engine_ready,
  input  logic                              wr_engine_ready,
  output logic                              issue_rd_valid,
  output logic                              issue_wr_valid,
  output logic                              pop_desc,
  output logic [u_core_pkg::DMA_DESC_W-1:0] issue_desc
);

  import u_core_pkg::*;

  logic [1:0] op_type;
  logic [1:0] buf_sel;

  always @* begin
    op_type       = head_desc[1:0];
    buf_sel       = head_desc[131:130];
    issue_desc    = head_desc;
    issue_rd_valid = 1'b0;
    issue_wr_valid = 1'b0;
    pop_desc       = 1'b0;

    if (!fifo_empty) begin
      case (op_type)
        DMA_OP_LOAD_ACT: begin
          if (rd_engine_ready && act_buf_writable[buf_sel]) begin
            issue_rd_valid = 1'b1;
            pop_desc       = 1'b1;
          end
        end
        DMA_OP_LOAD_WGT: begin
          if (rd_engine_ready && wgt_buf_writable[buf_sel]) begin
            issue_rd_valid = 1'b1;
            pop_desc       = 1'b1;
          end
        end
        DMA_OP_STORE_OUT: begin
          if (wr_engine_ready && out_buf_readable[0]) begin
            issue_wr_valid = 1'b1;
            pop_desc       = 1'b1;
          end
        end
        default: begin end
      endcase
    end
  end

endmodule

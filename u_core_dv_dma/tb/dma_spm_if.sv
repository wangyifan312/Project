interface dma_spm_if (
  input logic clk,
  input logic rst_n
);

  import u_core_pkg::*;

  logic                       wr_valid;
  logic                       wr_ready;
  logic [1:0]                 wr_type;
  logic [BUF_SEL_W-1:0]       wr_buf_sel;
  logic [DMA_SPM_ROW_W-1:0]   wr_row_idx;
  logic [AXI_DATA_W-1:0]      wr_data;
  logic [AXI_STRB_W-1:0]      wr_strb;
  logic                       wr_last;

  logic                       rd_req_valid;
  logic                       rd_req_ready;
  logic [BUF_SEL_W-1:0]       rd_buf_sel;
  logic [DMA_SPM_ROW_W-1:0]   rd_row_idx;
  logic                       rd_data_valid;
  logic                       rd_data_ready;
  logic [AXI_DATA_W-1:0]      rd_data;
  logic                       rd_last;

  logic [BUF_SEL_W-1:0]       act_buf_writable;
  logic [BUF_SEL_W-1:0]       wgt_buf_writable;
  logic [BUF_SEL_W-1:0]       out_buf_readable;
  logic                       spm_dma_error;
  logic [DMA_ERROR_CODE_W-1:0] spm_dma_error_code;

  clocking drv_cb @(posedge clk);
    default input #1step output #1step;
    input wr_valid, wr_type, wr_buf_sel, wr_row_idx, wr_data, wr_strb, wr_last;
    input rd_req_valid, rd_buf_sel, rd_row_idx, rd_data_ready;
    output wr_ready;
    output rd_req_ready, rd_data_valid, rd_data, rd_last;
    output act_buf_writable, wgt_buf_writable, out_buf_readable;
    output spm_dma_error, spm_dma_error_code;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step output #1step;
    input wr_valid, wr_ready, wr_type, wr_buf_sel, wr_row_idx, wr_data, wr_strb, wr_last;
    input rd_req_valid, rd_req_ready, rd_buf_sel, rd_row_idx;
    input rd_data_valid, rd_data_ready, rd_data, rd_last;
    input act_buf_writable, wgt_buf_writable, out_buf_readable;
    input spm_dma_error, spm_dma_error_code;
  endclocking

  task automatic init_slave();
    wr_ready         = 1'b0;
    rd_req_ready     = 1'b0;
    rd_data_valid    = 1'b0;
    rd_data          = '0;
    rd_last          = 1'b0;
    act_buf_writable = 2'b11;
    wgt_buf_writable = 2'b11;
    out_buf_readable = 2'b01;
    spm_dma_error    = 1'b0;
    spm_dma_error_code = '0;
  endtask

endinterface

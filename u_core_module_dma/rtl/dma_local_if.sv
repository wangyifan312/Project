module dma_local_if (
  input  logic                                rd_local_wr_valid,
  output logic                                rd_local_wr_ready,
  input  logic [1:0]                          rd_local_wr_type,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    rd_local_wr_buf_sel,
  input  logic [u_core_pkg::DMA_SPM_ROW_W-1:0] rd_local_wr_row_idx,
  input  logic [u_core_pkg::AXI_DATA_W-1:0]   rd_local_wr_data,
  input  logic [u_core_pkg::AXI_STRB_W-1:0]   rd_local_wr_strb,
  input  logic                                rd_local_wr_last,
  input  logic                                wr_local_rd_req_valid,
  output logic                                wr_local_rd_req_ready,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    wr_local_rd_buf_sel,
  input  logic [u_core_pkg::DMA_SPM_ROW_W-1:0] wr_local_rd_row_idx,
  output logic                                wr_local_rd_data_valid,
  input  logic                                wr_local_rd_data_ready,
  output logic [u_core_pkg::AXI_DATA_W-1:0]   wr_local_rd_data,
  output logic                                wr_local_rd_last,

  output logic                                dma_spm_wr_valid,
  input  logic                                dma_spm_wr_ready,
  output logic [1:0]                          dma_spm_wr_type,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    dma_spm_wr_buf_sel,
  output logic [u_core_pkg::DMA_SPM_ROW_W-1:0] dma_spm_wr_row_idx,
  output logic [u_core_pkg::AXI_DATA_W-1:0]   dma_spm_wr_data,
  output logic [u_core_pkg::AXI_STRB_W-1:0]   dma_spm_wr_strb,
  output logic                                dma_spm_wr_last,

  output logic                                dma_spm_rd_req_valid,
  input  logic                                dma_spm_rd_req_ready,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    dma_spm_rd_buf_sel,
  output logic [u_core_pkg::DMA_SPM_ROW_W-1:0] dma_spm_rd_row_idx,
  input  logic                                dma_spm_rd_data_valid,
  output logic                                dma_spm_rd_data_ready,
  input  logic [u_core_pkg::AXI_DATA_W-1:0]   dma_spm_rd_data,
  input  logic                                dma_spm_rd_last
);

  import u_core_pkg::*;

  assign dma_spm_wr_valid   = rd_local_wr_valid;
  assign rd_local_wr_ready  = dma_spm_wr_ready;
  assign dma_spm_wr_type    = rd_local_wr_type;
  assign dma_spm_wr_buf_sel = rd_local_wr_buf_sel;
  assign dma_spm_wr_row_idx = rd_local_wr_row_idx;
  assign dma_spm_wr_data    = rd_local_wr_data;
  assign dma_spm_wr_strb    = rd_local_wr_strb;
  assign dma_spm_wr_last    = rd_local_wr_last;

  assign dma_spm_rd_req_valid = wr_local_rd_req_valid;
  assign wr_local_rd_req_ready = dma_spm_rd_req_ready;
  assign dma_spm_rd_buf_sel   = wr_local_rd_buf_sel;
  assign dma_spm_rd_row_idx   = wr_local_rd_row_idx;
  assign wr_local_rd_data_valid = dma_spm_rd_data_valid;
  assign dma_spm_rd_data_ready = wr_local_rd_data_ready;
  assign wr_local_rd_data     = dma_spm_rd_data;
  assign wr_local_rd_last     = dma_spm_rd_last;

endmodule

module npu_top (
  input  logic                           clk,
  input  logic                           rst_n,

  input  logic                           npu_axil_awvalid,
  output logic                           npu_axil_awready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0] npu_axil_awaddr,
  input  logic [2:0]                     npu_axil_awprot,
  input  logic                           npu_axil_wvalid,
  output logic                           npu_axil_wready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0] npu_axil_wdata,
  input  logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] npu_axil_wstrb,
  output logic                           npu_axil_bvalid,
  input  logic                           npu_axil_bready,
  output logic [1:0]                     npu_axil_bresp,
  input  logic                           npu_axil_arvalid,
  output logic                           npu_axil_arready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0] npu_axil_araddr,
  input  logic [2:0]                     npu_axil_arprot,
  output logic                           npu_axil_rvalid,
  input  logic                           npu_axil_rready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0] npu_axil_rdata,
  output logic [1:0]                     npu_axil_rresp,

  input  logic                           spm_npu_vec_valid,
  output logic                           spm_npu_vec_ready,
  output logic [u_core_pkg::BUF_SEL_W-1:0] spm_npu_act_buf_sel,
  output logic [u_core_pkg::BUF_SEL_W-1:0] spm_npu_wgt_buf_sel,
  output logic [u_core_pkg::NPU_K_IDX_W-1:0] spm_npu_k_idx,
  input  logic [u_core_pkg::ACT_VEC_W-1:0] spm_npu_act_vec,
  input  logic [u_core_pkg::WGT_VEC_W-1:0] spm_npu_wgt_vec,

  output logic                           npu_spm_out_valid,
  input  logic                           npu_spm_out_ready,
  output logic [u_core_pkg::BUF_SEL_W-1:0] npu_spm_out_buf_sel,
  output logic [u_core_pkg::NPU_OUT_ROW_W-1:0] npu_spm_out_row_idx,
  output logic [u_core_pkg::ARRAY_N-1:0] npu_spm_out_col_mask,
  output logic [u_core_pkg::OUT_VEC_W-1:0] npu_spm_out_data,
  output logic                           npu_spm_out_last,

  input  logic [u_core_pkg::BUF_SEL_W-1:0] act_buf_ready,
  input  logic [u_core_pkg::BUF_SEL_W-1:0] wgt_buf_ready,
  input  logic [u_core_pkg::BUF_SEL_W-1:0] out_buf_free,
  input  logic                           spm_npu_error,
  input  logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] spm_npu_error_code,

  output logic                           npu_armed,
  output logic                           npu_busy,
  output logic                           npu_done,
  output logic                           npu_error,
  output logic [31:0]                    npu_stall_cycles,
  output logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] npu_error_code
);

  import u_core_pkg::*;

  assign npu_axil_awready   = 1'b0;
  assign npu_axil_wready    = 1'b0;
  assign npu_axil_bvalid    = 1'b0;
  assign npu_axil_bresp     = 2'b00;
  assign npu_axil_arready   = 1'b0;
  assign npu_axil_rvalid    = 1'b0;
  assign npu_axil_rdata     = '0;
  assign npu_axil_rresp     = 2'b00;

  assign spm_npu_vec_ready  = 1'b0;
  assign spm_npu_act_buf_sel = '0;
  assign spm_npu_wgt_buf_sel = '0;
  assign spm_npu_k_idx      = '0;

  assign npu_spm_out_valid    = 1'b0;
  assign npu_spm_out_buf_sel  = '0;
  assign npu_spm_out_row_idx  = '0;
  assign npu_spm_out_col_mask = '0;
  assign npu_spm_out_data     = '0;
  assign npu_spm_out_last     = 1'b0;

  assign npu_armed          = 1'b0;
  assign npu_busy           = 1'b0;
  assign npu_done           = 1'b0;
  assign npu_error          = spm_npu_error;
  assign npu_stall_cycles   = '0;
  assign npu_error_code     = spm_npu_error ? spm_npu_error_code : '0;

endmodule

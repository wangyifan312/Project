module dma_desc_stage (
  input  logic                                clk,
  input  logic                                rst_n,
  input  logic                                stage_we,
  input  logic [3:0]                          stage_addr,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  stage_wdata,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  cfg0_word,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  src_addr_word,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  dst_addr_word,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  row_cfg_word,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  stride_cfg_word,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  local_cfg_word,
  output logic [u_core_pkg::DMA_DESC_W-1:0]   desc_bus,
  output logic                                desc_valid,
  output logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] desc_error_code
);

  import u_core_pkg::*;

  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_NONE        = 8'h00;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_ILLEGAL_OP  = 8'h01;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_ILLEGAL_BUF = 8'h02;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_ZERO_LEN    = 8'h03;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_ZERO_CNT    = 8'h04;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_ALIGN       = 8'h05;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_UNSUPPORTED = 8'h07;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_LOCAL_RANGE = 8'h08;

  logic [1:0]  op_type_r;
  logic [1:0]  buf_sel_r;
  logic [31:0] src_addr_r;
  logic [31:0] dst_addr_r;
  logic [15:0] row_len_r;
  logic [15:0] row_cnt_r;
  logic [15:0] ext_stride_r;
  logic [15:0] spm_row_base_r;
  logic [9:0]  ext_stride_units_r;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      op_type_r      <= 2'b00;
      buf_sel_r      <= 2'b00;
      src_addr_r     <= 32'h0000_0000;
      dst_addr_r     <= 32'h0000_0000;
      row_len_r      <= 16'h0000;
      row_cnt_r      <= 16'h0000;
      ext_stride_r   <= 16'h0000;
      spm_row_base_r <= 16'h0000;
      ext_stride_units_r <= 10'h000;
    end else if (stage_we) begin
      case (stage_addr)
        4'h0: begin
          op_type_r <= stage_wdata[1:0];
          buf_sel_r <= stage_wdata[3:2];
          spm_row_base_r <= {13'h0000, stage_wdata[6:4]};
          row_len_r      <= {9'h000, stage_wdata[13:7]};
          row_cnt_r      <= {12'h000, stage_wdata[17:14]};
        end
        4'h1: src_addr_r <= stage_wdata;
        4'h2: dst_addr_r <= stage_wdata;
        4'h3: begin
          ext_stride_units_r <= stage_wdata[9:0];
          ext_stride_r       <= {stage_wdata[9:0], 6'b0};
        end
        default: begin end
      endcase
    end
  end

  always @* begin
    cfg0_word       = {14'h0000, row_cnt_r[3:0], row_len_r[6:0], spm_row_base_r[2:0], buf_sel_r, op_type_r};
    src_addr_word   = src_addr_r;
    dst_addr_word   = dst_addr_r;
    row_cfg_word    = {22'h000000, ext_stride_units_r};
    stride_cfg_word = 32'h0000_0000;
    local_cfg_word  = 32'h0000_0000;
    desc_bus = {16'h0000, 16'h0000, spm_row_base_r, buf_sel_r, ext_stride_r,
                ext_stride_r, row_cnt_r, row_len_r, dst_addr_r, src_addr_r, op_type_r};

    desc_valid      = 1'b0;
    desc_error_code = DMA_ERR_NONE;

    case (op_type_r)
      DMA_OP_LOAD_ACT,
      DMA_OP_LOAD_WGT,
      DMA_OP_STORE_OUT: begin
        desc_valid      = 1'b1;
        desc_error_code = DMA_ERR_NONE;
      end
      default: begin
        desc_valid      = 1'b0;
        desc_error_code = DMA_ERR_ILLEGAL_OP;
      end
    endcase

    if (desc_valid && (row_len_r == 16'h0000)) begin
      desc_valid      = 1'b0;
      desc_error_code = DMA_ERR_ZERO_LEN;
    end

    if (desc_valid && (row_cnt_r == 16'h0000)) begin
      desc_valid      = 1'b0;
      desc_error_code = DMA_ERR_ZERO_CNT;
    end

    if (desc_valid && (row_len_r > AXI_BEAT_BYTES)) begin
      desc_valid      = 1'b0;
      desc_error_code = DMA_ERR_UNSUPPORTED;
    end

    if (desc_valid && ((spm_row_base_r + row_cnt_r) > DMA_SPM_ROW_COUNT)) begin
      desc_valid      = 1'b0;
      desc_error_code = DMA_ERR_LOCAL_RANGE;
    end

    if (desc_valid) begin
      case (op_type_r)
        DMA_OP_LOAD_ACT,
        DMA_OP_LOAD_WGT: begin
          if (!((buf_sel_r == 2'd0) || (buf_sel_r == 2'd1))) begin
            desc_valid      = 1'b0;
            desc_error_code = DMA_ERR_ILLEGAL_BUF;
          end else if ((src_addr_r[5:0] != 6'b0) || (ext_stride_r[5:0] != 6'b0)) begin
            desc_valid      = 1'b0;
            desc_error_code = DMA_ERR_ALIGN;
          end
        end
        DMA_OP_STORE_OUT: begin
          if (buf_sel_r != 2'd0) begin
            desc_valid      = 1'b0;
            desc_error_code = DMA_ERR_ILLEGAL_BUF;
          end else if ((dst_addr_r[5:0] != 6'b0) || (ext_stride_r[5:0] != 6'b0)) begin
            desc_valid      = 1'b0;
            desc_error_code = DMA_ERR_ALIGN;
          end
        end
        default: begin end
      endcase
    end
  end

endmodule

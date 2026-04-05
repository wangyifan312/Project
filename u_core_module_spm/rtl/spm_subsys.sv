module spm_subsys (
  input  logic                                clk,
  input  logic                                rst_n,

  input  logic                                dma_spm_wr_valid,
  output logic                                dma_spm_wr_ready,
  input  logic [1:0]                          dma_spm_wr_type,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    dma_spm_wr_buf_sel,
  input  logic [u_core_pkg::DMA_SPM_ROW_W-1:0] dma_spm_wr_row_idx,
  input  logic [u_core_pkg::AXI_DATA_W-1:0]   dma_spm_wr_data,
  input  logic [u_core_pkg::AXI_STRB_W-1:0]   dma_spm_wr_strb,
  input  logic                                dma_spm_wr_last,

  input  logic                                dma_spm_rd_req_valid,
  output logic                                dma_spm_rd_req_ready,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    dma_spm_rd_buf_sel,
  input  logic [u_core_pkg::DMA_SPM_ROW_W-1:0] dma_spm_rd_row_idx,
  output logic                                dma_spm_rd_data_valid,
  input  logic                                dma_spm_rd_data_ready,
  output logic [u_core_pkg::AXI_DATA_W-1:0]   dma_spm_rd_data,
  output logic                                dma_spm_rd_last,

  output logic                                spm_npu_vec_valid,
  input  logic                                spm_npu_vec_ready,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    spm_npu_act_buf_sel,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    spm_npu_wgt_buf_sel,
  input  logic [u_core_pkg::NPU_K_IDX_W-1:0]  spm_npu_k_idx,
  output logic [u_core_pkg::ACT_VEC_W-1:0]    spm_npu_act_vec,
  output logic [u_core_pkg::WGT_VEC_W-1:0]    spm_npu_wgt_vec,

  input  logic                                npu_spm_out_valid,
  output logic                                npu_spm_out_ready,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    npu_spm_out_buf_sel,
  input  logic [u_core_pkg::NPU_OUT_ROW_W-1:0] npu_spm_out_row_idx,
  input  logic [u_core_pkg::ARRAY_N-1:0]      npu_spm_out_col_mask,
  input  logic [u_core_pkg::OUT_VEC_W-1:0]    npu_spm_out_data,
  input  logic                                npu_spm_out_last,

  output logic [u_core_pkg::BUF_SEL_W-1:0]    act_buf_writable,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    wgt_buf_writable,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    out_buf_readable,
  output logic                                spm_dma_error,
  output logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] spm_dma_error_code,

  output logic [u_core_pkg::BUF_SEL_W-1:0]    act_buf_ready,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    wgt_buf_ready,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    out_buf_free,
  output logic                                spm_npu_error,
  output logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] spm_npu_error_code
);

  import u_core_pkg::*;

  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_NONE          = 8'h00;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_WR_TYPE       = 8'h01;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_WR_BUF_SEL    = 8'h02;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_RD_BUF_SEL    = 8'h03;
  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_OUT_NOT_READY = 8'h04;

  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_NONE          = 8'h00;
  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_ACT_BUF_SEL   = 8'h01;
  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_WGT_BUF_SEL   = 8'h02;
  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_K_IDX         = 8'h03;
  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_OUT_BUF_SEL   = 8'h04;

  logic [BUF_SEL_W-1:0] act_buf_ready_r;
  logic [BUF_SEL_W-1:0] wgt_buf_ready_r;
  logic [BUF_SEL_W-1:0] out_buf_readable_r;

  logic spm_dma_error_r;
  logic [DMA_ERROR_CODE_W-1:0] spm_dma_error_code_r;
  logic spm_npu_error_r;
  logic [NPU_ERROR_CODE_W-1:0] spm_npu_error_code_r;

  logic act_spm_wr_en;
  logic wgt_spm_wr_en;
  logic out_spm_clear_en;
  logic out_spm_wr_en;

  function automatic logic buf_index_legal(input logic [BUF_SEL_W-1:0] idx);
    begin
      buf_index_legal = (idx == 2'd0) || (idx == 2'd1);
    end
  endfunction

  function automatic logic single_out_buf_legal(input logic [BUF_SEL_W-1:0] idx);
    begin
      single_out_buf_legal = (idx == 2'd0);
    end
  endfunction

  function automatic logic status_bit_select(
    input logic [BUF_SEL_W-1:0] status_bits,
    input logic [BUF_SEL_W-1:0] idx
  );
    begin
      case (idx)
        2'd0: status_bit_select = status_bits[0];
        2'd1: status_bit_select = status_bits[1];
        default: status_bit_select = 1'b0;
      endcase
    end
  endfunction

  assign dma_spm_wr_ready      = 1'b1;
  assign dma_spm_rd_req_ready  = ~dma_spm_rd_data_valid;
  assign npu_spm_out_ready     = 1'b1;

  assign act_buf_writable      = 2'b11;
  assign wgt_buf_writable      = 2'b11;
  assign act_buf_ready         = act_buf_ready_r;
  assign wgt_buf_ready         = wgt_buf_ready_r;
  assign out_buf_readable      = out_buf_readable_r;
  assign out_buf_free          = {1'b0, ~out_buf_readable_r[0]};
  assign spm_dma_error         = spm_dma_error_r;
  assign spm_dma_error_code    = spm_dma_error_code_r;
  assign spm_npu_error         = spm_npu_error_r;
  assign spm_npu_error_code    = spm_npu_error_code_r;

  assign act_spm_wr_en = dma_spm_wr_valid && dma_spm_wr_ready &&
                         (dma_spm_wr_type == 2'b00) &&
                         buf_index_legal(dma_spm_wr_buf_sel);

  assign wgt_spm_wr_en = dma_spm_wr_valid && dma_spm_wr_ready &&
                         (dma_spm_wr_type == 2'b01) &&
                         buf_index_legal(dma_spm_wr_buf_sel);

  assign out_spm_clear_en = npu_spm_out_valid && npu_spm_out_ready &&
                            single_out_buf_legal(npu_spm_out_buf_sel) &&
                            (npu_spm_out_row_idx == '0);

  assign out_spm_wr_en = npu_spm_out_valid && npu_spm_out_ready &&
                         single_out_buf_legal(npu_spm_out_buf_sel);

  act_spm u_act_spm (
    .clk       (clk),
    .rst_n     (rst_n),
    .wr_en     (act_spm_wr_en),
    .wr_buf_sel(dma_spm_wr_buf_sel),
    .wr_row_idx(dma_spm_wr_row_idx),
    .wr_data   (dma_spm_wr_data),
    .wr_strb   (dma_spm_wr_strb),
    .rd_buf_sel(spm_npu_act_buf_sel),
    .rd_k_idx  (spm_npu_k_idx),
    .rd_vec    (spm_npu_act_vec)
  );

  wgt_spm u_wgt_spm (
    .clk       (clk),
    .rst_n     (rst_n),
    .wr_en     (wgt_spm_wr_en),
    .wr_buf_sel(dma_spm_wr_buf_sel),
    .wr_row_idx(dma_spm_wr_row_idx),
    .wr_data   (dma_spm_wr_data),
    .wr_strb   (dma_spm_wr_strb),
    .rd_buf_sel(spm_npu_wgt_buf_sel),
    .rd_k_idx  (spm_npu_k_idx),
    .rd_vec    (spm_npu_wgt_vec)
  );

  out_spm u_out_spm (
    .clk       (clk),
    .rst_n     (rst_n),
    .clear_en  (out_spm_clear_en),
    .wr_en     (out_spm_wr_en),
    .wr_row_idx(npu_spm_out_row_idx),
    .wr_col_mask(npu_spm_out_col_mask),
    .wr_data   (npu_spm_out_data),
    .rd_row_idx(dma_spm_rd_row_idx),
    .rd_data   (dma_spm_rd_data)
  );

  always @* begin
    spm_npu_vec_valid = 1'b0;
    if (buf_index_legal(spm_npu_act_buf_sel) &&
        buf_index_legal(spm_npu_wgt_buf_sel) &&
        (spm_npu_k_idx < ARRAY_K_TILE) &&
        status_bit_select(act_buf_ready_r, spm_npu_act_buf_sel) &&
        status_bit_select(wgt_buf_ready_r, spm_npu_wgt_buf_sel)) begin
      spm_npu_vec_valid = 1'b1;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dma_spm_rd_data_valid <= 1'b0;
      dma_spm_rd_last       <= 1'b0;
      act_buf_ready_r       <= '0;
      wgt_buf_ready_r       <= '0;
      out_buf_readable_r    <= '0;
      spm_dma_error_r       <= 1'b0;
      spm_dma_error_code_r  <= DMA_ERR_NONE;
      spm_npu_error_r       <= 1'b0;
      spm_npu_error_code_r  <= NPU_ERR_NONE;
    end else begin
      if (dma_spm_rd_data_valid && dma_spm_rd_data_ready) begin
        dma_spm_rd_data_valid <= 1'b0;
        if (dma_spm_rd_last) begin
          out_buf_readable_r[0] <= 1'b0;
        end
      end

      if (dma_spm_wr_valid && dma_spm_wr_ready) begin
        case (dma_spm_wr_type)
          2'b00: begin
            if (!buf_index_legal(dma_spm_wr_buf_sel)) begin
              spm_dma_error_r      <= 1'b1;
              spm_dma_error_code_r <= DMA_ERR_WR_BUF_SEL;
            end else begin
              if (dma_spm_wr_row_idx == '0) begin
                act_buf_ready_r[dma_spm_wr_buf_sel] <= 1'b0;
              end
              if (dma_spm_wr_last) begin
                act_buf_ready_r[dma_spm_wr_buf_sel] <= 1'b1;
              end
            end
          end
          2'b01: begin
            if (!buf_index_legal(dma_spm_wr_buf_sel)) begin
              spm_dma_error_r      <= 1'b1;
              spm_dma_error_code_r <= DMA_ERR_WR_BUF_SEL;
            end else begin
              if (dma_spm_wr_row_idx == '0) begin
                wgt_buf_ready_r[dma_spm_wr_buf_sel] <= 1'b0;
              end
              if (dma_spm_wr_last) begin
                wgt_buf_ready_r[dma_spm_wr_buf_sel] <= 1'b1;
              end
            end
          end
          default: begin
            spm_dma_error_r      <= 1'b1;
            spm_dma_error_code_r <= DMA_ERR_WR_TYPE;
          end
        endcase
      end

      if (dma_spm_rd_req_valid && dma_spm_rd_req_ready) begin
        if (!single_out_buf_legal(dma_spm_rd_buf_sel)) begin
          spm_dma_error_r      <= 1'b1;
          spm_dma_error_code_r <= DMA_ERR_RD_BUF_SEL;
        end else if (!out_buf_readable_r[0]) begin
          spm_dma_error_r      <= 1'b1;
          spm_dma_error_code_r <= DMA_ERR_OUT_NOT_READY;
        end else begin
          dma_spm_rd_data_valid <= 1'b1;
          dma_spm_rd_last       <= &dma_spm_rd_row_idx;
        end
      end

      if (spm_npu_vec_ready) begin
        if (!buf_index_legal(spm_npu_act_buf_sel)) begin
          spm_npu_error_r      <= 1'b1;
          spm_npu_error_code_r <= NPU_ERR_ACT_BUF_SEL;
        end else if (!buf_index_legal(spm_npu_wgt_buf_sel)) begin
          spm_npu_error_r      <= 1'b1;
          spm_npu_error_code_r <= NPU_ERR_WGT_BUF_SEL;
        end else if (spm_npu_k_idx >= ARRAY_K_TILE) begin
          spm_npu_error_r      <= 1'b1;
          spm_npu_error_code_r <= NPU_ERR_K_IDX;
        end
      end

      if (npu_spm_out_valid && npu_spm_out_ready) begin
        if (!single_out_buf_legal(npu_spm_out_buf_sel)) begin
          spm_npu_error_r      <= 1'b1;
          spm_npu_error_code_r <= NPU_ERR_OUT_BUF_SEL;
        end else if (npu_spm_out_last) begin
          out_buf_readable_r[0] <= 1'b1;
        end
      end
    end
  end

endmodule

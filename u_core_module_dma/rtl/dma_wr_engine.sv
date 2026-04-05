module dma_wr_engine (
  input  logic                                 clk,
  input  logic                                 rst_n,
  input  logic                                 start_valid,
  input  logic [u_core_pkg::DMA_DESC_W-1:0]    start_desc,
  input  logic                                 local_rd_req_ready,
  input  logic                                 local_rd_data_valid,
  output logic                                 local_rd_data_ready,
  input  logic [u_core_pkg::AXI_DATA_W-1:0]    local_rd_data,
  input  logic                                 local_rd_last,
  output logic                                 m_axi_awvalid,
  input  logic                                 m_axi_awready,
  output logic [u_core_pkg::AXI_ADDR_W-1:0]    m_axi_awaddr,
  output logic [7:0]                           m_axi_awlen,
  output logic [2:0]                           m_axi_awsize,
  output logic [1:0]                           m_axi_awburst,
  output logic                                 m_axi_wvalid,
  input  logic                                 m_axi_wready,
  output logic [u_core_pkg::AXI_DATA_W-1:0]    m_axi_wdata,
  output logic [u_core_pkg::AXI_STRB_W-1:0]    m_axi_wstrb,
  output logic                                 m_axi_wlast,
  input  logic                                 m_axi_bvalid,
  output logic                                 m_axi_bready,
  input  logic [1:0]                           m_axi_bresp,
  output logic                                 engine_busy,
  output logic                                 engine_ready,
  output logic                                 done_pulse,
  output logic                                 beat_pulse,
  output logic                                 error_pulse,
  output logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] error_code,
  output logic                                 local_rd_req_valid,
  output logic [u_core_pkg::BUF_SEL_W-1:0]     local_rd_buf_sel,
  output logic [u_core_pkg::DMA_SPM_ROW_W-1:0] local_rd_row_idx
);

  import u_core_pkg::*;

  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_AXI_WR = 8'h0A;

  localparam logic [2:0] WR_IDLE       = 3'd0;
  localparam logic [2:0] WR_REQ_LOCAL  = 3'd1;
  localparam logic [2:0] WR_WAIT_LOCAL = 3'd2;
  localparam logic [2:0] WR_SEND_AW    = 3'd3;
  localparam logic [2:0] WR_SEND_W     = 3'd4;
  localparam logic [2:0] WR_WAIT_B     = 3'd5;

  logic [2:0]              state_r;
  logic [DMA_DESC_W-1:0]   active_desc_r;
  logic [15:0]             row_idx_r;
  logic [AXI_DATA_W-1:0]   local_data_buf_r;
  logic [AXI_ADDR_W-1:0]   rd_ext_addr_unused;
  logic [AXI_ADDR_W-1:0]   wr_ext_addr_w;
  logic [DMA_SPM_ROW_W-1:0] local_row_idx_w;
  logic                    last_row_w;

  function automatic [AXI_STRB_W-1:0] gen_strb(input logic [15:0] row_len_bytes);
    integer i;
    begin
      gen_strb = '0;
      for (i = 0; i < AXI_STRB_W; i = i + 1) begin
        if (i < row_len_bytes) begin
          gen_strb[i] = 1'b1;
        end
      end
    end
  endfunction

  dma_addr_gen u_dma_addr_gen (
    .desc_bus      (active_desc_r),
    .row_idx       (row_idx_r),
    .rd_ext_addr   (rd_ext_addr_unused),
    .wr_ext_addr   (wr_ext_addr_w),
    .local_row_idx (local_row_idx_w),
    .last_row      (last_row_w)
  );

  assign engine_busy        = (state_r != WR_IDLE);
  assign engine_ready       = (state_r == WR_IDLE);
  assign local_rd_req_valid = (state_r == WR_REQ_LOCAL);
  assign local_rd_buf_sel   = active_desc_r[131:130];
  assign local_rd_row_idx   = local_row_idx_w;
  assign local_rd_data_ready = (state_r == WR_WAIT_LOCAL);

  assign m_axi_awvalid      = (state_r == WR_SEND_AW);
  assign m_axi_awaddr       = wr_ext_addr_w;
  assign m_axi_awlen        = 8'h00;
  assign m_axi_awsize       = 3'd6;
  assign m_axi_awburst      = 2'b01;
  assign m_axi_wvalid       = (state_r == WR_SEND_W);
  assign m_axi_wdata        = local_data_buf_r;
  assign m_axi_wstrb        = gen_strb(active_desc_r[81:66]);
  assign m_axi_wlast        = 1'b1;
  assign m_axi_bready       = (state_r == WR_WAIT_B);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_r         <= WR_IDLE;
      active_desc_r   <= '0;
      row_idx_r       <= '0;
      local_data_buf_r <= '0;
      done_pulse      <= 1'b0;
      beat_pulse      <= 1'b0;
      error_pulse     <= 1'b0;
      error_code      <= '0;
    end else begin
      done_pulse  <= 1'b0;
      beat_pulse  <= 1'b0;
      error_pulse <= 1'b0;
      error_code  <= '0;

      case (state_r)
        WR_IDLE: begin
          if (start_valid) begin
            active_desc_r <= start_desc;
            row_idx_r     <= 16'h0000;
            state_r       <= WR_REQ_LOCAL;
          end
        end

        WR_REQ_LOCAL: begin
          if (local_rd_req_ready) begin
            state_r <= WR_WAIT_LOCAL;
          end
        end

        WR_WAIT_LOCAL: begin
          if (local_rd_data_valid) begin
            local_data_buf_r <= local_rd_data;
            state_r          <= WR_SEND_AW;
          end
        end

        WR_SEND_AW: begin
          if (m_axi_awready) begin
            state_r <= WR_SEND_W;
          end
        end

        WR_SEND_W: begin
          if (m_axi_wready) begin
            state_r <= WR_WAIT_B;
          end
        end

        WR_WAIT_B: begin
          if (m_axi_bvalid) begin
            if (m_axi_bresp != 2'b00) begin
              state_r     <= WR_IDLE;
              error_pulse <= 1'b1;
              error_code  <= DMA_ERR_AXI_WR;
            end else begin
              beat_pulse <= 1'b1;
              if (last_row_w || local_rd_last) begin
                state_r    <= WR_IDLE;
                done_pulse <= 1'b1;
              end else begin
                row_idx_r <= row_idx_r + 1'b1;
                state_r   <= WR_REQ_LOCAL;
              end
            end
          end
        end

        default: begin
          state_r <= WR_IDLE;
        end
      endcase
    end
  end

endmodule

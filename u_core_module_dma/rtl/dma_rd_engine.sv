module dma_rd_engine (
  input  logic                                 clk,
  input  logic                                 rst_n,
  input  logic                                 start_valid,
  input  logic [u_core_pkg::DMA_DESC_W-1:0]    start_desc,
  output logic                                 m_axi_arvalid,
  input  logic                                 m_axi_arready,
  output logic [u_core_pkg::AXI_ADDR_W-1:0]    m_axi_araddr,
  output logic [7:0]                           m_axi_arlen,
  output logic [2:0]                           m_axi_arsize,
  output logic [1:0]                           m_axi_arburst,
  input  logic                                 m_axi_rvalid,
  output logic                                 m_axi_rready,
  input  logic [u_core_pkg::AXI_DATA_W-1:0]    m_axi_rdata,
  input  logic [1:0]                           m_axi_rresp,
  input  logic                                 m_axi_rlast,
  input  logic                                 local_wr_ready,
  output logic                                 engine_busy,
  output logic                                 engine_ready,
  output logic                                 done_pulse,
  output logic                                 beat_pulse,
  output logic                                 error_pulse,
  output logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] error_code,
  output logic                                 local_wr_valid,
  output logic [1:0]                           local_wr_type,
  output logic [u_core_pkg::BUF_SEL_W-1:0]     local_wr_buf_sel,
  output logic [u_core_pkg::DMA_SPM_ROW_W-1:0] local_wr_row_idx,
  output logic [u_core_pkg::AXI_DATA_W-1:0]    local_wr_data,
  output logic [u_core_pkg::AXI_STRB_W-1:0]    local_wr_strb,
  output logic                                 local_wr_last
);

  import u_core_pkg::*;

  localparam logic [DMA_ERROR_CODE_W-1:0] DMA_ERR_AXI_RD = 8'h09;

  localparam logic [1:0] RD_IDLE      = 2'd0;
  localparam logic [1:0] RD_SEND_AR   = 2'd1;
  localparam logic [1:0] RD_WAIT_R    = 2'd2;
  localparam logic [1:0] RD_WRITE_SPM = 2'd3;

  logic [1:0]             state_r;
  logic [DMA_DESC_W-1:0]  active_desc_r;
  logic [15:0]            row_idx_r;
  logic [AXI_DATA_W-1:0]  rdata_buf_r;
  logic [AXI_ADDR_W-1:0]  rd_ext_addr_w;
  logic [AXI_ADDR_W-1:0]  wr_ext_addr_unused;
  logic [DMA_SPM_ROW_W-1:0] local_row_idx_w;
  logic                   last_row_w;

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
    .rd_ext_addr   (rd_ext_addr_w),
    .wr_ext_addr   (wr_ext_addr_unused),
    .local_row_idx (local_row_idx_w),
    .last_row      (last_row_w)
  );

  assign engine_busy      = (state_r != RD_IDLE);
  assign engine_ready     = (state_r == RD_IDLE);
  assign m_axi_arvalid    = (state_r == RD_SEND_AR);
  assign m_axi_araddr     = rd_ext_addr_w;
  assign m_axi_arlen      = 8'h00;
  assign m_axi_arsize     = 3'd6;
  assign m_axi_arburst    = 2'b01;
  assign m_axi_rready     = (state_r == RD_WAIT_R);
  assign local_wr_valid   = (state_r == RD_WRITE_SPM);
  assign local_wr_type    = active_desc_r[1:0];
  assign local_wr_buf_sel = active_desc_r[131:130];
  assign local_wr_row_idx = local_row_idx_w;
  assign local_wr_data    = rdata_buf_r;
  assign local_wr_strb    = gen_strb(active_desc_r[81:66]);
  assign local_wr_last    = last_row_w;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_r        <= RD_IDLE;
      active_desc_r  <= '0;
      row_idx_r      <= '0;
      rdata_buf_r    <= '0;
      done_pulse     <= 1'b0;
      beat_pulse     <= 1'b0;
      error_pulse    <= 1'b0;
      error_code     <= '0;
    end else begin
      done_pulse  <= 1'b0;
      beat_pulse  <= 1'b0;
      error_pulse <= 1'b0;
      error_code  <= '0;

      case (state_r)
        RD_IDLE: begin
          if (start_valid) begin
            active_desc_r <= start_desc;
            row_idx_r     <= 16'h0000;
            state_r       <= RD_SEND_AR;
          end
        end

        RD_SEND_AR: begin
          if (m_axi_arready) begin
            state_r <= RD_WAIT_R;
          end
        end

        RD_WAIT_R: begin
          if (m_axi_rvalid) begin
            if ((m_axi_rresp != 2'b00) || !m_axi_rlast) begin
              state_r     <= RD_IDLE;
              error_pulse <= 1'b1;
              error_code  <= DMA_ERR_AXI_RD;
            end else begin
              rdata_buf_r <= m_axi_rdata;
              state_r     <= RD_WRITE_SPM;
            end
          end
        end

        RD_WRITE_SPM: begin
          if (local_wr_ready) begin
            beat_pulse <= 1'b1;
            if (last_row_w) begin
              state_r    <= RD_IDLE;
              done_pulse <= 1'b1;
            end else begin
              row_idx_r <= row_idx_r + 1'b1;
              state_r   <= RD_SEND_AR;
            end
          end
        end

        default: begin
          state_r <= RD_IDLE;
        end
      endcase

    end
  end

endmodule

module dma_csr_if (
  input  logic                                clk,
  input  logic                                rst_n,
  input  logic                                dma_axil_awvalid,
  output logic                                dma_axil_awready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  dma_axil_awaddr,
  input  logic [2:0]                          dma_axil_awprot,
  input  logic                                dma_axil_wvalid,
  output logic                                dma_axil_wready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  dma_axil_wdata,
  input  logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] dma_axil_wstrb,
  output logic                                dma_axil_bvalid,
  input  logic                                dma_axil_bready,
  output logic [1:0]                          dma_axil_bresp,
  input  logic                                dma_axil_arvalid,
  output logic                                dma_axil_arready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  dma_axil_araddr,
  input  logic [2:0]                          dma_axil_arprot,
  output logic                                dma_axil_rvalid,
  input  logic                                dma_axil_rready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  dma_axil_rdata,
  output logic [1:0]                          dma_axil_rresp,
  output logic                                stage_we,
  output logic [3:0]                          stage_addr,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  stage_wdata,
  output logic                                submit_pulse,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  cfg0_word,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  src_addr_word,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  dst_addr_word,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  row_cfg_word,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  stride_cfg_word,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  local_cfg_word,
  input  logic                                dma_busy,
  input  logic                                dma_done,
  input  logic                                dma_error,
  input  logic                                dma_fifo_empty,
  input  logic                                dma_fifo_full,
  input  logic [u_core_pkg::DMA_FIFO_LEVEL_W-1:0] dma_fifo_level,
  input  logic [31:0]                         dma_done_count,
  input  logic [31:0]                         dma_rd_beat_count,
  input  logic [31:0]                         dma_wr_beat_count,
  input  logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] dma_error_code
);

  import u_core_pkg::*;

  logic aw_pending_r;
  logic w_pending_r;
  logic [AXIL_ADDR_W-1:0] awaddr_r;
  logic [AXIL_DATA_W-1:0] wdata_r;
  logic [(AXIL_DATA_W/8)-1:0] wstrb_r;
  logic bvalid_r;
  logic rvalid_r;
  logic [AXIL_DATA_W-1:0] rdata_r;

  function automatic [AXIL_DATA_W-1:0] read_mux(input logic [AXIL_ADDR_W-1:0] addr);
    begin
      case (addr[7:2])
        6'h00: read_mux = cfg0_word;
        6'h01: read_mux = src_addr_word;
        6'h02: read_mux = dst_addr_word;
        6'h03: read_mux = row_cfg_word;
        6'h04: read_mux = 32'h0000_0000;
        6'h05: read_mux = 32'h0000_0000;
        6'h06: read_mux = 32'h0000_0000;
        6'h07: read_mux = {29'h0, dma_error, dma_done, dma_busy};
        6'h08: read_mux = {27'h0, dma_fifo_level, dma_fifo_full, dma_fifo_empty};
        6'h09: read_mux = dma_done_count;
        6'h0A: read_mux = dma_rd_beat_count;
        6'h0B: read_mux = dma_wr_beat_count;
        6'h0C: read_mux = {24'h0, dma_error_code};
        default: read_mux = 32'h0000_0000;
      endcase
    end
  endfunction

  assign dma_axil_awready = ~aw_pending_r;
  assign dma_axil_wready  = ~w_pending_r;
  assign dma_axil_bvalid  = bvalid_r;
  assign dma_axil_bresp   = 2'b00;
  assign dma_axil_arready = ~rvalid_r;
  assign dma_axil_rvalid  = rvalid_r;
  assign dma_axil_rdata   = rdata_r;
  assign dma_axil_rresp   = 2'b00;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aw_pending_r <= 1'b0;
      w_pending_r  <= 1'b0;
      awaddr_r     <= '0;
      wdata_r      <= '0;
      wstrb_r      <= '0;
      bvalid_r     <= 1'b0;
      rvalid_r     <= 1'b0;
      rdata_r      <= '0;
      stage_we     <= 1'b0;
      stage_addr   <= '0;
      stage_wdata  <= '0;
      submit_pulse <= 1'b0;
    end else begin
      stage_we     <= 1'b0;
      stage_addr   <= '0;
      stage_wdata  <= '0;
      submit_pulse <= 1'b0;

      if (!aw_pending_r && dma_axil_awvalid) begin
        aw_pending_r <= 1'b1;
        awaddr_r     <= dma_axil_awaddr;
      end

      if (!w_pending_r && dma_axil_wvalid) begin
        w_pending_r <= 1'b1;
        wdata_r     <= dma_axil_wdata;
        wstrb_r     <= dma_axil_wstrb;
      end

      if (aw_pending_r && w_pending_r && !bvalid_r) begin
        if (|wstrb_r) begin
          case (awaddr_r[7:2])
            6'h00,
            6'h01,
            6'h02,
            6'h03: begin
              stage_we    <= 1'b1;
              stage_addr  <= awaddr_r[5:2];
              stage_wdata <= wdata_r;
            end
            6'h06: begin
              submit_pulse <= wdata_r[0];
            end
            default: begin end
          endcase
        end
        aw_pending_r <= 1'b0;
        w_pending_r  <= 1'b0;
        bvalid_r     <= 1'b1;
      end

      if (bvalid_r && dma_axil_bready) begin
        bvalid_r <= 1'b0;
      end

      if (!rvalid_r && dma_axil_arvalid) begin
        rvalid_r <= 1'b1;
        rdata_r  <= read_mux(dma_axil_araddr);
      end else if (rvalid_r && dma_axil_rready) begin
        rvalid_r <= 1'b0;
      end
    end
  end

endmodule

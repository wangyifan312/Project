module u_core_sys_csr (
  input  logic                                clk,
  input  logic                                rst_n,
  input  logic                                s_axil_awvalid,
  output logic                                s_axil_awready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  s_axil_awaddr,
  input  logic [2:0]                          s_axil_awprot,
  input  logic                                s_axil_wvalid,
  output logic                                s_axil_wready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  s_axil_wdata,
  input  logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] s_axil_wstrb,
  output logic                                s_axil_bvalid,
  input  logic                                s_axil_bready,
  output logic [1:0]                          s_axil_bresp,
  input  logic                                s_axil_arvalid,
  output logic                                s_axil_arready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  s_axil_araddr,
  input  logic [2:0]                          s_axil_arprot,
  output logic                                s_axil_rvalid,
  input  logic                                s_axil_rready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  s_axil_rdata,
  output logic [1:0]                          s_axil_rresp,
  input  logic                                cpu_trap,
  input  logic                                dma_busy,
  input  logic                                dma_done,
  input  logic                                dma_error,
  input  logic                                npu_armed,
  input  logic                                npu_busy,
  input  logic                                npu_done,
  input  logic                                npu_error,
  input  logic                                spm_dma_error,
  input  logic                                spm_npu_error,
  input  logic [31:0]                         dma_done_count,
  input  logic [31:0]                         dma_rd_beat_count,
  input  logic [31:0]                         dma_wr_beat_count,
  input  logic [31:0]                         npu_stall_cycles,
  input  logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] dma_error_code,
  input  logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] npu_error_code,
  input  logic [u_core_pkg::DMA_ERROR_CODE_W-1:0] spm_dma_error_code,
  input  logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] spm_npu_error_code
);

  import u_core_pkg::*;

  logic aw_pending_r;
  logic w_pending_r;
  logic bvalid_r;
  logic rvalid_r;
  logic [AXIL_DATA_W-1:0] rdata_r;

  function automatic [AXIL_DATA_W-1:0] read_mux(input logic [AXIL_ADDR_W-1:0] addr);
    begin
      case (addr[7:2])
        6'h00: read_mux = {
          22'h0,
          spm_npu_error,
          spm_dma_error,
          npu_error,
          npu_done,
          npu_busy,
          npu_armed,
          dma_error,
          dma_done,
          dma_busy,
          cpu_trap
        };
        6'h01: read_mux = dma_done_count;
        6'h02: read_mux = dma_rd_beat_count;
        6'h03: read_mux = dma_wr_beat_count;
        6'h04: read_mux = npu_stall_cycles;
        6'h05: read_mux = {spm_npu_error_code, spm_dma_error_code, npu_error_code, dma_error_code};
        default: read_mux = 32'h0000_0000;
      endcase
    end
  endfunction

  assign s_axil_awready = ~aw_pending_r;
  assign s_axil_wready  = ~w_pending_r;
  assign s_axil_bvalid  = bvalid_r;
  assign s_axil_bresp   = 2'b00;
  assign s_axil_arready = ~rvalid_r;
  assign s_axil_rvalid  = rvalid_r;
  assign s_axil_rdata   = rdata_r;
  assign s_axil_rresp   = 2'b00;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aw_pending_r <= 1'b0;
      w_pending_r  <= 1'b0;
      bvalid_r     <= 1'b0;
      rvalid_r     <= 1'b0;
      rdata_r      <= '0;
    end else begin
      if (!aw_pending_r && s_axil_awvalid) begin
        aw_pending_r <= 1'b1;
      end

      if (!w_pending_r && s_axil_wvalid) begin
        w_pending_r <= 1'b1;
      end

      if (aw_pending_r && w_pending_r && !bvalid_r) begin
        aw_pending_r <= 1'b0;
        w_pending_r  <= 1'b0;
        bvalid_r     <= 1'b1;
      end

      if (bvalid_r && s_axil_bready) begin
        bvalid_r <= 1'b0;
      end

      if (!rvalid_r && s_axil_arvalid) begin
        rvalid_r <= 1'b1;
        rdata_r  <= read_mux(s_axil_araddr);
      end else if (rvalid_r && s_axil_rready) begin
        rvalid_r <= 1'b0;
      end
    end
  end

endmodule

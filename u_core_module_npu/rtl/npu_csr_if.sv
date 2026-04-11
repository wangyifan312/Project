module npu_csr_if (
  input  logic                                clk,
  input  logic                                rst_n,
  input  logic                                npu_axil_awvalid,
  output logic                                npu_axil_awready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  npu_axil_awaddr,
  input  logic [2:0]                          npu_axil_awprot,
  input  logic                                npu_axil_wvalid,
  output logic                                npu_axil_wready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  npu_axil_wdata,
  input  logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] npu_axil_wstrb,
  output logic                                npu_axil_bvalid,
  input  logic                                npu_axil_bready,
  output logic [1:0]                          npu_axil_bresp,
  input  logic                                npu_axil_arvalid,
  output logic                                npu_axil_arready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  npu_axil_araddr,
  input  logic [2:0]                          npu_axil_arprot,
  output logic                                npu_axil_rvalid,
  input  logic                                npu_axil_rready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  npu_axil_rdata,
  output logic [1:0]                          npu_axil_rresp,

  output logic [3:0]                          npu_mode,
  output logic [7:0]                          ktile_cfg,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    act_buf_sel,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    wgt_buf_sel,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    out_buf_sel,
  output logic [7:0]                          quant_shift,
  output logic [15:0]                         quant_zero_point,
  output logic                                relu_en,
  output logic                                start_pulse,

  input  logic                                npu_armed,
  input  logic                                npu_busy,
  input  logic                                npu_done,
  input  logic                                npu_error,
  input  logic [31:0]                         npu_stall_cycles,
  input  logic [31:0]                         npu_busy_cycles,
  input  logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] npu_error_code
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
        6'h00: read_mux = {27'h0, relu_en, npu_mode};
        6'h01: read_mux = {26'h0, out_buf_sel, wgt_buf_sel, act_buf_sel};
        6'h02: read_mux = {24'h0, ktile_cfg};
        6'h03: read_mux = {8'h0, quant_zero_point, quant_shift};
        6'h04: read_mux = 32'h0000_0000;
        6'h05: read_mux = {28'h0, npu_error, npu_done, npu_busy, npu_armed};
        6'h06: read_mux = npu_stall_cycles;
        6'h07: read_mux = npu_busy_cycles;
        6'h08: read_mux = {24'h0, npu_error_code};
        default: read_mux = 32'h0000_0000;
      endcase
    end
  endfunction

  assign npu_axil_awready = ~aw_pending_r;
  assign npu_axil_wready  = ~w_pending_r;
  assign npu_axil_bvalid  = bvalid_r;
  assign npu_axil_bresp   = 2'b00;
  assign npu_axil_arready = ~rvalid_r;
  assign npu_axil_rvalid  = rvalid_r;
  assign npu_axil_rdata   = rdata_r;
  assign npu_axil_rresp   = 2'b00;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aw_pending_r     <= 1'b0;
      w_pending_r      <= 1'b0;
      awaddr_r         <= '0;
      wdata_r          <= '0;
      wstrb_r          <= '0;
      bvalid_r         <= 1'b0;
      rvalid_r         <= 1'b0;
      rdata_r          <= '0;
      npu_mode         <= 4'h0;
      ktile_cfg        <= ARRAY_K_TILE[7:0];
      act_buf_sel      <= '0;
      wgt_buf_sel      <= '0;
      out_buf_sel      <= '0;
      quant_shift      <= 8'h00;
      quant_zero_point <= 16'h0000;
      relu_en          <= 1'b0;
      start_pulse      <= 1'b0;
    end else begin
      start_pulse <= 1'b0;

      if (!aw_pending_r && npu_axil_awvalid) begin
        aw_pending_r <= 1'b1;
        awaddr_r     <= npu_axil_awaddr;
      end

      if (!w_pending_r && npu_axil_wvalid) begin
        w_pending_r <= 1'b1;
        wdata_r     <= npu_axil_wdata;
        wstrb_r     <= npu_axil_wstrb;
      end

      if (aw_pending_r && w_pending_r && !bvalid_r) begin
        if (|wstrb_r) begin
          case (awaddr_r[7:2])
            6'h00: begin
              npu_mode <= wdata_r[3:0];
              relu_en  <= wdata_r[4];
            end
            6'h01: begin
              act_buf_sel <= wdata_r[1:0];
              wgt_buf_sel <= wdata_r[3:2];
              out_buf_sel <= wdata_r[5:4];
            end
            6'h02: begin
              ktile_cfg <= wdata_r[7:0];
            end
            6'h03: begin
              quant_shift      <= wdata_r[7:0];
              quant_zero_point <= wdata_r[23:8];
            end
            6'h04: begin
              start_pulse <= wdata_r[0];
            end
            default: begin end
          endcase
        end
        aw_pending_r <= 1'b0;
        w_pending_r  <= 1'b0;
        bvalid_r     <= 1'b1;
      end

      if (bvalid_r && npu_axil_bready) begin
        bvalid_r <= 1'b0;
      end

      if (!rvalid_r && npu_axil_arvalid) begin
        rvalid_r <= 1'b1;
        rdata_r  <= read_mux(npu_axil_araddr);
      end else if (rvalid_r && npu_axil_rready) begin
        rvalid_r <= 1'b0;
      end
    end
  end

endmodule

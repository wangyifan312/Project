module u_core_axil_mem #(
  parameter logic [31:0] BASE_ADDR  = 32'h0000_0000,
  parameter integer      SIZE_BYTES = 4096,
  parameter bit          READ_ONLY  = 1'b0
) (
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
  output logic [1:0]                          s_axil_rresp
);

  import u_core_pkg::*;

  localparam integer WORD_COUNT = SIZE_BYTES / (AXIL_DATA_W / 8);
  localparam integer ADDR_LSB   = 2;

  logic aw_pending_r;
  logic w_pending_r;
  logic [AXIL_ADDR_W-1:0] awaddr_r;
  logic [AXIL_DATA_W-1:0] wdata_r;
  logic [(AXIL_DATA_W/8)-1:0] wstrb_r;
  logic bvalid_r;
  logic rvalid_r;
  logic [AXIL_DATA_W-1:0] rdata_r;

  logic [AXIL_DATA_W-1:0] mem_r [0:WORD_COUNT-1];

  integer idx;
  integer byte_idx;
  integer word_idx;

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
      awaddr_r     <= '0;
      wdata_r      <= '0;
      wstrb_r      <= '0;
      bvalid_r     <= 1'b0;
      rvalid_r     <= 1'b0;
      rdata_r      <= '0;
      for (idx = 0; idx < WORD_COUNT; idx = idx + 1) begin
        mem_r[idx] <= '0;
      end
    end else begin
      if (!aw_pending_r && s_axil_awvalid) begin
        aw_pending_r <= 1'b1;
        awaddr_r     <= s_axil_awaddr;
      end

      if (!w_pending_r && s_axil_wvalid) begin
        w_pending_r <= 1'b1;
        wdata_r     <= s_axil_wdata;
        wstrb_r     <= s_axil_wstrb;
      end

      if (aw_pending_r && w_pending_r && !bvalid_r) begin
        word_idx = (awaddr_r - BASE_ADDR) >> ADDR_LSB;
        if (!READ_ONLY && (word_idx >= 0) && (word_idx < WORD_COUNT)) begin
          for (byte_idx = 0; byte_idx < (AXIL_DATA_W/8); byte_idx = byte_idx + 1) begin
            if (wstrb_r[byte_idx]) begin
              mem_r[word_idx][byte_idx*8 +: 8] <= wdata_r[byte_idx*8 +: 8];
            end
          end
        end
        aw_pending_r <= 1'b0;
        w_pending_r  <= 1'b0;
        bvalid_r     <= 1'b1;
      end

      if (bvalid_r && s_axil_bready) begin
        bvalid_r <= 1'b0;
      end

      if (!rvalid_r && s_axil_arvalid) begin
        word_idx = (s_axil_araddr - BASE_ADDR) >> ADDR_LSB;
        rvalid_r <= 1'b1;
        if ((word_idx >= 0) && (word_idx < WORD_COUNT)) begin
          rdata_r <= mem_r[word_idx];
        end else begin
          rdata_r <= '0;
        end
      end else if (rvalid_r && s_axil_rready) begin
        rvalid_r <= 1'b0;
      end
    end
  end

endmodule

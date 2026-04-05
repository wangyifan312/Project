interface dma_axi_mem_if (
  input logic clk,
  input logic rst_n
);

  import u_core_pkg::*;

  logic                   awvalid;
  logic                   awready;
  logic [AXI_ADDR_W-1:0]  awaddr;
  logic [7:0]             awlen;
  logic [2:0]             awsize;
  logic [1:0]             awburst;
  logic                   wvalid;
  logic                   wready;
  logic [AXI_DATA_W-1:0]  wdata;
  logic [AXI_STRB_W-1:0]  wstrb;
  logic                   wlast;
  logic                   bvalid;
  logic                   bready;
  logic [1:0]             bresp;
  logic                   arvalid;
  logic                   arready;
  logic [AXI_ADDR_W-1:0]  araddr;
  logic [7:0]             arlen;
  logic [2:0]             arsize;
  logic [1:0]             arburst;
  logic                   rvalid;
  logic                   rready;
  logic [AXI_DATA_W-1:0]  rdata;
  logic [1:0]             rresp;
  logic                   rlast;

  clocking drv_cb @(posedge clk);
    default input #1step output #1step;
    input  awvalid, awaddr, awlen, awsize, awburst;
    input  wvalid, wdata, wstrb, wlast;
    input  bready;
    input  arvalid, araddr, arlen, arsize, arburst;
    input  rready;
    output awready, wready, bvalid, bresp;
    output arready, rvalid, rdata, rresp, rlast;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step output #1step;
    input awvalid, awready, awaddr, awlen, awsize, awburst;
    input wvalid, wready, wdata, wstrb, wlast;
    input bvalid, bready, bresp;
    input arvalid, arready, araddr, arlen, arsize, arburst;
    input rvalid, rready, rdata, rresp, rlast;
  endclocking

  task automatic init_slave();
    awready = 1'b0;
    wready  = 1'b0;
    bvalid  = 1'b0;
    bresp   = '0;
    arready = 1'b0;
    rvalid  = 1'b0;
    rdata   = '0;
    rresp   = '0;
    rlast   = 1'b0;
  endtask

endinterface

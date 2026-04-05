interface dma_axil_if (
  input logic clk,
  input logic rst_n
);

  import u_core_pkg::*;

  logic                     awvalid;
  logic                     awready;
  logic [AXIL_ADDR_W-1:0]   awaddr;
  logic [2:0]               awprot;
  logic                     wvalid;
  logic                     wready;
  logic [AXIL_DATA_W-1:0]   wdata;
  logic [(AXIL_DATA_W/8)-1:0] wstrb;
  logic                     bvalid;
  logic                     bready;
  logic [1:0]               bresp;
  logic                     arvalid;
  logic                     arready;
  logic [AXIL_ADDR_W-1:0]   araddr;
  logic [2:0]               arprot;
  logic                     rvalid;
  logic                     rready;
  logic [AXIL_DATA_W-1:0]   rdata;
  logic [1:0]               rresp;

  clocking drv_cb @(posedge clk);
    default input #1step output #1step;
    output awvalid, awaddr, awprot, wvalid, wdata, wstrb, bready;
    output arvalid, araddr, arprot, rready;
    input  awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step output #1step;
    input awvalid, awready, awaddr, awprot;
    input wvalid, wready, wdata, wstrb;
    input bvalid, bready, bresp;
    input arvalid, arready, araddr, arprot;
    input rvalid, rready, rdata, rresp;
  endclocking

  task automatic init_master();
    awvalid = 1'b0;
    awaddr  = '0;
    awprot  = '0;
    wvalid  = 1'b0;
    wdata   = '0;
    wstrb   = '0;
    bready  = 1'b0;
    arvalid = 1'b0;
    araddr  = '0;
    arprot  = '0;
    rready  = 1'b0;
  endtask

endinterface

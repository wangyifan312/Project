module cpu_subsys #(
  parameter logic [31:0] PROGADDR_RESET = u_core_pkg::PROGADDR_RESET,
  parameter logic [31:0] PROGADDR_IRQ   = u_core_pkg::PROGADDR_IRQ,
  parameter logic [31:0] STACKADDR      = u_core_pkg::STACKADDR
) (
  input  logic                           clk,
  input  logic                           rst_n,
  output logic                           trap,

  output logic                           cpu_axil_awvalid,
  input  logic                           cpu_axil_awready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0] cpu_axil_awaddr,
  output logic [2:0]                     cpu_axil_awprot,
  output logic                           cpu_axil_wvalid,
  input  logic                           cpu_axil_wready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0] cpu_axil_wdata,
  output logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] cpu_axil_wstrb,
  input  logic                           cpu_axil_bvalid,
  output logic                           cpu_axil_bready,
  input  logic [1:0]                     cpu_axil_bresp,
  output logic                           cpu_axil_arvalid,
  input  logic                           cpu_axil_arready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0] cpu_axil_araddr,
  output logic [2:0]                     cpu_axil_arprot,
  input  logic                           cpu_axil_rvalid,
  output logic                           cpu_axil_rready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0] cpu_axil_rdata,
  input  logic [1:0]                     cpu_axil_rresp,

  input  logic [31:0]                    irq,
  output logic [31:0]                    eoi
);

  import u_core_pkg::*;

  logic        pcpi_valid_unused;
  logic [31:0] pcpi_insn_unused;
  logic [31:0] pcpi_rs1_unused;
  logic [31:0] pcpi_rs2_unused;
  logic        trace_valid_unused;
  logic [35:0] trace_data_unused;

  picorv32_axi #(
    .ENABLE_PCPI      (1'b0),
    .ENABLE_IRQ       (1'b1),
    .PROGADDR_RESET   (PROGADDR_RESET),
    .PROGADDR_IRQ     (PROGADDR_IRQ),
    .STACKADDR        (STACKADDR)
  ) u_picorv32_axi (
    .clk              (clk),
    .resetn           (rst_n),
    .trap             (trap),
    .mem_axi_awvalid  (cpu_axil_awvalid),
    .mem_axi_awready  (cpu_axil_awready),
    .mem_axi_awaddr   (cpu_axil_awaddr),
    .mem_axi_awprot   (cpu_axil_awprot),
    .mem_axi_wvalid   (cpu_axil_wvalid),
    .mem_axi_wready   (cpu_axil_wready),
    .mem_axi_wdata    (cpu_axil_wdata),
    .mem_axi_wstrb    (cpu_axil_wstrb),
    .mem_axi_bvalid   (cpu_axil_bvalid),
    .mem_axi_bready   (cpu_axil_bready),
    .mem_axi_arvalid  (cpu_axil_arvalid),
    .mem_axi_arready  (cpu_axil_arready),
    .mem_axi_araddr   (cpu_axil_araddr),
    .mem_axi_arprot   (cpu_axil_arprot),
    .mem_axi_rvalid   (cpu_axil_rvalid),
    .mem_axi_rready   (cpu_axil_rready),
    .mem_axi_rdata    (cpu_axil_rdata),
    .pcpi_valid       (pcpi_valid_unused),
    .pcpi_insn        (pcpi_insn_unused),
    .pcpi_rs1         (pcpi_rs1_unused),
    .pcpi_rs2         (pcpi_rs2_unused),
    .pcpi_wr          (1'b0),
    .pcpi_rd          (32'b0),
    .pcpi_wait        (1'b0),
    .pcpi_ready       (1'b0),
    .irq              (irq),
    .eoi              (eoi),
    .trace_valid      (trace_valid_unused),
    .trace_data       (trace_data_unused)
  );

endmodule

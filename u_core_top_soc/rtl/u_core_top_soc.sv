module u_core_top_soc (
  input  logic                           clk,
  input  logic                           rst_n,

  output logic                           dma_m_axi_awvalid,
  input  logic                           dma_m_axi_awready,
  output logic [u_core_pkg::AXI_ADDR_W-1:0] dma_m_axi_awaddr,
  output logic [7:0]                     dma_m_axi_awlen,
  output logic [2:0]                     dma_m_axi_awsize,
  output logic [1:0]                     dma_m_axi_awburst,
  output logic                           dma_m_axi_wvalid,
  input  logic                           dma_m_axi_wready,
  output logic [u_core_pkg::AXI_DATA_W-1:0] dma_m_axi_wdata,
  output logic [u_core_pkg::AXI_STRB_W-1:0] dma_m_axi_wstrb,
  output logic                           dma_m_axi_wlast,
  input  logic                           dma_m_axi_bvalid,
  output logic                           dma_m_axi_bready,
  input  logic [1:0]                     dma_m_axi_bresp,
  output logic                           dma_m_axi_arvalid,
  input  logic                           dma_m_axi_arready,
  output logic [u_core_pkg::AXI_ADDR_W-1:0] dma_m_axi_araddr,
  output logic [7:0]                     dma_m_axi_arlen,
  output logic [2:0]                     dma_m_axi_arsize,
  output logic [1:0]                     dma_m_axi_arburst,
  input  logic                           dma_m_axi_rvalid,
  output logic                           dma_m_axi_rready,
  input  logic [u_core_pkg::AXI_DATA_W-1:0] dma_m_axi_rdata,
  input  logic [1:0]                     dma_m_axi_rresp,
  input  logic                           dma_m_axi_rlast,

  output logic                           cpu_trap,
  output logic                           dma_busy,
  output logic                           dma_done,
  output logic                           dma_error,
  output logic                           npu_busy,
  output logic                           npu_done,
  output logic                           npu_error
);

  import u_core_pkg::*;

  logic                           cpu_axil_awvalid;
  logic                           cpu_axil_awready;
  logic [AXIL_ADDR_W-1:0]         cpu_axil_awaddr;
  logic [2:0]                     cpu_axil_awprot;
  logic                           cpu_axil_wvalid;
  logic                           cpu_axil_wready;
  logic [AXIL_DATA_W-1:0]         cpu_axil_wdata;
  logic [(AXIL_DATA_W/8)-1:0]     cpu_axil_wstrb;
  logic                           cpu_axil_bvalid;
  logic                           cpu_axil_bready;
  logic [1:0]                     cpu_axil_bresp;
  logic                           cpu_axil_arvalid;
  logic                           cpu_axil_arready;
  logic [AXIL_ADDR_W-1:0]         cpu_axil_araddr;
  logic [2:0]                     cpu_axil_arprot;
  logic                           cpu_axil_rvalid;
  logic                           cpu_axil_rready;
  logic [AXIL_DATA_W-1:0]         cpu_axil_rdata;
  logic [1:0]                     cpu_axil_rresp;

  logic                           dma_axil_awvalid;
  logic                           dma_axil_awready;
  logic [AXIL_ADDR_W-1:0]         dma_axil_awaddr;
  logic [2:0]                     dma_axil_awprot;
  logic                           dma_axil_wvalid;
  logic                           dma_axil_wready;
  logic [AXIL_DATA_W-1:0]         dma_axil_wdata;
  logic [(AXIL_DATA_W/8)-1:0]     dma_axil_wstrb;
  logic                           dma_axil_bvalid;
  logic                           dma_axil_bready;
  logic [1:0]                     dma_axil_bresp;
  logic                           dma_axil_arvalid;
  logic                           dma_axil_arready;
  logic [AXIL_ADDR_W-1:0]         dma_axil_araddr;
  logic [2:0]                     dma_axil_arprot;
  logic                           dma_axil_rvalid;
  logic                           dma_axil_rready;
  logic [AXIL_DATA_W-1:0]         dma_axil_rdata;
  logic [1:0]                     dma_axil_rresp;

  logic                           boot_axil_awvalid;
  logic                           boot_axil_awready;
  logic [AXIL_ADDR_W-1:0]         boot_axil_awaddr;
  logic [2:0]                     boot_axil_awprot;
  logic                           boot_axil_wvalid;
  logic                           boot_axil_wready;
  logic [AXIL_DATA_W-1:0]         boot_axil_wdata;
  logic [(AXIL_DATA_W/8)-1:0]     boot_axil_wstrb;
  logic                           boot_axil_bvalid;
  logic                           boot_axil_bready;
  logic [1:0]                     boot_axil_bresp;
  logic                           boot_axil_arvalid;
  logic                           boot_axil_arready;
  logic [AXIL_ADDR_W-1:0]         boot_axil_araddr;
  logic [2:0]                     boot_axil_arprot;
  logic                           boot_axil_rvalid;
  logic                           boot_axil_rready;
  logic [AXIL_DATA_W-1:0]         boot_axil_rdata;
  logic [1:0]                     boot_axil_rresp;

  logic                           local_axil_awvalid;
  logic                           local_axil_awready;
  logic [AXIL_ADDR_W-1:0]         local_axil_awaddr;
  logic [2:0]                     local_axil_awprot;
  logic                           local_axil_wvalid;
  logic                           local_axil_wready;
  logic [AXIL_DATA_W-1:0]         local_axil_wdata;
  logic [(AXIL_DATA_W/8)-1:0]     local_axil_wstrb;
  logic                           local_axil_bvalid;
  logic                           local_axil_bready;
  logic [1:0]                     local_axil_bresp;
  logic                           local_axil_arvalid;
  logic                           local_axil_arready;
  logic [AXIL_ADDR_W-1:0]         local_axil_araddr;
  logic [2:0]                     local_axil_arprot;
  logic                           local_axil_rvalid;
  logic                           local_axil_rready;
  logic [AXIL_DATA_W-1:0]         local_axil_rdata;
  logic [1:0]                     local_axil_rresp;

  logic                           npu_axil_awvalid;
  logic                           npu_axil_awready;
  logic [AXIL_ADDR_W-1:0]         npu_axil_awaddr;
  logic [2:0]                     npu_axil_awprot;
  logic                           npu_axil_wvalid;
  logic                           npu_axil_wready;
  logic [AXIL_DATA_W-1:0]         npu_axil_wdata;
  logic [(AXIL_DATA_W/8)-1:0]     npu_axil_wstrb;
  logic                           npu_axil_bvalid;
  logic                           npu_axil_bready;
  logic [1:0]                     npu_axil_bresp;
  logic                           npu_axil_arvalid;
  logic                           npu_axil_arready;
  logic [AXIL_ADDR_W-1:0]         npu_axil_araddr;
  logic [2:0]                     npu_axil_arprot;
  logic                           npu_axil_rvalid;
  logic                           npu_axil_rready;
  logic [AXIL_DATA_W-1:0]         npu_axil_rdata;
  logic [1:0]                     npu_axil_rresp;

  logic                           sys_axil_awvalid;
  logic                           sys_axil_awready;
  logic [AXIL_ADDR_W-1:0]         sys_axil_awaddr;
  logic [2:0]                     sys_axil_awprot;
  logic                           sys_axil_wvalid;
  logic                           sys_axil_wready;
  logic [AXIL_DATA_W-1:0]         sys_axil_wdata;
  logic [(AXIL_DATA_W/8)-1:0]     sys_axil_wstrb;
  logic                           sys_axil_bvalid;
  logic                           sys_axil_bready;
  logic [1:0]                     sys_axil_bresp;
  logic                           sys_axil_arvalid;
  logic                           sys_axil_arready;
  logic [AXIL_ADDR_W-1:0]         sys_axil_araddr;
  logic [2:0]                     sys_axil_arprot;
  logic                           sys_axil_rvalid;
  logic                           sys_axil_rready;
  logic [AXIL_DATA_W-1:0]         sys_axil_rdata;
  logic [1:0]                     sys_axil_rresp;

  logic                           dma_spm_wr_valid;
  logic                           dma_spm_wr_ready;
  logic [1:0]                     dma_spm_wr_type;
  logic [BUF_SEL_W-1:0]           dma_spm_wr_buf_sel;
  logic [DMA_SPM_ROW_W-1:0]       dma_spm_wr_row_idx;
  logic [AXI_DATA_W-1:0]          dma_spm_wr_data;
  logic [AXI_STRB_W-1:0]          dma_spm_wr_strb;
  logic                           dma_spm_wr_last;

  logic                           dma_spm_rd_req_valid;
  logic                           dma_spm_rd_req_ready;
  logic [BUF_SEL_W-1:0]           dma_spm_rd_buf_sel;
  logic [DMA_SPM_ROW_W-1:0]       dma_spm_rd_row_idx;
  logic                           dma_spm_rd_data_valid;
  logic                           dma_spm_rd_data_ready;
  logic [AXI_DATA_W-1:0]          dma_spm_rd_data;
  logic                           dma_spm_rd_last;

  logic                           spm_npu_vec_valid;
  logic                           spm_npu_vec_ready;
  logic [BUF_SEL_W-1:0]           spm_npu_act_buf_sel;
  logic [BUF_SEL_W-1:0]           spm_npu_wgt_buf_sel;
  logic [NPU_K_IDX_W-1:0]         spm_npu_k_idx;
  logic [ACT_VEC_W-1:0]           spm_npu_act_vec;
  logic [WGT_VEC_W-1:0]           spm_npu_wgt_vec;

  logic                           npu_spm_out_valid;
  logic                           npu_spm_out_ready;
  logic [BUF_SEL_W-1:0]           npu_spm_out_buf_sel;
  logic [NPU_OUT_ROW_W-1:0]       npu_spm_out_row_idx;
  logic [ARRAY_N-1:0]             npu_spm_out_col_mask;
  logic [OUT_VEC_W-1:0]           npu_spm_out_data;
  logic                           npu_spm_out_last;

  logic [BUF_SEL_W-1:0]           act_buf_writable;
  logic [BUF_SEL_W-1:0]           wgt_buf_writable;
  logic [BUF_SEL_W-1:0]           out_buf_readable;
  logic                           spm_dma_error;
  logic [DMA_ERROR_CODE_W-1:0]    spm_dma_error_code;

  logic [BUF_SEL_W-1:0]           act_buf_ready;
  logic [BUF_SEL_W-1:0]           wgt_buf_ready;
  logic [BUF_SEL_W-1:0]           out_buf_free;
  logic                           spm_npu_error;
  logic [NPU_ERROR_CODE_W-1:0]    spm_npu_error_code;

  logic [31:0]                    cpu_irq;
  logic [31:0]                    cpu_eoi;
  logic                           npu_armed;
  logic [31:0]                    npu_stall_cycles;
  logic                           dma_fifo_empty;
  logic                           dma_fifo_full;
  logic [DMA_FIFO_LEVEL_W-1:0]    dma_fifo_level;
  logic [31:0]                    dma_done_count;
  logic [31:0]                    dma_rd_beat_count;
  logic [31:0]                    dma_wr_beat_count;
  logic [DMA_ERROR_CODE_W-1:0]    dma_error_code;
  logic [NPU_ERROR_CODE_W-1:0]    npu_error_code;

  assign cpu_irq = 32'b0;

  cpu_subsys u_cpu_subsys (
    .clk            (clk),
    .rst_n          (rst_n),
    .trap           (cpu_trap),
    .cpu_axil_awvalid(cpu_axil_awvalid),
    .cpu_axil_awready(cpu_axil_awready),
    .cpu_axil_awaddr(cpu_axil_awaddr),
    .cpu_axil_awprot(cpu_axil_awprot),
    .cpu_axil_wvalid(cpu_axil_wvalid),
    .cpu_axil_wready(cpu_axil_wready),
    .cpu_axil_wdata (cpu_axil_wdata),
    .cpu_axil_wstrb (cpu_axil_wstrb),
    .cpu_axil_bvalid(cpu_axil_bvalid),
    .cpu_axil_bready(cpu_axil_bready),
    .cpu_axil_bresp (cpu_axil_bresp),
    .cpu_axil_arvalid(cpu_axil_arvalid),
    .cpu_axil_arready(cpu_axil_arready),
    .cpu_axil_araddr(cpu_axil_araddr),
    .cpu_axil_arprot(cpu_axil_arprot),
    .cpu_axil_rvalid(cpu_axil_rvalid),
    .cpu_axil_rready(cpu_axil_rready),
    .cpu_axil_rdata (cpu_axil_rdata),
    .cpu_axil_rresp (cpu_axil_rresp),
    .irq            (cpu_irq),
    .eoi            (cpu_eoi)
  );

  u_core_axil_xbar u_core_axil_xbar (
    .clk              (clk),
    .rst_n            (rst_n),
    .m_axil_awvalid   (cpu_axil_awvalid),
    .m_axil_awready   (cpu_axil_awready),
    .m_axil_awaddr    (cpu_axil_awaddr),
    .m_axil_awprot    (cpu_axil_awprot),
    .m_axil_wvalid    (cpu_axil_wvalid),
    .m_axil_wready    (cpu_axil_wready),
    .m_axil_wdata     (cpu_axil_wdata),
    .m_axil_wstrb     (cpu_axil_wstrb),
    .m_axil_bvalid    (cpu_axil_bvalid),
    .m_axil_bready    (cpu_axil_bready),
    .m_axil_bresp     (cpu_axil_bresp),
    .m_axil_arvalid   (cpu_axil_arvalid),
    .m_axil_arready   (cpu_axil_arready),
    .m_axil_araddr    (cpu_axil_araddr),
    .m_axil_arprot    (cpu_axil_arprot),
    .m_axil_rvalid    (cpu_axil_rvalid),
    .m_axil_rready    (cpu_axil_rready),
    .m_axil_rdata     (cpu_axil_rdata),
    .m_axil_rresp     (cpu_axil_rresp),
    .boot_axil_awvalid(boot_axil_awvalid),
    .boot_axil_awready(boot_axil_awready),
    .boot_axil_awaddr (boot_axil_awaddr),
    .boot_axil_awprot (boot_axil_awprot),
    .boot_axil_wvalid (boot_axil_wvalid),
    .boot_axil_wready (boot_axil_wready),
    .boot_axil_wdata  (boot_axil_wdata),
    .boot_axil_wstrb  (boot_axil_wstrb),
    .boot_axil_bvalid (boot_axil_bvalid),
    .boot_axil_bready (boot_axil_bready),
    .boot_axil_bresp  (boot_axil_bresp),
    .boot_axil_arvalid(boot_axil_arvalid),
    .boot_axil_arready(boot_axil_arready),
    .boot_axil_araddr (boot_axil_araddr),
    .boot_axil_arprot (boot_axil_arprot),
    .boot_axil_rvalid (boot_axil_rvalid),
    .boot_axil_rready (boot_axil_rready),
    .boot_axil_rdata  (boot_axil_rdata),
    .boot_axil_rresp  (boot_axil_rresp),
    .local_axil_awvalid(local_axil_awvalid),
    .local_axil_awready(local_axil_awready),
    .local_axil_awaddr(local_axil_awaddr),
    .local_axil_awprot(local_axil_awprot),
    .local_axil_wvalid(local_axil_wvalid),
    .local_axil_wready(local_axil_wready),
    .local_axil_wdata (local_axil_wdata),
    .local_axil_wstrb (local_axil_wstrb),
    .local_axil_bvalid(local_axil_bvalid),
    .local_axil_bready(local_axil_bready),
    .local_axil_bresp (local_axil_bresp),
    .local_axil_arvalid(local_axil_arvalid),
    .local_axil_arready(local_axil_arready),
    .local_axil_araddr(local_axil_araddr),
    .local_axil_arprot(local_axil_arprot),
    .local_axil_rvalid(local_axil_rvalid),
    .local_axil_rready(local_axil_rready),
    .local_axil_rdata (local_axil_rdata),
    .local_axil_rresp (local_axil_rresp),
    .npu_axil_awvalid (npu_axil_awvalid),
    .npu_axil_awready (npu_axil_awready),
    .npu_axil_awaddr  (npu_axil_awaddr),
    .npu_axil_awprot  (npu_axil_awprot),
    .npu_axil_wvalid  (npu_axil_wvalid),
    .npu_axil_wready  (npu_axil_wready),
    .npu_axil_wdata   (npu_axil_wdata),
    .npu_axil_wstrb   (npu_axil_wstrb),
    .npu_axil_bvalid  (npu_axil_bvalid),
    .npu_axil_bready  (npu_axil_bready),
    .npu_axil_bresp   (npu_axil_bresp),
    .npu_axil_arvalid (npu_axil_arvalid),
    .npu_axil_arready (npu_axil_arready),
    .npu_axil_araddr  (npu_axil_araddr),
    .npu_axil_arprot  (npu_axil_arprot),
    .npu_axil_rvalid  (npu_axil_rvalid),
    .npu_axil_rready  (npu_axil_rready),
    .npu_axil_rdata   (npu_axil_rdata),
    .npu_axil_rresp   (npu_axil_rresp),
    .dma_axil_awvalid (dma_axil_awvalid),
    .dma_axil_awready (dma_axil_awready),
    .dma_axil_awaddr  (dma_axil_awaddr),
    .dma_axil_awprot  (dma_axil_awprot),
    .dma_axil_wvalid  (dma_axil_wvalid),
    .dma_axil_wready  (dma_axil_wready),
    .dma_axil_wdata   (dma_axil_wdata),
    .dma_axil_wstrb   (dma_axil_wstrb),
    .dma_axil_bvalid  (dma_axil_bvalid),
    .dma_axil_bready  (dma_axil_bready),
    .dma_axil_bresp   (dma_axil_bresp),
    .dma_axil_arvalid (dma_axil_arvalid),
    .dma_axil_arready (dma_axil_arready),
    .dma_axil_araddr  (dma_axil_araddr),
    .dma_axil_arprot  (dma_axil_arprot),
    .dma_axil_rvalid  (dma_axil_rvalid),
    .dma_axil_rready  (dma_axil_rready),
    .dma_axil_rdata   (dma_axil_rdata),
    .dma_axil_rresp   (dma_axil_rresp),
    .sys_axil_awvalid (sys_axil_awvalid),
    .sys_axil_awready (sys_axil_awready),
    .sys_axil_awaddr  (sys_axil_awaddr),
    .sys_axil_awprot  (sys_axil_awprot),
    .sys_axil_wvalid  (sys_axil_wvalid),
    .sys_axil_wready  (sys_axil_wready),
    .sys_axil_wdata   (sys_axil_wdata),
    .sys_axil_wstrb   (sys_axil_wstrb),
    .sys_axil_bvalid  (sys_axil_bvalid),
    .sys_axil_bready  (sys_axil_bready),
    .sys_axil_bresp   (sys_axil_bresp),
    .sys_axil_arvalid (sys_axil_arvalid),
    .sys_axil_arready (sys_axil_arready),
    .sys_axil_araddr  (sys_axil_araddr),
    .sys_axil_arprot  (sys_axil_arprot),
    .sys_axil_rvalid  (sys_axil_rvalid),
    .sys_axil_rready  (sys_axil_rready),
    .sys_axil_rdata   (sys_axil_rdata),
    .sys_axil_rresp   (sys_axil_rresp)
  );

  u_core_axil_mem #(
    .BASE_ADDR (BOOT_ROM_BASE),
    .SIZE_BYTES(BOOT_ROM_SIZE_BYTES),
    .READ_ONLY (1'b1)
  ) u_boot_rom (
    .clk          (clk),
    .rst_n        (rst_n),
    .s_axil_awvalid(boot_axil_awvalid),
    .s_axil_awready(boot_axil_awready),
    .s_axil_awaddr (boot_axil_awaddr),
    .s_axil_awprot (boot_axil_awprot),
    .s_axil_wvalid (boot_axil_wvalid),
    .s_axil_wready (boot_axil_wready),
    .s_axil_wdata  (boot_axil_wdata),
    .s_axil_wstrb  (boot_axil_wstrb),
    .s_axil_bvalid (boot_axil_bvalid),
    .s_axil_bready (boot_axil_bready),
    .s_axil_bresp  (boot_axil_bresp),
    .s_axil_arvalid(boot_axil_arvalid),
    .s_axil_arready(boot_axil_arready),
    .s_axil_araddr (boot_axil_araddr),
    .s_axil_arprot (boot_axil_arprot),
    .s_axil_rvalid (boot_axil_rvalid),
    .s_axil_rready (boot_axil_rready),
    .s_axil_rdata  (boot_axil_rdata),
    .s_axil_rresp  (boot_axil_rresp)
  );

  u_core_axil_mem #(
    .BASE_ADDR (LOCAL_RAM_BASE),
    .SIZE_BYTES(LOCAL_RAM_SIZE_BYTES),
    .READ_ONLY (1'b0)
  ) u_local_ram (
    .clk          (clk),
    .rst_n        (rst_n),
    .s_axil_awvalid(local_axil_awvalid),
    .s_axil_awready(local_axil_awready),
    .s_axil_awaddr (local_axil_awaddr),
    .s_axil_awprot (local_axil_awprot),
    .s_axil_wvalid (local_axil_wvalid),
    .s_axil_wready (local_axil_wready),
    .s_axil_wdata  (local_axil_wdata),
    .s_axil_wstrb  (local_axil_wstrb),
    .s_axil_bvalid (local_axil_bvalid),
    .s_axil_bready (local_axil_bready),
    .s_axil_bresp  (local_axil_bresp),
    .s_axil_arvalid(local_axil_arvalid),
    .s_axil_arready(local_axil_arready),
    .s_axil_araddr (local_axil_araddr),
    .s_axil_arprot (local_axil_arprot),
    .s_axil_rvalid (local_axil_rvalid),
    .s_axil_rready (local_axil_rready),
    .s_axil_rdata  (local_axil_rdata),
    .s_axil_rresp  (local_axil_rresp)
  );

  u_core_sys_csr u_core_sys_csr (
    .clk             (clk),
    .rst_n           (rst_n),
    .s_axil_awvalid  (sys_axil_awvalid),
    .s_axil_awready  (sys_axil_awready),
    .s_axil_awaddr   (sys_axil_awaddr),
    .s_axil_awprot   (sys_axil_awprot),
    .s_axil_wvalid   (sys_axil_wvalid),
    .s_axil_wready   (sys_axil_wready),
    .s_axil_wdata    (sys_axil_wdata),
    .s_axil_wstrb    (sys_axil_wstrb),
    .s_axil_bvalid   (sys_axil_bvalid),
    .s_axil_bready   (sys_axil_bready),
    .s_axil_bresp    (sys_axil_bresp),
    .s_axil_arvalid  (sys_axil_arvalid),
    .s_axil_arready  (sys_axil_arready),
    .s_axil_araddr   (sys_axil_araddr),
    .s_axil_arprot   (sys_axil_arprot),
    .s_axil_rvalid   (sys_axil_rvalid),
    .s_axil_rready   (sys_axil_rready),
    .s_axil_rdata    (sys_axil_rdata),
    .s_axil_rresp    (sys_axil_rresp),
    .cpu_trap        (cpu_trap),
    .dma_busy        (dma_busy),
    .dma_done        (dma_done),
    .dma_error       (dma_error),
    .npu_armed       (npu_armed),
    .npu_busy        (npu_busy),
    .npu_done        (npu_done),
    .npu_error       (npu_error),
    .spm_dma_error   (spm_dma_error),
    .spm_npu_error   (spm_npu_error),
    .dma_done_count  (dma_done_count),
    .dma_rd_beat_count(dma_rd_beat_count),
    .dma_wr_beat_count(dma_wr_beat_count),
    .npu_stall_cycles(npu_stall_cycles),
    .dma_error_code  (dma_error_code),
    .npu_error_code  (npu_error_code),
    .spm_dma_error_code(spm_dma_error_code),
    .spm_npu_error_code(spm_npu_error_code)
  );

  dma_top u_dma_top (
    .clk              (clk),
    .rst_n            (rst_n),
    .dma_axil_awvalid (dma_axil_awvalid),
    .dma_axil_awready (dma_axil_awready),
    .dma_axil_awaddr  (dma_axil_awaddr),
    .dma_axil_awprot  (dma_axil_awprot),
    .dma_axil_wvalid  (dma_axil_wvalid),
    .dma_axil_wready  (dma_axil_wready),
    .dma_axil_wdata   (dma_axil_wdata),
    .dma_axil_wstrb   (dma_axil_wstrb),
    .dma_axil_bvalid  (dma_axil_bvalid),
    .dma_axil_bready  (dma_axil_bready),
    .dma_axil_bresp   (dma_axil_bresp),
    .dma_axil_arvalid (dma_axil_arvalid),
    .dma_axil_arready (dma_axil_arready),
    .dma_axil_araddr  (dma_axil_araddr),
    .dma_axil_arprot  (dma_axil_arprot),
    .dma_axil_rvalid  (dma_axil_rvalid),
    .dma_axil_rready  (dma_axil_rready),
    .dma_axil_rdata   (dma_axil_rdata),
    .dma_axil_rresp   (dma_axil_rresp),
    .dma_m_axi_awvalid(dma_m_axi_awvalid),
    .dma_m_axi_awready(dma_m_axi_awready),
    .dma_m_axi_awaddr (dma_m_axi_awaddr),
    .dma_m_axi_awlen  (dma_m_axi_awlen),
    .dma_m_axi_awsize (dma_m_axi_awsize),
    .dma_m_axi_awburst(dma_m_axi_awburst),
    .dma_m_axi_wvalid (dma_m_axi_wvalid),
    .dma_m_axi_wready (dma_m_axi_wready),
    .dma_m_axi_wdata  (dma_m_axi_wdata),
    .dma_m_axi_wstrb  (dma_m_axi_wstrb),
    .dma_m_axi_wlast  (dma_m_axi_wlast),
    .dma_m_axi_bvalid (dma_m_axi_bvalid),
    .dma_m_axi_bready (dma_m_axi_bready),
    .dma_m_axi_bresp  (dma_m_axi_bresp),
    .dma_m_axi_arvalid(dma_m_axi_arvalid),
    .dma_m_axi_arready(dma_m_axi_arready),
    .dma_m_axi_araddr (dma_m_axi_araddr),
    .dma_m_axi_arlen  (dma_m_axi_arlen),
    .dma_m_axi_arsize (dma_m_axi_arsize),
    .dma_m_axi_arburst(dma_m_axi_arburst),
    .dma_m_axi_rvalid (dma_m_axi_rvalid),
    .dma_m_axi_rready (dma_m_axi_rready),
    .dma_m_axi_rdata  (dma_m_axi_rdata),
    .dma_m_axi_rresp  (dma_m_axi_rresp),
    .dma_m_axi_rlast  (dma_m_axi_rlast),
    .dma_spm_wr_valid (dma_spm_wr_valid),
    .dma_spm_wr_ready (dma_spm_wr_ready),
    .dma_spm_wr_type  (dma_spm_wr_type),
    .dma_spm_wr_buf_sel(dma_spm_wr_buf_sel),
    .dma_spm_wr_row_idx(dma_spm_wr_row_idx),
    .dma_spm_wr_data  (dma_spm_wr_data),
    .dma_spm_wr_strb  (dma_spm_wr_strb),
    .dma_spm_wr_last  (dma_spm_wr_last),
    .dma_spm_rd_req_valid(dma_spm_rd_req_valid),
    .dma_spm_rd_req_ready(dma_spm_rd_req_ready),
    .dma_spm_rd_buf_sel(dma_spm_rd_buf_sel),
    .dma_spm_rd_row_idx(dma_spm_rd_row_idx),
    .dma_spm_rd_data_valid(dma_spm_rd_data_valid),
    .dma_spm_rd_data_ready(dma_spm_rd_data_ready),
    .dma_spm_rd_data  (dma_spm_rd_data),
    .dma_spm_rd_last  (dma_spm_rd_last),
    .act_buf_writable (act_buf_writable),
    .wgt_buf_writable (wgt_buf_writable),
    .out_buf_readable (out_buf_readable),
    .spm_dma_error    (spm_dma_error),
    .spm_dma_error_code(spm_dma_error_code),
    .dma_busy         (dma_busy),
    .dma_done         (dma_done),
    .dma_error        (dma_error),
    .dma_fifo_empty   (dma_fifo_empty),
    .dma_fifo_full    (dma_fifo_full),
    .dma_fifo_level   (dma_fifo_level),
    .dma_done_count   (dma_done_count),
    .dma_rd_beat_count(dma_rd_beat_count),
    .dma_wr_beat_count(dma_wr_beat_count),
    .dma_error_code   (dma_error_code)
  );

  spm_subsys u_spm_subsys (
    .clk              (clk),
    .rst_n            (rst_n),
    .dma_spm_wr_valid (dma_spm_wr_valid),
    .dma_spm_wr_ready (dma_spm_wr_ready),
    .dma_spm_wr_type  (dma_spm_wr_type),
    .dma_spm_wr_buf_sel(dma_spm_wr_buf_sel),
    .dma_spm_wr_row_idx(dma_spm_wr_row_idx),
    .dma_spm_wr_data  (dma_spm_wr_data),
    .dma_spm_wr_strb  (dma_spm_wr_strb),
    .dma_spm_wr_last  (dma_spm_wr_last),
    .dma_spm_rd_req_valid(dma_spm_rd_req_valid),
    .dma_spm_rd_req_ready(dma_spm_rd_req_ready),
    .dma_spm_rd_buf_sel(dma_spm_rd_buf_sel),
    .dma_spm_rd_row_idx(dma_spm_rd_row_idx),
    .dma_spm_rd_data_valid(dma_spm_rd_data_valid),
    .dma_spm_rd_data_ready(dma_spm_rd_data_ready),
    .dma_spm_rd_data  (dma_spm_rd_data),
    .dma_spm_rd_last  (dma_spm_rd_last),
    .spm_npu_vec_valid(spm_npu_vec_valid),
    .spm_npu_vec_ready(spm_npu_vec_ready),
    .spm_npu_act_buf_sel(spm_npu_act_buf_sel),
    .spm_npu_wgt_buf_sel(spm_npu_wgt_buf_sel),
    .spm_npu_k_idx    (spm_npu_k_idx),
    .spm_npu_act_vec  (spm_npu_act_vec),
    .spm_npu_wgt_vec  (spm_npu_wgt_vec),
    .npu_spm_out_valid(npu_spm_out_valid),
    .npu_spm_out_ready(npu_spm_out_ready),
    .npu_spm_out_buf_sel(npu_spm_out_buf_sel),
    .npu_spm_out_row_idx(npu_spm_out_row_idx),
    .npu_spm_out_col_mask(npu_spm_out_col_mask),
    .npu_spm_out_data (npu_spm_out_data),
    .npu_spm_out_last (npu_spm_out_last),
    .act_buf_writable (act_buf_writable),
    .wgt_buf_writable (wgt_buf_writable),
    .out_buf_readable (out_buf_readable),
    .spm_dma_error    (spm_dma_error),
    .spm_dma_error_code(spm_dma_error_code),
    .act_buf_ready    (act_buf_ready),
    .wgt_buf_ready    (wgt_buf_ready),
    .out_buf_free     (out_buf_free),
    .spm_npu_error    (spm_npu_error),
    .spm_npu_error_code(spm_npu_error_code)
  );

  npu_top u_npu_top (
    .clk              (clk),
    .rst_n            (rst_n),
    .npu_axil_awvalid (npu_axil_awvalid),
    .npu_axil_awready (npu_axil_awready),
    .npu_axil_awaddr  (npu_axil_awaddr),
    .npu_axil_awprot  (npu_axil_awprot),
    .npu_axil_wvalid  (npu_axil_wvalid),
    .npu_axil_wready  (npu_axil_wready),
    .npu_axil_wdata   (npu_axil_wdata),
    .npu_axil_wstrb   (npu_axil_wstrb),
    .npu_axil_bvalid  (npu_axil_bvalid),
    .npu_axil_bready  (npu_axil_bready),
    .npu_axil_bresp   (npu_axil_bresp),
    .npu_axil_arvalid (npu_axil_arvalid),
    .npu_axil_arready (npu_axil_arready),
    .npu_axil_araddr  (npu_axil_araddr),
    .npu_axil_arprot  (npu_axil_arprot),
    .npu_axil_rvalid  (npu_axil_rvalid),
    .npu_axil_rready  (npu_axil_rready),
    .npu_axil_rdata   (npu_axil_rdata),
    .npu_axil_rresp   (npu_axil_rresp),
    .spm_npu_vec_valid(spm_npu_vec_valid),
    .spm_npu_vec_ready(spm_npu_vec_ready),
    .spm_npu_act_buf_sel(spm_npu_act_buf_sel),
    .spm_npu_wgt_buf_sel(spm_npu_wgt_buf_sel),
    .spm_npu_k_idx    (spm_npu_k_idx),
    .spm_npu_act_vec  (spm_npu_act_vec),
    .spm_npu_wgt_vec  (spm_npu_wgt_vec),
    .npu_spm_out_valid(npu_spm_out_valid),
    .npu_spm_out_ready(npu_spm_out_ready),
    .npu_spm_out_buf_sel(npu_spm_out_buf_sel),
    .npu_spm_out_row_idx(npu_spm_out_row_idx),
    .npu_spm_out_col_mask(npu_spm_out_col_mask),
    .npu_spm_out_data (npu_spm_out_data),
    .npu_spm_out_last (npu_spm_out_last),
    .act_buf_ready    (act_buf_ready),
    .wgt_buf_ready    (wgt_buf_ready),
    .out_buf_free     (out_buf_free),
    .spm_npu_error    (spm_npu_error),
    .spm_npu_error_code(spm_npu_error_code),
    .npu_armed        (npu_armed),
    .npu_busy         (npu_busy),
    .npu_done         (npu_done),
    .npu_error        (npu_error),
    .npu_stall_cycles (npu_stall_cycles),
    .npu_error_code   (npu_error_code)
  );

endmodule

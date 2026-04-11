module u_core_axil_xbar (
  input  logic                                clk,
  input  logic                                rst_n,

  input  logic                                m_axil_awvalid,
  output logic                                m_axil_awready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  m_axil_awaddr,
  input  logic [2:0]                          m_axil_awprot,
  input  logic                                m_axil_wvalid,
  output logic                                m_axil_wready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  m_axil_wdata,
  input  logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] m_axil_wstrb,
  output logic                                m_axil_bvalid,
  input  logic                                m_axil_bready,
  output logic [1:0]                          m_axil_bresp,
  input  logic                                m_axil_arvalid,
  output logic                                m_axil_arready,
  input  logic [u_core_pkg::AXIL_ADDR_W-1:0]  m_axil_araddr,
  input  logic [2:0]                          m_axil_arprot,
  output logic                                m_axil_rvalid,
  input  logic                                m_axil_rready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  m_axil_rdata,
  output logic [1:0]                          m_axil_rresp,

  output logic                                boot_axil_awvalid,
  input  logic                                boot_axil_awready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0]  boot_axil_awaddr,
  output logic [2:0]                          boot_axil_awprot,
  output logic                                boot_axil_wvalid,
  input  logic                                boot_axil_wready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  boot_axil_wdata,
  output logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] boot_axil_wstrb,
  input  logic                                boot_axil_bvalid,
  output logic                                boot_axil_bready,
  input  logic [1:0]                          boot_axil_bresp,
  output logic                                boot_axil_arvalid,
  input  logic                                boot_axil_arready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0]  boot_axil_araddr,
  output logic [2:0]                          boot_axil_arprot,
  input  logic                                boot_axil_rvalid,
  output logic                                boot_axil_rready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  boot_axil_rdata,
  input  logic [1:0]                          boot_axil_rresp,

  output logic                                local_axil_awvalid,
  input  logic                                local_axil_awready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0]  local_axil_awaddr,
  output logic [2:0]                          local_axil_awprot,
  output logic                                local_axil_wvalid,
  input  logic                                local_axil_wready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  local_axil_wdata,
  output logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] local_axil_wstrb,
  input  logic                                local_axil_bvalid,
  output logic                                local_axil_bready,
  input  logic [1:0]                          local_axil_bresp,
  output logic                                local_axil_arvalid,
  input  logic                                local_axil_arready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0]  local_axil_araddr,
  output logic [2:0]                          local_axil_arprot,
  input  logic                                local_axil_rvalid,
  output logic                                local_axil_rready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  local_axil_rdata,
  input  logic [1:0]                          local_axil_rresp,

  output logic                                npu_axil_awvalid,
  input  logic                                npu_axil_awready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0]  npu_axil_awaddr,
  output logic [2:0]                          npu_axil_awprot,
  output logic                                npu_axil_wvalid,
  input  logic                                npu_axil_wready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  npu_axil_wdata,
  output logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] npu_axil_wstrb,
  input  logic                                npu_axil_bvalid,
  output logic                                npu_axil_bready,
  input  logic [1:0]                          npu_axil_bresp,
  output logic                                npu_axil_arvalid,
  input  logic                                npu_axil_arready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0]  npu_axil_araddr,
  output logic [2:0]                          npu_axil_arprot,
  input  logic                                npu_axil_rvalid,
  output logic                                npu_axil_rready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  npu_axil_rdata,
  input  logic [1:0]                          npu_axil_rresp,

  output logic                                dma_axil_awvalid,
  input  logic                                dma_axil_awready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0]  dma_axil_awaddr,
  output logic [2:0]                          dma_axil_awprot,
  output logic                                dma_axil_wvalid,
  input  logic                                dma_axil_wready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  dma_axil_wdata,
  output logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] dma_axil_wstrb,
  input  logic                                dma_axil_bvalid,
  output logic                                dma_axil_bready,
  input  logic [1:0]                          dma_axil_bresp,
  output logic                                dma_axil_arvalid,
  input  logic                                dma_axil_arready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0]  dma_axil_araddr,
  output logic [2:0]                          dma_axil_arprot,
  input  logic                                dma_axil_rvalid,
  output logic                                dma_axil_rready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  dma_axil_rdata,
  input  logic [1:0]                          dma_axil_rresp,

  output logic                                sys_axil_awvalid,
  input  logic                                sys_axil_awready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0]  sys_axil_awaddr,
  output logic [2:0]                          sys_axil_awprot,
  output logic                                sys_axil_wvalid,
  input  logic                                sys_axil_wready,
  output logic [u_core_pkg::AXIL_DATA_W-1:0]  sys_axil_wdata,
  output logic [(u_core_pkg::AXIL_DATA_W/8)-1:0] sys_axil_wstrb,
  input  logic                                sys_axil_bvalid,
  output logic                                sys_axil_bready,
  input  logic [1:0]                          sys_axil_bresp,
  output logic                                sys_axil_arvalid,
  input  logic                                sys_axil_arready,
  output logic [u_core_pkg::AXIL_ADDR_W-1:0]  sys_axil_araddr,
  output logic [2:0]                          sys_axil_arprot,
  input  logic                                sys_axil_rvalid,
  output logic                                sys_axil_rready,
  input  logic [u_core_pkg::AXIL_DATA_W-1:0]  sys_axil_rdata,
  input  logic [1:0]                          sys_axil_rresp
);

  import u_core_pkg::*;

  localparam logic [2:0] AXIL_SEL_NONE  = 3'd0;
  localparam logic [2:0] AXIL_SEL_BOOT  = 3'd1;
  localparam logic [2:0] AXIL_SEL_LOCAL = 3'd2;
  localparam logic [2:0] AXIL_SEL_NPU   = 3'd3;
  localparam logic [2:0] AXIL_SEL_DMA   = 3'd4;
  localparam logic [2:0] AXIL_SEL_SYS   = 3'd5;

  localparam logic [1:0] WR_IDLE  = 2'd0;
  localparam logic [1:0] WR_ISSUE = 2'd1;
  localparam logic [1:0] WR_RESP  = 2'd2;

  localparam logic [1:0] RD_IDLE  = 2'd0;
  localparam logic [1:0] RD_ISSUE = 2'd1;
  localparam logic [1:0] RD_RESP  = 2'd2;

  logic [1:0] wr_state_r;
  logic [1:0] rd_state_r;
  logic aw_pending_r;
  logic w_pending_r;
  logic [AXIL_ADDR_W-1:0] awaddr_r;
  logic [2:0]             awprot_r;
  logic [AXIL_DATA_W-1:0] wdata_r;
  logic [(AXIL_DATA_W/8)-1:0] wstrb_r;
  logic [2:0] wr_sel_r;
  logic [2:0] rd_sel_r;
  logic wr_aw_sent_r;
  logic wr_w_sent_r;
  logic [AXIL_ADDR_W-1:0] araddr_r;
  logic [2:0]             arprot_r;
  logic rd_ar_sent_r;

  logic unmapped_bvalid_r;
  logic unmapped_rvalid_r;

  function automatic logic [2:0] decode_addr(input logic [AXIL_ADDR_W-1:0] addr);
    begin
      if ((addr >= BOOT_ROM_BASE) && (addr < (BOOT_ROM_BASE + BOOT_ROM_SIZE_BYTES))) begin
        decode_addr = AXIL_SEL_BOOT;
      end else if ((addr >= LOCAL_RAM_BASE) && (addr < (LOCAL_RAM_BASE + LOCAL_RAM_SIZE_BYTES))) begin
        decode_addr = AXIL_SEL_LOCAL;
      end else if ((addr >= NPU_CSR_BASE) && (addr < (NPU_CSR_BASE + CSR_WINDOW_SIZE_BYTES))) begin
        decode_addr = AXIL_SEL_NPU;
      end else if ((addr >= DMA_CSR_BASE) && (addr < (DMA_CSR_BASE + CSR_WINDOW_SIZE_BYTES))) begin
        decode_addr = AXIL_SEL_DMA;
      end else if ((addr >= SYS_CSR_BASE) && (addr < (SYS_CSR_BASE + CSR_WINDOW_SIZE_BYTES))) begin
        decode_addr = AXIL_SEL_SYS;
      end else begin
        decode_addr = AXIL_SEL_NONE;
      end
    end
  endfunction

  assign m_axil_awready = (wr_state_r == WR_IDLE) && ~aw_pending_r;
  assign m_axil_wready  = (wr_state_r == WR_IDLE) && ~w_pending_r;
  assign m_axil_arready = (rd_state_r == RD_IDLE);

  assign boot_axil_awaddr = awaddr_r;
  assign boot_axil_awprot = awprot_r;
  assign boot_axil_wdata  = wdata_r;
  assign boot_axil_wstrb  = wstrb_r;
  assign boot_axil_araddr = araddr_r;
  assign boot_axil_arprot = arprot_r;

  assign local_axil_awaddr = awaddr_r;
  assign local_axil_awprot = awprot_r;
  assign local_axil_wdata  = wdata_r;
  assign local_axil_wstrb  = wstrb_r;
  assign local_axil_araddr = araddr_r;
  assign local_axil_arprot = arprot_r;

  assign npu_axil_awaddr = awaddr_r;
  assign npu_axil_awprot = awprot_r;
  assign npu_axil_wdata  = wdata_r;
  assign npu_axil_wstrb  = wstrb_r;
  assign npu_axil_araddr = araddr_r;
  assign npu_axil_arprot = arprot_r;

  assign dma_axil_awaddr = awaddr_r;
  assign dma_axil_awprot = awprot_r;
  assign dma_axil_wdata  = wdata_r;
  assign dma_axil_wstrb  = wstrb_r;
  assign dma_axil_araddr = araddr_r;
  assign dma_axil_arprot = arprot_r;

  assign sys_axil_awaddr = awaddr_r;
  assign sys_axil_awprot = awprot_r;
  assign sys_axil_wdata  = wdata_r;
  assign sys_axil_wstrb  = wstrb_r;
  assign sys_axil_araddr = araddr_r;
  assign sys_axil_arprot = arprot_r;

  assign boot_axil_awvalid  = (wr_state_r == WR_ISSUE) && (wr_sel_r == AXIL_SEL_BOOT)  && ~wr_aw_sent_r;
  assign local_axil_awvalid = (wr_state_r == WR_ISSUE) && (wr_sel_r == AXIL_SEL_LOCAL) && ~wr_aw_sent_r;
  assign npu_axil_awvalid   = (wr_state_r == WR_ISSUE) && (wr_sel_r == AXIL_SEL_NPU)   && ~wr_aw_sent_r;
  assign dma_axil_awvalid   = (wr_state_r == WR_ISSUE) && (wr_sel_r == AXIL_SEL_DMA)   && ~wr_aw_sent_r;
  assign sys_axil_awvalid   = (wr_state_r == WR_ISSUE) && (wr_sel_r == AXIL_SEL_SYS)   && ~wr_aw_sent_r;

  assign boot_axil_wvalid   = (wr_state_r == WR_ISSUE) && (wr_sel_r == AXIL_SEL_BOOT)  && ~wr_w_sent_r;
  assign local_axil_wvalid  = (wr_state_r == WR_ISSUE) && (wr_sel_r == AXIL_SEL_LOCAL) && ~wr_w_sent_r;
  assign npu_axil_wvalid    = (wr_state_r == WR_ISSUE) && (wr_sel_r == AXIL_SEL_NPU)   && ~wr_w_sent_r;
  assign dma_axil_wvalid    = (wr_state_r == WR_ISSUE) && (wr_sel_r == AXIL_SEL_DMA)   && ~wr_w_sent_r;
  assign sys_axil_wvalid    = (wr_state_r == WR_ISSUE) && (wr_sel_r == AXIL_SEL_SYS)   && ~wr_w_sent_r;

  assign boot_axil_bready   = (wr_state_r == WR_RESP) && (wr_sel_r == AXIL_SEL_BOOT)  && m_axil_bready;
  assign local_axil_bready  = (wr_state_r == WR_RESP) && (wr_sel_r == AXIL_SEL_LOCAL) && m_axil_bready;
  assign npu_axil_bready    = (wr_state_r == WR_RESP) && (wr_sel_r == AXIL_SEL_NPU)   && m_axil_bready;
  assign dma_axil_bready    = (wr_state_r == WR_RESP) && (wr_sel_r == AXIL_SEL_DMA)   && m_axil_bready;
  assign sys_axil_bready    = (wr_state_r == WR_RESP) && (wr_sel_r == AXIL_SEL_SYS)   && m_axil_bready;

  assign boot_axil_arvalid  = (rd_state_r == RD_ISSUE) && (rd_sel_r == AXIL_SEL_BOOT)  && ~rd_ar_sent_r;
  assign local_axil_arvalid = (rd_state_r == RD_ISSUE) && (rd_sel_r == AXIL_SEL_LOCAL) && ~rd_ar_sent_r;
  assign npu_axil_arvalid   = (rd_state_r == RD_ISSUE) && (rd_sel_r == AXIL_SEL_NPU)   && ~rd_ar_sent_r;
  assign dma_axil_arvalid   = (rd_state_r == RD_ISSUE) && (rd_sel_r == AXIL_SEL_DMA)   && ~rd_ar_sent_r;
  assign sys_axil_arvalid   = (rd_state_r == RD_ISSUE) && (rd_sel_r == AXIL_SEL_SYS)   && ~rd_ar_sent_r;

  assign boot_axil_rready   = (rd_state_r == RD_RESP) && (rd_sel_r == AXIL_SEL_BOOT)  && m_axil_rready;
  assign local_axil_rready  = (rd_state_r == RD_RESP) && (rd_sel_r == AXIL_SEL_LOCAL) && m_axil_rready;
  assign npu_axil_rready    = (rd_state_r == RD_RESP) && (rd_sel_r == AXIL_SEL_NPU)   && m_axil_rready;
  assign dma_axil_rready    = (rd_state_r == RD_RESP) && (rd_sel_r == AXIL_SEL_DMA)   && m_axil_rready;
  assign sys_axil_rready    = (rd_state_r == RD_RESP) && (rd_sel_r == AXIL_SEL_SYS)   && m_axil_rready;

  always @* begin
    m_axil_bvalid = 1'b0;
    m_axil_bresp  = 2'b00;
    case (wr_sel_r)
      AXIL_SEL_BOOT: begin
        m_axil_bvalid = boot_axil_bvalid;
        m_axil_bresp  = boot_axil_bresp;
      end
      AXIL_SEL_LOCAL: begin
        m_axil_bvalid = local_axil_bvalid;
        m_axil_bresp  = local_axil_bresp;
      end
      AXIL_SEL_NPU: begin
        m_axil_bvalid = npu_axil_bvalid;
        m_axil_bresp  = npu_axil_bresp;
      end
      AXIL_SEL_DMA: begin
        m_axil_bvalid = dma_axil_bvalid;
        m_axil_bresp  = dma_axil_bresp;
      end
      AXIL_SEL_SYS: begin
        m_axil_bvalid = sys_axil_bvalid;
        m_axil_bresp  = sys_axil_bresp;
      end
      default: begin
        m_axil_bvalid = unmapped_bvalid_r;
        m_axil_bresp  = 2'b10;
      end
    endcase
  end

  always @* begin
    m_axil_rvalid = 1'b0;
    m_axil_rdata  = '0;
    m_axil_rresp  = 2'b00;
    case (rd_sel_r)
      AXIL_SEL_BOOT: begin
        m_axil_rvalid = boot_axil_rvalid;
        m_axil_rdata  = boot_axil_rdata;
        m_axil_rresp  = boot_axil_rresp;
      end
      AXIL_SEL_LOCAL: begin
        m_axil_rvalid = local_axil_rvalid;
        m_axil_rdata  = local_axil_rdata;
        m_axil_rresp  = local_axil_rresp;
      end
      AXIL_SEL_NPU: begin
        m_axil_rvalid = npu_axil_rvalid;
        m_axil_rdata  = npu_axil_rdata;
        m_axil_rresp  = npu_axil_rresp;
      end
      AXIL_SEL_DMA: begin
        m_axil_rvalid = dma_axil_rvalid;
        m_axil_rdata  = dma_axil_rdata;
        m_axil_rresp  = dma_axil_rresp;
      end
      AXIL_SEL_SYS: begin
        m_axil_rvalid = sys_axil_rvalid;
        m_axil_rdata  = sys_axil_rdata;
        m_axil_rresp  = sys_axil_rresp;
      end
      default: begin
        m_axil_rvalid = unmapped_rvalid_r;
        m_axil_rdata  = 32'h0000_0000;
        m_axil_rresp  = 2'b10;
      end
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_state_r        <= WR_IDLE;
      rd_state_r        <= RD_IDLE;
      aw_pending_r      <= 1'b0;
      w_pending_r       <= 1'b0;
      awaddr_r          <= '0;
      awprot_r          <= '0;
      wdata_r           <= '0;
      wstrb_r           <= '0;
      wr_sel_r          <= AXIL_SEL_NONE;
      rd_sel_r          <= AXIL_SEL_NONE;
      wr_aw_sent_r      <= 1'b0;
      wr_w_sent_r       <= 1'b0;
      araddr_r          <= '0;
      arprot_r          <= '0;
      rd_ar_sent_r      <= 1'b0;
      unmapped_bvalid_r <= 1'b0;
      unmapped_rvalid_r <= 1'b0;
    end else begin
      if ((wr_state_r == WR_IDLE) && !aw_pending_r && m_axil_awvalid) begin
        aw_pending_r <= 1'b1;
        awaddr_r     <= m_axil_awaddr;
        awprot_r     <= m_axil_awprot;
      end

      if ((wr_state_r == WR_IDLE) && !w_pending_r && m_axil_wvalid) begin
        w_pending_r <= 1'b1;
        wdata_r     <= m_axil_wdata;
        wstrb_r     <= m_axil_wstrb;
      end

      case (wr_state_r)
        WR_IDLE: begin
          wr_aw_sent_r <= 1'b0;
          wr_w_sent_r  <= 1'b0;
          if (aw_pending_r && w_pending_r) begin
            wr_sel_r   <= decode_addr(awaddr_r);
            wr_state_r <= WR_ISSUE;
          end
        end

        WR_ISSUE: begin
          if (wr_sel_r == AXIL_SEL_NONE) begin
            aw_pending_r      <= 1'b0;
            w_pending_r       <= 1'b0;
            unmapped_bvalid_r <= 1'b1;
            wr_state_r        <= WR_RESP;
          end else begin
            if (!wr_aw_sent_r) begin
              case (wr_sel_r)
                AXIL_SEL_BOOT:  if (boot_axil_awready)  wr_aw_sent_r <= 1'b1;
                AXIL_SEL_LOCAL: if (local_axil_awready) wr_aw_sent_r <= 1'b1;
                AXIL_SEL_NPU:   if (npu_axil_awready)   wr_aw_sent_r <= 1'b1;
                AXIL_SEL_DMA:   if (dma_axil_awready)   wr_aw_sent_r <= 1'b1;
                AXIL_SEL_SYS:   if (sys_axil_awready)   wr_aw_sent_r <= 1'b1;
                default: begin end
              endcase
            end

            if (!wr_w_sent_r) begin
              case (wr_sel_r)
                AXIL_SEL_BOOT:  if (boot_axil_wready)  wr_w_sent_r <= 1'b1;
                AXIL_SEL_LOCAL: if (local_axil_wready) wr_w_sent_r <= 1'b1;
                AXIL_SEL_NPU:   if (npu_axil_wready)   wr_w_sent_r <= 1'b1;
                AXIL_SEL_DMA:   if (dma_axil_wready)   wr_w_sent_r <= 1'b1;
                AXIL_SEL_SYS:   if (sys_axil_wready)   wr_w_sent_r <= 1'b1;
                default: begin end
              endcase
            end

            if (wr_aw_sent_r && wr_w_sent_r) begin
              aw_pending_r <= 1'b0;
              w_pending_r  <= 1'b0;
              wr_state_r   <= WR_RESP;
            end
          end
        end

        WR_RESP: begin
          if ((wr_sel_r == AXIL_SEL_NONE) && unmapped_bvalid_r && m_axil_bready) begin
            unmapped_bvalid_r <= 1'b0;
            wr_state_r        <= WR_IDLE;
          end else begin
            case (wr_sel_r)
              AXIL_SEL_BOOT:  if (boot_axil_bvalid  && m_axil_bready) wr_state_r <= WR_IDLE;
              AXIL_SEL_LOCAL: if (local_axil_bvalid && m_axil_bready) wr_state_r <= WR_IDLE;
              AXIL_SEL_NPU:   if (npu_axil_bvalid   && m_axil_bready) wr_state_r <= WR_IDLE;
              AXIL_SEL_DMA:   if (dma_axil_bvalid   && m_axil_bready) wr_state_r <= WR_IDLE;
              AXIL_SEL_SYS:   if (sys_axil_bvalid   && m_axil_bready) wr_state_r <= WR_IDLE;
              default: begin end
            endcase
          end
        end

        default: wr_state_r <= WR_IDLE;
      endcase

      case (rd_state_r)
        RD_IDLE: begin
          rd_ar_sent_r <= 1'b0;
          if (m_axil_arvalid) begin
            araddr_r   <= m_axil_araddr;
            arprot_r   <= m_axil_arprot;
            rd_sel_r   <= decode_addr(m_axil_araddr);
            rd_state_r <= RD_ISSUE;
          end
        end

        RD_ISSUE: begin
          if (rd_sel_r == AXIL_SEL_NONE) begin
            unmapped_rvalid_r <= 1'b1;
            rd_state_r        <= RD_RESP;
          end else begin
            case (rd_sel_r)
              AXIL_SEL_BOOT:  if (boot_axil_arready)  rd_ar_sent_r <= 1'b1;
              AXIL_SEL_LOCAL: if (local_axil_arready) rd_ar_sent_r <= 1'b1;
              AXIL_SEL_NPU:   if (npu_axil_arready)   rd_ar_sent_r <= 1'b1;
              AXIL_SEL_DMA:   if (dma_axil_arready)   rd_ar_sent_r <= 1'b1;
              AXIL_SEL_SYS:   if (sys_axil_arready)   rd_ar_sent_r <= 1'b1;
              default: begin end
            endcase
            if (rd_ar_sent_r) begin
              rd_state_r <= RD_RESP;
            end
          end
        end

        RD_RESP: begin
          if ((rd_sel_r == AXIL_SEL_NONE) && unmapped_rvalid_r && m_axil_rready) begin
            unmapped_rvalid_r <= 1'b0;
            rd_state_r        <= RD_IDLE;
          end else begin
            case (rd_sel_r)
              AXIL_SEL_BOOT:  if (boot_axil_rvalid  && m_axil_rready) rd_state_r <= RD_IDLE;
              AXIL_SEL_LOCAL: if (local_axil_rvalid && m_axil_rready) rd_state_r <= RD_IDLE;
              AXIL_SEL_NPU:   if (npu_axil_rvalid   && m_axil_rready) rd_state_r <= RD_IDLE;
              AXIL_SEL_DMA:   if (dma_axil_rvalid   && m_axil_rready) rd_state_r <= RD_IDLE;
              AXIL_SEL_SYS:   if (sys_axil_rvalid   && m_axil_rready) rd_state_r <= RD_IDLE;
              default: begin end
            endcase
          end
        end

        default: rd_state_r <= RD_IDLE;
      endcase
    end
  end

endmodule

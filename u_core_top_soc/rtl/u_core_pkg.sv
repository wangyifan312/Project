package u_core_pkg;

  localparam integer AXIL_ADDR_W = 32;
  localparam integer AXIL_DATA_W = 32;
  localparam integer AXI_ADDR_W  = 32;
  localparam integer AXI_DATA_W  = 512;
  localparam integer AXI_STRB_W  = AXI_DATA_W / 8;
  localparam integer AXI_BEAT_BYTES = AXI_DATA_W / 8;

  localparam integer ARRAY_M      = 16;
  localparam integer ARRAY_N      = 16;
  localparam integer ARRAY_K_TILE = 32;
  localparam integer ACT_ELEM_W   = 8;
  localparam integer WGT_ELEM_W   = 8;
  localparam integer PSUM_ELEM_W  = 32;
  localparam integer OUT_ELEM_W   = 16;

  localparam integer BUF_SEL_W         = 2;
  localparam integer DMA_SPM_ROW_W     = 3;
  localparam integer NPU_OUT_ROW_W     = 4;
  localparam integer NPU_K_IDX_W       = 6;
  localparam integer DMA_ERROR_CODE_W  = 8;
  localparam integer NPU_ERROR_CODE_W  = 8;
  localparam integer DMA_FIFO_LEVEL_W  = 3;
  localparam integer DMA_DESC_W        = 180;
  localparam integer DMA_FIFO_DEPTH    = 4;

  localparam integer ACT_VEC_W = ARRAY_M * ACT_ELEM_W;
  localparam integer WGT_VEC_W = ARRAY_N * WGT_ELEM_W;
  localparam integer OUT_VEC_W = ARRAY_N * OUT_ELEM_W;

  localparam integer ACT_BUF_BYTES = 512;
  localparam integer WGT_BUF_BYTES = 512;
  localparam integer OUT_BUF_BYTES = 512;
  localparam integer DMA_SPM_ROW_COUNT = ACT_BUF_BYTES / AXI_BEAT_BYTES;

  localparam logic [31:0] PROGADDR_RESET = 32'h0000_0000;
  localparam logic [31:0] PROGADDR_IRQ   = 32'h0000_0010;
  localparam logic [31:0] STACKADDR      = 32'h0001_8000;

  localparam logic [31:0] BOOT_ROM_BASE  = 32'h0000_0000;
  localparam logic [31:0] LOCAL_RAM_BASE = 32'h0001_0000;
  localparam logic [31:0] NPU_CSR_BASE   = 32'h1000_0000;
  localparam logic [31:0] DMA_CSR_BASE   = 32'h1000_1000;
  localparam logic [31:0] SYS_CSR_BASE   = 32'h1000_2000;

  typedef enum logic [1:0] {
    DMA_SPM_TYPE_ACT = 2'b00,
    DMA_SPM_TYPE_WGT = 2'b01
  } dma_spm_wr_type_e;

  typedef enum logic [1:0] {
    DMA_OP_LOAD_ACT = 2'b00,
    DMA_OP_LOAD_WGT = 2'b01,
    DMA_OP_STORE_OUT = 2'b10
  } dma_op_type_e;

endpackage

module dma_addr_gen (
  input  logic [u_core_pkg::DMA_DESC_W-1:0] desc_bus,
  input  logic [15:0]                       row_idx,
  output logic [u_core_pkg::AXI_ADDR_W-1:0] rd_ext_addr,
  output logic [u_core_pkg::AXI_ADDR_W-1:0] wr_ext_addr,
  output logic [u_core_pkg::DMA_SPM_ROW_W-1:0] local_row_idx,
  output logic                              last_row
);

  import u_core_pkg::*;

  logic [31:0] src_addr;
  logic [31:0] dst_addr;
  logic [15:0] row_cnt;
  logic [15:0] src_stride;
  logic [15:0] dst_stride;
  logic [15:0] spm_row_base;

  always @* begin
    src_addr     = desc_bus[33:2];
    dst_addr     = desc_bus[65:34];
    row_cnt      = desc_bus[97:82];
    src_stride   = desc_bus[113:98];
    dst_stride   = desc_bus[129:114];
    spm_row_base = desc_bus[147:132];

    rd_ext_addr  = src_addr + (row_idx * src_stride);
    wr_ext_addr  = dst_addr + (row_idx * dst_stride);
    local_row_idx = spm_row_base[DMA_SPM_ROW_W-1:0] + row_idx[DMA_SPM_ROW_W-1:0];
    last_row     = (row_idx == (row_cnt - 1'b1));
  end

endmodule

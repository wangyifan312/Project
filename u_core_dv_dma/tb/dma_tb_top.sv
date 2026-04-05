`timescale 1ns/1ps

module dma_tb_top;
  import uvm_pkg::*;
  import u_core_pkg::*;
  import dma_dv_pkg::*;

  logic clk;
  logic rst_n;

  dma_axil_if    axil_if(.clk(clk), .rst_n(rst_n));
  dma_axi_mem_if axi_mem_if(.clk(clk), .rst_n(rst_n));
  dma_spm_if     spm_if(.clk(clk), .rst_n(rst_n));
  dma_status_if  status_if(.clk(clk), .rst_n(rst_n));

  dma_top dut (
    .clk                 (clk),
    .rst_n               (rst_n),
    .dma_axil_awvalid    (axil_if.awvalid),
    .dma_axil_awready    (axil_if.awready),
    .dma_axil_awaddr     (axil_if.awaddr),
    .dma_axil_awprot     (axil_if.awprot),
    .dma_axil_wvalid     (axil_if.wvalid),
    .dma_axil_wready     (axil_if.wready),
    .dma_axil_wdata      (axil_if.wdata),
    .dma_axil_wstrb      (axil_if.wstrb),
    .dma_axil_bvalid     (axil_if.bvalid),
    .dma_axil_bready     (axil_if.bready),
    .dma_axil_bresp      (axil_if.bresp),
    .dma_axil_arvalid    (axil_if.arvalid),
    .dma_axil_arready    (axil_if.arready),
    .dma_axil_araddr     (axil_if.araddr),
    .dma_axil_arprot     (axil_if.arprot),
    .dma_axil_rvalid     (axil_if.rvalid),
    .dma_axil_rready     (axil_if.rready),
    .dma_axil_rdata      (axil_if.rdata),
    .dma_axil_rresp      (axil_if.rresp),
    .dma_m_axi_awvalid   (axi_mem_if.awvalid),
    .dma_m_axi_awready   (axi_mem_if.awready),
    .dma_m_axi_awaddr    (axi_mem_if.awaddr),
    .dma_m_axi_awlen     (axi_mem_if.awlen),
    .dma_m_axi_awsize    (axi_mem_if.awsize),
    .dma_m_axi_awburst   (axi_mem_if.awburst),
    .dma_m_axi_wvalid    (axi_mem_if.wvalid),
    .dma_m_axi_wready    (axi_mem_if.wready),
    .dma_m_axi_wdata     (axi_mem_if.wdata),
    .dma_m_axi_wstrb     (axi_mem_if.wstrb),
    .dma_m_axi_wlast     (axi_mem_if.wlast),
    .dma_m_axi_bvalid    (axi_mem_if.bvalid),
    .dma_m_axi_bready    (axi_mem_if.bready),
    .dma_m_axi_bresp     (axi_mem_if.bresp),
    .dma_m_axi_arvalid   (axi_mem_if.arvalid),
    .dma_m_axi_arready   (axi_mem_if.arready),
    .dma_m_axi_araddr    (axi_mem_if.araddr),
    .dma_m_axi_arlen     (axi_mem_if.arlen),
    .dma_m_axi_arsize    (axi_mem_if.arsize),
    .dma_m_axi_arburst   (axi_mem_if.arburst),
    .dma_m_axi_rvalid    (axi_mem_if.rvalid),
    .dma_m_axi_rready    (axi_mem_if.rready),
    .dma_m_axi_rdata     (axi_mem_if.rdata),
    .dma_m_axi_rresp     (axi_mem_if.rresp),
    .dma_m_axi_rlast     (axi_mem_if.rlast),
    .dma_spm_wr_valid    (spm_if.wr_valid),
    .dma_spm_wr_ready    (spm_if.wr_ready),
    .dma_spm_wr_type     (spm_if.wr_type),
    .dma_spm_wr_buf_sel  (spm_if.wr_buf_sel),
    .dma_spm_wr_row_idx  (spm_if.wr_row_idx),
    .dma_spm_wr_data     (spm_if.wr_data),
    .dma_spm_wr_strb     (spm_if.wr_strb),
    .dma_spm_wr_last     (spm_if.wr_last),
    .dma_spm_rd_req_valid(spm_if.rd_req_valid),
    .dma_spm_rd_req_ready(spm_if.rd_req_ready),
    .dma_spm_rd_buf_sel  (spm_if.rd_buf_sel),
    .dma_spm_rd_row_idx  (spm_if.rd_row_idx),
    .dma_spm_rd_data_valid(spm_if.rd_data_valid),
    .dma_spm_rd_data_ready(spm_if.rd_data_ready),
    .dma_spm_rd_data     (spm_if.rd_data),
    .dma_spm_rd_last     (spm_if.rd_last),
    .act_buf_writable    (spm_if.act_buf_writable),
    .wgt_buf_writable    (spm_if.wgt_buf_writable),
    .out_buf_readable    (spm_if.out_buf_readable),
    .spm_dma_error       (spm_if.spm_dma_error),
    .spm_dma_error_code  (spm_if.spm_dma_error_code),
    .dma_busy            (status_if.dma_busy),
    .dma_done            (status_if.dma_done),
    .dma_error           (status_if.dma_error),
    .dma_fifo_empty      (status_if.dma_fifo_empty),
    .dma_fifo_full       (status_if.dma_fifo_full),
    .dma_fifo_level      (status_if.dma_fifo_level),
    .dma_done_count      (status_if.dma_done_count),
    .dma_rd_beat_count   (status_if.dma_rd_beat_count),
    .dma_wr_beat_count   (status_if.dma_wr_beat_count),
    .dma_error_code      (status_if.dma_error_code)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 1'b0;
    repeat (10) @(posedge clk);
    rst_n = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual dma_axil_if)::set(null, "*", "axil_vif", axil_if);
    uvm_config_db#(virtual dma_axi_mem_if)::set(null, "*", "axi_mem_vif", axi_mem_if);
    uvm_config_db#(virtual dma_spm_if)::set(null, "*", "spm_vif", spm_if);
    uvm_config_db#(virtual dma_status_if)::set(null, "*", "status_vif", status_if);
    run_test();
  end
endmodule

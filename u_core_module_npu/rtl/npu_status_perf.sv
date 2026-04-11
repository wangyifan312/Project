module npu_status_perf (
  input  logic                                clk,
  input  logic                                rst_n,
  input  logic                                start_pulse,
  input  logic                                armed_in,
  input  logic                                busy_in,
  input  logic                                done_pulse_in,
  input  logic                                error_pulse_in,
  input  logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] error_code_in,
  input  logic                                stall_cycle_pulse_in,
  input  logic                                busy_cycle_pulse_in,
  output logic                                npu_armed,
  output logic                                npu_busy,
  output logic                                npu_done,
  output logic                                npu_error,
  output logic [31:0]                         npu_stall_cycles,
  output logic [31:0]                         npu_busy_cycles,
  output logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] npu_error_code
);

  import u_core_pkg::*;

  assign npu_armed = armed_in;
  assign npu_busy  = busy_in;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      npu_done         <= 1'b0;
      npu_error        <= 1'b0;
      npu_stall_cycles <= 32'h0000_0000;
      npu_busy_cycles  <= 32'h0000_0000;
      npu_error_code   <= '0;
    end else begin
      if (start_pulse) begin
        npu_done <= 1'b0;
      end

      if (done_pulse_in) begin
        npu_done <= 1'b1;
      end

      if (stall_cycle_pulse_in) begin
        npu_stall_cycles <= npu_stall_cycles + 1'b1;
      end

      if (busy_cycle_pulse_in) begin
        npu_busy_cycles <= npu_busy_cycles + 1'b1;
      end

      if (error_pulse_in) begin
        npu_error <= 1'b1;
        if (!npu_error) begin
          npu_error_code <= error_code_in;
        end
      end
    end
  end

endmodule

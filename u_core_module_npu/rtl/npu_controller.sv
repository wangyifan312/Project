module npu_controller (
  input  logic                                clk,
  input  logic                                rst_n,
  input  logic                                start_pulse,
  input  logic [3:0]                          cfg_mode,
  input  logic [7:0]                          cfg_ktile,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    cfg_act_buf_sel,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    cfg_wgt_buf_sel,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    cfg_out_buf_sel,

  input  logic                                spm_npu_vec_valid,
  output logic                                spm_npu_vec_ready,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    spm_npu_act_buf_sel,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    spm_npu_wgt_buf_sel,
  output logic [u_core_pkg::NPU_K_IDX_W-1:0]  spm_npu_k_idx,

  output logic                                npu_spm_out_valid,
  input  logic                                npu_spm_out_ready,
  output logic [u_core_pkg::BUF_SEL_W-1:0]    npu_spm_out_buf_sel,
  output logic [u_core_pkg::NPU_OUT_ROW_W-1:0] npu_spm_out_row_idx,
  output logic                                npu_spm_out_last,

  input  logic [u_core_pkg::BUF_SEL_W-1:0]    act_buf_ready,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    wgt_buf_ready,
  input  logic [u_core_pkg::BUF_SEL_W-1:0]    out_buf_free,
  input  logic                                spm_npu_error,
  input  logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] spm_npu_error_code,

  output logic                                clear_psum,
  output logic                                accum_valid,
  output logic [u_core_pkg::NPU_OUT_ROW_W-1:0] quant_row_idx,

  output logic                                armed_level,
  output logic                                busy_level,
  output logic                                done_pulse,
  output logic                                error_pulse,
  output logic [u_core_pkg::NPU_ERROR_CODE_W-1:0] error_code,
  output logic                                stall_cycle_pulse,
  output logic                                busy_cycle_pulse
);

  import u_core_pkg::*;

  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_NONE          = 8'h00;
  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_START_CONFLICT = 8'h01;
  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_ACT_BUF_SEL   = 8'h02;
  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_WGT_BUF_SEL   = 8'h03;
  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_OUT_BUF_SEL   = 8'h04;
  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_KTILE         = 8'h05;
  localparam logic [NPU_ERROR_CODE_W-1:0] NPU_ERR_SPM           = 8'h06;

  typedef enum logic [2:0] {
    NPU_IDLE  = 3'd0,
    NPU_ARMED = 3'd1,
    NPU_FETCH = 3'd2,
    NPU_DRAIN = 3'd3,
    NPU_WRITE = 3'd4
  } npu_state_e;

  npu_state_e state_r;
  logic [3:0] active_mode_r;
  logic [7:0] active_ktile_r;
  logic [BUF_SEL_W-1:0] active_act_buf_sel_r;
  logic [BUF_SEL_W-1:0] active_wgt_buf_sel_r;
  logic [BUF_SEL_W-1:0] active_out_buf_sel_r;
  logic [NPU_K_IDX_W-1:0] k_idx_r;
  logic [NPU_OUT_ROW_W-1:0] out_row_idx_r;

  function automatic logic buf_index_legal(input logic [BUF_SEL_W-1:0] idx);
    begin
      buf_index_legal = (idx == 2'd0) || (idx == 2'd1);
    end
  endfunction

  function automatic logic buf_status_select(
    input logic [BUF_SEL_W-1:0] status_bits,
    input logic [BUF_SEL_W-1:0] idx
  );
    begin
      case (idx)
        2'd0: buf_status_select = status_bits[0];
        2'd1: buf_status_select = status_bits[1];
        default: buf_status_select = 1'b0;
      endcase
    end
  endfunction

  function automatic logic [NPU_ERROR_CODE_W-1:0] cfg_error_code_f(
    input logic [7:0]                   cfg_ktile_i,
    input logic [BUF_SEL_W-1:0]         cfg_act_i,
    input logic [BUF_SEL_W-1:0]         cfg_wgt_i,
    input logic [BUF_SEL_W-1:0]         cfg_out_i
  );
    begin
      if (!buf_index_legal(cfg_act_i)) begin
        cfg_error_code_f = NPU_ERR_ACT_BUF_SEL;
      end else if (!buf_index_legal(cfg_wgt_i)) begin
        cfg_error_code_f = NPU_ERR_WGT_BUF_SEL;
      end else if (cfg_out_i != 2'd0) begin
        cfg_error_code_f = NPU_ERR_OUT_BUF_SEL;
      end else if ((cfg_ktile_i == 8'h00) || (cfg_ktile_i > ARRAY_K_TILE)) begin
        cfg_error_code_f = NPU_ERR_KTILE;
      end else begin
        cfg_error_code_f = NPU_ERR_NONE;
      end
    end
  endfunction

  logic cfg_valid_w;
  logic [NPU_ERROR_CODE_W-1:0] cfg_error_w;
  logic resources_ready_w;
  logic fetch_fire_w;
  logic write_fire_w;

  always @* begin
    cfg_error_w = cfg_error_code_f(cfg_ktile, cfg_act_buf_sel, cfg_wgt_buf_sel, cfg_out_buf_sel);
    cfg_valid_w = (cfg_error_w == NPU_ERR_NONE);
    resources_ready_w = buf_status_select(act_buf_ready, active_act_buf_sel_r) &&
                        buf_status_select(wgt_buf_ready, active_wgt_buf_sel_r) &&
                        buf_status_select(out_buf_free, active_out_buf_sel_r);
    fetch_fire_w = (state_r == NPU_FETCH) && spm_npu_vec_valid && spm_npu_vec_ready;
    write_fire_w = (state_r == NPU_WRITE) && npu_spm_out_valid && npu_spm_out_ready;
  end

  assign armed_level         = (state_r == NPU_ARMED);
  assign busy_level          = (state_r == NPU_FETCH) || (state_r == NPU_DRAIN) || (state_r == NPU_WRITE);
  assign spm_npu_vec_ready   = (state_r == NPU_FETCH);
  assign spm_npu_act_buf_sel = active_act_buf_sel_r;
  assign spm_npu_wgt_buf_sel = active_wgt_buf_sel_r;
  assign spm_npu_k_idx       = k_idx_r;
  assign npu_spm_out_valid   = (state_r == NPU_WRITE);
  assign npu_spm_out_buf_sel = active_out_buf_sel_r;
  assign npu_spm_out_row_idx = out_row_idx_r;
  assign npu_spm_out_last    = (out_row_idx_r == (ARRAY_M-1));
  assign quant_row_idx       = out_row_idx_r;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_r               <= NPU_IDLE;
      active_mode_r         <= '0;
      active_ktile_r        <= ARRAY_K_TILE[7:0];
      active_act_buf_sel_r  <= '0;
      active_wgt_buf_sel_r  <= '0;
      active_out_buf_sel_r  <= '0;
      k_idx_r               <= '0;
      out_row_idx_r         <= '0;
      clear_psum            <= 1'b0;
      accum_valid           <= 1'b0;
      done_pulse            <= 1'b0;
      error_pulse           <= 1'b0;
      error_code            <= NPU_ERR_NONE;
      stall_cycle_pulse     <= 1'b0;
      busy_cycle_pulse      <= 1'b0;
    end else begin
      clear_psum        <= 1'b0;
      accum_valid       <= 1'b0;
      done_pulse        <= 1'b0;
      error_pulse       <= 1'b0;
      error_code        <= NPU_ERR_NONE;
      stall_cycle_pulse <= 1'b0;
      busy_cycle_pulse  <= 1'b0;

      if (spm_npu_error && (state_r != NPU_IDLE)) begin
        state_r     <= NPU_IDLE;
        error_pulse <= 1'b1;
        error_code  <= (spm_npu_error_code == NPU_ERR_NONE) ? NPU_ERR_SPM : spm_npu_error_code;
      end else begin
        case (state_r)
          NPU_IDLE: begin
            if (start_pulse) begin
              if (!cfg_valid_w) begin
                error_pulse <= 1'b1;
                error_code  <= cfg_error_w;
              end else begin
                active_mode_r        <= cfg_mode;
                active_ktile_r       <= cfg_ktile;
                active_act_buf_sel_r <= cfg_act_buf_sel;
                active_wgt_buf_sel_r <= cfg_wgt_buf_sel;
                active_out_buf_sel_r <= cfg_out_buf_sel;
                k_idx_r              <= '0;
                out_row_idx_r        <= '0;

                if (buf_status_select(act_buf_ready, cfg_act_buf_sel) &&
                    buf_status_select(wgt_buf_ready, cfg_wgt_buf_sel) &&
                    buf_status_select(out_buf_free, cfg_out_buf_sel)) begin
                  clear_psum <= 1'b1;
                  state_r    <= NPU_FETCH;
                end else begin
                  state_r <= NPU_ARMED;
                end
              end
            end
          end

          NPU_ARMED: begin
            stall_cycle_pulse <= 1'b1;

            if (start_pulse) begin
              error_pulse <= 1'b1;
              error_code  <= NPU_ERR_START_CONFLICT;
            end

            if (resources_ready_w) begin
              clear_psum <= 1'b1;
              state_r    <= NPU_FETCH;
            end
          end

          NPU_FETCH: begin
            busy_cycle_pulse <= 1'b1;
            if (!spm_npu_vec_valid) begin
              stall_cycle_pulse <= 1'b1;
            end

            if (start_pulse) begin
              error_pulse <= 1'b1;
              error_code  <= NPU_ERR_START_CONFLICT;
            end

            if (fetch_fire_w) begin
              accum_valid <= 1'b1;
              if (k_idx_r == (active_ktile_r - 1'b1)) begin
                out_row_idx_r <= '0;
                state_r       <= NPU_DRAIN;
              end else begin
                k_idx_r <= k_idx_r + 1'b1;
              end
            end
          end

          NPU_DRAIN: begin
            // Hold one cycle so the last accepted K-step can retire into the
            // psum matrix before row 0 is exposed on the output write path.
            busy_cycle_pulse <= 1'b1;
            state_r          <= NPU_WRITE;
          end

          NPU_WRITE: begin
            if (!npu_spm_out_ready) begin
              stall_cycle_pulse <= 1'b1;
            end

            if (start_pulse) begin
              error_pulse <= 1'b1;
              error_code  <= NPU_ERR_START_CONFLICT;
            end

            if (write_fire_w) begin
              if (out_row_idx_r == (ARRAY_M-1)) begin
                state_r    <= NPU_IDLE;
                done_pulse <= 1'b1;
              end else begin
                out_row_idx_r <= out_row_idx_r + 1'b1;
              end
            end
          end

          default: begin
            state_r <= NPU_IDLE;
          end
        endcase
      end
    end
  end

endmodule

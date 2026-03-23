module axi4_master #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 64,
    parameter int ID_WIDTH   = 4
) (
    input  logic                     aclk,
    input  logic                     aresetn,

    input  logic                     wr_cmd_valid,
    output logic                     wr_cmd_ready,
    input  logic [ID_WIDTH-1:0]      wr_cmd_id,
    input  logic [ADDR_WIDTH-1:0]    wr_cmd_addr,
    input  logic [7:0]               wr_cmd_len,
    input  logic [2:0]               wr_cmd_size,
    input  logic [1:0]               wr_cmd_burst,
    input  logic                     wr_cmd_lock,
    input  logic [3:0]               wr_cmd_cache,
    input  logic [2:0]               wr_cmd_prot,
    input  logic [3:0]               wr_cmd_qos,

    input  logic                     wr_data_valid,
    output logic                     wr_data_ready,
    input  logic [DATA_WIDTH-1:0]    wr_data,
    input  logic [(DATA_WIDTH/8)-1:0] wr_data_strb,

    output logic                     wr_resp_valid,
    input  logic                     wr_resp_ready,
    output logic [ID_WIDTH-1:0]      wr_resp_id,
    output logic [1:0]               wr_resp,
    output logic                     wr_resp_local_err,

    input  logic                     rd_cmd_valid,
    output logic                     rd_cmd_ready,
    input  logic [ID_WIDTH-1:0]      rd_cmd_id,
    input  logic [ADDR_WIDTH-1:0]    rd_cmd_addr,
    input  logic [7:0]               rd_cmd_len,
    input  logic [2:0]               rd_cmd_size,
    input  logic [1:0]               rd_cmd_burst,
    input  logic                     rd_cmd_lock,
    input  logic [3:0]               rd_cmd_cache,
    input  logic [2:0]               rd_cmd_prot,
    input  logic [3:0]               rd_cmd_qos,

    output logic                     rd_data_valid,
    input  logic                     rd_data_ready,
    output logic [ID_WIDTH-1:0]      rd_data_id,
    output logic [DATA_WIDTH-1:0]    rd_data,
    output logic [1:0]               rd_data_resp,
    output logic                     rd_data_last,
    output logic                     rd_data_local_err,

    output logic [ID_WIDTH-1:0]      M_AXI_AWID,
    output logic [ADDR_WIDTH-1:0]    M_AXI_AWADDR,
    output logic [7:0]               M_AXI_AWLEN,
    output logic [2:0]               M_AXI_AWSIZE,
    output logic [1:0]               M_AXI_AWBURST,
    output logic                     M_AXI_AWLOCK,
    output logic [3:0]               M_AXI_AWCACHE,
    output logic [2:0]               M_AXI_AWPROT,
    output logic [3:0]               M_AXI_AWQOS,
    output logic                     M_AXI_AWVALID,
    input  logic                     M_AXI_AWREADY,

    output logic [DATA_WIDTH-1:0]    M_AXI_WDATA,
    output logic [(DATA_WIDTH/8)-1:0] M_AXI_WSTRB,
    output logic                     M_AXI_WLAST,
    output logic                     M_AXI_WVALID,
    input  logic                     M_AXI_WREADY,

    input  logic [ID_WIDTH-1:0]      M_AXI_BID,
    input  logic [1:0]               M_AXI_BRESP,
    input  logic                     M_AXI_BVALID,
    output logic                     M_AXI_BREADY,

    output logic [ID_WIDTH-1:0]      M_AXI_ARID,
    output logic [ADDR_WIDTH-1:0]    M_AXI_ARADDR,
    output logic [7:0]               M_AXI_ARLEN,
    output logic [2:0]               M_AXI_ARSIZE,
    output logic [1:0]               M_AXI_ARBURST,
    output logic                     M_AXI_ARLOCK,
    output logic [3:0]               M_AXI_ARCACHE,
    output logic [2:0]               M_AXI_ARPROT,
    output logic [3:0]               M_AXI_ARQOS,
    output logic                     M_AXI_ARVALID,
    input  logic                     M_AXI_ARREADY,

    input  logic [ID_WIDTH-1:0]      M_AXI_RID,
    input  logic [DATA_WIDTH-1:0]    M_AXI_RDATA,
    input  logic [1:0]               M_AXI_RRESP,
    input  logic                     M_AXI_RLAST,
    input  logic                     M_AXI_RVALID,
    output logic                     M_AXI_RREADY
);

    localparam int DATA_BYTES = DATA_WIDTH / 8;
    localparam logic [1:0] AXI_RESP_DECERR = 2'b11;
    localparam logic [1:0] AXI_BURST_FIXED = 2'b00;
    localparam logic [1:0] AXI_BURST_INCR  = 2'b01;
    localparam logic [1:0] AXI_BURST_WRAP  = 2'b10;

    typedef enum logic [1:0] {
        WR_IDLE,
        WR_AW,
        WR_DATA,
        WR_RESP
    } wr_state_t;

    typedef enum logic [1:0] {
        RD_IDLE,
        RD_AR,
        RD_DATA
    } rd_state_t;

    wr_state_t wr_state;
    rd_state_t rd_state;

    logic [8:0] wr_total_beats;
    logic [8:0] wr_load_beats;
    logic [ID_WIDTH-1:0] wr_active_id;

    logic       w_buf_valid;
    logic [DATA_WIDTH-1:0] w_buf_data;
    logic [(DATA_WIDTH/8)-1:0] w_buf_strb;
    logic       w_buf_last;

    logic       rd_buf_valid;
    logic [ID_WIDTH-1:0] rd_active_id;
    logic [ID_WIDTH-1:0] rd_buf_id;
    logic [DATA_WIDTH-1:0] rd_buf_data;
    logic [1:0] rd_buf_resp;
    logic       rd_buf_last;
    logic       rd_buf_local_err;

    logic       wr_resp_valid_r;
    logic [ID_WIDTH-1:0] wr_resp_id_r;
    logic [1:0] wr_resp_r;
    logic       wr_resp_local_err_r;

    logic       wr_cmd_legal;
    logic       rd_cmd_legal;

    function automatic logic [8:0] burst_beats(input logic [7:0] len);
        burst_beats = {1'b0, len} + 9'd1;
    endfunction

    function automatic logic [ADDR_WIDTH:0] bytes_per_beat(input logic [2:0] size);
        bytes_per_beat = {{ADDR_WIDTH{1'b0}}, 1'b1} << size;
    endfunction

    function automatic logic is_wrap_len_legal(input logic [7:0] len);
        is_wrap_len_legal = (len == 8'd1) || (len == 8'd3) || (len == 8'd7) || (len == 8'd15);
    endfunction

    function automatic logic [ADDR_WIDTH:0] burst_window_last_addr(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [7:0]            len,
        input logic [2:0]            size,
        input logic [1:0]            burst
    );
        logic [ADDR_WIDTH:0] beat_bytes;
        logic [ADDR_WIDTH:0] total_bytes;
        logic [ADDR_WIDTH:0] base_addr;
        logic [ADDR_WIDTH:0] addr_ext;
        begin
            beat_bytes = bytes_per_beat(size);
            total_bytes = beat_bytes * burst_beats(len);
            addr_ext = {1'b0, addr};
            base_addr = addr_ext;
            if (burst == AXI_BURST_WRAP) begin
                base_addr = (addr_ext / total_bytes) * total_bytes;
                burst_window_last_addr = base_addr + total_bytes - 1'b1;
            end else if (burst == AXI_BURST_FIXED) begin
                burst_window_last_addr = addr_ext + beat_bytes - 1'b1;
            end else begin
                burst_window_last_addr = addr_ext + total_bytes - 1'b1;
            end
        end
    endfunction

    function automatic logic is_cmd_legal(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [7:0]            len,
        input logic [2:0]            size,
        input logic [1:0]            burst
    );
        logic [ADDR_WIDTH:0] last_addr;
        logic size_ok;
        logic burst_ok;
        logic len_ok;
        logic wrap_align_ok;
        begin
            size_ok = (DATA_WIDTH >= 8) && (size <= $clog2(DATA_BYTES));
            burst_ok = (burst != 2'b11);
            len_ok = 1'b0;
            wrap_align_ok = 1'b1;

            unique case (burst)
                AXI_BURST_FIXED: len_ok = (len <= 8'd15);
                AXI_BURST_INCR:  len_ok = 1'b1;
                AXI_BURST_WRAP: begin
                    len_ok = is_wrap_len_legal(len);
                    wrap_align_ok = ((addr & (bytes_per_beat(size) - 1'b1)) == '0);
                end
                default: len_ok = 1'b0;
            endcase

            last_addr = burst_window_last_addr(addr, len, size, burst);
            is_cmd_legal = size_ok &&
                           burst_ok &&
                           len_ok &&
                           wrap_align_ok &&
                           ({1'b0, addr[ADDR_WIDTH-1:12]} == last_addr[ADDR_WIDTH:12]);
        end
    endfunction

    assign wr_cmd_legal = is_cmd_legal(wr_cmd_addr, wr_cmd_len, wr_cmd_size, wr_cmd_burst);
    assign rd_cmd_legal = is_cmd_legal(rd_cmd_addr, rd_cmd_len, rd_cmd_size, rd_cmd_burst);

    assign wr_cmd_ready = (wr_state == WR_IDLE) && !wr_resp_valid_r;
    assign rd_cmd_ready = (rd_state == RD_IDLE) && !rd_buf_valid;

    assign wr_data_ready = (wr_state == WR_DATA) &&
                           (wr_load_beats < wr_total_beats) &&
                           (!w_buf_valid || M_AXI_WREADY);

    assign M_AXI_AWID    = wr_active_id;

    assign M_AXI_WDATA  = w_buf_data;
    assign M_AXI_WSTRB  = w_buf_strb;
    assign M_AXI_WLAST  = w_buf_last;
    assign M_AXI_WVALID = w_buf_valid;

    assign M_AXI_BREADY = !wr_resp_valid_r || wr_resp_ready;

    assign M_AXI_ARID    = rd_active_id;

    assign M_AXI_RREADY = (rd_state == RD_DATA) && (!rd_buf_valid || rd_data_ready);

    assign wr_resp_valid     = wr_resp_valid_r;
    assign wr_resp_id        = wr_resp_id_r;
    assign wr_resp           = wr_resp_r;
    assign wr_resp_local_err = wr_resp_local_err_r;

    assign rd_data_valid     = rd_buf_valid;
    assign rd_data_id        = rd_buf_id;
    assign rd_data           = rd_buf_data;
    assign rd_data_resp      = rd_buf_resp;
    assign rd_data_last      = rd_buf_last;
    assign rd_data_local_err = rd_buf_local_err;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wr_state            <= WR_IDLE;
            rd_state            <= RD_IDLE;
            wr_total_beats      <= '0;
            wr_load_beats       <= '0;
            wr_active_id        <= '0;
            w_buf_valid         <= 1'b0;
            w_buf_data          <= '0;
            w_buf_strb          <= '0;
            w_buf_last          <= 1'b0;
            wr_resp_valid_r     <= 1'b0;
            wr_resp_id_r        <= '0;
            wr_resp_r           <= '0;
            wr_resp_local_err_r <= 1'b0;
            rd_buf_valid        <= 1'b0;
            rd_active_id        <= '0;
            rd_buf_id           <= '0;
            rd_buf_data         <= '0;
            rd_buf_resp         <= '0;
            rd_buf_last         <= 1'b0;
            rd_buf_local_err    <= 1'b0;
            M_AXI_AWADDR        <= '0;
            M_AXI_AWLEN         <= '0;
            M_AXI_AWSIZE        <= '0;
            M_AXI_AWBURST       <= AXI_BURST_INCR;
            M_AXI_AWLOCK        <= 1'b0;
            M_AXI_AWCACHE       <= '0;
            M_AXI_AWPROT        <= '0;
            M_AXI_AWQOS         <= '0;
            M_AXI_AWVALID       <= 1'b0;
            M_AXI_ARADDR        <= '0;
            M_AXI_ARLEN         <= '0;
            M_AXI_ARSIZE        <= '0;
            M_AXI_ARBURST       <= AXI_BURST_INCR;
            M_AXI_ARLOCK        <= 1'b0;
            M_AXI_ARCACHE       <= '0;
            M_AXI_ARPROT        <= '0;
            M_AXI_ARQOS         <= '0;
            M_AXI_ARVALID       <= 1'b0;
        end else begin
            if (wr_resp_valid_r && wr_resp_ready && !(M_AXI_BVALID && M_AXI_BREADY)) begin
                wr_resp_valid_r     <= 1'b0;
                wr_resp_id_r        <= '0;
                wr_resp_r           <= '0;
                wr_resp_local_err_r <= 1'b0;
            end

            if (rd_buf_valid && rd_data_ready && !(M_AXI_RVALID && M_AXI_RREADY)) begin
                rd_buf_valid     <= 1'b0;
                rd_buf_id        <= '0;
                rd_buf_data      <= '0;
                rd_buf_resp      <= '0;
                rd_buf_last      <= 1'b0;
                rd_buf_local_err <= 1'b0;
            end

            if (w_buf_valid && M_AXI_WREADY) begin
                if (!(wr_data_valid && wr_data_ready)) begin
                    w_buf_valid <= 1'b0;
                    w_buf_data  <= '0;
                    w_buf_strb  <= '0;
                    w_buf_last  <= 1'b0;
                end
            end

            if (wr_data_valid && wr_data_ready) begin
                w_buf_valid    <= 1'b1;
                w_buf_data     <= wr_data;
                w_buf_strb     <= wr_data_strb;
                w_buf_last     <= (wr_load_beats == (wr_total_beats - 1'b1));
                wr_load_beats  <= wr_load_beats + 1'b1;
            end

            if (M_AXI_BVALID && M_AXI_BREADY) begin
                wr_resp_valid_r     <= 1'b1;
                wr_resp_id_r        <= M_AXI_BID;
                wr_resp_r           <= M_AXI_BRESP;
                wr_resp_local_err_r <= 1'b0;
            end

            if (M_AXI_RVALID && M_AXI_RREADY) begin
                rd_buf_valid     <= 1'b1;
                rd_buf_id        <= M_AXI_RID;
                rd_buf_data      <= M_AXI_RDATA;
                rd_buf_resp      <= M_AXI_RRESP;
                rd_buf_last      <= M_AXI_RLAST;
                rd_buf_local_err <= 1'b0;
            end

            unique case (wr_state)
                WR_IDLE: begin
                    wr_total_beats <= '0;
                    wr_load_beats  <= '0;
                    if (wr_cmd_valid && wr_cmd_ready) begin
                        wr_active_id <= wr_cmd_id;
                        if (wr_cmd_legal) begin
                            M_AXI_AWADDR  <= wr_cmd_addr;
                            M_AXI_AWLEN   <= wr_cmd_len;
                            M_AXI_AWSIZE  <= wr_cmd_size;
                            M_AXI_AWBURST <= wr_cmd_burst;
                            M_AXI_AWLOCK  <= wr_cmd_lock;
                            M_AXI_AWCACHE <= wr_cmd_cache;
                            M_AXI_AWPROT  <= wr_cmd_prot;
                            M_AXI_AWQOS   <= wr_cmd_qos;
                            M_AXI_AWVALID <= 1'b1;
                            wr_total_beats <= burst_beats(wr_cmd_len);
                            wr_state       <= WR_AW;
                        end else begin
                            wr_resp_valid_r     <= 1'b1;
                            wr_resp_id_r        <= wr_cmd_id;
                            wr_resp_r           <= AXI_RESP_DECERR;
                            wr_resp_local_err_r <= 1'b1;
                        end
                    end
                end

                WR_AW: begin
                    if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                        M_AXI_AWVALID <= 1'b0;
                        wr_state      <= WR_DATA;
                    end
                end

                WR_DATA: begin
                    if (w_buf_valid && M_AXI_WREADY && w_buf_last) begin
                        wr_state <= WR_RESP;
                    end
                end

                WR_RESP: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        wr_state <= WR_IDLE;
                    end
                end

                default: wr_state <= WR_IDLE;
            endcase

            unique case (rd_state)
                RD_IDLE: begin
                    if (rd_cmd_valid && rd_cmd_ready) begin
                        if (rd_cmd_legal) begin
                            rd_active_id   <= rd_cmd_id;
                            M_AXI_ARADDR  <= rd_cmd_addr;
                            M_AXI_ARLEN   <= rd_cmd_len;
                            M_AXI_ARSIZE  <= rd_cmd_size;
                            M_AXI_ARBURST <= rd_cmd_burst;
                            M_AXI_ARLOCK  <= rd_cmd_lock;
                            M_AXI_ARCACHE <= rd_cmd_cache;
                            M_AXI_ARPROT  <= rd_cmd_prot;
                            M_AXI_ARQOS   <= rd_cmd_qos;
                            M_AXI_ARVALID <= 1'b1;
                            rd_state      <= RD_AR;
                        end else begin
                            rd_buf_valid     <= 1'b1;
                            rd_buf_id        <= rd_cmd_id;
                            rd_buf_data      <= '0;
                            rd_buf_resp      <= AXI_RESP_DECERR;
                            rd_buf_last      <= 1'b1;
                            rd_buf_local_err <= 1'b1;
                        end
                    end
                end

                RD_AR: begin
                    if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 1'b0;
                        rd_state      <= RD_DATA;
                    end
                end

                RD_DATA: begin
                    if (M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST) begin
                        rd_state <= RD_IDLE;
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase
        end
    end

`ifdef ASSERT_ON
    property p_aw_stable;
        @(posedge aclk) disable iff (!aresetn)
            M_AXI_AWVALID && !M_AXI_AWREADY |=> M_AXI_AWVALID &&
                $stable({M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST,
                         M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS});
    endproperty

    property p_ar_stable;
        @(posedge aclk) disable iff (!aresetn)
            M_AXI_ARVALID && !M_AXI_ARREADY |=> M_AXI_ARVALID &&
                $stable({M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST,
                         M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS});
    endproperty

    property p_w_stable;
        @(posedge aclk) disable iff (!aresetn)
            M_AXI_WVALID && !M_AXI_WREADY |=> M_AXI_WVALID &&
                $stable({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST});
    endproperty

    assert property (p_aw_stable);
    assert property (p_ar_stable);
    assert property (p_w_stable);
`endif

endmodule

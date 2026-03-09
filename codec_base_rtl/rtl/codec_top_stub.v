`include "codec_defs.vh"
//------------------------------------------------------------------------------
// File: codec_top_stub.v
// Description:
//   Minimal codec IP top-level skeleton.
//
// Control path:
//   host CSR -> codec_regfile -> codec_ctrl -> datapath enable/flush/clear
//
// Data path:
//   input stream -> skid -> pipe -> sync_fifo -> packer -> output stream
//
// This stub intentionally does not contain a codec algorithm kernel. It exists
// to prove out the integration skeleton, control/status plumbing, and baseline
// stream buffering behavior that future video/audio/custom codec datapaths can
// be inserted into.
//------------------------------------------------------------------------------
module codec_top_stub (clk, rst_n,
                       csr_valid, csr_write, csr_addr, csr_wdata,
                       csr_ready, csr_rvalid, csr_rdata, irq_o,
                       in_valid, in_ready, in_data, in_last, in_user,
                       out_valid, out_ready, out_data, out_last, out_user,
                       out_valid_count, out_valid_mask);

    parameter CSR_ADDR_W = 8;
    parameter CSR_DATA_W = 32;
    parameter IN_W       = 8;
    parameter OUT_W      = 32;
    parameter USER_W     = 4;
    parameter FIFO_DEPTH = 16;
    parameter COUNTER_W  = 32;

    function integer codec_packer_count_w;
        input integer out_width;
        input integer in_width;
        integer ratio;
        integer tmp;
        begin
            ratio = out_width / in_width;
            tmp = ratio;
            codec_packer_count_w = 0;
            while (tmp > 0) begin
                tmp = tmp >> 1;
                codec_packer_count_w = codec_packer_count_w + 1;
            end
        end
    endfunction

    localparam PACK_COUNT_W = codec_packer_count_w(OUT_W, IN_W);

    input                           clk;
    input                           rst_n;
    input                           csr_valid;
    input                           csr_write;
    input      [CSR_ADDR_W-1:0]     csr_addr;
    input      [CSR_DATA_W-1:0]     csr_wdata;
    output                          csr_ready;
    output                          csr_rvalid;
    output     [CSR_DATA_W-1:0]     csr_rdata;
    output                          irq_o;
    input                           in_valid;
    output                          in_ready;
    input      [IN_W-1:0]           in_data;
    input                           in_last;
    input      [USER_W-1:0]         in_user;
    output                          out_valid;
    input                           out_ready;
    output     [OUT_W-1:0]          out_data;
    output                          out_last;
    output     [USER_W-1:0]         out_user;
    output     [PACK_COUNT_W-1:0]   out_valid_count;
    output     [(OUT_W/IN_W)-1:0]   out_valid_mask;

    wire                     cfg_enable;
    wire                     cmd_start;
    wire                     cmd_stop;
    wire                     cmd_soft_reset;
    wire                     cmd_flush;

    wire [`CODEC_STATE_W-1:0] ctrl_state;
    wire                     ctrl_busy;
    wire                     ctrl_done;
    wire                     ctrl_error;
    wire                     ctrl_flush_active;
    wire                     ctrl_idle;
    wire                     ctrl_accept_input;
    wire                     ctrl_clear_pipeline;
    wire                     ctrl_done_pulse;
    wire                     ctrl_error_pulse;

    wire                     local_clear;
    wire                     monitor_clear;

    wire                     core_in_valid;
    wire                     skid_in_ready;

    wire                     skid_out_valid;
    wire                     skid_out_ready;
    wire [IN_W-1:0]          skid_out_data;
    wire                     skid_out_last;
    wire [USER_W-1:0]        skid_out_user;
    wire                     skid_holding;

    wire                     pipe_out_valid;
    wire                     pipe_out_ready;
    wire [IN_W-1:0]          pipe_out_data;
    wire                     pipe_out_last;
    wire [USER_W-1:0]        pipe_out_user;
    wire                     pipe_holding;

    wire                     fifo_out_valid;
    wire                     fifo_out_ready;
    wire [IN_W-1:0]          fifo_out_data;
    wire                     fifo_out_last;
    wire [USER_W-1:0]        fifo_out_user;
    wire                     fifo_empty;

    wire                     packer_out_valid;
    wire [OUT_W-1:0]         packer_out_data;
    wire                     packer_out_last;
    wire [USER_W-1:0]        packer_out_user;
    wire [PACK_COUNT_W-1:0]  packer_out_count;
    wire [(OUT_W/IN_W)-1:0]  packer_out_mask;
    wire                     packer_pending;

    wire                     pipeline_empty;
    wire                     op_done_evt;

    wire                     perf_stall;
    wire                     perf_input_beat;
    wire                     perf_output_beat;
    wire [COUNTER_W-1:0]     perf_cycle_cnt;
    wire [COUNTER_W-1:0]     perf_stall_cnt;
    wire [COUNTER_W-1:0]     perf_input_cnt;
    wire [COUNTER_W-1:0]     perf_output_cnt;
    wire [COUNTER_W-1:0]     perf_frame_done_cnt;

    wire [4:0]               error_status_full;
    wire [3:0]               error_status;
    wire                     error_any;
    wire                     protocol_error_evt;

    reg                      stall_hold_active_reg;
    reg [IN_W-1:0]           stall_hold_data_reg;
    reg                      stall_hold_last_reg;
    reg [USER_W-1:0]         stall_hold_user_reg;
    reg                      protocol_error_pulse_reg;

    assign local_clear   = cmd_soft_reset | ctrl_clear_pipeline;
    assign monitor_clear = cmd_soft_reset;

    assign core_in_valid = in_valid & ctrl_accept_input;
    assign in_ready      = ctrl_accept_input & skid_in_ready;

    assign pipeline_empty = (~skid_holding) & (~pipe_holding) & fifo_empty & (~packer_pending);
    assign op_done_evt    = out_valid & out_ready & out_last;

    assign out_valid       = packer_out_valid;
    assign out_data        = packer_out_data;
    assign out_last        = packer_out_last;
    assign out_user        = packer_out_user;
    assign out_valid_count = packer_out_count;
    assign out_valid_mask  = packer_out_mask;

    assign perf_input_beat  = core_in_valid & in_ready;
    assign perf_output_beat = out_valid & out_ready;
    assign perf_stall       = ctrl_busy & ((in_valid & (~in_ready)) | (out_valid & (~out_ready)));
    assign protocol_error_evt = protocol_error_pulse_reg;
    assign error_status = error_status_full[3:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stall_hold_active_reg  <= 1'b0;
            stall_hold_data_reg    <= {IN_W{1'b0}};
            stall_hold_last_reg    <= 1'b0;
            stall_hold_user_reg    <= {USER_W{1'b0}};
            protocol_error_pulse_reg <= 1'b0;
        end else if (monitor_clear) begin
            stall_hold_active_reg  <= 1'b0;
            stall_hold_data_reg    <= {IN_W{1'b0}};
            stall_hold_last_reg    <= 1'b0;
            stall_hold_user_reg    <= {USER_W{1'b0}};
            protocol_error_pulse_reg <= 1'b0;
        end else begin
            protocol_error_pulse_reg <= 1'b0;

            if (ctrl_busy & in_valid & (~in_ready)) begin
                if (!stall_hold_active_reg) begin
                    stall_hold_active_reg <= 1'b1;
                    stall_hold_data_reg   <= in_data;
                    stall_hold_last_reg   <= in_last;
                    stall_hold_user_reg   <= in_user;
                end else if ((stall_hold_data_reg != in_data) ||
                             (stall_hold_last_reg != in_last) ||
                             (stall_hold_user_reg != in_user)) begin
                    protocol_error_pulse_reg <= 1'b1;
                    stall_hold_data_reg      <= in_data;
                    stall_hold_last_reg      <= in_last;
                    stall_hold_user_reg      <= in_user;
                end
            end else begin
                stall_hold_active_reg <= 1'b0;
            end
        end
    end

    codec_regfile #(
        .ADDR_W(CSR_ADDR_W),
        .DATA_W(CSR_DATA_W),
        .COUNTER_W(COUNTER_W),
        .ERR_W(4)
    ) u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .csr_valid(csr_valid),
        .csr_write(csr_write),
        .csr_addr(csr_addr),
        .csr_wdata(csr_wdata),
        .csr_ready(csr_ready),
        .csr_rvalid(csr_rvalid),
        .csr_rdata(csr_rdata),
        .cfg_enable_o(cfg_enable),
        .cmd_start_pulse_o(cmd_start),
        .cmd_stop_pulse_o(cmd_stop),
        .cmd_soft_reset_pulse_o(cmd_soft_reset),
        .cmd_flush_pulse_o(cmd_flush),
        .status_idle_i(ctrl_idle),
        .status_busy_i(ctrl_busy),
        .status_done_i(ctrl_done),
        .status_error_i(ctrl_error),
        .status_flush_i(ctrl_flush_active),
        .irq_done_event_i(ctrl_done_pulse),
        .irq_error_event_i(ctrl_error_pulse),
        .irq_o(irq_o),
        .perf_cycle_cnt_i(perf_cycle_cnt),
        .perf_stall_cnt_i(perf_stall_cnt),
        .perf_input_beat_cnt_i(perf_input_cnt),
        .perf_output_beat_cnt_i(perf_output_cnt),
        .perf_frame_done_cnt_i(perf_frame_done_cnt),
        .error_status_i(error_status)
    );

    codec_ctrl u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .enable_i(cfg_enable),
        .start_i(cmd_start),
        .stop_i(cmd_stop),
        .soft_reset_i(cmd_soft_reset),
        .flush_i(cmd_flush),
        .error_i(error_any),
        .op_done_i(op_done_evt),
        .pipe_empty_i(pipeline_empty),
        .state_o(ctrl_state),
        .busy_o(ctrl_busy),
        .done_o(ctrl_done),
        .error_state_o(ctrl_error),
        .flush_active_o(ctrl_flush_active),
        .idle_o(ctrl_idle),
        .accept_input_o(ctrl_accept_input),
        .clear_pipeline_o(ctrl_clear_pipeline),
        .done_pulse_o(ctrl_done_pulse),
        .error_pulse_o(ctrl_error_pulse)
    );

    codec_skid_buffer #(
        .DATA_W(IN_W),
        .USER_W(USER_W)
    ) u_skid (
        .clk(clk),
        .rst_n(rst_n),
        .clear_i(local_clear),
        .in_valid(core_in_valid),
        .in_ready(skid_in_ready),
        .in_data(in_data),
        .in_last(in_last),
        .in_user(in_user),
        .out_valid(skid_out_valid),
        .out_ready(skid_out_ready),
        .out_data(skid_out_data),
        .out_last(skid_out_last),
        .out_user(skid_out_user),
        .holding_o(skid_holding)
    );

    codec_pipe_reg #(
        .DATA_W(IN_W),
        .USER_W(USER_W)
    ) u_pipe (
        .clk(clk),
        .rst_n(rst_n),
        .clear_i(local_clear),
        .in_valid(skid_out_valid),
        .in_ready(skid_out_ready),
        .in_data(skid_out_data),
        .in_last(skid_out_last),
        .in_user(skid_out_user),
        .out_valid(pipe_out_valid),
        .out_ready(pipe_out_ready),
        .out_data(pipe_out_data),
        .out_last(pipe_out_last),
        .out_user(pipe_out_user),
        .holding_o(pipe_holding)
    );

    codec_sync_fifo #(
        .DATA_W(IN_W),
        .USER_W(USER_W),
        .DEPTH(FIFO_DEPTH)
    ) u_sync_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .clear_i(local_clear),
        .in_valid(pipe_out_valid),
        .in_ready(pipe_out_ready),
        .in_data(pipe_out_data),
        .in_last(pipe_out_last),
        .in_user(pipe_out_user),
        .out_valid(fifo_out_valid),
        .out_ready(fifo_out_ready),
        .out_data(fifo_out_data),
        .out_last(fifo_out_last),
        .out_user(fifo_out_user),
        .full_o(),
        .empty_o(fifo_empty),
        .level_o()
    );

    codec_packer #(
        .IN_W(IN_W),
        .OUT_W(OUT_W),
        .USER_W(USER_W)
    ) u_packer (
        .clk(clk),
        .rst_n(rst_n),
        .clear_i(local_clear),
        .flush_i(ctrl_flush_active),
        .in_valid(fifo_out_valid),
        .in_ready(fifo_out_ready),
        .in_data(fifo_out_data),
        .in_last(fifo_out_last),
        .in_user(fifo_out_user),
        .out_valid(packer_out_valid),
        .out_ready(out_ready),
        .out_data(packer_out_data),
        .out_valid_count(packer_out_count),
        .out_valid_mask(packer_out_mask),
        .out_last(packer_out_last),
        .out_user(packer_out_user),
        .pending_o(packer_pending)
    );

    codec_perf_counter #(
        .COUNTER_W(COUNTER_W)
    ) u_perf_counter (
        .clk(clk),
        .rst_n(rst_n),
        .clear_i(monitor_clear),
        .enable_i(ctrl_busy),
        .stall_i(perf_stall),
        .input_beat_i(perf_input_beat),
        .output_beat_i(perf_output_beat),
        .frame_done_i(ctrl_done_pulse),
        .cycle_cnt_o(perf_cycle_cnt),
        .stall_cycle_cnt_o(perf_stall_cnt),
        .input_beat_cnt_o(perf_input_cnt),
        .output_beat_cnt_o(perf_output_cnt),
        .frame_done_cnt_o(perf_frame_done_cnt)
    );

    codec_err_monitor #(
        .EXTRA_ERR_W(0)
    ) u_err_monitor (
        .clk(clk),
        .rst_n(rst_n),
        .clear_i(monitor_clear),
        .enable_i(1'b1),
        .overflow_i(1'b0),
        .underflow_i(1'b0),
        .protocol_error_i(protocol_error_evt),
        .illegal_cfg_i(1'b0),
        .extra_error_i(1'b0),
        .error_status_o(error_status_full),
        .error_any_o(error_any)
    );

endmodule

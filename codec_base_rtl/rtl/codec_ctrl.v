`include "codec_defs.vh"
//------------------------------------------------------------------------------
// File: codec_ctrl.v
// Description:
//   Top-level codec control FSM.
//
// State behavior:
//   IDLE  : waits for enable_i + start_i.
//   RUN   : accepts input, tracks datapath completion, and responds to stop,
//           flush, and error requests.
//   FLUSH : blocks new input and waits until pipe_empty_i indicates all queued
//           data has drained.
//   DONE  : sticky completion state, cleared by a new start or soft_reset.
//   ERR   : sticky error state, cleared by a new start or soft_reset.
//
// Key assumptions:
//   - op_done_i is a pulse or level indicating the logical end of the current
//     job. If residual buffered data still exists, this module holds a private
//     done_pending flag and waits for pipe_empty_i before entering DONE.
//   - soft_reset_i is a higher-priority hard clear. It returns the FSM to IDLE
//     and pulses clear_pipeline_o for one cycle.
//------------------------------------------------------------------------------
module codec_ctrl (
    input                   clk,
    input                   rst_n,

    input                   enable_i,
    input                   start_i,
    input                   stop_i,
    input                   soft_reset_i,
    input                   flush_i,
    input                   error_i,
    input                   op_done_i,
    input                   pipe_empty_i,

    output reg [`CODEC_STATE_W-1:0] state_o,
    output reg              busy_o,
    output reg              done_o,
    output reg              error_state_o,
    output reg              flush_active_o,
    output reg              idle_o,
    output reg              accept_input_o,
    output reg              clear_pipeline_o,
    output reg              done_pulse_o,
    output reg              error_pulse_o
);

    reg [`CODEC_STATE_W-1:0] state_nxt;
    reg done_pending_reg;
    reg done_pending_nxt;

    always @(*) begin
        state_nxt        = state_o;
        done_pending_nxt = done_pending_reg;

        if (soft_reset_i) begin
            state_nxt        = `CODEC_ST_IDLE;
            done_pending_nxt = 1'b0;
        end else begin
            case (state_o)
                `CODEC_ST_IDLE: begin
                    done_pending_nxt = 1'b0;
                    if (enable_i && start_i) begin
                        state_nxt = `CODEC_ST_RUN;
                    end
                end

                `CODEC_ST_RUN: begin
                    if (error_i) begin
                        state_nxt        = `CODEC_ST_ERR;
                        done_pending_nxt = 1'b0;
                    end else if (stop_i || flush_i) begin
                        state_nxt        = `CODEC_ST_FLUSH;
                        done_pending_nxt = 1'b0;
                    end else if ((op_done_i || done_pending_reg) && pipe_empty_i) begin
                        state_nxt        = `CODEC_ST_DONE;
                        done_pending_nxt = 1'b0;
                    end else if (op_done_i && !pipe_empty_i) begin
                        state_nxt        = `CODEC_ST_RUN;
                        done_pending_nxt = 1'b1;
                    end
                end

                `CODEC_ST_FLUSH: begin
                    done_pending_nxt = 1'b0;
                    if (error_i) begin
                        state_nxt = `CODEC_ST_ERR;
                    end else if (pipe_empty_i) begin
                        state_nxt = `CODEC_ST_DONE;
                    end
                end

                `CODEC_ST_DONE: begin
                    done_pending_nxt = 1'b0;
                    if (enable_i && start_i) begin
                        state_nxt = `CODEC_ST_RUN;
                    end else if (!enable_i) begin
                        state_nxt = `CODEC_ST_IDLE;
                    end
                end

                `CODEC_ST_ERR: begin
                    done_pending_nxt = 1'b0;
                    if (enable_i && start_i && !error_i) begin
                        state_nxt = `CODEC_ST_RUN;
                    end else if (!enable_i) begin
                        state_nxt = `CODEC_ST_IDLE;
                    end
                end

                default: begin
                    state_nxt        = `CODEC_ST_IDLE;
                    done_pending_nxt = 1'b0;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_o           <= `CODEC_ST_IDLE;
            done_pending_reg  <= 1'b0;
            clear_pipeline_o  <= 1'b0;
            done_pulse_o      <= 1'b0;
            error_pulse_o     <= 1'b0;
        end else begin
            state_o          <= state_nxt;
            done_pending_reg <= done_pending_nxt;

            clear_pipeline_o <= 1'b0;
            done_pulse_o     <= 1'b0;
            error_pulse_o    <= 1'b0;

            if (soft_reset_i) begin
                clear_pipeline_o <= 1'b1;
            end else begin
                if ((state_o != `CODEC_ST_ERR) && (state_nxt == `CODEC_ST_ERR)) begin
                    clear_pipeline_o <= 1'b1;
                    error_pulse_o    <= 1'b1;
                end

                if ((state_o != `CODEC_ST_DONE) && (state_nxt == `CODEC_ST_DONE)) begin
                    done_pulse_o <= 1'b1;
                end
            end
        end
    end

    always @(*) begin
        idle_o          = 1'b0;
        busy_o          = 1'b0;
        done_o          = 1'b0;
        error_state_o   = 1'b0;
        flush_active_o  = 1'b0;
        accept_input_o  = 1'b0;

        case (state_o)
            `CODEC_ST_IDLE: begin
                idle_o = 1'b1;
            end

            `CODEC_ST_RUN: begin
                busy_o         = 1'b1;
                accept_input_o = ~done_pending_reg;
            end

            `CODEC_ST_FLUSH: begin
                busy_o         = 1'b1;
                flush_active_o = 1'b1;
            end

            `CODEC_ST_DONE: begin
                done_o = 1'b1;
            end

            `CODEC_ST_ERR: begin
                error_state_o = 1'b1;
            end

            default: begin
                idle_o = 1'b1;
            end
        endcase
    end

endmodule

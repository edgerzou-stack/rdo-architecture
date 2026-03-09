//------------------------------------------------------------------------------
// File: codec_perf_counter.v
// Description:
//   Simple performance monitor block for first-pass codec bring-up.
//
// Count rules:
//   - cycle_cnt_o increments every enabled cycle.
//   - stall_cycle_cnt_o increments on enabled cycles when stall_i is high.
//   - input/output beat counters increment on handshake pulses provided by the
//     surrounding logic.
//   - frame_done_cnt_o increments on frame_done_i pulses.
//------------------------------------------------------------------------------
module codec_perf_counter #(
    parameter COUNTER_W = 32
) (
    input                       clk,
    input                       rst_n,
    input                       clear_i,
    input                       enable_i,
    input                       stall_i,
    input                       input_beat_i,
    input                       output_beat_i,
    input                       frame_done_i,
    output reg [COUNTER_W-1:0]  cycle_cnt_o,
    output reg [COUNTER_W-1:0]  stall_cycle_cnt_o,
    output reg [COUNTER_W-1:0]  input_beat_cnt_o,
    output reg [COUNTER_W-1:0]  output_beat_cnt_o,
    output reg [COUNTER_W-1:0]  frame_done_cnt_o
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_cnt_o        <= {COUNTER_W{1'b0}};
            stall_cycle_cnt_o  <= {COUNTER_W{1'b0}};
            input_beat_cnt_o   <= {COUNTER_W{1'b0}};
            output_beat_cnt_o  <= {COUNTER_W{1'b0}};
            frame_done_cnt_o   <= {COUNTER_W{1'b0}};
        end else if (clear_i) begin
            cycle_cnt_o        <= {COUNTER_W{1'b0}};
            stall_cycle_cnt_o  <= {COUNTER_W{1'b0}};
            input_beat_cnt_o   <= {COUNTER_W{1'b0}};
            output_beat_cnt_o  <= {COUNTER_W{1'b0}};
            frame_done_cnt_o   <= {COUNTER_W{1'b0}};
        end else if (enable_i) begin
            cycle_cnt_o <= cycle_cnt_o + {{(COUNTER_W-1){1'b0}}, 1'b1};

            if (stall_i) begin
                stall_cycle_cnt_o <= stall_cycle_cnt_o + {{(COUNTER_W-1){1'b0}}, 1'b1};
            end

            if (input_beat_i) begin
                input_beat_cnt_o <= input_beat_cnt_o + {{(COUNTER_W-1){1'b0}}, 1'b1};
            end

            if (output_beat_i) begin
                output_beat_cnt_o <= output_beat_cnt_o + {{(COUNTER_W-1){1'b0}}, 1'b1};
            end

            if (frame_done_i) begin
                frame_done_cnt_o <= frame_done_cnt_o + {{(COUNTER_W-1){1'b0}}, 1'b1};
            end
        end
    end

endmodule

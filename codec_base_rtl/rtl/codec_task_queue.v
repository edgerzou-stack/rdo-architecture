//------------------------------------------------------------------------------
// File: codec_task_queue.v
// Description:
//   Small descriptor queue for frame/block/job metadata.
//
// Interface style:
//   - enqueue side: enq_valid / enq_ready / enq_desc
//   - dequeue side: deq_valid / deq_ready / deq_desc
//
// Implementation note:
//   - This module is a thin wrapper around codec_sync_fifo so that the queue
//     uses the same backpressure and reset semantics as the stream library.
//------------------------------------------------------------------------------
module codec_task_queue (clk, rst_n, clear_i,
                         enq_valid, enq_ready, enq_desc,
                         deq_valid, deq_ready, deq_desc,
                         full_o, empty_o, level_o);

    parameter DESC_W = 64;
    parameter DEPTH  = 8;

    function integer codec_clog2;
        input integer value;
        integer tmp;
        begin
            tmp = value - 1;
            codec_clog2 = 0;
            while (tmp > 0) begin
                tmp = tmp >> 1;
                codec_clog2 = codec_clog2 + 1;
            end
        end
    endfunction

    localparam LEVEL_W = codec_clog2(DEPTH + 1);

    input                   clk;
    input                   rst_n;
    input                   clear_i;
    input                   enq_valid;
    output                  enq_ready;
    input      [DESC_W-1:0] enq_desc;
    output                  deq_valid;
    input                   deq_ready;
    output     [DESC_W-1:0] deq_desc;
    output                  full_o;
    output                  empty_o;
    output     [LEVEL_W-1:0] level_o;

    wire deq_last_unused;
    wire [0:0] deq_user_unused;

    codec_sync_fifo #(
        .DATA_W(DESC_W),
        .USER_W(1),
        .DEPTH(DEPTH)
    ) u_task_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .clear_i(clear_i),
        .in_valid(enq_valid),
        .in_ready(enq_ready),
        .in_data(enq_desc),
        .in_last(1'b0),
        .in_user(1'b0),
        .out_valid(deq_valid),
        .out_ready(deq_ready),
        .out_data(deq_desc),
        .out_last(deq_last_unused),
        .out_user(deq_user_unused),
        .full_o(full_o),
        .empty_o(empty_o),
        .level_o(level_o)
    );

endmodule

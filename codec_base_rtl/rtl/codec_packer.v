//------------------------------------------------------------------------------
// File: codec_packer.v
// Description:
//   Packs narrow input beats into a wider output word.
//
// Design assumptions:
//   - OUT_W must be an integer multiple of IN_W.
//   - Segment order is low-to-high: the first accepted input beat is written to
//     out_data[IN_W-1:0], the second to out_data[2*IN_W-1:IN_W], and so on.
//   - in_user is captured from the first segment of each packed output word.
//     This is suitable for carrying SOP-like metadata. If richer sideband
//     aggregation is required, wrap this module with project-specific logic.
//
// Flush behavior:
//   - flush_i requests immediate emission of the current partial word.
//   - If the output side is backpressured, the flush request is remembered and
//     new input is blocked until the partial word is emitted.
//
// Backpressure guarantee:
//   - Input is accepted only when the module can either buffer the segment or
//     commit a completed word to the output register in the same cycle.
//   - No segment is dropped or duplicated under out_ready deassertion.
//------------------------------------------------------------------------------
module codec_packer (clk, rst_n, clear_i, flush_i,
                     in_valid, in_ready, in_data, in_last, in_user,
                     out_valid, out_ready, out_data, out_valid_count,
                     out_valid_mask, out_last, out_user, pending_o);

    parameter IN_W   = 8;
    parameter OUT_W  = 32;
    parameter USER_W = 4;

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

    localparam RATIO   = OUT_W / IN_W;
    localparam COUNT_W = codec_clog2(RATIO + 1);

    input                   clk;
    input                   rst_n;
    input                   clear_i;
    input                   flush_i;
    input                   in_valid;
    output                  in_ready;
    input      [IN_W-1:0]   in_data;
    input                   in_last;
    input      [USER_W-1:0] in_user;
    output                  out_valid;
    input                   out_ready;
    output     [OUT_W-1:0]  out_data;
    output     [COUNT_W-1:0] out_valid_count;
    output reg [RATIO-1:0]  out_valid_mask;
    output                  out_last;
    output     [USER_W-1:0] out_user;
    output                  pending_o;

    reg [OUT_W-1:0]         acc_data_reg;
    reg [COUNT_W-1:0]       acc_count_reg;
    reg [USER_W-1:0]        acc_user_reg;

    reg                     out_valid_reg;
    reg [OUT_W-1:0]         out_data_reg;
    reg [COUNT_W-1:0]       out_count_reg;
    reg                     out_last_reg;
    reg [USER_W-1:0]        out_user_reg;

    reg                     flush_pending_reg;

    reg [OUT_W-1:0]         assembled_data;
    reg [OUT_W-1:0]         emit_data;
    reg [COUNT_W-1:0]       emit_count;
    reg [USER_W-1:0]        emit_user;
    reg                     emit_last;

    wire out_slot_free;
    wire flush_hold;
    wire need_emit_if_accept;
    wire accept_in;
    wire emit_from_accept;
    wire emit_from_flush_now;
    wire emit_from_flush_pending;
    wire emit_fire;

    integer seg_idx;

    assign out_slot_free = (~out_valid_reg) | out_ready;
    assign flush_hold = flush_pending_reg & (acc_count_reg != {COUNT_W{1'b0}});
    assign need_emit_if_accept = in_valid &
                                 (flush_i | in_last | (acc_count_reg == (RATIO-1)));
    assign in_ready = (~flush_hold) & ((~need_emit_if_accept) | out_slot_free);
    assign accept_in = in_valid & in_ready;

    assign emit_from_accept = accept_in &
                              (flush_i | in_last | (acc_count_reg == (RATIO-1)));
    assign emit_from_flush_now = flush_i & (~in_valid) &
                                 (acc_count_reg != {COUNT_W{1'b0}}) & out_slot_free;
    assign emit_from_flush_pending = flush_pending_reg &
                                     (acc_count_reg != {COUNT_W{1'b0}}) & out_slot_free;
    assign emit_fire = emit_from_accept | emit_from_flush_now | emit_from_flush_pending;

    assign out_valid = out_valid_reg;
    assign out_data  = out_data_reg;
    assign out_valid_count = out_count_reg;
    assign out_last  = out_last_reg;
    assign out_user  = out_user_reg;
    assign pending_o = (acc_count_reg != {COUNT_W{1'b0}}) | out_valid_reg | flush_pending_reg;

    always @(*) begin
        assembled_data = acc_data_reg;
        if (accept_in) begin
            assembled_data[acc_count_reg*IN_W +: IN_W] = in_data;
        end
    end

    always @(*) begin
        emit_data  = acc_data_reg;
        emit_count = acc_count_reg;
        emit_user  = acc_user_reg;
        emit_last  = 1'b0;

        if (emit_from_accept) begin
            emit_data  = assembled_data;
            emit_count = acc_count_reg + {{(COUNT_W-1){1'b0}}, 1'b1};
            emit_user  = (acc_count_reg == {COUNT_W{1'b0}}) ? in_user : acc_user_reg;
            emit_last  = in_last;
        end else if (emit_from_flush_now || emit_from_flush_pending) begin
            emit_data  = acc_data_reg;
            emit_count = acc_count_reg;
            emit_user  = acc_user_reg;
            emit_last  = 1'b0;
        end
    end

    always @(*) begin
        out_valid_mask = {RATIO{1'b0}};
        for (seg_idx = 0; seg_idx < RATIO; seg_idx = seg_idx + 1) begin
            if (seg_idx < out_count_reg) begin
                out_valid_mask[seg_idx] = 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_data_reg      <= {OUT_W{1'b0}};
            acc_count_reg     <= {COUNT_W{1'b0}};
            acc_user_reg      <= {USER_W{1'b0}};
            out_valid_reg     <= 1'b0;
            out_data_reg      <= {OUT_W{1'b0}};
            out_count_reg     <= {COUNT_W{1'b0}};
            out_last_reg      <= 1'b0;
            out_user_reg      <= {USER_W{1'b0}};
            flush_pending_reg <= 1'b0;
        end else if (clear_i) begin
            acc_data_reg      <= {OUT_W{1'b0}};
            acc_count_reg     <= {COUNT_W{1'b0}};
            acc_user_reg      <= {USER_W{1'b0}};
            out_valid_reg     <= 1'b0;
            out_data_reg      <= {OUT_W{1'b0}};
            out_count_reg     <= {COUNT_W{1'b0}};
            out_last_reg      <= 1'b0;
            out_user_reg      <= {USER_W{1'b0}};
            flush_pending_reg <= 1'b0;
        end else begin
            if (out_valid_reg & out_ready & (~emit_fire)) begin
                out_valid_reg <= 1'b0;
            end

            if (emit_fire) begin
                out_valid_reg <= 1'b1;
                out_data_reg  <= emit_data;
                out_count_reg <= emit_count;
                out_last_reg  <= emit_last;
                out_user_reg  <= emit_user;
            end

            if (emit_from_accept || emit_from_flush_now || emit_from_flush_pending) begin
                acc_data_reg  <= {OUT_W{1'b0}};
                acc_count_reg <= {COUNT_W{1'b0}};
                acc_user_reg  <= {USER_W{1'b0}};
            end else if (accept_in) begin
                acc_data_reg  <= assembled_data;
                acc_count_reg <= acc_count_reg + {{(COUNT_W-1){1'b0}}, 1'b1};
                if (acc_count_reg == {COUNT_W{1'b0}}) begin
                    acc_user_reg <= in_user;
                end
            end

            if (emit_from_flush_now || emit_from_flush_pending) begin
                flush_pending_reg <= 1'b0;
            end else if (flush_i && (acc_count_reg != {COUNT_W{1'b0}}) && (~out_slot_free)) begin
                flush_pending_reg <= 1'b1;
            end
        end
    end

endmodule

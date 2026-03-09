//------------------------------------------------------------------------------
// File: codec_unpacker.v
// Description:
//   Unpacks a wide input word into multiple narrower output beats.
//
// Design assumptions:
//   - IN_W must be an integer multiple of OUT_W.
//   - Segment order is low-to-high: out_data first emits in_data[OUT_W-1:0].
//   - in_valid_count must be in the range 1..(IN_W/OUT_W). A zero count is
//     treated as one beat to avoid deadlock, but such input is protocol-invalid.
//   - in_user is replicated to all emitted narrow beats from the accepted word.
//
// Backpressure guarantee:
//   - While partial segments remain buffered, the module will not accept a new
//     input word until the final buffered output segment is accepted.
//   - Internal segment index only advances on out_valid && out_ready.
//------------------------------------------------------------------------------
module codec_unpacker (clk, rst_n, clear_i,
                       in_valid, in_ready, in_data, in_valid_count, in_last, in_user,
                       out_valid, out_ready, out_data, out_last, out_user, pending_o);

    parameter IN_W   = 32;
    parameter OUT_W  = 8;
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

    localparam SEG_NUM = IN_W / OUT_W;
    localparam COUNT_W = codec_clog2(SEG_NUM + 1);

    input                   clk;
    input                   rst_n;
    input                   clear_i;
    input                   in_valid;
    output                  in_ready;
    input      [IN_W-1:0]   in_data;
    input      [COUNT_W-1:0] in_valid_count;
    input                   in_last;
    input      [USER_W-1:0] in_user;
    output                  out_valid;
    input                   out_ready;
    output reg [OUT_W-1:0]  out_data;
    output                  out_last;
    output     [USER_W-1:0] out_user;
    output                  pending_o;

    reg                 buf_valid_reg;
    reg [IN_W-1:0]      buf_data_reg;
    reg [COUNT_W-1:0]   buf_count_reg;
    reg [COUNT_W-1:0]   buf_idx_reg;
    reg                 buf_last_reg;
    reg [USER_W-1:0]    buf_user_reg;

    wire                final_seg_fire;
    wire                accept_in;
    wire [COUNT_W-1:0]  load_count;

    assign load_count = (in_valid_count == {COUNT_W{1'b0}}) ?
                        {{(COUNT_W-1){1'b0}}, 1'b1} : in_valid_count;

    assign out_valid = buf_valid_reg;
    assign out_user  = buf_user_reg;
    assign out_last  = buf_valid_reg & buf_last_reg &
                       (buf_idx_reg == (buf_count_reg - {{(COUNT_W-1){1'b0}}, 1'b1}));
    assign pending_o = buf_valid_reg;

    assign in_ready = (~buf_valid_reg) |
                      (buf_valid_reg & out_ready &
                       (buf_idx_reg == (buf_count_reg - {{(COUNT_W-1){1'b0}}, 1'b1})));
    assign accept_in = in_valid & in_ready;
    assign final_seg_fire = buf_valid_reg & out_ready &
                            (buf_idx_reg == (buf_count_reg - {{(COUNT_W-1){1'b0}}, 1'b1}));

    always @(*) begin
        out_data = {OUT_W{1'b0}};
        if (buf_valid_reg) begin
            out_data = buf_data_reg[buf_idx_reg*OUT_W +: OUT_W];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf_valid_reg <= 1'b0;
            buf_data_reg  <= {IN_W{1'b0}};
            buf_count_reg <= {COUNT_W{1'b0}};
            buf_idx_reg   <= {COUNT_W{1'b0}};
            buf_last_reg  <= 1'b0;
            buf_user_reg  <= {USER_W{1'b0}};
        end else if (clear_i) begin
            buf_valid_reg <= 1'b0;
            buf_data_reg  <= {IN_W{1'b0}};
            buf_count_reg <= {COUNT_W{1'b0}};
            buf_idx_reg   <= {COUNT_W{1'b0}};
            buf_last_reg  <= 1'b0;
            buf_user_reg  <= {USER_W{1'b0}};
        end else begin
            if (buf_valid_reg) begin
                if (out_ready) begin
                    if (final_seg_fire) begin
                        if (accept_in) begin
                            buf_valid_reg <= 1'b1;
                            buf_data_reg  <= in_data;
                            buf_count_reg <= load_count;
                            buf_idx_reg   <= {COUNT_W{1'b0}};
                            buf_last_reg  <= in_last;
                            buf_user_reg  <= in_user;
                        end else begin
                            buf_valid_reg <= 1'b0;
                        end
                    end else begin
                        buf_idx_reg <= buf_idx_reg + {{(COUNT_W-1){1'b0}}, 1'b1};
                    end
                end
            end else if (accept_in) begin
                buf_valid_reg <= 1'b1;
                buf_data_reg  <= in_data;
                buf_count_reg <= load_count;
                buf_idx_reg   <= {COUNT_W{1'b0}};
                buf_last_reg  <= in_last;
                buf_user_reg  <= in_user;
            end
        end
    end

endmodule

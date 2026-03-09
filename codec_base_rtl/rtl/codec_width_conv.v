//------------------------------------------------------------------------------
// File: codec_width_conv.v
// Description:
//   Wrapper that selects pack, unpack, or passthrough behavior based on IN_W
//   and OUT_W.
//
// Supported cases:
//   - IN_W == OUT_W : direct passthrough.
//   - IN_W <  OUT_W : instantiate codec_packer, requires OUT_W % IN_W == 0.
//   - IN_W >  OUT_W : instantiate codec_unpacker, requires IN_W % OUT_W == 0.
//
// Limitations:
//   - This first-drop wrapper does not attempt arbitrary rational conversion.
//   - For pack mode, out_valid_count/out_valid_mask describe the emitted wide
//     word payload density. For unpack and passthrough, both are fixed to one.
//------------------------------------------------------------------------------
module codec_width_conv (clk, rst_n, clear_i, flush_i,
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

    localparam OUT_RATIO = (OUT_W > IN_W) ? (OUT_W / IN_W) : 1;
    localparam COUNT_W   = codec_clog2(OUT_RATIO + 1);

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
    output     [OUT_RATIO-1:0] out_valid_mask;
    output                  out_last;
    output     [USER_W-1:0] out_user;
    output                  pending_o;

    wire pack_out_valid;
    wire pack_in_ready;
    wire [OUT_W-1:0] pack_out_data;
    wire [COUNT_W-1:0] pack_out_count;
    wire [OUT_RATIO-1:0] pack_out_mask;
    wire pack_out_last;
    wire [USER_W-1:0] pack_out_user;
    wire pack_pending;

    wire unpack_out_valid;
    wire unpack_in_ready;
    wire [OUT_W-1:0] unpack_out_data;
    wire unpack_out_last;
    wire [USER_W-1:0] unpack_out_user;
    wire unpack_pending;

    generate
        if (IN_W == OUT_W) begin : gen_width_equal
            assign in_ready = out_ready;
            assign out_valid = in_valid;
            assign out_data = in_data;
            assign out_valid_count = {{(COUNT_W-1){1'b0}}, 1'b1};
            assign out_valid_mask = {{(OUT_RATIO-1){1'b0}}, 1'b1};
            assign out_last = in_last;
            assign out_user = in_user;
            assign pending_o = 1'b0;
        end else if (IN_W < OUT_W) begin : gen_width_pack
            codec_packer #(
                .IN_W(IN_W),
                .OUT_W(OUT_W),
                .USER_W(USER_W)
            ) u_codec_packer (
                .clk(clk),
                .rst_n(rst_n),
                .clear_i(clear_i),
                .flush_i(flush_i),
                .in_valid(in_valid),
                .in_ready(pack_in_ready),
                .in_data(in_data),
                .in_last(in_last),
                .in_user(in_user),
                .out_valid(pack_out_valid),
                .out_ready(out_ready),
                .out_data(pack_out_data),
                .out_valid_count(pack_out_count),
                .out_valid_mask(pack_out_mask),
                .out_last(pack_out_last),
                .out_user(pack_out_user),
                .pending_o(pack_pending)
            );

            assign in_ready = pack_in_ready;
            assign out_valid = pack_out_valid;
            assign out_data = pack_out_data;
            assign out_valid_count = pack_out_count;
            assign out_valid_mask = pack_out_mask;
            assign out_last = pack_out_last;
            assign out_user = pack_out_user;
            assign pending_o = pack_pending;
        end else begin : gen_width_unpack
            codec_unpacker #(
                .IN_W(IN_W),
                .OUT_W(OUT_W),
                .USER_W(USER_W)
            ) u_codec_unpacker (
                .clk(clk),
                .rst_n(rst_n),
                .clear_i(clear_i),
                .in_valid(in_valid),
                .in_ready(unpack_in_ready),
                .in_data(in_data),
                .in_valid_count({{(COUNT_W-1){1'b0}}, 1'b1}),
                .in_last(in_last),
                .in_user(in_user),
                .out_valid(unpack_out_valid),
                .out_ready(out_ready),
                .out_data(unpack_out_data),
                .out_last(unpack_out_last),
                .out_user(unpack_out_user),
                .pending_o(unpack_pending)
            );

            assign in_ready = unpack_in_ready;
            assign out_valid = unpack_out_valid;
            assign out_data = unpack_out_data;
            assign out_valid_count = {{(COUNT_W-1){1'b0}}, 1'b1};
            assign out_valid_mask = {{(OUT_RATIO-1){1'b0}}, 1'b1};
            assign out_last = unpack_out_last;
            assign out_user = unpack_out_user;
            assign pending_o = unpack_pending;
        end
    endgenerate

endmodule

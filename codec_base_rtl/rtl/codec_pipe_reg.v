//------------------------------------------------------------------------------
// File: codec_pipe_reg.v
// Description:
//   Single-stage elastic pipeline register with valid/ready handshake.
//
// Handshake rule:
//   - Input transfer occurs when in_valid and in_ready are both high.
//   - Output transfer occurs when out_valid and out_ready are both high.
//   - This module may contain one item. No data is dropped or duplicated.
//
// Sideband:
//   - in_last/out_last is preserved.
//   - in_user/out_user is preserved bit-exact.
//------------------------------------------------------------------------------
module codec_pipe_reg #(
    parameter DATA_W = 32,
    parameter USER_W = 4
) (
    input                   clk,
    input                   rst_n,
    input                   clear_i,

    input                   in_valid,
    output                  in_ready,
    input      [DATA_W-1:0] in_data,
    input                   in_last,
    input      [USER_W-1:0] in_user,

    output                  out_valid,
    input                   out_ready,
    output     [DATA_W-1:0] out_data,
    output                  out_last,
    output     [USER_W-1:0] out_user,

    output                  holding_o
);

    reg                 out_valid_reg;
    reg [DATA_W-1:0]    out_data_reg;
    reg                 out_last_reg;
    reg [USER_W-1:0]    out_user_reg;

    assign in_ready  = out_ready | (~out_valid_reg);
    assign out_valid = out_valid_reg;
    assign out_data  = out_data_reg;
    assign out_last  = out_last_reg;
    assign out_user  = out_user_reg;
    assign holding_o = out_valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid_reg <= 1'b0;
            out_data_reg  <= {DATA_W{1'b0}};
            out_last_reg  <= 1'b0;
            out_user_reg  <= {USER_W{1'b0}};
        end else if (clear_i) begin
            out_valid_reg <= 1'b0;
            out_data_reg  <= {DATA_W{1'b0}};
            out_last_reg  <= 1'b0;
            out_user_reg  <= {USER_W{1'b0}};
        end else if (in_ready) begin
            out_valid_reg <= in_valid;
            out_data_reg  <= in_data;
            out_last_reg  <= in_last;
            out_user_reg  <= in_user;
        end
    end

endmodule

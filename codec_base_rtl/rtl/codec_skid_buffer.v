//------------------------------------------------------------------------------
// File: codec_skid_buffer.v
// Description:
//   Two-entry skid buffer used to break a long combinational ready chain.
//
// Timing intent:
//   - in_ready does not depend on out_ready.
//   - One beat can be accepted after downstream deasserts ready, allowing the
//     buffer to absorb a single-cycle skid without dropping data.
//
// Behavior:
//   - main_* drives the output.
//   - buf_* stores one extra item when the output is stalled.
//   - holding_o is high when either internal slot contains valid data.
//------------------------------------------------------------------------------
module codec_skid_buffer #(
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

    reg                 main_valid_reg;
    reg [DATA_W-1:0]    main_data_reg;
    reg                 main_last_reg;
    reg [USER_W-1:0]    main_user_reg;

    reg                 buf_valid_reg;
    reg [DATA_W-1:0]    buf_data_reg;
    reg                 buf_last_reg;
    reg [USER_W-1:0]    buf_user_reg;

    wire pop_main;
    wire push_in;

    assign in_ready  = ~buf_valid_reg;
    assign out_valid = main_valid_reg;
    assign out_data  = main_data_reg;
    assign out_last  = main_last_reg;
    assign out_user  = main_user_reg;
    assign holding_o = main_valid_reg | buf_valid_reg;

    assign pop_main = main_valid_reg & out_ready;
    assign push_in  = in_valid & in_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_valid_reg <= 1'b0;
            main_data_reg  <= {DATA_W{1'b0}};
            main_last_reg  <= 1'b0;
            main_user_reg  <= {USER_W{1'b0}};
            buf_valid_reg  <= 1'b0;
            buf_data_reg   <= {DATA_W{1'b0}};
            buf_last_reg   <= 1'b0;
            buf_user_reg   <= {USER_W{1'b0}};
        end else if (clear_i) begin
            main_valid_reg <= 1'b0;
            main_data_reg  <= {DATA_W{1'b0}};
            main_last_reg  <= 1'b0;
            main_user_reg  <= {USER_W{1'b0}};
            buf_valid_reg  <= 1'b0;
            buf_data_reg   <= {DATA_W{1'b0}};
            buf_last_reg   <= 1'b0;
            buf_user_reg   <= {USER_W{1'b0}};
        end else begin
            if (pop_main) begin
                if (buf_valid_reg) begin
                    main_valid_reg <= 1'b1;
                    main_data_reg  <= buf_data_reg;
                    main_last_reg  <= buf_last_reg;
                    main_user_reg  <= buf_user_reg;
                    buf_valid_reg  <= 1'b0;
                end else if (push_in) begin
                    main_valid_reg <= 1'b1;
                    main_data_reg  <= in_data;
                    main_last_reg  <= in_last;
                    main_user_reg  <= in_user;
                end else begin
                    main_valid_reg <= 1'b0;
                end
            end else if (!main_valid_reg) begin
                if (push_in) begin
                    main_valid_reg <= 1'b1;
                    main_data_reg  <= in_data;
                    main_last_reg  <= in_last;
                    main_user_reg  <= in_user;
                end
            end else begin
                if (push_in) begin
                    buf_valid_reg <= 1'b1;
                    buf_data_reg  <= in_data;
                    buf_last_reg  <= in_last;
                    buf_user_reg  <= in_user;
                end
            end
        end
    end

endmodule

//------------------------------------------------------------------------------
// File: codec_counter.v
// Description:
//   Generic configurable counter.
//
// Priority:
//   1. clear_i resets count to zero.
//   2. load_i loads load_value_i.
//   3. enable_i increments by one.
//
// Terminal-count behavior:
//   - tc_o is level-high whenever count_o == terminal_value_i.
//   - If saturate_i is high, the counter stops incrementing at terminal_value_i.
//   - If saturate_i is low, the counter wraps naturally on overflow.
//------------------------------------------------------------------------------
module codec_counter #(
    parameter WIDTH = 32
) (
    input                   clk,
    input                   rst_n,
    input                   clear_i,
    input                   enable_i,
    input                   load_i,
    input      [WIDTH-1:0]  load_value_i,
    input                   saturate_i,
    input      [WIDTH-1:0]  terminal_value_i,
    output reg [WIDTH-1:0]  count_o,
    output                  tc_o
);

    wire hit_terminal;

    assign hit_terminal = (count_o == terminal_value_i);
    assign tc_o = hit_terminal;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_o <= {WIDTH{1'b0}};
        end else if (clear_i) begin
            count_o <= {WIDTH{1'b0}};
        end else if (load_i) begin
            count_o <= load_value_i;
        end else if (enable_i) begin
            if (saturate_i && hit_terminal) begin
                count_o <= count_o;
            end else begin
                count_o <= count_o + {{(WIDTH-1){1'b0}}, 1'b1};
            end
        end
    end

endmodule

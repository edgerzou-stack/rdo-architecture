//------------------------------------------------------------------------------
// File: codec_addr_gen.v
// Description:
//   Generic address generator for line/block/frame stepping.
//
// Interface contract:
//   - start_i loads base_addr_i, resets index_o to zero, and clears done_o.
//   - advance_i consumes the current address and moves to the next one.
//   - done_o is sticky high after the final requested advance.
//
// Last-address definition:
//   - addr_o always presents the current address to be consumed next.
//   - After the final advance, addr_o holds the last valid address and done_o
//     becomes high on the following cycle.
//
// Edge case:
//   - If length_i == 0 at start_i, done_o is asserted immediately and no
//     address progression occurs.
//------------------------------------------------------------------------------
module codec_addr_gen #(
    parameter ADDR_W = 32,
    parameter LEN_W  = 16
) (
    input                   clk,
    input                   rst_n,
    input                   clear_i,
    input                   start_i,
    input                   advance_i,
    input      [ADDR_W-1:0] base_addr_i,
    input      [ADDR_W-1:0] stride_i,
    input      [LEN_W-1:0]  length_i,
    output reg [ADDR_W-1:0] addr_o,
    output reg [LEN_W-1:0]  index_o,
    output reg              done_o
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_o  <= {ADDR_W{1'b0}};
            index_o <= {LEN_W{1'b0}};
            done_o  <= 1'b1;
        end else if (clear_i) begin
            addr_o  <= {ADDR_W{1'b0}};
            index_o <= {LEN_W{1'b0}};
            done_o  <= 1'b1;
        end else if (start_i) begin
            addr_o  <= base_addr_i;
            index_o <= {LEN_W{1'b0}};
            done_o  <= (length_i == {LEN_W{1'b0}});
        end else if (advance_i && !done_o) begin
            if (index_o == (length_i - {{(LEN_W-1){1'b0}}, 1'b1})) begin
                done_o <= 1'b1;
            end else begin
                index_o <= index_o + {{(LEN_W-1){1'b0}}, 1'b1};
                addr_o  <= addr_o + stride_i;
            end
        end
    end

endmodule

//------------------------------------------------------------------------------
// File: codec_ram_sdp_wrapper.v
// Description:
//   Simple-dual-port RAM wrapper with one write port and one read port.
//
// Port timing:
//   - Write port is synchronous to wr_clk.
//   - Read port is synchronous to rd_clk and returns data one rd_clk later
//     after rd_en is asserted.
//
// Macro replacement note:
//   - This behavioral model is intended as a clean wrapper boundary. Replace
//     the internals with foundry SRAM or FPGA RAM primitives as needed.
//
// Limitation:
//   - Simultaneous read and write to the same address across different clocks
//     is modelled as implementation-defined. Final macro behavior should be
//     taken from the target memory datasheet.
//------------------------------------------------------------------------------
module codec_ram_sdp_wrapper #(
    parameter ADDR_W = 8,
    parameter DATA_W = 32
) (
    input                   wr_clk,
    input                   wr_rst_n,
    input                   wr_en,
    input      [ADDR_W-1:0] wr_addr,
    input      [DATA_W-1:0] wr_data,

    input                   rd_clk,
    input                   rd_rst_n,
    input                   rd_en,
    input      [ADDR_W-1:0] rd_addr,
    output reg [DATA_W-1:0] rd_data
);

    reg [DATA_W-1:0] mem [0:(1<<ADDR_W)-1];

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
        end else if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_data <= {DATA_W{1'b0}};
        end else if (rd_en) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule

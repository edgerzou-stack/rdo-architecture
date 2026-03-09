//------------------------------------------------------------------------------
// File: codec_async_fifo.v
// Description:
//   Parameterized asynchronous FIFO using Gray-code pointers and two-flop CDC
//   synchronization.
//
// Critical CDC notes:
//   1. Binary pointers are used locally for RAM addressing and depth tracking.
//   2. Gray-code copies of those pointers are synchronized into the opposite
//      clock domain because only one bit changes per increment.
//   3. Empty is detected in the read domain when the synchronized write Gray
//      pointer matches the current read Gray pointer.
//   4. Full is detected in the write domain by comparing the next write Gray
//      pointer against the synchronized read Gray pointer with its top two bits
//      inverted. This is the standard ring-buffer full test for power-of-two
//      depth FIFOs.
//
// Reset assumption:
//   - wr_rst_n and rd_rst_n are both asserted asynchronously.
//   - Deassertion must occur only after the respective clock is stable.
//
// Limitation:
//   - DEPTH must be a power of two and >= 2.
//------------------------------------------------------------------------------
module codec_async_fifo #(
    parameter DATA_W = 32,
    parameter USER_W = 4,
    parameter DEPTH  = 16
) (
    input                       wr_clk,
    input                       wr_rst_n,
    input                       rd_clk,
    input                       rd_rst_n,

    input                       in_valid,
    output                      in_ready,
    input      [DATA_W-1:0]     in_data,
    input                       in_last,
    input      [USER_W-1:0]     in_user,

    output                      out_valid,
    input                       out_ready,
    output     [DATA_W-1:0]     out_data,
    output                      out_last,
    output     [USER_W-1:0]     out_user,

    output                      wr_full_o,
    output                      rd_empty_o
);

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

    localparam ADDR_W    = codec_clog2(DEPTH);
    localparam PTR_W     = ADDR_W + 1;
    localparam PAYLOAD_W = DATA_W + 1 + USER_W;

    reg [PAYLOAD_W-1:0] mem [0:DEPTH-1];

    reg [PTR_W-1:0] wr_ptr_bin_reg;
    reg [PTR_W-1:0] wr_ptr_gray_reg;
    reg [PTR_W-1:0] rd_ptr_bin_reg;
    reg [PTR_W-1:0] rd_ptr_gray_reg;

    reg [PTR_W-1:0] rd_ptr_gray_wr_sync1_reg;
    reg [PTR_W-1:0] rd_ptr_gray_wr_sync2_reg;
    reg [PTR_W-1:0] wr_ptr_gray_rd_sync1_reg;
    reg [PTR_W-1:0] wr_ptr_gray_rd_sync2_reg;

    wire [PTR_W-1:0] wr_ptr_bin_nxt;
    wire [PTR_W-1:0] wr_ptr_gray_nxt;
    wire [PTR_W-1:0] rd_ptr_bin_nxt;
    wire [PTR_W-1:0] rd_ptr_gray_nxt;
    wire [PTR_W-1:0] rd_gray_full_cmp;

    wire write_fire;
    wire read_fire;

    wire [PAYLOAD_W-1:0] rd_payload;

    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin_value;
        begin
            bin2gray = (bin_value >> 1) ^ bin_value;
        end
    endfunction

    assign wr_ptr_bin_nxt  = wr_ptr_bin_reg + {{(PTR_W-1){1'b0}}, 1'b1};
    assign wr_ptr_gray_nxt = bin2gray(wr_ptr_bin_nxt);
    assign rd_ptr_bin_nxt  = rd_ptr_bin_reg + {{(PTR_W-1){1'b0}}, 1'b1};
    assign rd_ptr_gray_nxt = bin2gray(rd_ptr_bin_nxt);

    generate
        if (PTR_W == 2) begin : gen_full_cmp_2b
            assign rd_gray_full_cmp = ~rd_ptr_gray_wr_sync2_reg[PTR_W-1:0];
        end else begin : gen_full_cmp_nb
            assign rd_gray_full_cmp = {
                ~rd_ptr_gray_wr_sync2_reg[PTR_W-1:PTR_W-2],
                 rd_ptr_gray_wr_sync2_reg[PTR_W-3:0]
            };
        end
    endgenerate

    assign wr_full_o  = (wr_ptr_gray_nxt == rd_gray_full_cmp);
    assign rd_empty_o = (wr_ptr_gray_rd_sync2_reg == rd_ptr_gray_reg);

    assign in_ready  = ~wr_full_o;
    assign out_valid = ~rd_empty_o;
    assign write_fire = in_valid & in_ready;
    assign read_fire  = out_valid & out_ready;

    assign rd_payload = mem[rd_ptr_bin_reg[ADDR_W-1:0]];
    assign out_data   = rd_payload[DATA_W-1:0];
    assign out_last   = rd_payload[DATA_W];
    assign out_user   = rd_payload[PAYLOAD_W-1:DATA_W+1];

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin_reg          <= {PTR_W{1'b0}};
            wr_ptr_gray_reg         <= {PTR_W{1'b0}};
            rd_ptr_gray_wr_sync1_reg <= {PTR_W{1'b0}};
            rd_ptr_gray_wr_sync2_reg <= {PTR_W{1'b0}};
        end else begin
            rd_ptr_gray_wr_sync1_reg <= rd_ptr_gray_reg;
            rd_ptr_gray_wr_sync2_reg <= rd_ptr_gray_wr_sync1_reg;

            if (write_fire) begin
                mem[wr_ptr_bin_reg[ADDR_W-1:0]] <= {in_user, in_last, in_data};
                wr_ptr_bin_reg                  <= wr_ptr_bin_nxt;
                wr_ptr_gray_reg                 <= wr_ptr_gray_nxt;
            end
        end
    end

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin_reg          <= {PTR_W{1'b0}};
            rd_ptr_gray_reg         <= {PTR_W{1'b0}};
            wr_ptr_gray_rd_sync1_reg <= {PTR_W{1'b0}};
            wr_ptr_gray_rd_sync2_reg <= {PTR_W{1'b0}};
        end else begin
            wr_ptr_gray_rd_sync1_reg <= wr_ptr_gray_reg;
            wr_ptr_gray_rd_sync2_reg <= wr_ptr_gray_rd_sync1_reg;

            if (read_fire) begin
                rd_ptr_bin_reg  <= rd_ptr_bin_nxt;
                rd_ptr_gray_reg <= rd_ptr_gray_nxt;
            end
        end
    end

endmodule

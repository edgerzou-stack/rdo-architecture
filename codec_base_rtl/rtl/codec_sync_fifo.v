//------------------------------------------------------------------------------
// File: codec_sync_fifo.v
// Description:
//   Parameterized synchronous FIFO with valid/ready ports.
//
// Design assumptions:
//   - Single clock domain.
//   - DEPTH may be any integer >= 2. This implementation uses explicit pointer
//     wrap logic, so DEPTH does not need to be a power of two.
//   - Output is first-word fall-through: out_data/out_last/out_user reflect the
//     current read pointer entry whenever the FIFO is not empty.
//
// Boundary behavior:
//   - full_o is asserted when level_o == DEPTH.
//   - empty_o is asserted when level_o == 0.
//   - A read and write in the same cycle is supported and keeps level_o stable.
//------------------------------------------------------------------------------
module codec_sync_fifo (clk, rst_n, clear_i,
                        in_valid, in_ready, in_data, in_last, in_user,
                        out_valid, out_ready, out_data, out_last, out_user,
                        full_o, empty_o, level_o);

    parameter DATA_W = 32;
    parameter USER_W = 4;
    parameter DEPTH  = 16;

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

    localparam PTR_W   = codec_clog2(DEPTH);
    localparam LEVEL_W = codec_clog2(DEPTH+1);

    input                       clk;
    input                       rst_n;
    input                       clear_i;
    input                       in_valid;
    output                      in_ready;
    input      [DATA_W-1:0]     in_data;
    input                       in_last;
    input      [USER_W-1:0]     in_user;
    output                      out_valid;
    input                       out_ready;
    output     [DATA_W-1:0]     out_data;
    output                      out_last;
    output     [USER_W-1:0]     out_user;
    output                      full_o;
    output                      empty_o;
    output     [LEVEL_W-1:0]    level_o;

    reg [DATA_W-1:0] mem_data [0:DEPTH-1];
    reg              mem_last [0:DEPTH-1];
    reg [USER_W-1:0] mem_user [0:DEPTH-1];

    reg [PTR_W-1:0]  wr_ptr_reg;
    reg [PTR_W-1:0]  rd_ptr_reg;
    reg [LEVEL_W-1:0] level_reg;

    reg [PTR_W-1:0] wr_ptr_nxt;
    reg [PTR_W-1:0] rd_ptr_nxt;

    wire write_fire;
    wire read_fire;

    assign full_o  = (level_reg == DEPTH);
    assign empty_o = (level_reg == {LEVEL_W{1'b0}});
    assign out_valid = ~empty_o;
    assign in_ready  = (~full_o) | (out_valid & out_ready);
    assign write_fire = in_valid & in_ready;
    assign read_fire  = out_valid & out_ready;

    assign out_data = mem_data[rd_ptr_reg];
    assign out_last = mem_last[rd_ptr_reg];
    assign out_user = mem_user[rd_ptr_reg];
    assign level_o  = level_reg;

    always @(*) begin
        if (wr_ptr_reg == DEPTH-1) begin
            wr_ptr_nxt = {PTR_W{1'b0}};
        end else begin
            wr_ptr_nxt = wr_ptr_reg + {{(PTR_W-1){1'b0}}, 1'b1};
        end

        if (rd_ptr_reg == DEPTH-1) begin
            rd_ptr_nxt = {PTR_W{1'b0}};
        end else begin
            rd_ptr_nxt = rd_ptr_reg + {{(PTR_W-1){1'b0}}, 1'b1};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_reg <= {PTR_W{1'b0}};
            rd_ptr_reg <= {PTR_W{1'b0}};
            level_reg  <= {LEVEL_W{1'b0}};
        end else if (clear_i) begin
            wr_ptr_reg <= {PTR_W{1'b0}};
            rd_ptr_reg <= {PTR_W{1'b0}};
            level_reg  <= {LEVEL_W{1'b0}};
        end else begin
            if (write_fire) begin
                mem_data[wr_ptr_reg] <= in_data;
                mem_last[wr_ptr_reg] <= in_last;
                mem_user[wr_ptr_reg] <= in_user;
                wr_ptr_reg           <= wr_ptr_nxt;
            end

            if (read_fire) begin
                rd_ptr_reg <= rd_ptr_nxt;
            end

            case ({write_fire, read_fire})
                2'b10: level_reg <= level_reg + {{(LEVEL_W-1){1'b0}}, 1'b1};
                2'b01: level_reg <= level_reg - {{(LEVEL_W-1){1'b0}}, 1'b1};
                default: level_reg <= level_reg;
            endcase
        end
    end

endmodule

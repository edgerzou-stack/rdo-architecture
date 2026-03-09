//------------------------------------------------------------------------------
// File: codec_rr_arbiter.v
// Description:
//   Round-robin arbiter with one-hot grant and grant index outputs.
//
// Update rule:
//   - A new rotation point is committed only when grant_valid_o and
//     grant_accept_i are both high.
//   - This prevents the priority pointer from advancing when the selected
//     requester has not yet consumed the grant.
//
// Fairness:
//   - Once a requester is granted and accepted, the next arbitration pass
//     starts at the following requester index, preventing permanent starvation.
//------------------------------------------------------------------------------
module codec_rr_arbiter (clk, rst_n, req_i, grant_accept_i,
                         grant_valid_o, grant_onehot_o, grant_idx_o);

    parameter NUM_REQ = 4;

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

    localparam IDX_W = codec_clog2(NUM_REQ);

    input                   clk;
    input                   rst_n;
    input      [NUM_REQ-1:0] req_i;
    input                   grant_accept_i;
    output reg              grant_valid_o;
    output reg [NUM_REQ-1:0] grant_onehot_o;
    output reg [IDX_W-1:0]  grant_idx_o;

    reg [IDX_W-1:0] rr_ptr_reg;

    integer offset_int;
    integer candidate_int;

    always @(*) begin
        grant_valid_o  = 1'b0;
        grant_onehot_o = {NUM_REQ{1'b0}};
        grant_idx_o    = {IDX_W{1'b0}};

        for (offset_int = 0; offset_int < NUM_REQ; offset_int = offset_int + 1) begin
            candidate_int = rr_ptr_reg + offset_int;
            if (candidate_int >= NUM_REQ) begin
                candidate_int = candidate_int - NUM_REQ;
            end

            if ((!grant_valid_o) && req_i[candidate_int]) begin
                grant_valid_o = 1'b1;
                grant_onehot_o[candidate_int] = 1'b1;
                grant_idx_o = candidate_int;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_ptr_reg <= {IDX_W{1'b0}};
        end else if (grant_valid_o && grant_accept_i) begin
            if (grant_idx_o == (NUM_REQ-1)) begin
                rr_ptr_reg <= {IDX_W{1'b0}};
            end else begin
                rr_ptr_reg <= grant_idx_o + {{(IDX_W-1){1'b0}}, 1'b1};
            end
        end
    end

endmodule

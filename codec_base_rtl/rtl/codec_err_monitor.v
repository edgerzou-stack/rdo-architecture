`include "codec_defs.vh"
//------------------------------------------------------------------------------
// File: codec_err_monitor.v
// Description:
//   Sticky error monitor for common codec integration faults.
//
// Bit definition:
//   error_status_o[0] : overflow
//   error_status_o[1] : underflow
//   error_status_o[2] : protocol_error
//   error_status_o[3] : illegal_cfg
//   error_status_o[4 +: EXTRA_ERR_W] : implementation-specific external errors
//------------------------------------------------------------------------------
module codec_err_monitor #(
    parameter EXTRA_ERR_W = 0
) (
    input                           clk,
    input                           rst_n,
    input                           clear_i,
    input                           enable_i,
    input                           overflow_i,
    input                           underflow_i,
    input                           protocol_error_i,
    input                           illegal_cfg_i,
    input      [((EXTRA_ERR_W > 0) ? EXTRA_ERR_W : 1)-1:0] extra_error_i,
    output reg [4+((EXTRA_ERR_W > 0) ? EXTRA_ERR_W : 1)-1:0] error_status_o,
    output                          error_any_o
);

    assign error_any_o = |error_status_o;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_status_o <= {(4+((EXTRA_ERR_W > 0) ? EXTRA_ERR_W : 1)){1'b0}};
        end else if (clear_i) begin
            error_status_o <= {(4+((EXTRA_ERR_W > 0) ? EXTRA_ERR_W : 1)){1'b0}};
        end else if (enable_i) begin
            if (overflow_i) begin
                error_status_o[`CODEC_ERR_OVERFLOW_BIT] <= 1'b1;
            end
            if (underflow_i) begin
                error_status_o[`CODEC_ERR_UNDERFLOW_BIT] <= 1'b1;
            end
            if (protocol_error_i) begin
                error_status_o[`CODEC_ERR_PROTO_BIT] <= 1'b1;
            end
            if (illegal_cfg_i) begin
                error_status_o[`CODEC_ERR_CFG_BIT] <= 1'b1;
            end
            if (EXTRA_ERR_W > 0) begin
                error_status_o[4+EXTRA_ERR_W-1:4] <=
                    error_status_o[4+EXTRA_ERR_W-1:4] | extra_error_i;
            end
        end
    end

endmodule

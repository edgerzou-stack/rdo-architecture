`ifndef CODEC_DEFS_VH
`define CODEC_DEFS_VH
//------------------------------------------------------------------------------
// File: codec_defs.vh
// Description:
//   Shared macros and project-wide constants for the first-drop codec RTL
//   library. This header intentionally stays small and stable so that it can
//   be included by synthesis, lint, and simulation flows without pulling in
//   heavy dependencies.
//
// Stream interface convention:
//   Mandatory handshake:
//     in_valid / in_ready / in_data
//     out_valid / out_ready / out_data
//
//   Optional sideband carried by the first-drop library:
//     in_last / out_last
//     in_user / out_user
//
//   Recommended user-bit mapping when packet markers are needed:
//     user[0] : SOP
//     user[1] : EOP
//     user[2] : ERR
//   Modules in this library preserve user bits unless stated otherwise.
//------------------------------------------------------------------------------

`define CODEC_STATE_W          3
`define CODEC_ST_IDLE          3'd0
`define CODEC_ST_RUN           3'd1
`define CODEC_ST_DONE          3'd2
`define CODEC_ST_ERR           3'd3
`define CODEC_ST_FLUSH         3'd4

`define CODEC_USER_SOP_BIT     0
`define CODEC_USER_EOP_BIT     1
`define CODEC_USER_ERR_BIT     2

`define CODEC_CTRL_EN_BIT      0
`define CODEC_CTRL_START_BIT   1
`define CODEC_CTRL_STOP_BIT    2
`define CODEC_CTRL_SRST_BIT    3
`define CODEC_CTRL_FLUSH_BIT   4

`define CODEC_STATUS_IDLE_BIT  0
`define CODEC_STATUS_BUSY_BIT  1
`define CODEC_STATUS_DONE_BIT  2
`define CODEC_STATUS_ERR_BIT   3
`define CODEC_STATUS_FLUSH_BIT 4

`define CODEC_IRQ_DONE_BIT     0
`define CODEC_IRQ_ERR_BIT      1

`define CODEC_ERR_OVERFLOW_BIT 0
`define CODEC_ERR_UNDERFLOW_BIT 1
`define CODEC_ERR_PROTO_BIT    2
`define CODEC_ERR_CFG_BIT      3

`define CODEC_CSR_CTRL_ADDR        8'h00
`define CODEC_CSR_STATUS_ADDR      8'h04
`define CODEC_CSR_IRQ_EN_ADDR      8'h08
`define CODEC_CSR_IRQ_STATUS_ADDR  8'h0C
`define CODEC_CSR_IRQ_CLEAR_ADDR   8'h10
`define CODEC_CSR_ERR_STATUS_ADDR  8'h14
`define CODEC_CSR_PERF_CYCLE_ADDR  8'h20
`define CODEC_CSR_PERF_STALL_ADDR  8'h24
`define CODEC_CSR_PERF_INBEAT_ADDR 8'h28
`define CODEC_CSR_PERF_OUTBEAT_ADDR 8'h2C
`define CODEC_CSR_PERF_FRAME_ADDR  8'h30
`define CODEC_CSR_DEBUG0_ADDR      8'h34
`define CODEC_CSR_DEBUG1_ADDR      8'h38

`define CODEC_TRUE  1'b1
`define CODEC_FALSE 1'b0

`endif

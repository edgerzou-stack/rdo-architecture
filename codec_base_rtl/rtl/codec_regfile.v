`include "codec_defs.vh"
//------------------------------------------------------------------------------
// File: codec_regfile.v
// Description:
//   Base CSR register block for codec IP control and status.
//
// Handshake:
//   - csr_valid with csr_ready accepts a transaction in the same cycle.
//   - csr_ready is hard-wired high in this first-drop implementation.
//   - Read data is returned combinationally with csr_rvalid = csr_valid & ~csr_write.
//
// Design notes:
//   - CTRL register bit0 is a persistent enable bit.
//   - start/stop/soft_reset/flush are write-one pulse commands on CTRL writes.
//   - IRQ status bits are sticky until cleared by IRQ_CLEAR or soft_reset.
//   - This module is intentionally protocol-light so it can be wrapped by APB,
//     AXI-Lite, or custom host shells later.
//------------------------------------------------------------------------------
module codec_regfile #(
    parameter ADDR_W     = 8,
    parameter DATA_W     = 32,
    parameter COUNTER_W  = 32,
    parameter ERR_W      = 8
) (
    input                       clk,
    input                       rst_n,

    input                       csr_valid,
    input                       csr_write,
    input      [ADDR_W-1:0]     csr_addr,
    input      [DATA_W-1:0]     csr_wdata,
    output                      csr_ready,
    output                      csr_rvalid,
    output reg [DATA_W-1:0]     csr_rdata,

    output reg                  cfg_enable_o,
    output reg                  cmd_start_pulse_o,
    output reg                  cmd_stop_pulse_o,
    output reg                  cmd_soft_reset_pulse_o,
    output reg                  cmd_flush_pulse_o,

    input                       status_idle_i,
    input                       status_busy_i,
    input                       status_done_i,
    input                       status_error_i,
    input                       status_flush_i,

    input                       irq_done_event_i,
    input                       irq_error_event_i,
    output                      irq_o,

    input      [COUNTER_W-1:0]  perf_cycle_cnt_i,
    input      [COUNTER_W-1:0]  perf_stall_cnt_i,
    input      [COUNTER_W-1:0]  perf_input_beat_cnt_i,
    input      [COUNTER_W-1:0]  perf_output_beat_cnt_i,
    input      [COUNTER_W-1:0]  perf_frame_done_cnt_i,
    input      [ERR_W-1:0]      error_status_i
);

    reg [DATA_W-1:0] irq_enable_reg;
    reg [DATA_W-1:0] irq_status_reg;

    wire csr_wr_fire;
    wire [DATA_W-1:0] status_word;
    wire [DATA_W-1:0] error_word;
    wire soft_reset_wr;

    assign csr_ready  = 1'b1;
    assign csr_rvalid = csr_valid & (~csr_write);
    assign csr_wr_fire = csr_valid & csr_write & csr_ready;
    assign soft_reset_wr = csr_wr_fire &&
                           (csr_addr == `CODEC_CSR_CTRL_ADDR) &&
                           csr_wdata[`CODEC_CTRL_SRST_BIT];

    assign status_word = {
        {(DATA_W-5){1'b0}},
        status_flush_i,
        status_error_i,
        status_done_i,
        status_busy_i,
        status_idle_i
    };

    assign error_word = {{(DATA_W-ERR_W){1'b0}}, error_status_i};
    assign irq_o = |(irq_enable_reg & irq_status_reg);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cfg_enable_o          <= 1'b0;
            cmd_start_pulse_o     <= 1'b0;
            cmd_stop_pulse_o      <= 1'b0;
            cmd_soft_reset_pulse_o <= 1'b0;
            cmd_flush_pulse_o     <= 1'b0;
            irq_enable_reg        <= {DATA_W{1'b0}};
            irq_status_reg        <= {DATA_W{1'b0}};
        end else begin
            cmd_start_pulse_o      <= 1'b0;
            cmd_stop_pulse_o       <= 1'b0;
            cmd_soft_reset_pulse_o <= 1'b0;
            cmd_flush_pulse_o      <= 1'b0;

            if (csr_wr_fire) begin
                case (csr_addr)
                    `CODEC_CSR_CTRL_ADDR: begin
                        cfg_enable_o <= csr_wdata[`CODEC_CTRL_EN_BIT];
                        if (csr_wdata[`CODEC_CTRL_START_BIT]) begin
                            cmd_start_pulse_o <= 1'b1;
                        end
                        if (csr_wdata[`CODEC_CTRL_STOP_BIT]) begin
                            cmd_stop_pulse_o <= 1'b1;
                        end
                        if (csr_wdata[`CODEC_CTRL_SRST_BIT]) begin
                            cmd_soft_reset_pulse_o <= 1'b1;
                            irq_status_reg <= {DATA_W{1'b0}};
                        end
                        if (csr_wdata[`CODEC_CTRL_FLUSH_BIT]) begin
                            cmd_flush_pulse_o <= 1'b1;
                        end
                    end

                    `CODEC_CSR_IRQ_EN_ADDR: begin
                        irq_enable_reg <= csr_wdata;
                    end

                    `CODEC_CSR_IRQ_CLEAR_ADDR: begin
                        irq_status_reg <= irq_status_reg & (~csr_wdata);
                    end

                    default: begin
                    end
                endcase
            end

            if (!soft_reset_wr) begin
                if (irq_done_event_i) begin
                    irq_status_reg[`CODEC_IRQ_DONE_BIT] <= 1'b1;
                end
                if (irq_error_event_i) begin
                    irq_status_reg[`CODEC_IRQ_ERR_BIT] <= 1'b1;
                end
            end
        end
    end

    always @(*) begin
        csr_rdata = {DATA_W{1'b0}};

        case (csr_addr)
            `CODEC_CSR_CTRL_ADDR: begin
                csr_rdata[`CODEC_CTRL_EN_BIT] = cfg_enable_o;
            end

            `CODEC_CSR_STATUS_ADDR: begin
                csr_rdata = status_word;
            end

            `CODEC_CSR_IRQ_EN_ADDR: begin
                csr_rdata = irq_enable_reg;
            end

            `CODEC_CSR_IRQ_STATUS_ADDR: begin
                csr_rdata = irq_status_reg;
            end

            `CODEC_CSR_IRQ_CLEAR_ADDR: begin
                csr_rdata = {DATA_W{1'b0}};
            end

            `CODEC_CSR_ERR_STATUS_ADDR: begin
                csr_rdata = error_word;
            end

            `CODEC_CSR_PERF_CYCLE_ADDR: begin
                csr_rdata = {{(DATA_W-COUNTER_W){1'b0}}, perf_cycle_cnt_i};
            end

            `CODEC_CSR_PERF_STALL_ADDR: begin
                csr_rdata = {{(DATA_W-COUNTER_W){1'b0}}, perf_stall_cnt_i};
            end

            `CODEC_CSR_PERF_INBEAT_ADDR: begin
                csr_rdata = {{(DATA_W-COUNTER_W){1'b0}}, perf_input_beat_cnt_i};
            end

            `CODEC_CSR_PERF_OUTBEAT_ADDR: begin
                csr_rdata = {{(DATA_W-COUNTER_W){1'b0}}, perf_output_beat_cnt_i};
            end

            `CODEC_CSR_PERF_FRAME_ADDR: begin
                csr_rdata = {{(DATA_W-COUNTER_W){1'b0}}, perf_frame_done_cnt_i};
            end

            `CODEC_CSR_DEBUG0_ADDR: begin
                csr_rdata = {DATA_W{1'b0}};
            end

            `CODEC_CSR_DEBUG1_ADDR: begin
                csr_rdata = {DATA_W{1'b0}};
            end

            default: begin
                csr_rdata = {DATA_W{1'b0}};
            end
        endcase
    end

endmodule

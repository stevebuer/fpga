// ============================================================================
// onewire_reset.v
//
// Stage 1 of the 1-Wire hardware peripheral: RESET / PRESENCE detect only.
// Soft-core register interface (memory-mapped, wire up to your bus later):
//
//   OW_CMD    (write) - reserved for future opcodes; ignored in this stage
//   OW_CTRL   (write) - bit0 = START (self-clearing strobe)
//   OW_STATUS (read)  - bit0 = BUSY
//                       bit1 = DONE  (sticky, cleared by writing DONE_CLR)
//                       bit2 = PRESENCE (valid once DONE=1)
//
// Timing is generated from CLK_HZ at synthesis time -- change CLK_HZ to
// match your actual system clock before building.
//
// dq_in / dq_out / dq_oe implement an open-drain pin: when dq_oe=1 the pad
// is driven to dq_out (always 0 in this design), when dq_oe=0 the pad is
// released (high-Z) and the external 4.7k pull-up brings it high. This is
// the FPGA equivalent of writing 1 vs 0 to a quasi-bidirectional 8051 port
// pin -- same electrical idea, now explicit.
// ============================================================================

module onewire_reset #(
    parameter CLK_HZ = 50_000_000
) (
    input  wire       clk,
    input  wire       rst_n,        // active-low synchronous reset

    // register interface
    input  wire        ctrl_start,   // pulse: soft core wrote START bit
    input  wire        status_clr,   // pulse: soft core cleared DONE
    output reg         status_busy,
    output reg         status_done,
    output reg         status_presence,

    // 1-Wire pad
    input  wire        dq_in,        // synchronized pin input (see note below)
    output reg         dq_oe         // 1 = drive low, 0 = release (tri-state)
);

    // ------------------------------------------------------------------
    // Timing constants: duration_us * (cycles per us)
    // ------------------------------------------------------------------
    localparam CYCLES_PER_US = CLK_HZ / 1_000_000;

    localparam [31:0] T_RESET_LOW    = CYCLES_PER_US * 480; // master holds low
    localparam [31:0] T_RELEASE_WAIT = CYCLES_PER_US * 70;  // wait before sampling (15-60us window, 70 gives margin)
    localparam [31:0] T_RECOVER      = CYCLES_PER_US * 410; // remainder of 960us total slot after sample

    // ------------------------------------------------------------------
    // Two-flop synchronizer for the async slave-driven pin.
    // This has no 8051 equivalent -- on the CPU side a single MOV/JB
    // instruction just reads the pin. In an FPGA, an external signal
    // crossing into our clock domain needs synchronizing or you risk
    // metastability, exactly the concern flagged earlier.
    // ------------------------------------------------------------------
    reg dq_in_meta, dq_in_sync;
    always @(posedge clk) begin
        dq_in_meta <= dq_in;
        dq_in_sync <= dq_in_meta;
    end

    // ------------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------------
    localparam S_IDLE            = 3'd0;
    localparam S_RESET_LOW       = 3'd1;
    localparam S_RELEASE_WAIT    = 3'd2;
    localparam S_SAMPLE_PRESENCE = 3'd3;
    localparam S_RECOVER         = 3'd4;

    reg [2:0]  state;
    reg [31:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= S_IDLE;
            counter         <= 32'd0;
            dq_oe           <= 1'b0;      // released at reset, matches
                                           // classic-8051 port-reset default
                                           // of "weak pull-up / input state"
            status_busy     <= 1'b0;
            status_done     <= 1'b0;
            status_presence <= 1'b0;
        end else begin
            case (state)

                S_IDLE: begin
                    dq_oe <= 1'b0;         // bus released while idle
                    if (status_clr)
                        status_done <= 1'b0;

                    if (ctrl_start) begin
                        status_busy <= 1'b1;
                        status_done <= 1'b0;
                        counter     <= 32'd0;
                        dq_oe       <= 1'b1;   // begin driving low
                        state       <= S_RESET_LOW;
                    end
                end

                // Drive DQ low for >= 480us
                S_RESET_LOW: begin
                    if (counter < T_RESET_LOW - 1) begin
                        counter <= counter + 1'b1;
                    end else begin
                        counter <= 32'd0;
                        dq_oe   <= 1'b0;        // release -- master stops driving
                        state   <= S_RELEASE_WAIT;
                    end
                end

                // Wait into the 15-60us presence window before sampling
                S_RELEASE_WAIT: begin
                    if (counter < T_RELEASE_WAIT - 1) begin
                        counter <= counter + 1'b1;
                    end else begin
                        counter <= 32'd0;
                        state   <= S_SAMPLE_PRESENCE;
                    end
                end

                // Sample: low = device present, high = nothing answered
                S_SAMPLE_PRESENCE: begin
                    status_presence <= ~dq_in_sync;
                    counter         <= 32'd0;
                    state           <= S_RECOVER;
                end

                // Finish out the remainder of the reset slot
                S_RECOVER: begin
                    if (counter < T_RECOVER - 1) begin
                        counter <= counter + 1'b1;
                    end else begin
                        status_busy <= 1'b0;
                        status_done <= 1'b1;
                        state       <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule

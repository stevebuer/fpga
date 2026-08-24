// ============================================================================
// blinky_top.v
//
// Cyclone II EP2C5T144 bring-up / sanity-check project.
// Purpose: verify clock frequency, pin mapping, and basic Quartus flow
// before building anything more complex (e.g. the 1-Wire FSM).
//
// Contents:
//   - Clock-divided LED blink   -> confirms real oscillator frequency
//   - Button -> LED passthrough -> confirms button pin + polarity
//   - AND / OR of two switch inputs -> confirms combinational logic +
//     two independent input pin assignments actually work end to end
//
// Update the placeholder CLK_HZ and every "PIN_xx" assignment in
// blinky_top.qsf once you've confirmed the real oscillator pin and
// header-to-FPGA-pin mapping for your board.
// ============================================================================

module blinky_top #(
    parameter CLK_HZ = 50_000_000   // CONFIRM with the blink test itself;
                                     // this is only used to size the counter
) (
    input  wire clk,        // oscillator input
    input  wire btn,        // one pushbutton, raw (no debounce yet)
    input  wire sw_a,       // switch/pin A, for AND/OR test
    input  wire sw_b,       // switch/pin B, for AND/OR test

    output wire led_blink,  // slow blink, ~1 Hz-ish, eyeball/stopwatch check
    output wire led_btn,    // lights while button is pressed (check polarity)
    output wire and_out,    // sw_a & sw_b
    output wire or_out      // sw_a | sw_b
);

    // ------------------------------------------------------------------
    // Clock-divided blink
    //
    // Counter width chosen so the LED toggles roughly once every ~1-2s
    // at 50MHz. If your real clock is a different frequency, the blink
    // rate will scale accordingly -- that mismatch IS the diagnostic.
    // Time it with a stopwatch: half-period = 2^(WIDTH-1) / CLK_HZ.
    // ------------------------------------------------------------------
    localparam WIDTH = 25;   // 2^25 / 50MHz ~= 0.67s half-period at 50MHz

    reg [WIDTH-1:0] div_counter;

    always @(posedge clk) begin
        div_counter <= div_counter + 1'b1;
    end

    assign led_blink = div_counter[WIDTH-1];

    // ------------------------------------------------------------------
    // Button passthrough (no debounce -- this is a pin/polarity check,
    // not a "real" input yet). If the board's button reads active-low
    // (common: pressed = 0), invert here once confirmed:
    //   assign led_btn = ~btn;
    // ------------------------------------------------------------------
    assign led_btn = btn;

    // ------------------------------------------------------------------
    // Combinational logic test pins
    // ------------------------------------------------------------------
    assign and_out = sw_a & sw_b;
    assign or_out  = sw_a | sw_b;

endmodule

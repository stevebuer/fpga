// ============================================================================
// onewire_reset_tb.v
//
// Testbench for onewire_reset.v. Drives a fake 1-Wire slave: watches DQ,
// and after the master releases following its reset pulse, pulls DQ low
// for a presence pulse inside the 60-240us window, then releases.
//
// Run with e.g.:
//   iverilog -o sim.out onewire_reset_tb.v ../src/onewire_reset.v
//   vvp sim.out
//   gtkwave onewire_reset_tb.vcd
//
// or load into ModelSim-Altera (bundled with Quartus II 13.0sp1) as a
// standard testbench-driven simulation.
// ============================================================================

`timescale 1ns/1ps

module onewire_reset_tb;

    // Use a low CLK_HZ so the 480us+ timing constants simulate in a
    // reasonable number of cycles/wall-clock time, while keeping the
    // *ratios* between phases identical to the real design (still
    // computed from CYCLES_PER_US inside the DUT). 1MHz here just means
    // "1 cycle per us" for an easy-to-reason-about testbench; swap to
    // your real board's CLK_HZ (e.g. 50_000_000) for a slower but fully
    // representative run once this passes.
    localparam CLK_HZ    = 1_000_000;
    localparam CLK_PERIOD_NS = 1_000_000_000 / CLK_HZ;

    reg clk;
    reg rst_n;
    reg ctrl_start;
    reg status_clr;

    wire status_busy;
    wire status_done;
    wire status_presence;

    // Shared 1-wire net, modeled with separate drive/release for master
    // and slave so we can see both sides pulling it low independently --
    // a real bus would just be a single wire with pull-up; here we OR
    // together whichever side is actively driving low.
    wire dq_master_oe;
    reg  dq_slave_oe;

    wire dq_line = (dq_master_oe || dq_slave_oe) ? 1'b0 : 1'b1; // pull-up model

    // ------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------
    onewire_reset #(
        .CLK_HZ(CLK_HZ)
    ) dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .ctrl_start      (ctrl_start),
        .status_clr      (status_clr),
        .status_busy     (status_busy),
        .status_done     (status_done),
        .status_presence (status_presence),
        .dq_in           (dq_line),
        .dq_oe           (dq_master_oe)
    );

    // ------------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------------
    always #(CLK_PERIOD_NS/2) clk = ~clk;

    // ------------------------------------------------------------------
    // Fake slave process: watch for DQ released after master's reset
    // pull-down, then assert presence inside the 60-240us window.
    // ------------------------------------------------------------------
    initial begin
        dq_slave_oe = 1'b0;
        forever begin
            // wait for the bus to go low (master's reset pulse starting)
            @(negedge dq_line);
            // wait for the bus to release back high (reset pulse ending)
            @(posedge dq_line);
            // per spec, slave must assert within 15-60us of release --
            // 30us keeps comfortable margin on both sides
            #(30 * 1000);
            dq_slave_oe = 1'b1;
            #(150 * 1000);          // hold presence pulse ~150us (spec: 60-240us)
            dq_slave_oe = 1'b0;
        end
    end

    // ------------------------------------------------------------------
    // Stimulus / checks
    // ------------------------------------------------------------------
    initial begin
        $dumpfile("onewire_reset_tb.vcd");
        $dumpvars(0, onewire_reset_tb);

        clk        = 0;
        rst_n      = 0;
        ctrl_start = 0;
        status_clr = 0;

        #100;
        rst_n = 1;
        #100;

        // Issue a reset/presence cycle
        ctrl_start = 1;
        #(CLK_PERIOD_NS);
        ctrl_start = 0;

        wait (status_done == 1'b1);

        if (status_presence)
            $display("PASS: presence detected at time %0t", $time);
        else
            $display("FAIL: no presence detected at time %0t", $time);

        status_clr = 1;
        #(CLK_PERIOD_NS);
        status_clr = 0;

        #1000;
        $finish;
    end

endmodule

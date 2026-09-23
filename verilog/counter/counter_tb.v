`timescale 1ms/1us

module counter_tb;

    reg        clk;
    reg        rst;
    wire [7:0] count;

    /* instantiate the counter */

    counter uut (
        .clk(clk),
        .rst(rst),
        .count(count)
    );

    /* clock generation: 100 Hz */

    initial clk = 0;
    always #5 clk = ~clk;

    /* stimulus */

    initial begin

        /* output waveform for GTKWave */

        $dumpfile("counter.vcd");
        $dumpvars(0, counter_tb);

        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        /* Let it count for a while */

        repeat (20) @(posedge clk);

        $display("Final count = %0d", count);
        $finish;
    end

    /* Print count on every clock edge */

    always @(posedge clk) begin
        $display("time=%0t rst=%b count=%0d", $time, rst, count);
    end

endmodule

/* 
 * counter module 
 *
 * Steve Buer, Olympic College
 * September 2026
 */

module counter #(
	parameter WIDTH = 8
)(
	input wire clk,
	input wire rst,
	output reg [WIDTH - 1:0] count
);

	/* per clock: increment or reset */

	always @(posedge clk) 
	begin
	if (rst)
		count <= 0;
        else
		count <= count + 1;
	end

endmodule

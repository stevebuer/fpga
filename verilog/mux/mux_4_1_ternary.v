// 4:1 MUX using ternary operator

module mux_4_1_case (
    input [3:0] data,
    input [1:0] sel,
    output Y
);

assign Y = (sel == 2'd0) ? data[0] : ((sel == 2'd1) ? data[1] : ((sel == 2'd2) ? data[2] : data[3]));

endmodule

// 4:1 MUX using if-else

module mux_4_1_case (
    input [3:0] data,
    input [1:0] sel,
    output Y
);

reg tmp;

always @ (sel, data)
begin
    if (sel == 2'd0)
        tmp <= data[0];
    else if (sel == 2'd1)
        tmp <= data[1];
    else if (sel == 2'd2)
        tmp <= data[2];
    else
        tmp <= data[3];
end

assign Y = tmp;

endmodule

`include "alu_func.v"

module alu #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C,
       	output reg OverflowFlag);
// Do not use delay in your implementation.

// You can declare any variables as needed.
/*
	YOUR VARIABLE DECLARATION...
*/

initial begin
	C = 0;
	OverflowFlag = 0;
end   	

// TODO: You should implement the functionality of ALU!
// (HINT: Use 'always @(...) begin ... end')
/*
	YOUR ALU FUNCTIONALITY IMPLEMENTATION...
*/

always @(*) begin 
if (FuncCode == 4'b0000) 
begin
    C = A + B;
    if (((A >> 15) == (B >>15)) && ((A >> 15) != (C >> 15)))
        OverflowFlag = 1;
    else
        OverflowFlag = 0;
end
else if (FuncCode == 4'b0001)
begin
    C = A - B;
    if (((A >> 15) == ((-B)>>15)) && ((A >> 15) != (C >> 15)))
        OverflowFlag = 1;
    else
        OverflowFlag = 0;
end
else if (FuncCode == 4'b0010)
begin
    C = A;
    OverflowFlag = 0;
end
else if (FuncCode == 4'b0011)
begin
    C = ~A;
    OverflowFlag = 0;
end
else if (FuncCode == 4'b0100)
begin
    C = A & B;
    OverflowFlag = 0;
end
else if (FuncCode == 4'b0101)
begin
    C = A | B;
    OverflowFlag = 0;
end
else if (FuncCode == 4'b0110)
begin
    C = ~(A & B);
    OverflowFlag = 0;
end
else if (FuncCode == 4'b0111)
begin
    C = ~(A | B);
    OverflowFlag = 0;
end
else if (FuncCode == 4'b1000)
begin
    C = A ^ B;
    OverflowFlag = 0;
end
else if (FuncCode == 4'b1001)
begin
    C = ~(A ^ B);
    OverflowFlag = 0;
end
else if (FuncCode == 4'b1010)
begin
    C = A << 1;
    OverflowFlag = 0;
end
else if (FuncCode == 4'b1011)
begin
    C = A >> 1;
    OverflowFlag = 0;
end
else if (FuncCode == 4'b1100)
begin
    C = A <<< 1;
    OverflowFlag = 0;
end
else if (FuncCode == 4'b1101)
begin
    C = (A >> 1) + ((A >> 15) << 15);
    OverflowFlag = 0;
end
else if (FuncCode == 4'b1110)
begin
    C = ~A + 1;
    OverflowFlag = 0;
end
else if (FuncCode == 4'b1111)
begin
    C = 0;
    OverflowFlag = 0;
end
else
begin
    C = A;
    OverflowFlag = 0;
end

end


endmodule


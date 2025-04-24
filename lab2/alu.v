`include "alu_func.v"

module alu (
    input [3:0] alu_op,      // input
    input [31:0] alu_in_1,    // input  
    input [31:0] alu_in_2,    // input
    output reg [31:0] alu_result,  // output
    output reg alu_bcond    // output   
  ); 	

always @(*) begin
	if (alu_op == `FUNC_BEQ)
		alu_bcond = (alu_in_1 == alu_in_2);
	else if (alu_op == `FUNC_BNE)
		alu_bcond = (alu_in_1 != alu_in_2); 
	else if (alu_op == `FUNC_BGE)
		alu_bcond = (alu_in_1 >= alu_in_2); 
	else if (alu_op == `FUNC_BLT)
		alu_bcond = (alu_in_1 < alu_in_2);
	else  
		alu_bcond = 0;
end

always @(*) begin
	if (alu_op == `FUNC_ADD)
		alu_result = alu_in_1 + alu_in_2;
	else if (alu_op == `FUNC_SUB)
		alu_result = alu_in_1 - alu_in_2; 
	else if (alu_op == `FUNC_AND)
		alu_result = alu_in_1 & alu_in_2;
	else if (alu_op == `FUNC_OR)
		alu_result = alu_in_1 | alu_in_2;
	else if (alu_op == `FUNC_XOR)
		alu_result = alu_in_1 ^ alu_in_2;
	else if (alu_op == `FUNC_LLS)
		alu_result = alu_in_1 << alu_in_2;
	else if (alu_op == `FUNC_LRS)
		alu_result = alu_in_1 >> alu_in_2;  
	else
        alu_result = 0;	 	
end
endmodule


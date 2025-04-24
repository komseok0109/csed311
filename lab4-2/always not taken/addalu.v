module addalu (
    input [31:0] alu_in_1,    // input  
    input [31:0] alu_in_2,    // input
    input stall,
    output reg [31:0] alu_result
  ); 	

assign alu_result = alu_in_1 + (!stall) * alu_in_2;

endmodule


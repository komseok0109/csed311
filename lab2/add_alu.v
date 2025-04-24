module add_alu (
    input [31:0] alu_in_1,    
    input [31:0] alu_in_2,    
    output reg [31:0] alu_result
  ); 	

assign alu_result = alu_in_1 + alu_in_2;

endmodule


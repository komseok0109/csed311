`include "opcodes.v"

module ForwardingUnit( input [4:0] rs1_id,
                        input [4:0] rs2_id,
                        input [4:0] mem_rd,
                        input [4:0] wb_rd,
                        input [6:0] opcode,
                        input mem_reg_write,
                        input wb_reg_write,
                        output reg [1:0] ForwardA,
                        output reg [1:0] ForwardB,
                        output reg [1:0] ForwardE);      

always @(*) begin
      if (rs1_id != 0 && rs1_id == mem_rd && mem_reg_write) 
            ForwardA = 2'b10;
	else if (rs1_id != 0 && rs1_id == wb_rd && wb_reg_write)
		ForwardA = 2'b01;
	else
            ForwardA = 2'b00;	
end
    
always @(*) begin
	if (rs2_id != 0 && rs2_id == mem_rd && mem_reg_write) 
            ForwardB = 2'b10;
	else if (rs2_id != 0 && rs2_id == wb_rd && wb_reg_write)
		ForwardB = 2'b01;
	else
            ForwardB = 2'b00;
end

always @(*) begin
      if (opcode == `ECALL && mem_rd == 17 && mem_reg_write)
            ForwardE = 2'b10;
      else if (opcode == `ECALL && wb_rd == 17 && wb_reg_write)
            ForwardE = 2'b01;
      else  
            ForwardE = 2'b00;
end

endmodule

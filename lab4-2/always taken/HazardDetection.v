`include "opcodes.v"

module   HazardDetection (input [4:0] rs1,
              input [4:0] rs2,  
              input [6:0] opcode,
              input EX_mem_read,  
              input [4:0] EX_rd,
              input [4:0] MEM_rd,
              input EX_reg_write,
              output reg stall);

assign stall = (((rs1 == EX_rd && rs1 != 0) || (rs2 == EX_rd  && rs2 != 0 && (opcode == `ARITHMETIC || opcode == `STORE || opcode == `BRANCH))) && EX_mem_read) 
|| (opcode == `ECALL && EX_rd == 17 && EX_reg_write);

endmodule

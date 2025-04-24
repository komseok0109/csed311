`include "opcodes.v"

module ControlUnit (
    input [6:0] part_of_inst,  // input
    output reg mem_read,      // output
    output reg mem_to_reg,    // output
    output reg mem_write,     // output
    output reg alu_src,       // output
    output reg write_enable,  // output
    output reg pc_to_reg,     // output
    output reg [6:0] alu_op,        // output
    output reg is_ecall,       // output (ecall inst)
    output reg is_branch,
    output reg is_jal,
    output reg is_jalr
  );

assign alu_op = part_of_inst;
assign is_jal = (part_of_inst == `JAL);
assign is_jalr = (part_of_inst == `JALR);
assign is_branch = (part_of_inst == `BRANCH);
assign mem_read = (part_of_inst == `LOAD);
assign mem_to_reg = (part_of_inst == `LOAD);
assign mem_write = (part_of_inst == `STORE);

assign alu_src = (part_of_inst != `ARITHMETIC) && (part_of_inst != `BRANCH);
assign write_enable = (part_of_inst != `STORE) && (part_of_inst != `BRANCH);

assign pc_to_reg = (part_of_inst == `JAL) || (part_of_inst == `JALR);
assign is_ecall = (part_of_inst == `ECALL);

endmodule

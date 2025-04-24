`include "alu_func.v"
// Submit this file with other files you created.
// Do not touch port declarations of the module 'cpu'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,                     // positive reset signal
           input clk,                       // clock signal
           output is_halted,                // Whehther to finish simulation
           output [31:0] print_reg [0:31]); // TO PRINT REGISTER VALUES IN TESTBENCH (YOU SHOULD NOT USE THIS)
  
  /***** Wire declarations *****/
  wire [31:0] next_pc, current_pc; 
  wire [31:0] pctarget, pc4;

  wire [31:0] mux1output, mux2output, mux3output, mux4output;

  wire [31:0] instruction;

  wire [31:0] rs1_out, rs2_out;
  wire [31:0] immgen;
  wire [31:0] alu_result;
  wire [31:0] dout;

  wire [3:0] alu_op;
  wire pcsrc1;
  wire alu_bcond;
  wire is_jal, is_jalr, branch, mem_read, mem_to_reg, mem_write, alu_src, write_enable, pc_to_reg, is_ecall;
  /***** Register declarations *****/

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  pc pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );
  
  add_alu pc_add(      // input
    .alu_in_1(current_pc),    // input  
    .alu_in_2(4),    // input
    .alu_result(pc4)  // output
  );

  add_alu pc_target(
    .alu_in_1(current_pc),    // input  
    .alu_in_2(immgen),    // input
    .alu_result(pctarget)  // output
  );

assign pcsrc1 = (alu_bcond && branch) || is_jal;
  mux mux4 (
    .input1(pctarget),  // input
    .input2(pc4),  //input
    .condition(pcsrc1), //input
    .muxoutput(mux4output) // output
  );

  mux mux5 (
    .input1(alu_result),  // input
    .input2(mux4output),  //input
    .condition(is_jalr), //input
    .muxoutput(next_pc)  // output
  );

  // ---------- Instruction Memory ----------
  instruction_memory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(instruction)     // output
  );

  mux mux2 (
    .input1(pc4),  // input
    .input2(mux3output),  // input
    .condition(pc_to_reg), // input
    .muxoutput(mux2output)         // output
  );

  // ---------- Register File ----------
  register_file reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (instruction[19:15]),          // input
    .rs2 (instruction[24:20]),          // input
    .rd (instruction[11:7]),           // input
    .rd_din (mux2output),       // input
    .is_ecall(is_ecall), //input
    .write_enable (write_enable), // input
    .rs1_dout (rs1_out),     // output
    .rs2_dout (rs2_out),     // output
    .print_reg (print_reg),  //DO NOT TOUCH THIS
    .is_halted (is_halted) //output
  );

  
  // ---------- Control Unit ----------
  control_unit ctrl_unit (
    .part_of_inst(instruction[6:0]),  // input
    .is_jal(is_jal),        // output
    .is_jalr(is_jalr),       // output
    .branch(branch),        // output
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(write_enable),  // output
    .pc_to_reg(pc_to_reg),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  immediate_generator imm_gen(
    .part_of_inst(instruction),  // input
    .imm_gen_out(immgen)    // output
  );

  mux mux1 (
    .input1(immgen),  // input
    .input2(rs2_out),  // input
    .condition(alu_src), // input
    .muxoutput(mux1output)         // output
  );


  // ---------- ALU Control Unit ----------
  alu_control_unit alu_ctrl_unit (
    .funct3(instruction[14:12]), //input
    .funct7_5(instruction[30]),  //input
    .opcode(instruction[6:0]),  // input
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  alu alu (
    .alu_op(alu_op),      // input
    .alu_in_1(rs1_out),    // input  
    .alu_in_2(mux1output),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)    // output
  );

  data_memory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (alu_result),       // input
    .din (rs2_out),        // input
    .mem_read (mem_read),   // input
    .mem_write (mem_write),  // input
    .dout (dout)        // output
  );

  mux mux3 (
    .input1(dout),  // input
    .input2(alu_result),  //
    .condition(mem_to_reg), //
    .muxoutput(mux3output)         // output
  );
endmodule

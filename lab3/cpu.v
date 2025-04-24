// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted,
           output [31:0]print_reg[0:31]
           ); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [31:0] next_pc, current_pc;
  wire PCUpdate = PCWrite | (~alu_bcond & PCWriteNotCond); 
  wire [31:0] rd_din, rs1_dout, rs2_dout;
  wire PCWriteNotCond, PCWrite, IorD, MemRead, MemWrite, MemtoReg, IRWrite, PCSource, RegWrite, ALUSrcA;
  wire [6:0] ALUOp;
  wire [1:0] ALUSrcB;
  wire is_ecall;
  wire [31:0] imm_gen_out, alu_in_1, alu_in_2, alu_result;
  wire [3:0] alu_op;
  wire alu_bcond;
  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  reg [31:0] addr, dout;
  // Do not modify and use registers declared above.

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock. 
  PC pc(
    .PCUpdate(PCUpdate),
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );

  mux PCSourcemux(
    .input1(ALUOut), //input
    .input2(alu_result), //input
    .condition(PCSource), //input
    .muxoutput(next_pc)  //output
  );

  mux MemtoRegmux(
    .input1(MDR),  //input
    .input2(ALUOut),  //input
    .condition(MemtoReg), //condition
    .muxoutput(rd_din) //condition
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(IR[19:15]),          // input
    .rs2(IR[24:20]),          // input
    .rd(IR[11:7]),           // input
    .rd_din(rd_din),       // input
    .write_enable(RegWrite),    // input
    .is_ecall(is_ecall),
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout),     // output
    .is_halted(is_halted),     // output
    .print_reg(print_reg)     // output (TO PRINT REGISTER VALUES IN TESTBENCH)
  );

  mux IorDmux(
    .input1(ALUOut),  //input
    .input2(current_pc),  //input
    .condition(IorD), //condition
    .muxoutput(addr) //condition
  );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(addr),         // input
    .din(B),          // input
    .mem_read(MemRead),     // input
    .mem_write(MemWrite),    // input
    .dout(dout)          // output
  ); 
  
  always @(posedge clk) begin
    if(reset) begin
      IR <= 0;
      MDR <= 0;
      A <= 0;
      B <= 0;
      ALUOut <= 0;
    end
    else begin
      if(IRWrite)
        IR <= dout;
      MDR <= dout;
      A <= rs1_dout;
      B <= rs2_dout;
      ALUOut <= alu_result;
    end
  end

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .clk(clk),
    .reset(reset),
    .part_of_inst(IR[6:0]),  // input
    .pc_update(PCUpdate),
    .pc_write_not_cond(PCWriteNotCond),        // output
    .pc_write(PCWrite),       // output
    .IorD(IorD),        // output
    .mem_read(MemRead),      // output
    .mem_to_reg(MemtoReg),    // output
    .mem_write(MemWrite),     // output
    .alu_src_a(ALUSrcA),       // output
    .alu_src_b(ALUSrcB),       // output
    .alu_op(ALUOp),       // output
    .ir_write(IRWrite),  // output
    .reg_write(RegWrite),  // output
    .pc_src(PCSource),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IR),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .funct3(IR[14:12]),  // input
    .funct7_5(IR[30]),       // input
    .opcode(ALUOp),      // input
    .alu_op(alu_op)         // output
  );

  mux ALUSrcAmux(
    .input1(A),
    .input2(current_pc),  //input
    .condition(ALUSrcA), //condition
    .muxoutput(alu_in_1)//condition
  );

  alusrcmux ALUSrcBmux(
    .input1(B),
    .input2(4),
    .input3(imm_gen_out),
    .condition(ALUSrcB),
    .muxoutput(alu_in_2)
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );

endmodule

// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted, // Whehther to finish simulation
           output [31:0]print_reg[0:31]); // Whehther to finish simulation
  /***** Wire declarations *****/
  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF stage *****/
  reg [31:0] next_pc, current_pc; //next PC value, current PC value
  reg [31:0] instruction; // instruction
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst; //IF/ID stage IR
  reg [31:0] IF_ID_pc; //IF/ID stage PC register
  /***** ID stage *****/
  reg mem_read, mem_to_reg, mem_write, alu_src, write_enable, pc_to_reg, is_branch, is_ecall; // single bit control value
  reg [6:0] alu_op; // ALU op
  reg [31:0] rd_din, rs1_dout, rs2_dout; //Register input data, Read Register 1 data, Read Register 2 data
  reg [31:0] imm_value; //Generated immediate value
  wire [4:0] reg1_id; //Reg1 ID (If instruction is ECALL, it is 17. If not, it is rs1)
  wire stall; // Stall or not.
  wire [1:0] ForwardE; //ECALL forwarding signal
  reg [31:0] E; //ECALL forwarding result
  /***** ID/EX pipeline registers *****/
  reg [6:0] ID_EX_alu_op; // ID/EX ALU op pipeline register
  reg ID_EX_alu_src, ID_EX_mem_write, ID_EX_mem_read, ID_EX_is_branch, ID_EX_mem_to_reg, ID_EX_reg_write; 
  // ID/EX single bit control value pipeline register       
  reg ID_EX_is_halted;  // ID/EX is_halted pipeline register
  reg [31:0] ID_EX_rs1_data, ID_EX_rs2_data, ID_EX_imm; // ID/EX rs1 data, rs2 data, immediate value pipeline register 
  reg [3:0] ID_EX_ALU_ctrl_unit_input; // ID/EX ALU control unit input (funct7_5, funct3) pipeline register 
  reg [4:0] ID_EX_rd; // ID/EX Destination Register ID pipeline register 
  reg [31:0] ID_EX_pc; // ID/EX PC value pipeline register  
  /***** EX stage *****/
  reg [3:0] ALU_op; // ALUControlUnit output
  reg [31:0] ALUSrcmuxout; // 2nd input of ALU
  reg [31:0] alu_result; // Computed Result of ALU 
  reg bcond; //bcond
  reg [31:0] A, B; // Output of ForwardA, ForwardB mux
  reg [4:0] EX_rs1_id, EX_rs2_id; // EX stage rs1 ID, rs2 ID (Forwarding Unit)
  wire [1:0] ForwardA, ForwardB; // ForwardA, ForwardB signal
  /***** EX/MEM pipeline registers *****/
  reg EX_MEM_mem_write, EX_MEM_mem_read, EX_MEM_is_branch, EX_MEM_mem_to_reg, EX_MEM_reg_write; 
  // EX/MEM single bit control value pipeline register 
  reg EX_MEM_is_halted; // EX/MEM is_halted pipeline register
  reg [31:0] EX_MEM_alu_out; // EX/MEM ALU result pipeline register
  reg [31:0] EX_MEM_dmem_data; // EX/MEM rs2 data(store) pipeline register
  reg [4:0] EX_MEM_rd; // EX/MEM Destination Register ID pipeline register
  reg EX_MEM_bcond; //bcond
  /***** MEM stage *****/
  reg [31:0] dout; //output of data memory
  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg, MEM_WB_reg_write; // MEM/WB single bit control value pipeline register   
  reg MEM_WB_is_halted; // MEM/WB is_halted pipeline register 
  reg [4:0] MEM_WB_rd; // MEM/WB Destination Register ID pipeline register
  reg [31:0] MEM_WB_mem_to_reg_src_1, MEM_WB_mem_to_reg_src_2; // MEM/WB MemToReg mux input pipeline register

  /***** IF stage *****/
  PC pc(
    .reset(reset),      
    .clk(clk),        
    .next_pc(next_pc),    
    .current_pc(current_pc)   
  );
  addalu pcalu (      
    .alu_in_1(current_pc),     
    .alu_in_2(4),
    .stall(stall),    
    .alu_result(next_pc)  
  );
  InstMemory imem(
    .reset(reset),   
    .clk(clk),     
    .addr(current_pc),   
    .dout(instruction)     
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      IF_ID_inst <= 0;
      IF_ID_pc <= 0;
    end
    else begin
      if (!stall) begin 
        IF_ID_inst <= instruction;
        IF_ID_pc <= current_pc;
      end
    end
  end

  /***** ID stage *****/
  mux MemToRegmux(
    .input1(MEM_WB_mem_to_reg_src_2),
    .input2(MEM_WB_mem_to_reg_src_1),
    .condition(MEM_WB_mem_to_reg),
    .muxoutput(rd_din)
  );
  RegSrcMUX RegSrcmux(
    .input1(17),
    .input2(IF_ID_inst[19:15]),
    .condition(is_ecall),
    .muxoutput(reg1_id)
  );
  RegisterFile reg_file (
    .reset (reset),       
    .clk (clk),         
    .rs1 (reg1_id),        
    .rs2 (IF_ID_inst[24:20]),       
    .rd (MEM_WB_rd),        
    .rd_din (rd_din),      
    .write_enable (MEM_WB_reg_write),    
    .rs1_dout (rs1_dout),     
    .rs2_dout (rs2_dout),      
    .print_reg(print_reg)
  );
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst[6:0]),
    .mem_read(mem_read),      
    .mem_to_reg(mem_to_reg),   
    .mem_write(mem_write),     
    .alu_src(alu_src),      
    .write_enable(write_enable),  
    .pc_to_reg(pc_to_reg),    
    .alu_op(alu_op),       
    .is_branch(is_branch),
    .is_ecall(is_ecall)      
  );
  HazardDetection hazardunit (
    .rs1(reg1_id),
    .rs2(IF_ID_inst[24:20]), 
    .opcode(IF_ID_inst[6:0]),
    .EX_mem_read(ID_EX_mem_read),
    .EX_rd(ID_EX_rd),
    .MEM_rd(EX_MEM_rd),
    .EX_reg_write(ID_EX_reg_write),
    .stall(stall)
  );
  ForwardMUX ECALLmux(
    .input1(rs1_dout),
    .input2(rd_din),
    .input3(EX_MEM_alu_out),
    .condition(ForwardE),
    .muxoutput(E)
  );
  ImmediateGenerator imm_gen(
    .part_of_inst(IF_ID_inst),  
    .imm_gen_out(imm_value)   
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      ID_EX_alu_op <= 0;         
      ID_EX_alu_src <= 0;        
      ID_EX_mem_write <= 0;     
      ID_EX_mem_read <= 0;       
      ID_EX_is_branch <= 0;     
      ID_EX_mem_to_reg <= 0;   
      ID_EX_reg_write <= 0;      
      ID_EX_is_halted <= 0;
      ID_EX_rs1_data <= 0;
      ID_EX_rs2_data <= 0;
      ID_EX_imm <= 0;
      ID_EX_ALU_ctrl_unit_input <= 0;
      ID_EX_rd <= 0;
      ID_EX_pc <= 0;
      EX_rs1_id <= 0;
      EX_rs2_id <= 0;
    end
    else begin
      ID_EX_alu_op <= alu_op;         
      ID_EX_alu_src <= alu_src;       
      ID_EX_mem_read <= mem_read;       
      ID_EX_is_branch <= is_branch;      
      ID_EX_mem_to_reg <= mem_to_reg;     
      if (stall) begin
        ID_EX_reg_write <= 0;      
        ID_EX_mem_write <= 0;      
      end
      else begin
        ID_EX_reg_write <= write_enable;      
        ID_EX_mem_write <= mem_write;     
      end
      ID_EX_rs1_data <= rs1_dout;
      ID_EX_rs2_data <= rs2_dout;
      ID_EX_imm <= imm_value;
      ID_EX_ALU_ctrl_unit_input <= {IF_ID_inst[30], IF_ID_inst[14:12]};
      ID_EX_rd <= IF_ID_inst[11:7];
      ID_EX_pc <= IF_ID_pc;
      ID_EX_is_halted <= ((E == 10) && (is_ecall));
      EX_rs1_id <= reg1_id;
      EX_rs2_id <= IF_ID_inst[24:20];
    end
  end

  /***** EX stage *****/
  ALUControlUnit alu_ctrl_unit (
    .opcode(ID_EX_alu_op),
    .funct3(ID_EX_ALU_ctrl_unit_input[2:0]),
    .funct7_5(ID_EX_ALU_ctrl_unit_input[3]), 
    .alu_op(ALU_op)        
  );
  ForwardMUX ALUSrcAmux(
    .input1(ID_EX_rs1_data),
    .input2(rd_din),
    .input3(EX_MEM_alu_out),
    .condition(ForwardA),
    .muxoutput(A)
  );
  ForwardMUX ALUSrcBmux(
    .input1(ID_EX_rs2_data),
    .input2(rd_din),
    .input3(EX_MEM_alu_out),
    .condition(ForwardB),
    .muxoutput(B)
  );
  mux ALUSrcmux(
    .input1(ID_EX_imm),
    .input2(B),
    .condition(ID_EX_alu_src),
    .muxoutput(ALUSrcmuxout)
  );
  ForwardingUnit forwardingunit( 
	  .rs1_id(EX_rs1_id),
    .rs2_id(EX_rs2_id),
    .mem_rd(EX_MEM_rd),
    .wb_rd(MEM_WB_rd),
    .opcode(IF_ID_inst[6:0]),
    .mem_reg_write(EX_MEM_reg_write),
    .wb_reg_write(MEM_WB_reg_write),
    .ForwardA(ForwardA),
    .ForwardB(ForwardB),
    .ForwardE(ForwardE)
  );      
  ALU alu (
    .alu_op(ALU_op),      
    .alu_in_1(A),    
    .alu_in_2(ALUSrcmuxout),   
    .alu_result(alu_result),  
    .alu_zero(bcond)    
  );

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write <= 0;     
      EX_MEM_mem_read <= 0;      
      EX_MEM_is_branch <= 0;     
      EX_MEM_mem_to_reg <= 0;    
      EX_MEM_reg_write <= 0;     
      EX_MEM_alu_out <= 0;
      EX_MEM_dmem_data <= 0;
      EX_MEM_rd <= 0;
      EX_MEM_is_halted <= 0;
    end
    else begin
      EX_MEM_mem_write <= ID_EX_mem_write;     
      EX_MEM_mem_read <= ID_EX_mem_read;      
      EX_MEM_is_branch <= is_branch;     
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;    
      EX_MEM_reg_write <= ID_EX_reg_write;     
      EX_MEM_alu_out <= alu_result;
      EX_MEM_dmem_data <= B;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_bcond <= bcond;
      EX_MEM_is_halted <= ID_EX_is_halted;
    end
  end

  /***** MEM stage *****/
  DataMemory dmem(
    .reset (reset),   
    .clk (clk),       
    .addr (EX_MEM_alu_out),      
    .din (EX_MEM_dmem_data),      
    .mem_read (EX_MEM_mem_read),  
    .mem_write (EX_MEM_mem_write),  
    .dout (dout)        
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_is_halted <= 0;
      MEM_WB_mem_to_reg <= 0;    
      MEM_WB_reg_write <= 0;    
      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
      MEM_WB_rd <= 0;
    end
    else begin
      MEM_WB_is_halted <= EX_MEM_is_halted;
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;    
      MEM_WB_reg_write <= EX_MEM_reg_write;    
      MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out;
      MEM_WB_mem_to_reg_src_2 <= dout;
      MEM_WB_rd <= EX_MEM_rd;
    end
  end

  assign is_halted = MEM_WB_is_halted;

endmodule

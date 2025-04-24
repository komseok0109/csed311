`include "opcodes.v"
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
  reg [31:0] next_pc, current_pc, pc4, predict_pc, jump_pc; //next PC value, current PC value
  reg [31:0] instruction; // instruction
  reg [31:0] BTB [31:0]; // 32 entries
  reg BP [31:0]; // branch predcitor
  integer i;

  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst; //IF/ID stage IR
  reg [31:0] IF_ID_pc; //IF/ID stage PC register

  /***** ID stage *****/
  reg mem_read, mem_to_reg, mem_write, alu_src, write_enable, pc_to_reg, is_branch, is_ecall, is_jal, is_jalr; // single bit control value
  reg [6:0] alu_op; // ALU op
  reg [31:0] rd_din, rs1_dout, rs2_dout; //Register input data, Read Register 1 data, Read Register 2 data
  reg [31:0] imm_value; //Generated immediate value
  wire [4:0] reg1_id; //Reg1 ID (If instruction is ECALL, it is 17. If not, it is rs1)
  wire stall; // Stall or not.
  wire [1:0] ForwardE; //ECALL forwarding signal
  reg [31:0] E; //ECALL forwarding result

  /***** ID/EX pipeline registers *****/
  reg [6:0] ID_EX_alu_op; // ID/EX ALU op pipeline register
  reg ID_EX_alu_src, ID_EX_mem_write, ID_EX_mem_read, ID_EX_mem_to_reg, ID_EX_reg_write, ID_EX_is_branch, ID_EX_is_jal, ID_EX_is_jalr, ID_EX_pc_to_reg; 
  // ID/EX single bit control value pipeline register       
  reg ID_EX_is_halted;  // ID/EX is_halted pipeline register
  reg [31:0] ID_EX_rs1_data, ID_EX_rs2_data, ID_EX_imm; // ID/EX rs1 data, rs2 data, immediate value pipeline register 
  reg [3:0] ID_EX_ALU_ctrl_unit_input; // ID/EX ALU control unit input (funct7_5, funct3) pipeline register 
  reg [4:0] ID_EX_rd; // ID/EX Destination Register ID pipeline register 
  reg [31:0] ID_EX_pc, ID_EX_pc4; // ID/EX PC value pipeline register  

  /***** EX stage *****/
  reg [3:0] ALU_op; // ALUControlUnit output
  reg [31:0] ALUSrcmuxout; // 2nd input of ALU
  reg [31:0] alu_result; // Computed Result of ALU 
  reg [31:0] pc_imm;
  reg bcond; //bcond
  reg [31:0] A, B; // Output of ForwardA, ForwardB mux
  reg [4:0] EX_rs1_id, EX_rs2_id; // EX stage rs1 ID, rs2 ID (Forwarding Unit)
  wire [1:0] ForwardA, ForwardB; // ForwardA, ForwardB signal
  wire [1:0] pc_src;
  wire pc_stall;

  /***** EX/MEM pipeline registers *****/
  reg EX_MEM_mem_write, EX_MEM_mem_read, EX_MEM_mem_to_reg, EX_MEM_reg_write, EX_MEM_pc_to_reg; 

  // EX/MEM single bit control value pipeline register 
  reg EX_MEM_is_halted; // EX/MEM is_halted pipeline register
  reg [31:0] EX_MEM_alu_out; // EX/MEM ALU result pipeline register
  reg [31:0] EX_MEM_dmem_data; // EX/MEM rs2 data(store) pipeline register
  reg [31:0] EX_MEM_pc; // EX/MEM PC value pipeline register
  reg [4:0] EX_MEM_rd; // EX/MEM Destination Register ID pipeline register

  /***** MEM stage *****/
  reg [31:0] dout; //output of data memory
  
  /***** MEM/WB pipeline registers *****/
  reg MEM_WB_mem_to_reg, MEM_WB_reg_write, MEM_WB_pc_to_reg; // MEM/WB single bit control value pipeline register   
  reg MEM_WB_is_halted; // MEM/WB is_halted pipeline register 
  reg [4:0] MEM_WB_rd; // MEM/WB Destination Register ID pipeline register
  reg [31:0] MEM_WB_mem_to_reg_src_1, MEM_WB_mem_to_reg_src_2; // MEM/WB MemToReg mux input pipeline register
  reg [31:0] MEM_WB_pc; // MEM/WB pc value pipeline register
  reg [31:0] mtrmuxout, wbpc4; //MemToReg mux output

  /***** IF stage *****/
  always @(*) begin
    if(((instruction[6:0] == `JAL) || (instruction[6:0] == `JALR) || (instruction[6:0] == `BRANCH)) && BP[current_pc[6:2]])
      predict_pc = BTB[current_pc[6:2]];
    else
      predict_pc = pc4;
  end

  TriMUX PcSrcmux(
    .input1(ID_EX_pc4),
    .input2(pc_imm),
    .input3(alu_result),
    .condition(pc_src),
    .muxoutput(jump_pc)
  );

  mux Pcmux(
    .input1(jump_pc),
    .input2(predict_pc),
    .condition(pc_stall),
    .muxoutput(next_pc)
  );

  PC pc(
    .reset(reset),      
    .clk(clk),        
    .next_pc(next_pc),    
    .current_pc(current_pc)   
  );
  
  addalu pc4alu (      
    .alu_in_1(current_pc),     
    .alu_in_2(4),
    .stall(stall),    
    .alu_result(pc4)  
  );

  InstMemory imem(
    .reset(reset),   
    .clk(clk),     
    .addr(current_pc),   
    .dout(instruction)     
  );

  // Update BTB
  always @(posedge clk) begin
    if(reset) begin
      for (i = 0; i < 32; i = i + 1) begin
        BTB[i] <= 0;
        BP[i] <= 0;
      end
    end
    else if(pc_src != 0) begin
      $display("%h %h", ID_EX_pc[6:2], jump_pc);
      BTB[ID_EX_pc[6:2]] <= jump_pc;
      BP[ID_EX_pc[6:2]] <= 1;
    end
  end

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      IF_ID_inst <= 0;
      IF_ID_pc <= 0;
    end
    else begin
      if (!stall && !pc_stall) begin 
        IF_ID_inst <= instruction;
        IF_ID_pc <= current_pc;
      end
      else if (pc_stall) begin
        IF_ID_inst <= 0;
      end
    end
  end
  
  /***** ID stage *****/
  RegSrcMUX RegSrcmux(
    .input1(17),
    .input2(IF_ID_inst[19:15]),
    .condition(is_ecall),
    .muxoutput(reg1_id)
  );
  addalu wbpc4alu (      
    .alu_in_1(MEM_WB_pc),     
    .alu_in_2(4),
    .stall(0),    
    .alu_result(wbpc4)  
  );
  mux PcToRegmux(
    .input1(wbpc4),
    .input2(mtrmuxout),
    .condition(MEM_WB_pc_to_reg),
    .muxoutput(rd_din)
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
    .is_ecall(is_ecall),
    .is_jal(is_jal),
    .is_jalr(is_jalr)      
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
  TriMUX ECALLmux(
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
      ID_EX_is_jal <= 0; 
      ID_EX_is_jalr <= 0;    
      ID_EX_mem_to_reg <= 0;   
      ID_EX_reg_write <= 0;   
      ID_EX_pc_to_reg <= 0;   
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
      ID_EX_mem_to_reg <= mem_to_reg;     
      if (stall || pc_stall) begin
        ID_EX_reg_write <= 0;      
        ID_EX_mem_write <= 0;
        ID_EX_is_branch <= 0; 
        ID_EX_is_jal <= 0; 
        ID_EX_is_jalr <= 0;    
        ID_EX_pc_to_reg <= 0;  
      end
      else begin
        ID_EX_reg_write <= write_enable;      
        ID_EX_mem_write <= mem_write;    
        ID_EX_is_branch <= is_branch; 
        ID_EX_is_jal <= is_jal; 
        ID_EX_is_jalr <= is_jalr;
        ID_EX_pc_to_reg <= pc_to_reg;
        ID_EX_pc <= IF_ID_pc;  
      end
      ID_EX_rs1_data <= rs1_dout;
      ID_EX_rs2_data <= rs2_dout;
      ID_EX_imm <= imm_value;
      ID_EX_ALU_ctrl_unit_input <= {IF_ID_inst[30], IF_ID_inst[14:12]};
      ID_EX_rd <= IF_ID_inst[11:7];
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
  TriMUX ALUSrcAmux(
    .input1(ID_EX_rs1_data),
    .input2(rd_din),
    .input3(EX_MEM_alu_out),
    .condition(ForwardA),
    .muxoutput(A)
  );
  TriMUX ALUSrcBmux(
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
    .alu_bcond(bcond)    
  );
  addalu pcimmalu (      
    .alu_in_1(ID_EX_pc),     
    .alu_in_2(ID_EX_imm),
    .stall(0),    
    .alu_result(pc_imm)  
  );
  addalu ID_EX_pc4alu (      
    .alu_in_1(ID_EX_pc),     
    .alu_in_2(4),
    .stall(stall),    
    .alu_result(ID_EX_pc4)  
  );
  PcControlUnit pccontrolunit (      
    .bcond(bcond),     
    .is_branch(ID_EX_is_branch),
    .is_jal(ID_EX_is_jal),
    .is_jalr(ID_EX_is_jalr),    
    .pc_src(pc_src)  
  );
  

  //assign pc_stall = (pc_src == 1) || (pc_src == 2) && (jump_pc != IF_ID_pc);
  assign pc_stall = (ID_EX_is_branch || ID_EX_is_jal || ID_EX_is_jalr) && (jump_pc != IF_ID_pc);

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write <= 0;     
      EX_MEM_mem_read <= 0;          
      EX_MEM_mem_to_reg <= 0;    
      EX_MEM_reg_write <= 0;
      EX_MEM_pc_to_reg <= 0;     
      EX_MEM_alu_out <= 0;
      EX_MEM_dmem_data <= 0;
      EX_MEM_rd <= 0;
      EX_MEM_is_halted <= 0;
      EX_MEM_pc <= 0;
    end
    else begin
      EX_MEM_mem_write <= ID_EX_mem_write;     
      EX_MEM_mem_read <= ID_EX_mem_read;          
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;   
      EX_MEM_pc_to_reg <= ID_EX_pc_to_reg;
      EX_MEM_reg_write <= ID_EX_reg_write; 
      EX_MEM_is_halted <= ID_EX_is_halted;  
      EX_MEM_alu_out <= alu_result;
      EX_MEM_dmem_data <= B;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_pc <= ID_EX_pc;
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
      MEM_WB_pc_to_reg <= 0;  
      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
      MEM_WB_rd <= 0;
      MEM_WB_pc <= 0;
    end
    else begin
      MEM_WB_is_halted <= EX_MEM_is_halted;
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;    
      MEM_WB_reg_write <= EX_MEM_reg_write; 
      MEM_WB_pc_to_reg <= EX_MEM_pc_to_reg;   
      MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out;
      MEM_WB_mem_to_reg_src_2 <= dout;
      MEM_WB_rd <= EX_MEM_rd;
      MEM_WB_pc <= EX_MEM_pc;
    end
  end

  mux MemToRegmux(
    .input1(MEM_WB_mem_to_reg_src_2),
    .input2(MEM_WB_mem_to_reg_src_1),
    .condition(MEM_WB_mem_to_reg),
    .muxoutput(mtrmuxout)
  );
  assign is_halted = MEM_WB_is_halted;

  always @(posedge clk) begin
    //$display("IF %h, ID: %h x15: %h x14: %h PCSTALL %d", instruction, IF_ID_inst, print_reg[15], print_reg[14], pc_stall);
    //$display("ID mem: %h mem in: %h addr: %h MEM memwrite, memread: %d %d dout %h", mem_write, EX_MEM_dmem_data, EX_MEM_alu_out, EX_MEM_mem_write, EX_MEM_mem_read, dout);
    $display("PC: %h IF %h, %h j:%h p:%h", current_pc, instruction, pc_src, jump_pc, predict_pc);
  end
endmodule

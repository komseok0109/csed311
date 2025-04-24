`include "opcodes.v"

module  ControlUnit(input clk,
    input reset,
    input [6:0] part_of_inst, // input
    input pc_update , // input
    output reg pc_write_not_cond,        // output
    output reg pc_write,       // output
    output reg IorD,        // output
    output reg mem_read,      // output
    output reg mem_to_reg,    // output
    output reg mem_write,     // output
    output reg alu_src_a,       // output
    output reg [1:0] alu_src_b,       // output
    output reg [6:0] alu_op,       // output
    output reg ir_write,  // output
    output reg reg_write,  // output
    output reg pc_src,     // output
    output reg is_ecall       // output (ecall inst)
  );

  reg [31:0] state; // state register 0 ~ 3 : IF, 4 : ID, 5 ~ 6 : EX, 7 ~ 10 : MEM, 11 : WB 

always @(posedge clk) begin
    if(reset) begin
      state <= 3;
    end
    else if((pc_update) && (state != 3)) begin // temporary IF state for branch 
      state <= 3;
    end
    else if(state == 4) begin // EX for JAL & ID for the others
      if(part_of_inst == `JAL || part_of_inst == `ECALL)
        state <= 11;
      else
        state <= 6;
    end
    else if(state == 6) begin //EX_2
      if((part_of_inst == `LOAD) || (part_of_inst == `STORE))
        state <= 10;
      else
        state <= 11;
    end
    else if(state == 10) begin // MEM_4
      state <= 11;
    end
    else // IF 
      state <= 4;
  end

  always @(*) begin
    if((state == 10) && (part_of_inst == `STORE))
      pc_write = 1;
    else if(state == 11)
      pc_write = 1;
    else
      pc_write = 0;
  end

  always @(*) begin
    if((part_of_inst == `BRANCH) && (state == 6))
      pc_write_not_cond = 1;
    else
      pc_write_not_cond = 0;
  end

  always @(*) begin
    if((part_of_inst == `LOAD) && (state == 10))  // LD & MEM
      IorD = 1;
    else if((part_of_inst == `STORE) && (state == 10))  // LD & MEM
      IorD = 1;
    else
      IorD = 0;
  end

  always @(*) begin
    if((state == 3)) // IF
      mem_read = 1;
    else if((part_of_inst == `LOAD) && (state == 10)) // LD & MEM
      mem_read = 1;
    else
      mem_read = 0;
  end

  always @(*) begin
    if((part_of_inst == `LOAD) && (state == 11))
      mem_to_reg = 1;
    else
      mem_to_reg = 0;
  end

  always @(*) begin
    if((part_of_inst == `STORE) && (state == 10))
      mem_write = 1;
    else
      mem_write = 0;
  end  

  always @(*) begin
    if(state == 6) begin
      if((part_of_inst != `JAL) && (part_of_inst != `JALR))
        alu_src_a = 1;
      else
        alu_src_a = 0;
    end
    else if(state == 11) begin
      if(part_of_inst == `JALR)
        alu_src_a = 1;
      else
        alu_src_a = 0;
    end
    else
      alu_src_a = 0;
  end

  always @(*) begin
    if(state == 6) begin
      if((part_of_inst == `ARITHMETIC) || (part_of_inst == `BRANCH))
        alu_src_b = 2'b00;
      else if (part_of_inst == `JALR)
        alu_src_b = 2'b01;
      else
        alu_src_b = 2'b10;
    end
    else if((state == 11)) begin
      if((part_of_inst == `JAL)||(part_of_inst == `JALR)||(part_of_inst == `BRANCH))
        alu_src_b = 2'b10;
      else
        alu_src_b = 2'b01;
    end
    else
      alu_src_b = 2'b01;
  end

  always @(*) begin
    if ((state == 3))
      ir_write = 1;
    else
      ir_write = 0;
  end

  always @(*) begin
    if((state == 11) && (part_of_inst != `BRANCH))
      reg_write = 1;
    else
      reg_write = 0;
  end

  always @(*) begin
    if((part_of_inst == `BRANCH) && (state == 6))
      pc_src = 1;
    else
      pc_src = 0;
  end


  always @(*) begin
    if(state == 6) begin
      if(part_of_inst == `ARITHMETIC)
        alu_op = part_of_inst;
      else if(part_of_inst == `ARITHMETIC_IMM)
        alu_op = part_of_inst;
      else if(part_of_inst == `BRANCH)
        alu_op = part_of_inst;
      else 
        alu_op = 7'b1111111; // ADD
    end
    else
      alu_op = 7'b1111111;
  end

  assign is_ecall = (part_of_inst == `ECALL);
endmodule


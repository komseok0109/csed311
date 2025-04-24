`include "alu_func.v"
`include "opcodes.v"

module ALUControlUnit (input [2:0] funct3,
                        input funct7_5,
                        input [6:0] opcode,
                        output reg [3:0] alu_op);

always @(*) begin
    if(opcode == `ARITHMETIC) begin
        if (funct7_5) begin
            alu_op = `FUNC_SUB;
        end
        else begin
            if (funct3 == `FUNCT3_ADD)
                alu_op = `FUNC_ADD;
            else if (funct3 == `FUNCT3_SRL)
                alu_op = `FUNC_LRS;
            else if (funct3 == `FUNCT3_SLL)
                alu_op = `FUNC_LLS;
            else if (funct3 == `FUNCT3_XOR)
                alu_op = `FUNC_XOR;
            else if (funct3 == `FUNCT3_OR)
                alu_op = `FUNC_OR;
            else //(funct3 == `FUNCT3_AND)
                alu_op = `FUNC_AND;
        end 
    end
    else if(opcode == `ARITHMETIC_IMM) begin
        if (funct3 == `FUNCT3_ADD)
            alu_op = `FUNC_ADD;
        else if (funct3 == `FUNCT3_XOR)
            alu_op = `FUNC_XOR;
        else if (funct3 == `FUNCT3_OR)
            alu_op = `FUNC_OR;
        else if (funct3 == `FUNCT3_AND)
            alu_op = `FUNC_AND;
        else if (funct3 == `FUNCT3_SRL)
            alu_op = `FUNC_LRS;
        else //(funct3 == `FUNCT3_SLL)
            alu_op = `FUNC_LLS;
    end
    else if(opcode == `BRANCH) begin
        if (funct3 == `FUNCT3_BEQ)
            alu_op = `FUNC_BEQ;
        else if (funct3 == `FUNCT3_BLT)
            alu_op = `FUNC_BLT;
        else if (funct3 == `FUNCT3_BGE)
            alu_op = `FUNC_BGE;
        else //(funct3 == `FUNCT3_BNE)
            alu_op = `FUNC_BNE;
    end
    else
        alu_op = `FUNC_ADD;
end
endmodule


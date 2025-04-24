module PcControlUnit (input bcond,     
                    input is_branch,
                    input is_jal,
                    input is_jalr,    
                    output reg [1:0] pc_src);

    always @(*) begin
        if ((bcond && is_branch) || is_jal) 
            pc_src = 2'b01;
        else if (is_jalr)
            pc_src = 2'b10;
        else 
            pc_src = 2'b00;
    end

endmodule

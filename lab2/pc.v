module pc( input reset,
                input clk,
                input [31:0] next_pc,
                output reg [31:0] current_pc);      // input (Use reset to initialize PC. Initial value must be 0)

    always @(posedge clk ) begin
		if (reset) 
			current_pc <= 0;
		else 
			current_pc <= next_pc;
	end
endmodule

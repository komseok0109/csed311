module ForwardMUX (input [31:0] input1,  // input
            input [31:0] input2,    // input
            input [31:0] input3,  // input
            input [1:0] condition, // input
            output reg [31:0] muxoutput); //output

    always @(*) begin
        if (condition == 0) 
            muxoutput = input1;
        else if (condition == 1)
            muxoutput = input2;
        else 
            muxoutput = input3;
    end

endmodule

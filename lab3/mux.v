module mux (input [31:0] input1,  // input
            input [31:0] input2,  // input
            input condition, // input
            output reg [31:0] muxoutput); //output

    always @(*) begin
        if(condition) 
            muxoutput = input1;
        else
            muxoutput = input2; 
    end

endmodule

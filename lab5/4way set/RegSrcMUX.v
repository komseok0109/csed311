module   RegSrcMUX (input [4:0] input1,  // input
              input [4:0] input2,  //
              input condition,
              output reg [4:0] muxoutput);

    always @(*) begin
        if(condition) 
            muxoutput = input1;
        else
            muxoutput = input2; 
    end

endmodule

`include "vending_machine_def.v"

module check_time_and_coin(i_input_coin,i_select_item,clk,reset_n,wait_time,o_return_coin, i_trigger_return, current_total);
	input clk;
	input reset_n;
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0]	i_select_item;
	input [`kTotalBits - 1:0] current_total;
	input i_trigger_return;
	output reg  [`kNumCoins-1:0] o_return_coin;
	output reg [31:0] wait_time;
	
	reg [`kNumCoins-1:0] i_input_coin_prev;
	reg [`kNumItems-1:0] i_select_item_prev;
	reg triggered;

    // initiate values
	initial begin
    	o_return_coin = 3'b000;
    	wait_time = 10;
    	i_input_coin_prev = 0;
		i_select_item_prev = 0;
		triggered = 0; 
	end

	// update coin return time and reset wait_time
	always @(posedge clk) begin
    	if(i_trigger_return) begin
			if(!triggered) begin
				wait_time <= 3;
				triggered <= 1;
			end
			else begin 
				if (wait_time > 0)
            		wait_time <= wait_time - 1;
			end
		end
		else if (!reset_n || (i_input_coin != i_input_coin_prev) || (i_select_item != i_select_item_prev)) 
        	wait_time <= 10;
    	else begin
        	if (wait_time > 0)
            	wait_time <= wait_time - 1;
    	end
    	i_input_coin_prev <= i_input_coin;
		i_select_item_prev <= i_select_item;
	end

	always @(*) begin
		if (current_total >= 1600)
			o_return_coin = 3'b111;
		else if (current_total >= 1500)
			o_return_coin = 3'b110;
		else if (current_total >= 1100)
			o_return_coin = 3'b101;
		else if (current_total >= 1000)
			o_return_coin = 3'b100;
		else if (current_total >= 600)
		    o_return_coin = 3'b011;
		else if (current_total >= 500)
		    o_return_coin = 3'b010;
		else if (current_total >= 100)
		    o_return_coin = 3'b001;
		else
		    o_return_coin = 0;
	end

endmodule 

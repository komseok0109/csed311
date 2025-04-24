
`include "vending_machine_def.v"
	

module calculate_current_state(i_input_coin,i_select_item,item_price,coin_value,current_total,
wait_time,current_total_nxt,o_available_item,o_return_coin,o_output_item, i_trigger_return);


	input [`kNumCoins-1:0] i_input_coin, o_return_coin;
	input [`kNumItems-1:0]	i_select_item;			
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];	
	input [`kTotalBits-1:0] current_total;
	input [31:0] wait_time;
	input i_trigger_return;
	output reg [`kNumItems-1:0] o_available_item,o_output_item;
	output reg  [`kTotalBits-1:0] current_total_nxt;  
	integer i;	


	// Combinational logic for the next states
	always @(*) begin
		if(wait_time == 0) 
			current_total_nxt = current_total - o_return_coin[0] * coin_value[0] - o_return_coin[1] * coin_value[1] - o_return_coin[2] * coin_value[2];
		else if (i_trigger_return) 
			current_total_nxt = current_total;
		else if(i_select_item != 0) begin
			if(i_select_item[0] && current_total >= item_price[0]) 
				current_total_nxt = current_total - item_price[0];
			else if(i_select_item[1] && current_total >= item_price[1]) 
				current_total_nxt = current_total - item_price[1];
			else if(i_select_item[2] && current_total >= item_price[2]) 
				current_total_nxt = current_total - item_price[2];
			else if(i_select_item[3] && current_total >= item_price[3])
				current_total_nxt = current_total - item_price[3];
			else
				current_total_nxt = current_total;
		end
		else if(i_input_coin != 0)
			current_total_nxt = current_total + i_input_coin[0] * coin_value[0] + i_input_coin[1] * coin_value[1] + i_input_coin[2] * coin_value[2];
		else 
			current_total_nxt = current_total;
	end

	
	
	// Combinational logic for the outputs
	always @(*) begin
		for(i = 0; i < `kNumItems; i = i + 1 ) begin
				if(current_total >= item_price[i])
					o_available_item[i] = 1;
				else
					o_available_item[i] = 0;
			end
		if(i_select_item[0] && current_total >= item_price[0]) 
			o_output_item = 4'b0001;
		else if(i_select_item[1] && current_total >= item_price[1]) 
			o_output_item = 4'b0010;
		else if(i_select_item[2] && current_total >= item_price[2]) 
			o_output_item = 4'b0100;
		else if(i_select_item[3] && current_total >= item_price[3]) 
			o_output_item = 4'b1000;
		else
			o_output_item = 0;
	end
 
endmodule 

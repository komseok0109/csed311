`include "CLOG2.v"

module Cache #(parameter LINE_SIZE = 16,
               parameter NUM_SETS = 4,
               parameter NUM_WAYS = 4) (
    input reset,
    input clk,

    input is_input_valid,
    input [31:0] addr,
    input mem_rw,
    input [31:0] din,

    output reg is_ready,
    output reg is_output_valid,
    output reg [31:0] dout,
    output reg is_hit);
  // Wire declarations
  integer i, j;
  wire is_data_mem_ready;
  reg [LINE_SIZE * 8 - 1 : 0] data_bank [0: (NUM_SETS - 1)][0 : NUM_WAYS-1]; // 16 * 8(data)
  reg [31:0] tag_bank [0: NUM_SETS - 1][0 : NUM_WAYS - 1]; // 4(e)31,28 + 1(v)27 + 1(d)26 + 26(t)
  reg [LINE_SIZE * 8 - 1 : 0] mem_din;
  reg [LINE_SIZE * 8 - 1 : 0] mem_dout;
  reg [1:0] set_idx;
  reg [1:0] block_offset;
  reg mem_is_output_valid;
  reg mem_is_input_valid;
  reg mem_write, mem_read;
  reg [31:0] mem_addr;
  reg wb_done;
  reg [1:0] way;
  reg evict;

  // Cache initialization
  always @(posedge clk) begin
    if(reset) begin
      for(i = 0; i < NUM_SETS; i = i + 1) begin
        for(j=0; j< NUM_WAYS; j = j + 1) begin
          tag_bank[i][j] <= 0;
          data_bank[i][j] <= 0;
        end
      end
    end
  end

  assign set_idx = addr[5:4];
  assign block_offset = addr[3:2];

  always @(*) begin // Memory controller
    if (mem_is_output_valid || (is_data_mem_ready && wb_done)) begin
      mem_read = 0;
      mem_write = 0;
      mem_is_input_valid = 0;
      mem_din = 0;
      mem_addr = addr;
    end
    else if(is_input_valid && (is_hit == 0)) begin 
      if(evict && tag_bank[set_idx][way][26] == 1) begin 
        mem_write = 1;
        mem_read = 0;
        mem_is_input_valid = 1;
        mem_din = data_bank[set_idx][way];
        mem_addr = {tag_bank[set_idx][way][25:0], set_idx, 4'b0000};
      end
      else begin 
        mem_read = 1;
        mem_write = 0;
        mem_is_input_valid = 1;
        mem_din = 0;
        mem_addr = addr;
      end
    end
    else begin
      mem_read = 0;
      mem_write = 0;
      mem_is_input_valid = 0;
      mem_din = 0;
      mem_addr = addr;
    end
  end

  // Cache controller
  always @(*) begin 
    if((tag_bank[set_idx][0][27] == 1 && tag_bank[set_idx][0][25:0] == addr[31:6])) begin
      is_hit = 1;
      way = 0;
      evict = 0;
    end
    else if(tag_bank[set_idx][1][27] == 1 && tag_bank[set_idx][1][25:0] == addr[31:6]) begin
      is_hit = 1;
      way = 1;
      evict = 0;
    end
    else if(tag_bank[set_idx][2][27] == 1 && tag_bank[set_idx][2][25:0] == addr[31:6]) begin
      is_hit = 1;
      way = 2;
      evict = 0;
    end
    else if(tag_bank[set_idx][3][27] == 1 && tag_bank[set_idx][3][25:0] == addr[31:6]) begin
      is_hit = 1;
      way = 3;
      evict = 0;
    end
    else begin 
      is_hit = 0;
      if (tag_bank[set_idx][0][27] == 0) begin
        way = 0;
        evict = 0;
      end
      else if (tag_bank[set_idx][1][27] == 0) begin
        way = 1;
        evict = 0;
      end
      else if (tag_bank[set_idx][2][27] == 0) begin
        way = 2;
        evict = 0;
      end
      else if (tag_bank[set_idx][3][27] == 0) begin
        way = 3;
        evict = 0;
      end
      else begin
        evict = 1;
        if (tag_bank[set_idx][0][31:29] == 0) begin
          way = 0;
        end
        else if (tag_bank[set_idx][1][31:29] == 0) begin
          way = 1;
        end
        else if (tag_bank[set_idx][2][31:29] == 0) begin
          way = 2;
        end
        else begin
          way = 3;
        end
      end
    end
  end

  always @(*) begin // cache read
    if(is_input_valid && (mem_rw == 0)) begin
      if(is_hit) begin
        if(block_offset == 3)
          dout = data_bank[set_idx][way][127:96];
        else if(block_offset == 2)
          dout = data_bank[set_idx][way][95:64];
        else if(block_offset == 1)
          dout = data_bank[set_idx][way][63:32];
        else 
          dout = data_bank[set_idx][way][31:0];
      end
      else 
        dout = 0;
    end
    else
      dout = 0; 
  end

  always @(posedge clk) begin // cache write
    if(is_input_valid && (mem_rw == 1)) begin
      if(is_hit) begin 
        if(block_offset == 3)
          data_bank[set_idx][way][127:96] <= din;
        else if(block_offset == 2)
          data_bank[set_idx][way][95:64] <= din;
        else if(block_offset == 1)
          data_bank[set_idx][way][63:32] <= din;
        else 
          data_bank[set_idx][way][31:0] <= din; 
        tag_bank[set_idx][way][26] <= 1; //dirty
      end
    end
  end

    //Update LRU bit
  always @(posedge clk) begin
    if(is_input_valid && is_hit) begin
      for(i = 0; i < 4; i++) 
        tag_bank[set_idx][i][31:28] <= tag_bank[set_idx][i][31:28] >> 1;  
      tag_bank[set_idx][way][31] <= 1;
    end
  end

  //Update WB
  always @(posedge clk) begin
    if(reset)
      wb_done <= 0;
    else if(is_input_valid && !is_hit && evict && (tag_bank[set_idx][way][27] == 1)) begin
      if(is_data_mem_ready)
        wb_done <= 0;
      else
        wb_done <= 1;
    end    
  end
  // Write Back & Replace
  always @(posedge clk) begin
    if(mem_is_output_valid) begin 
      tag_bank[set_idx][way][27] <= 1; 
      tag_bank[set_idx][way][26] <= 0; 
      tag_bank[set_idx][way][25:0] <= addr[31:6]; 
      data_bank[set_idx][way] <= mem_dout; 
    end
    else if(is_data_mem_ready && wb_done) begin
      tag_bank[set_idx][way][26] <= 0; // dirty
    end
  end

  assign is_output_valid = (mem_rw == 0) && is_hit;
  assign is_ready = is_input_valid ? is_hit && is_data_mem_ready : is_data_mem_ready;

  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),

    .is_input_valid(mem_is_input_valid),
    .addr(mem_addr >> `CLOG2(LINE_SIZE)),        // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read(mem_read),
    .mem_write(mem_write),
    .din(mem_din),

    // is output from the data memory valid?
    .is_output_valid(mem_is_output_valid),
    .dout(mem_dout),
    // is data memory ready to accept request?
    .mem_ready(is_data_mem_ready)
  );
endmodule

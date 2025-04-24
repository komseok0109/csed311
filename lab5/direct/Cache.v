`include "CLOG2.v"

module Cache #(parameter LINE_SIZE = 16,
               parameter NUM_SETS = 16,
               parameter NUM_WAYS = 1) (
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
  wire is_data_mem_ready;
  
  // Reg declarations
  reg [LINE_SIZE * 8 - 1 : 0] data_bank [0: (NUM_SETS - 1) * NUM_WAYS]; // 16 * 8(data)
  reg [25:0] tag_bank [0: NUM_SETS - 1]; // 1(v) + 1(d) + 24(t)
  reg [LINE_SIZE * 8 - 1 : 0] mem_din;
  reg [LINE_SIZE * 8 - 1 : 0] mem_dout;

  // You might need registers to keep the status.
  integer i;
  reg [3:0] set_idx;
  reg [3:0] block_offset;
  reg memory_is_output_valid;
  reg mem_is_input_valid;
  reg mem_write, mem_read;
  reg [31:0] mem_addr;
  reg _mem_rw;

  always @(posedge clk) begin
    if(reset) begin
      for(i = 0; i < NUM_SETS; i = i + 1) begin
        tag_bank[i] <= 0;
        data_bank[i] <= 0;
      end
    end
    // Cache Initialization
   // $display("iv: %h mem_ready: %h is_hit: %h", is_input_valid, is_data_mem_ready, is_hit);
  end

  assign set_idx = addr[7:4];
  assign block_offset = addr[3:0];

  always @(*) begin // Cache controller
    if (memory_is_output_valid || (is_data_mem_ready && _mem_rw)) begin
      mem_read = 0;
      mem_write = 0;
      mem_is_input_valid = 0;
      mem_din = 0;
      mem_addr = addr;
    end
    else if(is_input_valid && (mem_rw == 0) && (is_hit == 0)) begin //LD/ST && read && miss -> read miss -> mem read = 1 mem_is_input_valid = 1
      if(tag_bank[set_idx][24] == 1) begin // Read Miss, dirty case, have to write back
        mem_write = 1;
        mem_read = 0;
        mem_is_input_valid = 1;
        mem_din = data_bank[set_idx];
        mem_addr = {tag_bank[set_idx][23:0], set_idx, 4'b0000};
        $display("%h %h", mem_din, mem_addr);
      end
      else begin // Read miss, clean case. Don't need to write back
        mem_read = 1;
        mem_write = 0;
        mem_is_input_valid = 1;
        mem_din = 0;
        mem_addr = addr;
      end
    end
    else if (is_input_valid && (mem_rw == 1) && (is_hit == 0)) begin //LD/ST && write && miss -> write miss
      if(tag_bank[set_idx][24] == 1) begin // Write miss, dirty case. Have to write back
        mem_write = 1;
        mem_read = 0;
        mem_is_input_valid = 1;
        mem_din = data_bank[set_idx];
        mem_addr = {tag_bank[set_idx][23:0], set_idx, 4'b0000};
      end
      else begin // Write miss, clean case. Don't need to write back
        mem_read = 1;
        mem_write = 0;
        mem_is_input_valid = 1;
        mem_din = 0;
        mem_addr = addr;
      end
    end //Not miss case(Hit or input valid). Do not enter memory.
    else begin
      mem_read = 0;
      mem_write = 0;
      mem_is_input_valid = 0;
      mem_din = 0;
      mem_addr = addr;
    end
  end

  always @(*) begin // is_hit
    if(tag_bank[set_idx][25] == 1) begin 
      if(tag_bank[set_idx][23:0] == addr[31:8]) //hit 
        is_hit = 1;
      else //conflict miss
        is_hit = 0;
    end
    else //cold miss
      is_hit = 0;
  end

  always @(*) begin // cache read
    if(is_input_valid && (mem_rw == 0)) begin
      if(is_hit) begin
        $display("READ HIT, %h, %h, %h", addr, data_bank[set_idx], block_offset);
        if(block_offset[3:2] == 3)
          dout = data_bank[set_idx][127:96];
        else if(block_offset[3:2] == 2)
          dout = data_bank[set_idx][95:64];
        else if(block_offset[3:2] == 1)
          dout = data_bank[set_idx][63:32];
        else 
          dout = data_bank[set_idx][31:0];
      end
      else 
        dout = 0;
    end
    else
      dout = 0; 
  end

  always @(posedge clk) begin // cache write
    if(is_input_valid && (mem_rw == 1)) begin
      if(is_hit) begin //cache write hit
        $display("WRITE HIT, %h, %h, %h", addr, set_idx, block_offset);
        if(block_offset[3:2] == 3)
          data_bank[set_idx][127:96] <= din;
        else if(block_offset[3:2] == 2)
          data_bank[set_idx][95:64] <= din;
        else if(block_offset[3:2] == 1)
          data_bank[set_idx][63:32] <= din;
        else 
          data_bank[set_idx][31:0] <= din; 
        tag_bank[set_idx][24] <= 1; //dirty
      end
    end
  end

  always @(posedge clk) begin
    if(reset)
      _mem_rw <= 0;
    else if(is_input_valid && !is_hit && (tag_bank[set_idx][24] == 1)) begin
      if(is_data_mem_ready)
        _mem_rw <= 0;
      else
        _mem_rw <= 1;
    end    
  end
  always @(posedge clk) begin
    //$display("$$");
    if(memory_is_output_valid) begin // call data
      tag_bank[set_idx][25] <= 1; // valid
      tag_bank[set_idx][24] <= 0; // dirty
      tag_bank[set_idx][23:0] <= addr[31:8]; // tag
      data_bank[set_idx] <= mem_dout; 
      $display("LINE BROUGHT___________________________________________");
    end
    else if(is_data_mem_ready && _mem_rw) begin
      tag_bank[set_idx][24] <= 0; // dirty
      $display("WRITE BACK___________________________________________");
    end
  end

  // always @(posedge clk) begin
  //   $display("MEM_RW: %h", _mem_rw);
  // end

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
    .is_output_valid(memory_is_output_valid),
    .dout(mem_dout),
    // is data memory ready to accept request?
    .mem_ready(is_data_mem_ready)
  );
endmodule

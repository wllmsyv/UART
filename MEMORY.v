module MEMORY(
 clk,
 address,
 rden,
 wren,
 data
);

parameter DATA_WIDTH = 32, ADDRESS_WIDTH = 4;
parameter RAM_DEPTH = 1<<ADDRESS_WIDTH;


input clk;
input [ADDRESS_WIDTH - 1:0]address;
input wren;
input rden;
inout [DATA_WIDTH - 1: 0]data;
integer i = 0;


reg [DATA_WIDTH - 1:0]MEM[RAM_DEPTH-1:0];
reg [DATA_WIDTH - 1:0]DATA_OUT;

assign data = (rden && ~wren)?DATA_OUT:32'bz;

initial begin
  DATA_OUT = 0;
  for (i = 0; i < RAM_DEPTH; i = i + 1)begin
    MEM[i] = 0;
  end
end



always@(posedge clk) begin
  if(rden && ~wren)begin
    DATA_OUT <= MEM[address];
  end else if (wren && ~rden) begin
    MEM[address] <= data;
  end
end


endmodule 
/*


Author: Bill Sylvia
			wllmsyv@comcast.net

Module I/O definitions:
	clk 						= (input) System Clock
	rx_data					= (input) 8 bit data to be recieved from RX module
	rx_rdy					= (input) rdy flag from RX module
	controller_data		= (output) 8 bit data interface
	contoller_new_data	= (output) flag to indicate that there is new data in the buffer
	controller_data_rdy	= (output) falg to indicate the request for new data has been answered and ready at the controller_data interface
	controller_req_data	= (input)  flag to indicate to the controller module that the interface is requesting data from the buffer
	controller_overflow	= (output) flag to indicate that the buffer is full and the oldest data will start to be overwritten
	mem_wren					= (output) flag to enable writing to the buffer
	mem_rden					= (output) flag to enable reading from the buffer
	mem_addr					= (output) read/write address from the buffer
	mem_data					= (bidir)  read/write data line to/from buffer
	probe 					= (output) probes used to indicate current state of the module for debugging purposes.


Parameters definitions:
	None

Instruction:

	Module assumes 8 bit data
	
	This module required a TX, RX, and data buffer (memory).

 	"rx_rdy"  line is monitored continously. When new data is recieved from RX module, the data is stored in the buffer
	and the  "contoller_new_data"  interface flag is raised to indicate to the interface that there is new data in the buffer.
	If the buffer is filled, the  "controller_overflow"  flag is raised to indicate to the interface that the buffer is full
	and the oldest data is going to be overwritter. Data must be read from the controller to deassert  "controller_overflow" flag.
	
	"contoller_new_data"  indicates that there is new data in the buffer. A 1 can then be asserted to  "controller_req_data"  to 
	request data from the buffer. The controller will then get the oldest data from the buffer and send it to  "controller_data".
	Once the data is ready  "controller_data_rdy"  will be asserted to let the interface know that it may read the  "controller_data"
	line. The controller module will wait until  "controller_req_data"  has been deasserted to indicate that the data has been
	recived by the interface. If the  "controller_req_data"  is not deasserted before a new data comes in from the 
	RX module, the contoller will about the request for new data to catch the incoming data from the RX module. If  "controller_req_data"
	is still asserted, the process to recieve new data will be started again.
	
	When all the data has been read from the buffer  "contoller_new_data"  will be deasserted.
	
	
*/

module CONTROLLER(
clk,
rst,
rx_data,
rx_rdy,
controller_data,
contoller_new_data,
controller_data_rdy,
controller_req_data,
controller_overflow,
mem_wren,
mem_rden,
mem_addr,
mem_data,
probe
);



/*********************************
			Module I/O
**********************************/

input clk;
input rst;
input [7:0]rx_data;
input rx_rdy;
output reg [7:0]controller_data;
output reg contoller_new_data;
output reg controller_data_rdy;
input controller_req_data;
output reg controller_overflow;
output reg mem_wren;
output reg mem_rden;
output reg [7:0]mem_addr;
inout [7:0]mem_data;
output wire [15:0]probe;



/*********************************
			Parameters
**********************************/

//states
localparam WAIT = 4'H0, INCREMENT_STACK_TOP = 4'H1,  SET_WR_ADDR = 4'H2, WRITE_DELAY = 4'H3, MEM_WRITE = 4'H4, MEM_READ = 4'H5;
localparam SET_RD_ADDR = 4'H6, INCREMENT_STACK_BOTTOM = 4'H7, READ_DELAY = 4'H8, SEND_DATA = 4'H9, RESET = 4'HA;
localparam RX_WAITING_FOR_DATA = 4'H0, RX_WAIT_TO_RELEASE = 4'H1, RX_WAIT_FOR_DATA_STORE = 4'H2, RX_RESET = 4'H3;


/*********************************
			Local Variable
**********************************/

reg [7:0]rx_data_buffer;
reg [7:0]stack_top;
reg [7:0]stack_bottom;
reg new_rx_buffer_rdy;
reg new_data_stored;
reg [3:0]state;
assign probe[7:0] = stack_top;
assign probe[15:8] = stack_bottom;
reg [3:0]rx_state;

/*********************************
			Initialization Block
**********************************/

initial begin
	controller_data <= 8'H0;
	contoller_new_data <= 1'B0;
	controller_data_rdy <= 1'B0;
	controller_overflow <= 1'B0;
	mem_wren <= 1'B0;
	mem_rden <= 1'B0;
	mem_addr <= 8'B0;

	rx_data_buffer <= 8'H0;
	stack_top <= 8'H0;
	stack_bottom <= 8'H0;
	new_rx_buffer_rdy <= 1'B0;
	new_data_stored <= 1'B0;
	state <= WAIT;
end

assign mem_data = (~mem_rden && mem_wren)?rx_data_buffer:8'bz;



/*********************************
		Controller State Machine
**********************************/

always@(posedge clk)begin

	case(rx_state)

		RX_WAITING_FOR_DATA:begin
			if(rst)begin
				rx_state <= RX_RESET;
			end else if (rx_rdy && ~new_data_stored && ~new_rx_buffer_rdy)begin
				rx_state <= RX_WAIT_TO_RELEASE;
				rx_data_buffer <= rx_data;
			end
		end RX_WAIT_TO_RELEASE: begin
			if(~rx_rdy)begin
				rx_state <= RX_WAIT_FOR_DATA_STORE;
				new_rx_buffer_rdy <= 1'B1;
			end
		end RX_WAIT_FOR_DATA_STORE: begin
			if(new_data_stored)begin
				rx_state <= RX_WAITING_FOR_DATA;
				new_rx_buffer_rdy <= 1'B0;
			end
		end RX_RESET: begin
			rx_data_buffer <= 8'H0;
			new_rx_buffer_rdy <= 1'B0;
			rx_state <= RX_WAITING_FOR_DATA;
		end
		
	
	endcase
	
end


always@(posedge clk)begin
	case(state)

		//WAIT
		WAIT: begin

			case({rst, new_rx_buffer_rdy,controller_req_data})
				3'b000:state <= state;
				3'b001:state <= INCREMENT_STACK_TOP;
				3'b010:state <= SET_RD_ADDR;
				3'b011:state <= SET_RD_ADDR;
				default:state <= RESET;
			endcase
			
			
		//INCREMENT_STACK_TOP
		end INCREMENT_STACK_TOP: begin

			case({rst,(stack_top == (stack_bottom - 8'H1))})
				2'b00:begin
					stack_top <= stack_top + 8'H1;
					controller_overflow <= 1'B0;
					state <= SET_WR_ADDR;
					contoller_new_data <= 1'B1;
				end 2'b01:begin
					stack_top <= stack_top + 8'H1;
					stack_bottom <= stack_bottom + 8'H1;
					controller_overflow <= 1'B1;
					state <= SET_WR_ADDR;
					contoller_new_data <= 1'B1;
				end default:begin
					state <= RESET;
				end
			endcase
			

		//SET_WR_ADDR
		end SET_WR_ADDR: begin
			mem_addr <= stack_top;
			mem_wren <= 1'B1;
			state <= WRITE_DELAY;

			
		//WRITE_DELAY
		end WRITE_DELAY: begin
			state <= MEM_WRITE;
			new_data_stored <= 1'B1;

			
		//MEM_WRITE
		end MEM_WRITE: begin
			mem_wren <= 1'B0;
			new_data_stored <= 1'B0;
			state <= WAIT;

			
		//SET_RD_ADDR
		end SET_RD_ADDR: begin
			mem_addr <= stack_bottom;
			mem_rden <= 1'B1;
			state <= READ_DELAY;

			
		//READ_DELAY
		end READ_DELAY: begin
			state <= MEM_READ;
			
			
		//MEM_READ
		end MEM_READ: begin
			controller_data <= mem_data;
			state <= SEND_DATA;
			controller_data_rdy <= 1'B1;
		
		
		//SEND_DATA
		end SEND_DATA: begin

			mem_rden <= 1'B0;
			case({rst, ~controller_req_data,new_rx_buffer_rdy})
				3'b000:begin
					state <= state;
				end 3'b001:begin
					state <= INCREMENT_STACK_TOP;
					controller_data_rdy <= 1'B0;
				end 3'b010:begin
					state <= INCREMENT_STACK_BOTTOM;
					controller_data_rdy <= 1'B0;
				end 3'b011:begin
					state <= INCREMENT_STACK_BOTTOM;
					controller_data_rdy <= 1'B0;
				end 3'b100:begin
					state <= RESET;
				end 3'b101:begin
					state <= RESET;
				end 3'b111:begin
					state <= RESET;
				end
			endcase
			
			
		//INCREMENT_STACK_BOTTOM
		end INCREMENT_STACK_BOTTOM: begin
			case({rst, (stack_top == stack_bottom)})
				2'b00:begin
					stack_bottom = stack_bottom + 8'H1;
					controller_overflow <= 1'B0;
					state <= WAIT;
				end 2'b01:begin
					contoller_new_data <= 1'B0;
					controller_overflow <= 1'B0;
					state <= WAIT;
				end 2'b10:begin
					state <= RESET;
				end 2'b11:begin
					state <= RESET;
				end
			endcase

			
		//RESET
		end RESET: begin
			controller_data <= 8'H0;
			contoller_new_data <= 1'B0;
			controller_data_rdy <= 1'B0;
			controller_overflow <= 1'B0;
			mem_wren <= 1'B0;
			mem_rden <= 1'B0;
			mem_addr <= 8'B0;

			stack_top <= 8'H0;
			stack_bottom <= 8'H0;
			new_data_stored <= 1'B0;
			state <= WAIT;	
		end 
	endcase
end
endmodule

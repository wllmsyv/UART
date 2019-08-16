
/*

Author: Bill Sylvia
			wllmsyv@comcast.net

Module I/O definitions:
	clk 	= (input) System Clock
	rst 	= (input) 1 resets the module, 0 return the module to normal operating state
	rx 	= (input) Incoming data transmission line
	data 	= (output) 8 bit data to be recieved
	rdy 	= (output) flag to indicate that data is ready at the data line
	probe = (output) probes used to indicate current state of the module for debugging purposes.


Parameters definitions:
	BAUD_RATE UART transmission rate, default 115200 b/s
	SYS_CLOCK_FREQUENCY System clock frequency, default 50,000,000 mHz

Instruction:
	1 Start Bit
	8 data bits
	1 stop bit
	Currently no option for parity bit
	
	
	rdy flag needs to be contiously monitored. Once data is recieved, the rdy flag
	will be asserted (1) during the stop bit. Once transmission is complete and the RX
	module is ready to recieve new data, the rdy flag will be deasserted (0).
	
*/



module UART_RX(
clk,
rst,
rx,
data,
rdy,
probe
);

/*********************************
			Module I/O
**********************************/
input clk;
input rx;
input rst;
output reg	[7:0]data;
output reg rdy;
output wire [3:0]probe;

/*********************************
			Parameters
**********************************/
parameter SYS_CLOCK_FREQUENCY = 32'H2FAF080, BAUD_RATE = 32'H1C200;
localparam WAIT_TIME = SYS_CLOCK_FREQUENCY/BAUD_RATE/2;
localparam WAIT = 4'H0, START = 4'H1, READ = 4'H2, ADVANCE = 4'H3, SEND = 4'H4,  STOP = 4'H5, RESET = 4'H6;

/*********************************
			Local Variable
**********************************/

reg [31:0]counter;
reg [3:0] state;
reg [3:0] data_index;
assign probe = state;

/*********************************
			Initialization Block
**********************************/
initial begin
	data 		<= 8'H0;
	rdy 		<= 1'B0;
	counter 	<= 32'H0;
	state 		<= WAIT;
	data_index 	<= 4'H0;
end

/*********************************
			RX State Machine
**********************************/
always @(posedge clk)begin


		case(state)
		
			//WAIT
			WAIT: begin
				if(rst)begin
					state <= RESET;
				end else if(~rx)begin
					state <= START;
				end
			
			//START
			end START: begin
				counter <= counter + 32'H1;
				if(rst)begin
					state <= RESET;
				end else if(counter == WAIT_TIME)begin
					counter <= 32'H0;
					state <= READ;
				end
			
			//READ
			end READ: begin
				counter <= counter + 32'H1;
				if(rst)begin
					state <= RESET;
				end else if(counter == 2*WAIT_TIME)begin
					data[data_index] <= rx;
					state <= ADVANCE;
					counter <= 32'H0;
					data_index <= data_index + 4'H1;
				end
			
			//ADVANCE		
			end ADVANCE: begin
				counter <= counter + 32'H1;
				if(rst)begin
					state <= RESET;
				end else if(data_index == 4'H8)begin
					state <= SEND;
				end else begin
					state <= READ;
				end
				
			//SEND	
			end SEND: begin
				counter <= counter + 32'H1;
				if(rst)begin
					state <= RESET;
				end else if(counter == WAIT_TIME)begin
					rdy <= 1'B1;
					state <= STOP;
				end
				
			//STOP
			end STOP: begin
				counter <= counter + 32'H1;
				if(rst)begin
					state <= RESET;
				end else if(counter == 2*WAIT_TIME)begin
					rdy <= 1'B0;
					data_index <= 4'H0;
					state <= WAIT;
					counter <= 32'H0;
				end
			
			//RESET
			end RESET: begin
				data 			<= 8'H0;
				rdy 			<= 1'B0;
				counter 		<= 32'H0;
				state 		<= WAIT;
				data_index 	<= 4'H0;
			//default
			end default: begin
				state <= WAIT;
			end
		endcase
end

endmodule 
/*


Author: Bill Sylvia
			wllmsyv@comcast.net

Module I/O definitions:
	clk 	= (input) System Clock
	rst 	= (input) 1 resets the module, 0 return the module to normal operating state
	TX 	= (input) Outgoing transmission line
	data 	= (input) 8 bit data to be transmitted
	rdy 	= (input) flag to indicate that data is ready at the data line to be transmitted
	busy 	= (output) flag to indicate that the tx module us busy transmitting data.
	probe = (output) probes used to indicate current state of the module for debugging purposes.


Parameters definitions:
	BAUD_RATE UART transmission rate, default 115200 b/s
	SYS_CLOCK_FREQUENCY System clock frequency, default 50,000,000 mHz

Instruction:
	1 Start Bit
	8 data bits
	1 stop bit
	Currently no option for parity bit
	
	
	, assert a 1 for "rdy", once the "rdy" flag has been released to 0	
	the data transmission will begin. While transmission is in progress the "busy" flag will
	be raised until the transmission has been completed.
	
	
*/

module UART_TX(
clk,
rst,
TX,
data,
rdy,
busy,
probe
);



/*********************************
			Module I/O
**********************************/

input clk;
input rst;
input wire [7:0]data;
input wire rdy;
output reg busy;
output reg TX;
output wire [3:0]probe;

/*********************************
			Parameters
**********************************/

parameter BAUD_RATE = 32'H1C200, SYS_CLOCK_FREQUENCY = 32'H2FAF080;
localparam WAIT_TIME = SYS_CLOCK_FREQUENCY/BAUD_RATE;
localparam START_BIT = 1'B0, STOP_BIT = 1'B1;
localparam WAIT = 4'H0, RELEASE = 4'H1, TRANSMIT_DATA = 4'H2, END_TRANSMISSION = 4'H3, RESET = 4'H4;


/*********************************
			Local Variable
**********************************/

reg [31:0]timer;
reg [9:0]msg;
reg [4:0]msg_index;
reg [3:0]state;
assign probe = state;

/*********************************
			Initialization Block
**********************************/
initial begin
	state <= WAIT;
	TX <= 1'B1;
	msg_index  = 5'H0;
	timer <= 32'H0;
	msg <=	{STOP_BIT, 8'H48, START_BIT};
	busy <= 1'B0;
end


/*********************************
			TX State Machine
**********************************/
always@(posedge clk)begin

	case(state)
	
		//WAIT
		WAIT:begin
			if(rdy)begin
				busy <= 1'B1;
				msg <=	{STOP_BIT, data, START_BIT};
				state <= RELEASE;
			end
		
		//RELEASE
		end RELEASE:begin
			if(~rdy)begin
				state <= TRANSMIT_DATA;
			end
		
		//TRANSMIT_DATA
		end TRANSMIT_DATA:begin
			timer <= timer + 32'H1;
			if(timer == WAIT_TIME)begin
				TX <= msg[msg_index];
				msg_index <= msg_index + 5'H1;
				timer <= 31'H0;
			end
			if(msg_index == 5'HA)begin
				state <= END_TRANSMISSION;
			end
			
		//END_TRANSMISSION
		end END_TRANSMISSION:begin
			timer <= timer + 32'H1;
			if(timer == WAIT_TIME)begin
				msg_index <= 5'H0;
				busy <= 1'B0;
				state <= WAIT;
				timer <= 32'H0;
			end
			
		//RESET
		end RESET:begin
			msg_index <= 5'H0;
			busy <= 1'B0;
			state <= WAIT;
			timer <= 32'H0;
		
		//default
		end default: begin
			msg_index <= 5'H0;
			busy <= 1'B0;
			state <= WAIT;
			timer <= 32'H0;
		end
	endcase
	
end



endmodule 
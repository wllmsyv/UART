/*


Author: Bill Sylvia
			wllmsyv@comcast.net

Module I/O definitions:
		clk						= (input) System Clock
		rst						= (input) SSystem Reset
		tx_data					= (input) S8'bit data to be transmitted
		tx_rdy					= (input) Sflag to indicate data is ready at the tx_data line
		tx_busy					= (output) indicates that the tx module is busy transmitting data
		rx_data_out				= (output) data line where data is recieved from the rx mdoule
		rx_req_data				= (input) flag to indicate that the interface is ready to recieve data on rx_data_out line			
		rx_new_data				= (output) Flag to indicate that there is new rx data waiting in the buffer
		rx_data_rdy				= (output) flag to indicate that the requested data is ready at the interface on the rx_data_out line
		rx_data_overflow		= (output) flag to indicate that the rx data buffer is full
		TX							= (output) external tx line
		RX							= (input) Sexternal rx line

Parameters definitions:
	None

Instruction:

	Module assumes 8 bit data
	
	UART.v is the top level module.
		|------ UART_TX
		|------ UART_RX
		|------ MY_MEMORY
		|------ CONTROLLER
	
	
	
	TX
	To transmit data, assert data on the tx_data line then assert tx_data. When the data begins to transmit, the UART_TX module
	will raise the tx_busy flag. When the transmit is complete the tx_busy will return to 0.
	
	RX
	When new data has been recieved, the rx_new_data flag will be raised. Assert a 1 on the rx_req_data line to get a new byte. When a new
	byte is ready to be read from the rx_data_out line, the rx_data_rdy flag will be raised. Once the data has been read from rx_req_data
	line, a 0 must be asserted on the rx_req_data line in order to complete the read. To get the next byte, the rx_req_data line must have a 1 asserted.
	When all the data has been read from the buffer, rx_new_data flag will be lowered (0) to indicate that the buffer is empty. If no data is read 
	from the buffer and all 255 bytes are full, a 1 will be asserted on the rx_data_overflow line to indicate that the buffer will start to overwrite
	the oldest data. Once data is read from the buffer, the rx_data_overflow flag will be lowered (0).
	
	Default baud rate for the module is 115200
	Default clock speed is 50 mHz.
	
*/


module UART(
				clk, 
				rst,
				tx_data, 
				tx_rdy,
				tx_busy,
				rx_data_out,
				rx_req_data,
				rx_new_data,
				rx_data_rdy,
				rx_data_overflow,
				TX, 
				RX
				);


/*********************************
			Module I/O
**********************************/

input				clk;
input 			rst;
input 			[7:0]tx_data;
input 			tx_rdy;
output wire 	tx_busy;
output wire 	[7:0]rx_data_out;
input 			rx_req_data;
output wire 	rx_new_data;
output wire 	rx_data_rdy;
output wire 	rx_data_overflow;
input 			RX;
output wire 	TX;


/*********************************
			Parameters
**********************************/



/*********************************
			Local Variable
**********************************/

wire[31:0]probes; 	// Dangling Probe Wires
wire [7:0] rx_data;
wire  rx_rdy;
wire mem_wren;
wire mem_rden;
wire [7:0]mem_addr;
wire [7:0]mem_data;
wire [3:0] dangle;	// Dangling Probe Wires


UART_TX uart_tx(
clk,
rst,
TX,
tx_data,
tx_rdy,
tx_busy,
dangle
);


UART_RX uart_rx(
clk,
rst, //rst
RX,
rx_data,
rx_rdy,
probes[30:27]
);

MEMORY #(.DATA_WIDTH(8), .ADDRESS_WIDTH(8)) rx_buffer(
 clk,
 mem_addr,
 mem_rden,
 mem_wren,
 mem_data
);


CONTROLLER c0(
clk,
rst,
rx_data,
rx_rdy,
rx_data_out, 		//controller_data,
rx_new_data,		//contoller_new_data,
rx_data_rdy, 		//controller_data_rdy,
rx_req_data, 		//controller_req_data,
rx_data_overflow, //controller_overflow,
mem_wren,
mem_rden,
mem_addr,
mem_data,
probes[15:0]
);

endmodule 
//////////////////////////////////////////////////////////////////////////////////
// 
//	SIMULATES L1,L2 CACHE AND MAIN MEMORY ALL WORKING TOGETHER
// 
//////////////////////////////////////////////////////////////////////////////////

// TODO: i-cache

module CacheModel #(parameter CORE = 0, DATA_WIDTH = 32, ADDR_WIDTH = 8)(
	input 						clk,			// clock
	input 						rst,			// synchronous reset active high
	input 						report,			// report stats active high
	input 						write_en,
	input	[ADDR_WIDTH-1:0]	address,
	input	[DATA_WIDTH-1:0]	write_data,
	output	[DATA_WIDTH-1:0]	read_data
);


///////////////////////////////////// L1 CACHE /////////////////////////////////////
	
	wire 						l1i_hit, l1d_hit;
	wire 						l1i_update, l1d_update;
	wire 	[DATA_WIDTH-1:0]	l1i_write_data, l1d_write_data;
	wire 	[DATA_WIDTH-1:0]	l1i_read_data, l1d_read_data;

	Cache #(
		.LOG_NUM_LINES(2),
		.LOG_NUM_BLOCKS(1),
		.DATA_WIDTH(32),
		.ADDR_WIDTH(8))
		l1icache (
		.clk       (clk),
		.rst       (rst),
		.update    (l1i_update),
		.write_en  (l1i_write_en),
		.write_data(l1i_write_data),
		.address   (address),
		.hit       (l1i_hit),
		.read_data (l1i_read_data)
	);

	Cache #(
		.LOG_NUM_LINES(2),
		.LOG_NUM_BLOCKS(1),
		.DATA_WIDTH(32),
		.ADDR_WIDTH(8))
		l1dcache (
		.clk       (clk),
		.rst       (rst),
		.update    (l1d_update),
		.write_en  (l1d_write_en),
		.write_data(l1d_write_data),
		.address   (address),
		.hit       (l1d_hit),
		.read_data (l1d_read_data)
	);


///////////////////////////////////// L2 CACHE /////////////////////////////////////

	wire 						l2_hit;
	wire 						l2_update;
	wire 	[DATA_WIDTH-1:0]	l2_write_data;
	wire 	[DATA_WIDTH-1:0]	l2_read_data;

	Cache #(
		.LOG_NUM_LINES(3),
		.LOG_NUM_BLOCKS(1),
		.DATA_WIDTH(32),
		.ADDR_WIDTH(8))
		l2cache (
		.clk       (clk),
		.rst       (rst),
		.update    (l2_update),
		.write_en  (l2_write_en),
		.write_data(l2_write_data),
		.address   (address),
		.hit       (l2_hit),
		.read_data (l2_read_data)
	);


///////////////////////////////////// MAIN MEMORY /////////////////////////////////////

	wire 						mm_read_en = 1;
	wire 	[DATA_WIDTH-1:0]	mm_read_data;

	BSRAM main_memory (
		.clock       (clk),
		.reset       (rst),
		.readEnable  (mm_read_en),
		.readAddress (address),
		.readData    (mm_read_data),
		.writeEnable (write_en),
		.writeAddress(address),
		.writeData   (write_data),
		.report      (report)
	);


////////////////////////////////////// READS //////////////////////////////////////

	// In this simulation, all caches and mem can be read at the same time but
	// this is not realistic and impossible in real workd
	assign read_data = l1d_hit	?	l1d_read_data
					 : l2_hit	?	l2_read_data
					 : mm_read_data;


///////////////////////////////////// WRITES /////////////////////////////////////

	// write in cache if 1) write requested and write hit
	assign l1d_write_en = rst		? 1'b0
						: write_en	? 1'b1
						: 1'b0;
	assign l2_write_en = rst 		? 1'b0
					   : write_en 	? 1'b1
					   : 1'b0;

	// write in cache if 2) not a write req, but a read miss
	assign l1d_update = ~write_en && ~l1d_hit;
	assign l2_update = ~write_en && ~l2_hit;

	assign mm_write_en = rst 		? 1'b0
					   : write_en 	? 1'b1
					   : 1'b0;

	// in write req, write the input data. in read miss, write data from lower level of memory
	assign l1d_write_data = ~l1d_hit ? ( ~l2_hit ? mm_read_data : l2_read_data)
						  : write_data;

	assign l2_write_data = ~l2_hit ? mm_read_data : write_data;

endmodule

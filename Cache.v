//////////////////////////////////////////////////////////////////////////////////
// 
//	GENERIC DIRECT-MAPPED CACHE MODEL WITH WRITE-THROUGH AND NO-WRITE-ALLOCATE
// 
//////////////////////////////////////////////////////////////////////////////////

// TODO: should have different read and write inputs for consistency?

module Cache #(
	parameter LOG_NUM_LINES = 2,		// number of lines (entries) in cache
	parameter LOG_NUM_BLOCKS = 1,		// number of blocks in each cache line
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 8)(
	input 						clk,
	input 						rst,
	input 						update,
	input 						write_en,
	input 	[DATA_WIDTH-1:0]	write_data,
	input 	[ADDR_WIDTH-1:0] 	address,
	output						hit,
	output	[DATA_WIDTH-1:0]	read_data
);

	localparam NUM_TAG_BITS = ADDR_WIDTH-LOG_NUM_LINES-LOG_NUM_BLOCKS;
	localparam NUM_LINES = 2**LOG_NUM_LINES;
	localparam NUM_BLOCKS = 2**LOG_NUM_BLOCKS;

	// valid bits of all data in cache
	reg [NUM_LINES-1:0] valid;
	
	// tags of all data in cache
	reg [NUM_TAG_BITS-1:0] tags[0:NUM_LINES-1];

	// actual cache storage. each cache line is of size (data width) * (num blocks)
	reg [DATA_WIDTH-1:0] cachemem[0:NUM_LINES-1][0:NUM_BLOCKS-1];

	// index, tag, block offset bits in requested address
	wire [NUM_TAG_BITS-1:0] tag = address[ADDR_WIDTH-1:ADDR_WIDTH-NUM_TAG_BITS];
	wire [LOG_NUM_BLOCKS-1:0] block_offset = address[LOG_NUM_BLOCKS-1:0];
	wire [LOG_NUM_LINES-1:0] index = address[LOG_NUM_LINES+LOG_NUM_BLOCKS-1:LOG_NUM_BLOCKS];

	// asynchronous read
	assign hit = valid[index] && tags[index]==tag;
	assign read_data = cachemem[index][block_offset];

	always @ (posedge clk) begin

		if (rst) begin
			valid <= 0;
		end // if (rst)

		else begin

			if (update) begin

				cachemem[index][block_offset] <= write_data;
				tags[index] <= tag;
				valid[index] <= 1'b1;
			
			end // if (update)

			// write in cache only if it is a hit
			else if (write_en) begin

				if(valid[index] && tags[index]==tag)
				begin
					cachemem[index][block_offset] <= write_data;
					tags[index] <= tag;
					valid[index] <= 1'b1;
				end

			end // if (write_en)
	
		end // else

	end // always @ (posedge clk)

endmodule

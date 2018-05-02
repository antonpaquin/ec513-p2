module tb_CacheModel;

	// Inputs
	reg 		clk;
	reg 		rst;
	reg 		report;
	reg 		write_en;
	reg	[7:0]	address;
	reg	[31:0]	write_data;

	// Outputs
	wire [31:0] read_data;

	CacheModel uut (
		.clk       (clk),
		.rst       (rst),
		.report    (report),
		.write_en  (write_en),
		.address   (address),
		.write_data(write_data),
		.read_data (read_data)
	);

	// clock generator
	always #1 clk = ~clk;

	initial begin

		$dumpfile("CacheModel.vcd");
		$dumpvars(0, uut, uut.l1dcache.cachemem[0][0], uut.l1dcache.cachemem[0][1],
							uut.l2cache.cachemem[0][0], uut.l2cache.cachemem[0][1],
							uut.l2cache.cachemem[4][0], uut.l2cache.cachemem[4][1],
							uut.l1dcache.tags[0], uut.l1dcache.tags[1],
							uut.l2cache.tags[0], uut.l2cache.tags[1]);

		clk = 1;
		rst = 1;
		report = 0;
		write_en = 0;
		write_data = 32'habcdef;

		#10 rst = 0;
		// first 2s - all miss (cold)
		// next 2s - all hit (same addr)
		address = 8'h20;
		
		// next 2s - all miss
		// next 2s - all hit (same addr)
		#4 address = 8'h28;

		// next 2s - l1 miss, l2 hit
		// next 2s - all hit (same addr)
		#4 address = 8'h20;

		// write through all because write hit
		#10 write_en = 1;

		// write only in l2 because it hit. no write on l1 (because miss)
		#4 write_data = 32'h12345;
		address = 8'h28;

		#10;
		$finish;

	end // initial

endmodule
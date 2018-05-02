module tb_SpecialPcUnit;

	localparam ADDRESS_BITS = 20;
	localparam DATA_WIDTH = 32;

	reg 						clk;
	reg 						rst;
	reg 						en;
	reg 	[ADDRESS_BITS-1:0] 	curr_pc;

	wire						done;
	wire						valid;
	wire	[ADDRESS_BITS-1:0] 	out_pc;

	SpecialPcUnit uut (
		.clk    (clk),
		.en     (en),
		.rst    (rst),
		.curr_pc(curr_pc),
		.done   (done),
		.valid  (valid),
		.out_pc	(out_pc)
	);

	always #1 clk = !clk;
	always #2 curr_pc = curr_pc + 4;

	initial
	begin

		$dumpfile("specialunit.vcd");
		$dumpvars();

		clk = 1;
		rst = 1;
		en = 0;
		curr_pc = 20'hb000f;

		#10;
		rst = 0;

		#10 en = 1;
		#2 en = 0;	// en has to be asserted only for one cycle to trigger

		#10 en = 1;
		#4 en = 0;

		#100;
		$finish;

	end

endmodule

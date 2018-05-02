/**
 * This module emulates the special operation performing part of the processor
 * When it receives the en signal, it saves the PC and starts doing special ops
 * (eg convolution). After it is done, it restores the PC to its value before
 * special ops began
 * 
 * Top module has to have a mux to decide when to select out_pc as the pc while
 * 
 * NOTE: THIS MODULE IS TO BE USED ONLY IF RUNNING SPECIAL OPERATIONS ARE BEING
 * PERFORMED ON THE PROCESSOR ITSELF
 */

module SpecialPcUnit #(parameter ADDRESS_BITS = 20,
	DATA_WIDTH = 32)(
	input  wire						clk,  		// clock
	input  wire						rst,  		// reset
	input  wire						en, 		// start special module
	input  wire	[ADDRESS_BITS-1:0] 	curr_pc,	// current pc
	output wire						done,		// special computation done
	output reg  [ADDRESS_BITS-1:0] 	out_pc		// pc for current instruction of special operation
);

	// number of special instructions to run
	localparam IDLE = 0;
	localparam RUNNING = 1;
	localparam LOG2_NUM_SPECIAL_INST = 2;
	localparam NUM_SPECIAL_INST = 2**LOG2_NUM_SPECIAL_INST;

	// the special instructions to run when en is asserted
	reg [ADDRESS_BITS-1:0] special_instr_pcs[0:NUM_SPECIAL_INST-1];
	reg	[LOG2_NUM_SPECIAL_INST:0] instr_idx;	// keep bitwidth one more than LOG2_NUM_SPECIAL_INST else it will overflow to zero
	
	// value of pc to restore after done
	reg [ADDRESS_BITS-1:0] saved_pc;

	// current state of special ops pc unit
	reg state;

	// fill dummy values for debug
	initial
	begin
		special_instr_pcs[0] <= 20'hB;
		special_instr_pcs[1] <= 20'hE;
		special_instr_pcs[2] <= 20'hE;
		special_instr_pcs[3] <= 20'hF;
	end

	assign done = (state==RUNNING) && (instr_idx==NUM_SPECIAL_INST);

	always @(posedge clk)
	begin
		
		if (rst)
		begin
			state <= IDLE;
			instr_idx <= 0;
			out_pc <= 0;
		end

		else
		begin

			case (state)

				IDLE:
				begin
					if (en == 1'b1)
					begin
						saved_pc <= curr_pc + 4;	// save pc of next instruction
						state <= RUNNING;
					end
					else
					begin
						instr_idx <= 0;
						state <= IDLE;
					end
				end

				RUNNING:
				begin
					if (instr_idx < NUM_SPECIAL_INST) // continue running special ops
					begin
						out_pc = special_instr_pcs[instr_idx];
						instr_idx <= instr_idx + 1;
					end
					else // done with special ops
					begin
						state <= IDLE;
						instr_idx <= 0;
						out_pc <= saved_pc;	// restore pc
					end
				end
			
			endcase

		end

	end

endmodule

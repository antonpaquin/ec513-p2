`timescale 1ns / 1ns

`define memory_init_dec

`include "accel.v"

/* Accel test bench
 *
 * Testbenches are starting to get simple. This mainly hooks up "accel" with
 * what it should be reading from the CPU, and lets it go
 */
   

module main();
    reg clk;
    reg rst;

    reg [31:0] instruction;

    wire [18:0] accel_interrupt;

    wire [106:0] mem_out;
    wire [35:0] mem_in;

    wire done;

    Accel uut (
        .instruction(instruction),
        .accel_interrupt(accel_interrupt),
        .mem_out(mem_out),
        .mem_in(mem_in),
        .accel_done(done),

        .clk(clk),
        .rst_ext(rst)
    );

    reg [17:0] memory [60*1024];

    integer ii;
    initial begin
        for (ii=0; ii<60*1024; ii=ii+1) begin
            memory[ii] <= ii;
        end
        for (ii=76; ii<85; ii=ii+1) begin
            memory[ii] <= (ii-76);
        end
    end


    wire [20:0] accel_imem_read_addr;
    wire [17:0] accel_imem_read_data;
    
    wire [15:0] accel_fmem_read_addr;
    wire [17:0] accel_fmem_read_data;
    
    wire [15:0] accel_omem_write_addr;
    wire [17:0] accel_omem_write_data;
    wire        accel_omem_write_en;

    assign accel_imem_read_addr = mem_out[106:86];
    assign accel_imem_read_data = memory[accel_imem_read_addr][17:0];
    
    assign accel_fmem_read_addr = mem_out[85:70];
    assign accel_fmem_read_data = memory[accel_fmem_read_addr][17:0];
    
    assign accel_omem_write_addr = mem_out[69:54];
    assign accel_omem_write_data = mem_out[53:36];
    assign accel_omem_write_en = mem_out[35];
    
    assign mem_in = {accel_imem_read_data, accel_fmem_read_data};
    
    always @(posedge clk) begin
        if (accel_omem_write_en) begin
            memory[accel_omem_write_addr] <= accel_omem_write_data;
        end
    end

    initial begin
        @(posedge clk);
        @(posedge clk);
        instruction <= {20'd5, `RD_IMAGE_DIM, `EXTEND_OPCODE};
        @(posedge clk);
        instruction <= {20'd3, `RD_IMAGE_DEPTH, `EXTEND_OPCODE};
        @(posedge clk);
        instruction <= {20'd0, `RD_IMAGE_OFFSET, `EXTEND_OPCODE};
        @(posedge clk);
        instruction <= {20'd76, `RD_FILTER_OFFSET, `EXTEND_OPCODE};
        @(posedge clk);
        instruction <= {20'd86, `RD_OUTPUT_OFFSET, `EXTEND_OPCODE};
        @(posedge clk);
        instruction <= {20'd1, `RD_FILTER_HALFSIZE, `EXTEND_OPCODE};
        @(posedge clk);
        instruction <= {20'd1, `RD_FILTER_STRIDE, `EXTEND_OPCODE};
        @(posedge clk);
        instruction <= {20'd9, `RD_FILTER_LENGTH, `EXTEND_OPCODE};
        @(posedge clk);
        instruction <= {20'd0, `RD_FILTER_BIAS, `EXTEND_OPCODE};
        @(posedge clk);
        instruction <= {20'hF00BA, `RD_ACCEL_INTERRUPT, `EXTEND_OPCODE};
        @(posedge clk);
        instruction <= {20'd0, `RD_TRIGGER_ACCEL, `EXTEND_OPCODE};
    end


    initial begin
        rst = 1;
        #10 rst = 0;
    end

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("accel.vcd");
        $dumpvars(0, uut);
    end

    always @(posedge clk) begin
        if (done) begin
            #100 $finish;
        end
    end
endmodule

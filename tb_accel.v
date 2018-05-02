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
            // Sleep 100 to allow the last value to propagate out, because
            // "done" is raised prematurely (see comment in "accel.v")
            #100 $finish;
        end
    end
endmodule

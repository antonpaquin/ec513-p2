/** @module : regFile
 *  @author : Adaptive & Secure Computing Systems (ASCS) Laboratory
 
 *  Copyright (c) 2018 BRISC-V (ASCS/ECE/BU)
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.

 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

// Parameterized register file
module regFile #(parameter REG_DATA_WIDTH = 32, REG_SEL_BITS = 5) (
                clock, reset, read_sel1, read_sel2,
                wEn, write_sel, write_data, 
                read_data1, read_data2
);

input clock, reset, wEn; 
input [REG_DATA_WIDTH-1:0] write_data;
input [REG_SEL_BITS-1:0] read_sel1, read_sel2, write_sel;
output[REG_DATA_WIDTH-1:0] read_data1; 
output[REG_DATA_WIDTH-1:0] read_data2; 

(* ram_style = "distributed" *) 
reg   [REG_DATA_WIDTH-1:0] register_file[0:(1<<REG_SEL_BITS)-1];
integer i;

always @(posedge clock)
    if(reset==1)
        register_file[0] <= 0; 
    else 
        if (wEn & write_sel != 0) register_file[write_sel] <= write_data;
          
//----------------------------------------------------
// Drive the outputs
//----------------------------------------------------
assign  read_data1 = register_file[read_sel1];
assign  read_data2 = register_file[read_sel2];

wire [REG_DATA_WIDTH-1:0] reg_zero; 
assign reg_zero = register_file[0];
wire [REG_DATA_WIDTH-1:0] reg_ra; 
assign reg_ra = register_file[1];
wire [REG_DATA_WIDTH-1:0] reg_sp; 
assign reg_sp = register_file[2];
wire [REG_DATA_WIDTH-1:0] reg_gp; 
assign reg_gp = register_file[3];
wire [REG_DATA_WIDTH-1:0] reg_tp; 
assign reg_tp = register_file[4];
wire [REG_DATA_WIDTH-1:0] reg_t0; 
assign reg_t0 = register_file[5];
wire [REG_DATA_WIDTH-1:0] reg_t1; 
assign reg_t1 = register_file[6];
wire [REG_DATA_WIDTH-1:0] reg_t2; 
assign reg_t2 = register_file[7];
wire [REG_DATA_WIDTH-1:0] reg_s0; 
assign reg_s0 = register_file[8];
wire [REG_DATA_WIDTH-1:0] reg_s1; 
assign reg_s1 = register_file[9];
wire [REG_DATA_WIDTH-1:0] reg_a0; 
assign reg_a0 = register_file[10];
wire [REG_DATA_WIDTH-1:0] reg_a1; 
assign reg_a1 = register_file[11];
wire [REG_DATA_WIDTH-1:0] reg_a2; 
assign reg_a2 = register_file[12];
wire [REG_DATA_WIDTH-1:0] reg_a3; 
assign reg_a3 = register_file[13];
wire [REG_DATA_WIDTH-1:0] reg_a4; 
assign reg_a4 = register_file[14];
wire [REG_DATA_WIDTH-1:0] reg_a5; 
assign reg_a5 = register_file[15];
wire [REG_DATA_WIDTH-1:0] reg_a6; 
assign reg_a6 = register_file[16];
wire [REG_DATA_WIDTH-1:0] reg_a7; 
assign reg_a7 = register_file[17];
wire [REG_DATA_WIDTH-1:0] reg_s2; 
assign reg_s2 = register_file[18];
wire [REG_DATA_WIDTH-1:0] reg_s3; 
assign reg_s3 = register_file[19];
wire [REG_DATA_WIDTH-1:0] reg_s4; 
assign reg_s4 = register_file[20];
wire [REG_DATA_WIDTH-1:0] reg_s5; 
assign reg_s5 = register_file[21];
wire [REG_DATA_WIDTH-1:0] reg_s6; 
assign reg_s6 = register_file[22];
wire [REG_DATA_WIDTH-1:0] reg_s7; 
assign reg_s7 = register_file[23];
wire [REG_DATA_WIDTH-1:0] reg_s8; 
assign reg_s8 = register_file[24];
wire [REG_DATA_WIDTH-1:0] reg_s9; 
assign reg_s9 = register_file[25];
wire [REG_DATA_WIDTH-1:0] reg_s10; 
assign reg_s10 = register_file[26];
wire [REG_DATA_WIDTH-1:0] reg_s11; 
assign reg_s11 = register_file[27];
wire [REG_DATA_WIDTH-1:0] reg_t3; 
assign reg_t3 = register_file[28];
wire [REG_DATA_WIDTH-1:0] reg_t4; 
assign reg_t4 = register_file[29];
wire [REG_DATA_WIDTH-1:0] reg_t5; 
assign reg_t5 = register_file[30];
wire [REG_DATA_WIDTH-1:0] reg_t6; 
assign reg_t6 = register_file[31];

endmodule

/** @module : BSRAM
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
 
//Same cycle read memory access 

 (* ram_style = "block" *)
module BSRAM #(parameter CORE = 0, DATA_WIDTH = 32, ADDR_WIDTH = 8) (
        clock,
        reset,
        readEnable,
        readAddress,
        readData,
        writeEnable,
        writeAddress,
        writeData, 

        accel_mem_in,
        accel_mem_out,

        report
); 

localparam MEM_DEPTH = 1 << ADDR_WIDTH;

input clock; 
input reset; 
input readEnable;
input [ADDR_WIDTH-1:0]   readAddress;
output [DATA_WIDTH-1:0]  readData;
input writeEnable;
input [ADDR_WIDTH-1:0]   writeAddress;
input [DATA_WIDTH-1:0]   writeData;

input [106:0] accel_mem_in;
output [35:0] accel_mem_out;

input report; 
 
wire [DATA_WIDTH-1:0]     readData;
reg  [DATA_WIDTH-1:0]     sram [0:MEM_DEPTH-1];
 
//--------------Code Starts Here------------------ 
assign readData = (readEnable & writeEnable & (readAddress == writeAddress))? 
                  writeData : readEnable? sram[readAddress] : 0;

initial begin
    $readmemh("program.mem", sram);
end

wire [20:0] accel_imem_read_addr;
wire [17:0] accel_imem_read_data;

wire [15:0] accel_fmem_read_addr;
wire [17:0] accel_fmem_read_data;

wire [15:0] accel_omem_write_addr;
wire [17:0] accel_omem_write_data;
wire        accel_omem_write_en;

assign accel_imem_read_addr = accel_mem_in[106:86];
assign accel_imem_read_data = sram[accel_imem_read_addr][17:0];

assign accel_fmem_read_addr = accel_mem_in[85:70];
assign accel_fmem_read_data = sram[accel_fmem_read_addr][17:0];

assign accel_omem_write_addr = accel_mem_in[69:54];
assign accel_omem_write_data = accel_mem_in[53:36];
assign accel_omem_write_en = accel_mem_in[35];

assign accel_mem_out = {accel_imem_read_data, accel_fmem_read_data};

always @(posedge clock) begin
    if (accel_omem_write_en) begin
        sram[accel_omem_write_addr] <= accel_omem_write_data;
    end
end

always@(posedge clock) begin : RAM_WRITE
    if(writeEnable) begin
        sram[writeAddress] <= writeData;
    end
end

reg [31: 0] cycles; 
always @ (posedge clock) begin 
    cycles <= reset? 0 : cycles + 1; 
    if (report)begin
        $display ("------ Core %d SBRAM Unit - Current Cycle %d --------", CORE, cycles); 
        $display ("| Read        [%b]", readEnable);
        $display ("| Read Address[%h]", readAddress);
        $display ("| Read Data   [%h]", readData);
        $display ("| Write       [%b]", writeEnable);
        $display ("| Write Addres[%h]", writeAddress);
        $display ("| Write Data  [%h]", writeData);
        $display ("----------------------------------------------------------------------");
    end 
 end    

endmodule


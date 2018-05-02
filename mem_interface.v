/** @module : memory_interface
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
module mem_interface #(parameter CORE = 0, DATA_WIDTH = 32, INDEX_BITS = 6, 
                     OFFSET_BITS = 3, ADDRESS_BITS = 20) (
                     clock, reset,  
                     read, write, address, in_data, 
                     out_addr, out_data, valid, ready,
                     accel_mem_in, accel_mem_out,
                     report
);

input clock, reset; 
input read, write;
input [ADDRESS_BITS-1:0] address;
input [DATA_WIDTH-1:0]   in_data;
input [106:0] accel_mem_in;

output [35:0] accel_mem_out;
output valid, ready;
output[ADDRESS_BITS-1:0] out_addr;
output[DATA_WIDTH-1:0]   out_data;

input  report; 


BSRAM #(CORE, DATA_WIDTH, ADDRESS_BITS) RAM (
        .clock(clock),
        .reset(reset),
        .readEnable(read),
        .readAddress(address),
        .readData(out_data),
        
        .writeEnable(write),
        .writeAddress(address),
        .writeData(in_data),
        
        // Yes, this is a hacky thing that kills the simplicity of the BSRAM
        // module. There is some motion to put computation alongside memory,
        // though, which makes this a little bit less horrifying.
        .accel_mem_in(accel_mem_in),
        .accel_mem_out(accel_mem_out),

        .report(report)
); 

assign out_addr = read? address : 0; 
assign valid    = (read | write)? 1 : 0; 
assign ready    = (read | write)? 0 : 1; /// Just for testing now

reg [31: 0] cycles; 
always @ (posedge clock) begin 
    cycles <= reset? 0 : cycles + 1; 
    if (report)begin
        $display ("------ Core %d Memory Interface - Current Cycle %d --", CORE, cycles); 
        
        $display ("| Address     [%h]", address);
        $display ("| Read        [%b]", read);
        $display ("| Write       [%b]", write);
        $display ("| Out Data    [%h]", out_data);
        $display ("| In Data     [%h]", in_data);
        $display ("| Ready       [%b]", ready);
        $display ("| Valid       [%b]", valid);
        $display ("----------------------------------------------------------------------");
    end
end

endmodule


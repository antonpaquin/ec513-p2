`ifndef _include_writeback_
`define _include_writeback_

`define write_out_file

module Writeback (
        input  wire [17:0] data,
        input  wire        en,
        
        output reg  [17:0] out_mem_data,
        output reg  [15:0] out_mem_addr,
        output reg         out_mem_en,

        input  wire clk,
        input  wire rst
    );

    reg [12:0] output_counter;

    always @(posedge clk) begin
        if (rst) begin
            output_counter <= 0;
            out_mem_data <= 0;
            out_mem_addr <= 0;
            out_mem_en <= 0;
        end else if (en) begin
            //$display("Writeback: %d <-- %d", output_counter, data);

            out_mem_data <= data;
            out_mem_addr <= output_counter;
            out_mem_en <= 1;
            output_counter <= output_counter + 1;
        end else if (out_mem_en) begin
            out_mem_en <= 0;
        end
    end

    `ifdef write_out_file
    integer fptr;
    initial begin
        fptr = $fopen("/home/anton/tmp/verilog.out", "w");
    end

    always @(posedge clk) begin
        if (rst) begin
        end else if (en) begin
            $fwrite(fptr, "%d\n", data);
        end
    end
    `endif // write_out_file

endmodule
`endif // _include_writeback_

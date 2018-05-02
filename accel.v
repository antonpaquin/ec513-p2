`ifndef _include_accel_
`define _include_accel_

`include "accel_scheduler.v"
`include "accel_image_broadcast.v"
`include "accel_filter_broadcast.v"
`include "accel_positioner.v"
`include "accel_allocator.v"
`include "accel_writeback.v"

/* 
 * accel.v
 *
 * This is the accel module, which connects the allocator and issue stage into
 * one unit. You'll see that there isn't much logic here, just wiring up the
 * two modules.
 *
 * What accel _is_ responsible for: controlling the allocator resets + timing
 * the issue rounds. The logic is described more but generally allocator is
 * controlling what is running when.
 * 
 */

`define EXTEND_OPCODE 7'b0001011

`define RD_IMAGE_DIM       5'b00000
`define RD_IMAGE_DEPTH     5'b00001
`define RD_IMAGE_OFFSET    5'b00010
`define RD_FILTER_OFFSET   5'b00011
`define RD_OUTPUT_OFFSET   5'b00100
`define RD_FILTER_HALFSIZE 5'b00101
`define RD_FILTER_STRIDE   5'b00110
`define RD_FILTER_LENGTH   5'b00111
`define RD_FILTER_BIAS     5'b01000
`define RD_ACCEL_INTERRUPT 5'b01001
`define RD_TRIGGER_ACCEL   5'b11111

module Accel(
        input wire [31:0] instruction,

        output reg [18:0] accel_interrupt,

        output wire [106:0] mem_out, // compressed signals from elsewhere
        input  wire [35:0] mem_in,
    
        // Done signal for when this (image, filter) pair has been completed
        output wire        accel_done,

        input  wire        clk,
        input  wire        rst_ext
    );

    reg [7:0] image_dim;
    reg [8:0] image_depth;

    reg [19:0] image_memory_offset;
    reg [19:0] filter_memory_offset;
    reg [19:0] output_memory_offset;

    reg [1:0] filter_halfsize;
    reg [2:0] filter_stride;
    reg [12:0] filter_length;
    reg [17:0] filter_bias;

    wire [6:0] instruction_opcode;
    wire [4:0] instruction_rd;
    wire [18:0] instruction_imm19;
    assign instruction_opcode = instruction[6:0];
    assign instruction_rd = instruction[11:7];
    assign instruction_imm19 = instruction[31:12];

    reg rst;

    always @(posedge clk) begin
        if (rst_ext) begin
            rst <= 1;
        end else if (instruction_opcode == `EXTEND_OPCODE) begin
            if (instruction_rd == `RD_IMAGE_DIM) begin
                image_dim <= instruction_imm19[7:0];
            end
            else if (instruction_rd == `RD_IMAGE_DEPTH) begin
                image_depth <= instruction_imm19[8:0];
            end
            else if (instruction_rd == `RD_IMAGE_OFFSET) begin
                image_memory_offset <= instruction_imm19[19:0];
            end
            else if (instruction_rd == `RD_FILTER_OFFSET) begin
                filter_memory_offset <= instruction_imm19[19:0];
            end
            else if (instruction_rd == `RD_OUTPUT_OFFSET) begin
                output_memory_offset <= instruction_imm19[19:0];
            end
            else if (instruction_rd == `RD_FILTER_HALFSIZE) begin
                filter_halfsize <= instruction_imm19[1:0];
            end
            else if (instruction_rd == `RD_FILTER_STRIDE) begin
                filter_stride <= instruction_imm19[2:0];
            end
            else if (instruction_rd == `RD_FILTER_LENGTH) begin
                filter_length <= instruction_imm19[12:0];
            end
            else if (instruction_rd == `RD_FILTER_BIAS) begin
                filter_bias <= instruction_imm19[17:0];
            end
            else if (instruction_rd == `RD_FILTER_BIAS) begin
                filter_bias <= instruction_imm19[17:0];
            end
            else if (instruction_rd == `RD_ACCEL_INTERRUPT) begin
                accel_interrupt <= instruction_imm19;
            end
            else if (instruction_rd == `RD_TRIGGER_ACCEL) begin
                rst <= 0;
            end
        end
    end

    // Reset control for the positioner. Positioner should start off, turn on
    // when we begin working on an (image, filter) pair, walk through one or
    // more rounds of positioning, and turn off after
    wire image_broadcast_round;
    wire image_broadcast_rst;

    wire filter_broadcast_done;
    wire filter_broadcast_rst;

    wire positioner_round;
    wire positioner_advance;
    wire positioner_done;
    wire positioner_rst;

    wire allocator_done;
    wire allocator_rst;
    
    wire writeback_en;
    wire writeback_rst;

    wire [17:0] image_broadcast_data;
    wire [ 7:0] image_broadcast_x;
    wire [ 7:0] image_broadcast_y;
    wire        image_broadcast_block;
    wire        image_broadcast_en;

    // filter data out of filter issue
    wire [12:0] filter_broadcast_counter;
    wire [17:0] filter_broadcast_data;
    wire        filter_broadcast_block;
    wire        filter_broadcast_en;

    wire [7:0] positioner_x;
    wire [7:0] positioner_y;
    wire       positioner_sel;

    // The positioner computes where it has placed DSPs this round, and stores
    // that information in these signals. These are then sent to issue to
    // determine which pixels need to be sent.
    wire [7:0] field_x_min,
               field_x_max,
               field_x_start,
               field_x_end,
               field_y_min,
               field_y_max;

    wire [17:0] allocator_data;

    // I'm naming this "virtual" and "physical", though that isn't perfectly
    // accurate. The issue stages assume that their data starts at address 0,
    // so if we need to store it somewhere else we just add a constant offset.
    // This is that computation for image memory
    wire [20:0] imem_read_addr_virt;
    wire [20:0] imem_read_addr_phys;
    wire [17:0] imem_read_data;

    assign imem_read_addr_phys = imem_read_addr_virt + image_memory_offset;
    
    // as above, for filter memory
    wire [15:0] fmem_read_addr_virt;
    wire [15:0] fmem_read_addr_phys;
    wire [17:0] fmem_read_data;

    assign fmem_read_addr_phys = fmem_read_addr_virt + filter_memory_offset;

    // as above, for output
    wire [15:0] omem_write_addr_virt;
    wire [15:0] omem_write_addr_phys;
    wire [17:0] omem_write_data;
    wire        omem_write_en;

    assign omem_write_addr_phys = omem_write_addr_virt + output_memory_offset;

    Scheduler scheduler (
        .positioner_round(positioner_round),
        .positioner_advance(positioner_advance),
        .positioner_done(positioner_done),
        .positioner_rst(positioner_rst),

        .image_broadcast_round(image_broadcast_round),
        .image_broadcast_rst(image_broadcast_rst),

        .filter_broadcast_done(filter_broadcast_done),
        .filter_broadcast_rst(filter_broadcast_rst),

        .allocator_done(allocator_done),
        .allocator_rst(allocator_rst),
        
        // TODO writeback_en is a hack that only works because we're running
        // a single allocator. Remove and implement properly by sourcing it
        // from the allocators (requires additions to allocator.v) when we
        // move out of single DSP testing
        .writeback_en(writeback_en),
        .writeback_rst(writeback_rst),

        .accel_done(accel_done),
        
        .clk(clk),
        .rst(rst)
    );

    // The issue stage, which picks out what values from image memory need to
    // be sent to the DSPs, and sends them to all the DSPs
    ImageBroadcast image_broadcast (
        .ramb_read_addr(imem_read_addr_virt),
        .ramb_read_data(imem_read_data),

        .image_dim(image_dim),
        .image_padding(filter_halfsize),

        .x_min(field_x_min),
        .x_max(field_x_max),
        .x_start(field_x_start),
        .x_end(field_x_end),
        .y_min(field_y_min),
        .y_max(field_y_max),
        .z_max((image_depth-1)),

        .block(image_broadcast_block),
        .en(image_broadcast_en),

        .current_x(image_broadcast_x),
        .current_y(image_broadcast_y),
        .current_data(image_broadcast_data),

        .round(image_broadcast_round),

        .clk(clk),
        .rst(rst | image_broadcast_rst)
    );

    // The filter issue stage, which sends a sequence of filter data to the
    // DSPs, fairly simply. If we move to a systolic array, this only needs to
    // be connected to the first DSP.
    FilterBroadcast #(
        .num_allocators(1)
    ) filter_broadcast (
        .counter(filter_broadcast_counter),
        .data(filter_broadcast_data),
        .en(filter_broadcast_en),
        .block(filter_broadcast_block),
        
        .filter_length(filter_length),

        .filter_read_addr(fmem_read_addr_virt),
        .filter_read_data(fmem_read_data),

        .done(filter_broadcast_done),

        .clk(clk),
        .rst(rst | filter_broadcast_rst)
    );

    Positioner #(
        .num_allocators(1)
    ) positioner (
        .image_dim(image_dim),
        .padding(filter_halfsize),
        .stride(filter_stride),

        .center_x(positioner_x),
        .center_y(positioner_y),
        .allocator_select(positioner_sel),

        .x_min(field_x_min),
        .x_max(field_x_max),
        .x_start(field_x_start),
        .x_end(field_x_end),
        .y_min(field_y_min),
        .y_max(field_y_max),

        .advance(positioner_advance),
        .round(positioner_round),
        .done(positioner_done),

        .clk(clk),
        .rst(rst | positioner_rst)
    );
    
    
    // The allocator stage, which controls a single DSP. When we eventually
    // move to more DSP units, we'll need to set up a "generate" loop here to
    // place a bunch of them down
    Allocator allocator (
        .image_a_x(image_broadcast_x),
        .image_a_y(image_broadcast_y),
        .image_a_data(image_broadcast_data),
        .image_a_blocked(~image_broadcast_en),
        .image_a_block(image_broadcast_block),

        .filter_counter(filter_broadcast_counter),
        .filter_data(filter_broadcast_data),
        .filter_blocked(~filter_broadcast_en),
        .filter_block(filter_broadcast_block),

        .center_x_input(positioner_x),
        .center_y_input(positioner_y),
        .center_write_enable(positioner_sel),

        .filter_halfsize(filter_halfsize),
        .filter_bias(filter_bias),
        .filter_length(filter_length),

        .done(allocator_done),
        .result_data(allocator_data),

        .clk(clk),
        .rst(rst | allocator_rst)
    );

    Writeback writeback (
        .data(allocator_data),
        .en(writeback_en),

        .out_mem_data(omem_write_data),
        .out_mem_addr(omem_write_addr_virt),
        .out_mem_en(omem_write_en),

        .clk(clk),
        .rst(rst | writeback_rst)
    );
    
    assign mem_out = {imem_read_addr_phys, fmem_read_addr_phys, omem_write_addr_phys, omem_write_data, omem_write_en, 35'b0};
    assign imem_read_data = mem_in[35:18];
    assign fmem_read_data = mem_in[17:0];
    // Simple memory unit. We'll probably expose the write lines to the
    // interface module.
    // If we move to multiple broadcast stages, this will become more
    // interesting.
    /*
    Memory memory (
        .read_addr_a(imem_read_addr_phys),
        .read_data_a(imem_read_data),

        .read_addr_b(fmem_read_addr_phys),
        .read_data_b(fmem_read_data),

        .write_addr_a(omem_write_addr_phys),
        .write_data_a(omem_write_data),
        .write_en_a(omem_write_en),

        .write_addr_b(interface_write_addr),
        .write_data_b(interface_write_data),
        .write_en_b(interface_write_en),

        .clk(clk)
    );
    */
    

endmodule

`endif // _include_accel_

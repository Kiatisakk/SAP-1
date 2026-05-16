`timescale 1ns / 1ps

// Top-level modified SAP-1 computer.
// Connects the program counter, registers, RAM, ALU, mux bus, and control FSM.
module sap1_top(
    input clk,
    input reset,
    input prog_we,
    input [3:0] prog_addr,
    input [7:0] prog_data,
    output [7:0] out,
    output halted,
    output reg div_zero
);
    localparam BUS_ALU = 3'd5;
    localparam OP_DIV  = 4'h5;

    wire [3:0] pc;
    wire [3:0] mar_address;
    wire [7:0] ram_data;
    wire [7:0] instruction;
    wire [3:0] opcode;
    wire [3:0] operand;
    wire [7:0] a_data;
    wire [7:0] b_data;
    wire [7:0] alu_result;
    wire alu_div_zero;
    wire [7:0] bus_data;

    wire [2:0] bus_sel;
    wire mar_load;
    wire ir_load;
    wire pc_inc;
    wire pc_load;
    wire a_load;
    wire b_load;
    wire out_load;
    wire [3:0] alu_op;

    program_counter u_pc(
        .clk(clk),
        .reset(reset),
        .load(pc_load),
        .inc(pc_inc),
        .data_in(bus_data[3:0]),
        .pc(pc)
    );

    memory_address_register u_mar(
        .clk(clk),
        .reset(reset),
        .load(mar_load),
        .data_in(bus_data[3:0]),
        .address(mar_address)
    );

    ram_16x8 u_ram(
        .clk(clk),
        .prog_we(prog_we),
        .prog_addr(prog_addr),
        .prog_data(prog_data),
        .address(mar_address),
        .data_out(ram_data)
    );

    instruction_register u_ir(
        .clk(clk),
        .reset(reset),
        .load(ir_load),
        .data_in(bus_data),
        .instruction(instruction),
        .opcode(opcode),
        .operand(operand)
    );

    accumulator u_accumulator(
        .clk(clk),
        .reset(reset),
        .load(a_load),
        .data_in(bus_data),
        .data_out(a_data)
    );

    b_register u_b_register(
        .clk(clk),
        .reset(reset),
        .load(b_load),
        .data_in(bus_data),
        .data_out(b_data)
    );

    alu u_alu(
        .a(a_data),
        .b(b_data),
        .opcode(alu_op),
        .result(alu_result),
        .div_zero(alu_div_zero)
    );

    output_register u_output_register(
        .clk(clk),
        .reset(reset),
        .load(out_load),
        .data_in(bus_data),
        .data_out(out)
    );

    bus_mux u_bus_mux(
        .sel(bus_sel),
        .pc(pc),
        .ram_data(ram_data),
        .ir_operand(operand),
        .a_data(a_data),
        .alu_result(alu_result),
        .bus_data(bus_data)
    );

    control_unit u_control_unit(
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .bus_sel(bus_sel),
        .mar_load(mar_load),
        .ir_load(ir_load),
        .pc_inc(pc_inc),
        .pc_load(pc_load),
        .a_load(a_load),
        .b_load(b_load),
        .out_load(out_load),
        .alu_op(alu_op),
        .halted(halted)
    );

    always @(posedge clk or posedge reset) begin
        if (reset)
            div_zero <= 1'b0;
        else if (a_load && bus_sel == BUS_ALU)
            div_zero <= (alu_op == OP_DIV) ? alu_div_zero : 1'b0;
    end
endmodule

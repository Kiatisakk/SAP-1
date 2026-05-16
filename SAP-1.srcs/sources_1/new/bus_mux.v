`timescale 1ns / 1ps

// Shared 8-bit datapath bus implemented as a multiplexer.
// This replaces internal tri-state wiring with FPGA-friendly mux logic.
module bus_mux(
    input [2:0] sel,
    input [3:0] pc,
    input [7:0] ram_data,
    input [3:0] ir_operand,
    input [7:0] a_data,
    input [7:0] alu_result,
    output reg [7:0] bus_data
);
    localparam BUS_ZERO    = 3'd0;
    localparam BUS_PC      = 3'd1;
    localparam BUS_RAM     = 3'd2;
    localparam BUS_OPERAND = 3'd3;
    localparam BUS_A       = 3'd4;
    localparam BUS_ALU     = 3'd5;

    always @(*) begin
        case (sel)
            BUS_PC:
                bus_data = {4'h0, pc};
            BUS_RAM:
                bus_data = ram_data;
            BUS_OPERAND:
                bus_data = {4'h0, ir_operand};
            BUS_A:
                bus_data = a_data;
            BUS_ALU:
                bus_data = alu_result;
            BUS_ZERO:
                bus_data = 8'h00;
            default:
                bus_data = 8'h00;
        endcase
    end
endmodule

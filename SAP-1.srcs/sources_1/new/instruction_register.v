`timescale 1ns / 1ps

// Instruction Register.
// Captures the 8-bit instruction and exposes opcode and operand fields.
module instruction_register(
    input clk,
    input reset,
    input load,
    input [7:0] data_in,
    output reg [7:0] instruction,
    output [3:0] opcode,
    output [3:0] operand
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            instruction <= 8'h00;
        else if (load)
            instruction <= data_in;
    end

    assign opcode = instruction[7:4];
    assign operand = instruction[3:0];
endmodule

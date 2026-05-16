`timescale 1ns / 1ps

// Accumulator A Register.
// Stores the main arithmetic value for load and ALU operations.
module accumulator(
    input clk,
    input reset,
    input load,
    input [7:0] data_in,
    output reg [7:0] data_out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            data_out <= 8'h00;
        else if (load)
            data_out <= data_in;
    end
endmodule

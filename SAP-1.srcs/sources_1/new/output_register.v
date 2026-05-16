`timescale 1ns / 1ps

// Output Register.
// Captures the accumulator value when the OUT instruction executes.
module output_register(
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

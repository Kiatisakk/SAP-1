`timescale 1ns / 1ps

// 4-bit Program Counter.
// Holds the address of the next instruction and increments during fetch.
module program_counter(
    input clk,
    input reset,
    input load,
    input inc,
    input [3:0] data_in,
    output reg [3:0] pc
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 4'h0;
        else if (load)
            pc <= data_in;
        else if (inc)
            pc <= pc + 4'h1;
    end
endmodule

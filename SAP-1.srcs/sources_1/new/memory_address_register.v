`timescale 1ns / 1ps

// Memory Address Register.
// Stores the 4-bit address used for RAM reads during fetch and execute.
module memory_address_register(
    input clk,
    input reset,
    input load,
    input [3:0] data_in,
    output reg [3:0] address
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            address <= 4'h0;
        else if (load)
            address <= data_in;
    end
endmodule

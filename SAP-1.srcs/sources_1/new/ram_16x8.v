`timescale 1ns / 1ps

// 16-location by 8-bit RAM.
// The CPU reads from address; the testbench or programmer loads memory
// through the separate prog_* port before execution starts.
module ram_16x8(
    input clk,
    input prog_we,
    input [3:0] prog_addr,
    input [7:0] prog_data,
    input [3:0] address,
    output [7:0] data_out
);
    reg [7:0] memory [0:15];

    assign data_out = memory[address];

    always @(posedge clk) begin
        if (prog_we)
            memory[prog_addr] <= prog_data;
    end
endmodule

`timescale 1ns / 1ps

// 8-bit ALU for the modified SAP-1.
// ADD and SUB use normal adders. MUL uses shift-add logic. DIV uses
// restoring division logic. DIV by zero returns 8'hFF and raises div_zero.
module alu(
    input [7:0] a,
    input [7:0] b,
    input [3:0] opcode,
    output reg [7:0] result,
    output reg div_zero
);
    localparam OP_ADD = 4'h2;
    localparam OP_SUB = 4'h3;
    localparam OP_MUL = 4'h4;
    localparam OP_DIV = 4'h5;

    function [7:0] multiply_shift_add;
        input [7:0] multiplicand;
        input [7:0] multiplier;
        reg [15:0] product;
        reg [15:0] shifted_multiplicand;
        integer i;
        begin
            product = 16'h0000;
            shifted_multiplicand = {8'h00, multiplicand};

            for (i = 0; i < 8; i = i + 1) begin
                if (multiplier[i])
                    product = product + shifted_multiplicand;
                shifted_multiplicand = shifted_multiplicand << 1;
            end

            multiply_shift_add = product[7:0];
        end
    endfunction

    function [7:0] divide_restoring;
        input [7:0] dividend;
        input [7:0] divisor;
        reg [8:0] remainder;
        reg [7:0] quotient;
        integer i;
        begin
            remainder = 9'h000;
            quotient = 8'h00;

            for (i = 7; i >= 0; i = i - 1) begin
                remainder = {remainder[7:0], dividend[i]};
                if (remainder >= {1'b0, divisor}) begin
                    remainder = remainder - {1'b0, divisor};
                    quotient[i] = 1'b1;
                end
            end

            divide_restoring = quotient;
        end
    endfunction

    always @(*) begin
        div_zero = 1'b0;

        case (opcode)
            OP_ADD:
                result = a + b;
            OP_SUB:
                result = a - b;
            OP_MUL:
                result = multiply_shift_add(a, b);
            OP_DIV: begin
                if (b == 8'h00) begin
                    result = 8'hFF;
                    div_zero = 1'b1;
                end else begin
                    result = divide_restoring(a, b);
                end
            end
            default:
                result = a;
        endcase
    end
endmodule

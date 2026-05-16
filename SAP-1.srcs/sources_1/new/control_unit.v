`timescale 1ns / 1ps

// FSM-based Control Unit.
// Generates load, increment, bus select, and halt controls for each CPU cycle.
module control_unit(
    input clk,
    input reset,
    input [3:0] opcode,
    output reg [2:0] bus_sel,
    output reg mar_load,
    output reg ir_load,
    output reg pc_inc,
    output reg pc_load,
    output reg a_load,
    output reg b_load,
    output reg out_load,
    output reg [3:0] alu_op,
    output reg halted
);
    localparam OP_NOP = 4'h0;
    localparam OP_LDA = 4'h1;
    localparam OP_ADD = 4'h2;
    localparam OP_SUB = 4'h3;
    localparam OP_MUL = 4'h4;
    localparam OP_DIV = 4'h5;
    localparam OP_OUT = 4'hE;
    localparam OP_HLT = 4'hF;

    localparam BUS_ZERO    = 3'd0;
    localparam BUS_PC      = 3'd1;
    localparam BUS_RAM     = 3'd2;
    localparam BUS_OPERAND = 3'd3;
    localparam BUS_A       = 3'd4;
    localparam BUS_ALU     = 3'd5;

    localparam FETCH_ADDR = 4'd0;
    localparam FETCH_INST = 4'd1;
    localparam DECODE     = 4'd2;
    localparam MEM_ADDR   = 4'd3;
    localparam LDA_READ   = 4'd4;
    localparam ALU_READ   = 4'd5;
    localparam ALU_WRITE  = 4'd6;
    localparam OUT_WRITE  = 4'd7;
    localparam HALT       = 4'd8;

    reg [3:0] state;
    reg [3:0] next_state;

    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH_ADDR;
        else
            state <= next_state;
    end

    always @(*) begin
        bus_sel = BUS_ZERO;
        mar_load = 1'b0;
        ir_load = 1'b0;
        pc_inc = 1'b0;
        pc_load = 1'b0;
        a_load = 1'b0;
        b_load = 1'b0;
        out_load = 1'b0;
        alu_op = opcode;
        halted = 1'b0;
        next_state = FETCH_ADDR;

        case (state)
            // FETCH_ADDR: place PC on the bus and copy it into MAR.
            FETCH_ADDR: begin
                bus_sel = BUS_PC;
                mar_load = 1'b1;
                next_state = FETCH_INST;
            end

            // FETCH_INST: read RAM[MAR] into IR and advance PC.
            FETCH_INST: begin
                bus_sel = BUS_RAM;
                ir_load = 1'b1;
                pc_inc = 1'b1;
                next_state = DECODE;
            end

            // DECODE: choose the execute path from the opcode.
            DECODE: begin
                case (opcode)
                    OP_HLT:
                        next_state = HALT;
                    OP_OUT:
                        next_state = OUT_WRITE;
                    OP_NOP:
                        next_state = FETCH_ADDR;
                    default:
                        next_state = MEM_ADDR;
                endcase
            end

            // MEM_ADDR: copy the instruction operand into MAR.
            MEM_ADDR: begin
                bus_sel = BUS_OPERAND;
                mar_load = 1'b1;
                case (opcode)
                    OP_LDA:
                        next_state = LDA_READ;
                    OP_ADD, OP_SUB, OP_MUL, OP_DIV:
                        next_state = ALU_READ;
                    default:
                        next_state = FETCH_ADDR;
                endcase
            end

            // LDA_READ: load the accumulator from RAM[MAR].
            LDA_READ: begin
                bus_sel = BUS_RAM;
                a_load = 1'b1;
                next_state = FETCH_ADDR;
            end

            // ALU_READ: load the RAM operand into B.
            ALU_READ: begin
                bus_sel = BUS_RAM;
                b_load = 1'b1;
                next_state = ALU_WRITE;
            end

            // ALU_WRITE: place the ALU result on the bus and store it in A.
            ALU_WRITE: begin
                bus_sel = BUS_ALU;
                a_load = 1'b1;
                alu_op = opcode;
                next_state = FETCH_ADDR;
            end

            // OUT_WRITE: copy A into the output register.
            OUT_WRITE: begin
                bus_sel = BUS_A;
                out_load = 1'b1;
                next_state = FETCH_ADDR;
            end

            // HALT: stop sequencing and keep halted asserted.
            HALT: begin
                halted = 1'b1;
                next_state = HALT;
            end

            default: begin
                next_state = FETCH_ADDR;
            end
        endcase
    end
endmodule

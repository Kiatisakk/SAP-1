`timescale 1ns / 1ps

// Testbench for the modified SAP-1 CPU.
// Loads programs through prog_* and verifies normal operation plus edge cases.
module sap1_tb;
    reg clk;
    reg reset;
    reg prog_we;
    reg [3:0] prog_addr;
    reg [7:0] prog_data;
    wire [7:0] out;
    wire halted;
    wire div_zero;

    // Waveform monitor signals for the ALU and datapath inside the CPU.
    // These are not extra hardware; they only make internal DUT signals easier
    // to view in simulation.
    wire [3:0] cpu_pc;
    wire [3:0] cpu_mar;
    wire [7:0] cpu_instruction;
    wire [3:0] cpu_opcode;
    wire [3:0] cpu_operand;
    wire [7:0] cpu_a;
    wire [7:0] cpu_b;
    wire [7:0] cpu_bus;
    wire [2:0] cpu_bus_sel;
    wire [3:0] cpu_alu_op;
    wire [7:0] cpu_alu_result;
    wire cpu_alu_div_zero;
    wire [3:0] cpu_state;

    integer errors;
    integer cycles;

    sap1_top dut(
        .clk(clk),
        .reset(reset),
        .prog_we(prog_we),
        .prog_addr(prog_addr),
        .prog_data(prog_data),
        .out(out),
        .halted(halted),
        .div_zero(div_zero)
    );

    assign cpu_pc = dut.pc;
    assign cpu_mar = dut.mar_address;
    assign cpu_instruction = dut.instruction;
    assign cpu_opcode = dut.opcode;
    assign cpu_operand = dut.operand;
    assign cpu_a = dut.a_data;
    assign cpu_b = dut.b_data;
    assign cpu_bus = dut.bus_data;
    assign cpu_bus_sel = dut.bus_sel;
    assign cpu_alu_op = dut.alu_op;
    assign cpu_alu_result = dut.alu_result;
    assign cpu_alu_div_zero = dut.alu_div_zero;
    assign cpu_state = dut.u_control_unit.state;

    always #1 clk = ~clk;

    task write_memory;
        input [3:0] address;
        input [7:0] data;
        begin
            @(negedge clk);
            prog_addr = address;
            prog_data = data;
            prog_we = 1'b1;
            @(negedge clk);
            prog_we = 1'b0;
        end
    endtask

    task wait_for_halt;
        begin
            cycles = 0;
            while (!halted && cycles < 100) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            if (!halted) begin
                $display("FAIL: CPU did not halt within 100 cycles.");
                errors = errors + 1;
            end
        end
    endtask

    task begin_program_load;
        input [8*48:1] test_name;
        begin
            $display("Running: %0s", test_name);
            @(negedge clk);
            reset = 1'b1;
            prog_we = 1'b0;
            repeat (2) @(negedge clk);
        end
    endtask

    task execute_and_check;
        input [8*48:1] test_name;
        input [7:0] expected_out;
        input expected_div_zero;
        begin
            @(negedge clk);
            reset = 1'b0;

            wait_for_halt;
            #1;

            if (out !== expected_out) begin
                $display("FAIL: %0s expected OUT = %0d (0x%02h), got %0d (0x%02h).",
                         test_name, expected_out, expected_out, out, out);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s OUT = %0d (0x%02h).", test_name, out, out);
            end

            if (div_zero !== expected_div_zero) begin
                $display("FAIL: %0s expected div_zero = %b, got %b.",
                         test_name, expected_div_zero, div_zero);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s div_zero = %b.", test_name, div_zero);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        prog_we = 1'b0;
        prog_addr = 4'h0;
        prog_data = 8'h00;
        errors = 0;

        begin_program_load("normal LDA ADD SUB MUL DIV");
        write_memory(4'h0, 8'h18); // LDA RAM[0x8]
        write_memory(4'h1, 8'h29); // ADD RAM[0x9]
        write_memory(4'h2, 8'h3A); // SUB RAM[0xA]
        write_memory(4'h3, 8'h4B); // MUL RAM[0xB]
        write_memory(4'h4, 8'h5C); // DIV RAM[0xC]
        write_memory(4'h5, 8'hE0); // OUT
        write_memory(4'h6, 8'hF0); // HLT

        write_memory(4'h8, 8'd10);
        write_memory(4'h9, 8'd3);
        write_memory(4'hA, 8'd4);
        write_memory(4'hB, 8'd2);
        write_memory(4'hC, 8'd3);
        execute_and_check("normal LDA ADD SUB MUL DIV", 8'd6, 1'b0);

        begin_program_load("CPU DIV by zero");
        write_memory(4'h0, 8'h18); // LDA RAM[0x8]
        write_memory(4'h1, 8'h59); // DIV RAM[0x9]
        write_memory(4'h2, 8'hE0); // OUT
        write_memory(4'h3, 8'hF0); // HLT
        write_memory(4'h8, 8'd25);
        write_memory(4'h9, 8'd0);
        execute_and_check("CPU DIV by zero", 8'hFF, 1'b1);

        begin_program_load("MUL overflow");
        write_memory(4'h0, 8'h18); // LDA RAM[0x8]
        write_memory(4'h1, 8'h49); // MUL RAM[0x9]
        write_memory(4'h2, 8'hE0); // OUT
        write_memory(4'h3, 8'hF0); // HLT
        write_memory(4'h8, 8'd20);
        write_memory(4'h9, 8'd20);
        execute_and_check("MUL overflow", 8'd144, 1'b0);

        begin_program_load("ADD overflow");
        write_memory(4'h0, 8'h18); // LDA RAM[0x8]
        write_memory(4'h1, 8'h29); // ADD RAM[0x9]
        write_memory(4'h2, 8'hE0); // OUT
        write_memory(4'h3, 8'hF0); // HLT
        write_memory(4'h8, 8'd250);
        write_memory(4'h9, 8'd10);
        execute_and_check("ADD overflow", 8'd4, 1'b0);

        begin_program_load("SUB underflow");
        write_memory(4'h0, 8'h18); // LDA RAM[0x8]
        write_memory(4'h1, 8'h39); // SUB RAM[0x9]
        write_memory(4'h2, 8'hE0); // OUT
        write_memory(4'h3, 8'hF0); // HLT
        write_memory(4'h8, 8'd3);
        write_memory(4'h9, 8'd10);
        execute_and_check("SUB underflow", 8'd249, 1'b0);

        begin_program_load("DIV truncates remainder");
        write_memory(4'h0, 8'h18); // LDA RAM[0x8]
        write_memory(4'h1, 8'h59); // DIV RAM[0x9]
        write_memory(4'h2, 8'hE0); // OUT
        write_memory(4'h3, 8'hF0); // HLT
        write_memory(4'h8, 8'd7);
        write_memory(4'h9, 8'd2);
        execute_and_check("DIV truncates remainder", 8'd3, 1'b0);

        begin_program_load("LDA overwrites A");
        write_memory(4'h0, 8'h18); // LDA RAM[0x8]
        write_memory(4'h1, 8'h19); // LDA RAM[0x9]
        write_memory(4'h2, 8'hE0); // OUT
        write_memory(4'h3, 8'hF0); // HLT
        write_memory(4'h8, 8'd10);
        write_memory(4'h9, 8'd99);
        execute_and_check("LDA overwrites A", 8'd99, 1'b0);

        begin_program_load("HLT stops execution");
        write_memory(4'h0, 8'h18); // LDA RAM[0x8]
        write_memory(4'h1, 8'hE0); // OUT
        write_memory(4'h2, 8'hF0); // HLT
        write_memory(4'h3, 8'h19); // LDA RAM[0x9], must not execute
        write_memory(4'h4, 8'hE0); // OUT, must not execute
        write_memory(4'h8, 8'd5);
        write_memory(4'h9, 8'd99);
        execute_and_check("HLT stops execution", 8'd5, 1'b0);

        repeat (12) @(posedge clk);
        #1;
        if (out !== 8'd5 || halted !== 1'b1) begin
            $display("FAIL: HLT did not hold CPU stopped. OUT=%0d halted=%b.", out, halted);
            errors = errors + 1;
        end else begin
            $display("PASS: HLT holds CPU stopped and OUT remains 5.");
        end

        if (errors == 0)
            $display("ALL TESTS PASSED.");
        else
            $display("TESTS FAILED: %0d error(s).", errors);

        $finish;
    end
endmodule

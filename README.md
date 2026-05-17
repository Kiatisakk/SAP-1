# Modified SAP-1 CPU in Verilog HDL

A compact SAP-1 style CPU implemented in synthesizable Verilog HDL.  
This project keeps the educational structure of the original SAP-1 computer, then extends it with a richer ALU that supports multiplication and division without using Verilog's `*` or `/` operators.

The design is built as a multi-cycle processor with a mux-based shared bus, separate datapath modules, and an FSM-based control unit.

## What This CPU Implements

- 8-bit datapath
- 4-bit address space
- 16 x 8 RAM
- 4-bit opcode + 4-bit operand instruction format
- Multi-cycle fetch, decode, and execute flow
- Shared internal bus implemented using a multiplexer
- FSM-based control unit
- ALU with ADD, SUB, MUL, and DIV
- Manual multiplication and division algorithms
- CPU-level divide-by-zero flag
- Vivado/XSim testbench with normal and edge-case tests

## Instruction Set

Each instruction is one byte:

```text
[ opcode:4 ][ operand/address:4 ]
```

| Opcode | Instruction | Behavior |
|---|---|---|
| `1` | `LDA addr` | `A = RAM[addr]` |
| `2` | `ADD addr` | `A = A + RAM[addr]` |
| `3` | `SUB addr` | `A = A - RAM[addr]` |
| `4` | `MUL addr` | `A = A * RAM[addr]` using shift-and-add |
| `5` | `DIV addr` | `A = A / RAM[addr]` using restoring division |
| `E` | `OUT` | `OUT = A` |
| `F` | `HLT` | Halt CPU execution |
| `0` | `NOP` | Reserved / no operation |

Example:

```text
8'h4B = opcode 4, operand B = MUL RAM[0xB]
```

## Implementation Overview

The CPU is separated into small modules so each part of the datapath can be understood and tested independently.

| Module | File | Role |
|---|---|---|
| Program Counter | `program_counter.v` | Holds the next instruction address |
| MAR | `memory_address_register.v` | Holds the RAM address currently being accessed |
| RAM | `ram_16x8.v` | Stores instructions and data |
| Instruction Register | `instruction_register.v` | Stores opcode and operand |
| Accumulator | `accumulator.v` | Main working register |
| B Register | `b_register.v` | Second ALU operand register |
| ALU | `alu.v` | Performs ADD, SUB, MUL, and DIV |
| Output Register | `output_register.v` | Stores result of OUT instruction |
| Bus Mux | `bus_mux.v` | Selects one datapath source onto the shared bus |
| Control Unit | `control_unit.v` | FSM that controls each CPU cycle |
| Top Module | `sap1_top.v` | Connects all CPU components |
| Testbench | `sap1_tb.v` | Loads programs and verifies behavior |

## Datapath Design

The processor uses one internal 8-bit bus. Instead of internal tri-state buffers, the project uses a bus multiplexer:

```verilog
case (sel)
    BUS_PC:      bus_data = {4'h0, pc};
    BUS_RAM:     bus_data = ram_data;
    BUS_OPERAND: bus_data = {4'h0, ir_operand};
    BUS_A:       bus_data = a_data;
    BUS_ALU:     bus_data = alu_result;
    default:     bus_data = 8'h00;
endcase
```

This is more FPGA-friendly than an internal tri-state bus. A tri-state bus is closer to the traditional SAP-1 diagram, but internal tri-state logic is not ideal for FPGA synthesis and can lead to multiple-driver issues. The mux-based bus is more explicit, easier to debug in waveform simulation, and safer for hardware implementation.

## Control Unit FSM

The CPU executes instructions using a multi-cycle FSM:

```text
FETCH_ADDR  -> MAR <- PC
FETCH_INST  -> IR <- RAM[MAR], PC <- PC + 1
DECODE      -> Select instruction path
MEM_ADDR    -> MAR <- IR operand
LDA_READ    -> A <- RAM[MAR]
ALU_READ    -> B <- RAM[MAR]
ALU_WRITE   -> A <- ALU result
OUT_WRITE   -> OUT <- A
HALT        -> Stop execution
```

This makes the CPU timing easy to inspect in simulation because every instruction is broken into simple register-transfer steps.

## ALU Implementation

The ALU is combinational. It continuously produces a result from:

- accumulator value `A`
- B register value `B`
- current ALU opcode

ADD and SUB use normal 8-bit arithmetic:

```verilog
OP_ADD: result = a + b;
OP_SUB: result = a - b;
```

MUL and DIV are implemented manually.

### Multiplication

Multiplication uses a shift-and-add algorithm:

1. Start with product = 0.
2. Check each bit of the multiplier.
3. If the bit is `1`, add the shifted multiplicand to the product.
4. Shift the multiplicand left each iteration.
5. Return the lower 8 bits.

This avoids the Verilog `*` operator and maps the idea of binary multiplication into circuit-style logic.

### Division

Division uses restoring division:

1. Build the quotient from MSB to LSB.
2. Shift the next dividend bit into the partial remainder.
3. Compare the partial remainder with the divisor.
4. Subtract the divisor when possible.
5. Set the corresponding quotient bit.

This avoids the Verilog `/` operator and produces integer division, so the remainder is discarded.

### Divide-by-Zero Flag

If the divisor is zero:

```verilog
result = 8'hFF;
div_zero = 1'b1;
```

The raw divide-by-zero signal comes from the ALU, but the CPU-level `div_zero` flag is latched in `sap1_top.v`. This keeps the control unit focused on sequencing states while the datapath records whether the committed ALU result came from a divide-by-zero operation.

## Test Program

The main testbench program is:

```verilog
write_memory(4'h0, 8'h18); // LDA 8
write_memory(4'h1, 8'h29); // ADD 9
write_memory(4'h2, 8'h3A); // SUB A
write_memory(4'h3, 8'h4B); // MUL B
write_memory(4'h4, 8'h5C); // DIV C
write_memory(4'h5, 8'hE0); // OUT
write_memory(4'h6, 8'hF0); // HLT
```

Data:

```text
RAM[8] = 10
RAM[9] = 3
RAM[A] = 4
RAM[B] = 2
RAM[C] = 3
```

Expected result:

```text
((10 + 3 - 4) * 2) / 3 = 6
```

The final output must be:

```text
out = 8'd6
halted = 1
div_zero = 0
```

## Additional Test Coverage

The testbench also checks:

- CPU-level divide by zero
- multiplication overflow
- addition overflow
- subtraction underflow
- integer division truncation
- LDA overwrite behavior
- HLT hold behavior

These cases help verify that the CPU handles both normal instruction flow and important edge behavior.

## Project Structure

```text
SAP-1.srcs/
  sources_1/new/
    program_counter.v
    memory_address_register.v
    ram_16x8.v
    instruction_register.v
    accumulator.v
    b_register.v
    alu.v
    output_register.v
    bus_mux.v
    control_unit.v
    sap1_top.v

  sim_1/new/
    sap1_tb.v

modified_sap1_report.tex
modified_sap1_report.pdf
sap1_tb_behav.wcfg
```

## Running The Simulation

### Vivado / XSim

Open the project in Vivado and run behavioral simulation with:

```tcl
launch_simulation
```

The expected console result is:

```text
PASS: Program result OUT = 6.
PASS: CPU div_zero flag remained 0.
ALL TESTS PASSED.
```

## Report

The full mini-project report is included here:

- `modified_sap1_report.tex`
- `modified_sap1_report.pdf`

It explains the system architecture, module design, FSM, ALU algorithms, waveform results, test coverage, design decisions, and implementation challenges.

## Key Design Takeaway

This project shows how a simple CPU is built from small hardware blocks: registers, memory, an ALU, a bus, and a control FSM. The most important implementation step is connecting these parts with correct timing. Once the datapath and control signals are aligned, each instruction becomes a sequence of small and predictable register transfers.

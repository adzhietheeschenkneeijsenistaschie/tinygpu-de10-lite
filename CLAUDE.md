# CLAUDE.md — tinygpu-de10-lite

## 1. Project Goals & Context

**Objective:** Build a custom graphics card from scratch on an Intel MAX 10 FPGA (Terasic DE10-Lite board) using SystemVerilog.

**Primary Learning Goals:**

a) **GPU Architecture** — SIMT/SIMD execution models, fetch/decode/execute pipelines, thread scheduling across blocks, and memory arbitration between multiple cores sharing limited bandwidth.

b) **Hardware Verification** — Writing robust, self-checking testbenches in Questa, handling edge cases, and verifying all state machines before committing to Quartus synthesis.

---

## 2. Architecture Overview

### Display Path (25 MHz pixel clock)
- A PLL (`vga_pll`) divides the 50 MHz board clock down to **25 MHz**.
- A **VGA controller** (`quartus/vga_controller.sv`) generates 640×480 @ 60 Hz timing (hsync, vsync, blanking). The active display window is mapped to a 320×200 sub-region with a letterbox offset.
- A **64 KB dual-port BRAM** (`quartus/framebuffer_ram.v`) stores pixel data in **8-bit 3:3:2 color** (3 bits red, 3 bits green, 2 bits blue). Read port runs on `clk_25mhz`; write port runs on `MAX10_CLK1_50`.
- The read address is driven continuously by `bram_addr` from the VGA controller.

### Compute Path (50 MHz board clock)
- The **tiny-gpu** engine (`src/gpu.sv`) runs on `MAX10_CLK1_50`.
- An **instruction ROM** holds the kernel program; a **Device Control Register** (`src/dcr.sv`) sets the thread/block count before the `start` signal is asserted.
- A **scheduler** (`src/scheduler.sv`) dispatches blocks of threads to available **cores** (`src/core.sv`).
- Each core runs a fetch → decode → execute pipeline: a **fetcher** (`src/fetcher.sv`) issues reads through a **memory controller** (`src/controller.sv`), the **decoder** (`src/decoder.sv`) produces control signals, and functional units (ALU `src/alu.sv`, LSU `src/lsu.sv`, PC `src/pc.sv`, register file `src/registers.sv`) execute per-thread.
- Completed threads write pixel results directly into the write port of the BRAM framebuffer.
- The top-level integration lives in `src/top.sv`. Currently a `mock_rpi_generator` (`quartus/mock_rpi_generator.sv`) drives the write port for testing without the full GPU compute path wired in.

### Key Parameters (gpu.sv)
| Parameter | Default | Meaning |
|---|---|---|
| `DATA_MEM_ADDR_BITS` | 8 | 256-row data memory |
| `DATA_MEM_DATA_BITS` | 8 | 8-bit data words |
| `DATA_MEM_NUM_CHANNELS` | 4 | Concurrent data memory channels |
| `PROGRAM_MEM_ADDR_BITS` | 8 | 256-row program memory |
| `PROGRAM_MEM_DATA_BITS` | 16 | 16-bit instructions |
| `NUM_CORES` | 2 | Number of parallel cores |
| `THREADS_PER_BLOCK` | 4 | Threads per core (sets compute resources) |

---

## 3. Workflow & Commands

**Verification First.** Always write a testbench in the `sim/` folder and simulate with Questa before running Quartus synthesis. When suggesting design changes, explain the architectural trade-off (area vs. timing vs. correctness).

### Questa (simulation)
```sh
# Compile all RTL and testbenches
vlog -sv src/*.sv sim/*.sv

# Run a specific testbench non-interactively
vsim -c -do "run -all; quit" work.<testbench_name>
```

### Quartus (synthesis)
```sh
quartus_sh --flow compile tinygpu-de10-lite
```

The Quartus project file is `quartus/tinygpu-de10-lite.qpf`. IP cores (PLL, BRAM) are pre-generated under `quartus/` and must be included in the project's source file list.

---

## 4. STRICT Quartus SystemVerilog Rules (CRITICAL)

Quartus has a significantly stricter synthesizer than Verilator or simulation tools. Code that simulates correctly will often **fail to synthesize**. Enforce every rule below in all generated RTL.

### 4.1 No Trailing Commas
Never leave a dangling comma in port lists, parameter lists, or module instantiations. Quartus rejects them as syntax errors.

```systemverilog
// WRONG
module foo (
    input wire a,
    input wire b,   // <-- trailing comma
);

// CORRECT
module foo (
    input wire a,
    input wire b
);
```

### 4.2 Port Direction + Type Must Be Explicit
Always write `input wire`, `output wire`, or `output reg`. **Never use `input reg`** — this causes **Error 10170**.

```systemverilog
// WRONG
input reg [7:0] data;

// CORRECT
input wire [7:0] data;
output reg [7:0] result;
```

### 4.3 No Variable Declarations Inside `always` Blocks
All `logic`, `reg`, `int`, and `integer` variables must be declared in the module scope, **outside** any `always` or `always_ff` block. Quartus does not support procedural local variables.

```systemverilog
// WRONG
always_ff @(posedge clk) begin
    integer i;   // <-- illegal in Quartus
    for (i = 0; i < N; i++) ...
end

// CORRECT
integer i;
always_ff @(posedge clk) begin
    for (i = 0; i < N; i++) ...
end
```

### 4.4 No `break` Statements in `always` Blocks
`break` is not supported inside synthesizable `always` blocks. Use a **boolean flag variable** declared in module scope to conditionally skip the remaining loop body.

```systemverilog
// WRONG
always_comb begin
    for (i = 0; i < N; i++) begin
        if (found) break;   // <-- not synthesizable
        ...
    end
end

// CORRECT
reg is_found;
always_comb begin
    is_found = 1'b0;
    for (i = 0; i < N; i++) begin
        if (!is_found) begin
            if (condition[i]) is_found = 1'b1;
        end
    end
end
```

### 4.5 Unpacked Array Reset Requires a `for` Loop
Resetting an unpacked array with a scalar assignment (e.g., `my_array <= 0;`) causes **Error 10928**. Always iterate with a `for` loop using an `integer` index variable.

```systemverilog
// WRONG
output reg [7:0] data_out [3:0];
// ...
data_out <= 0;   // Error 10928

// CORRECT
integer ch;
// ...
for (ch = 0; ch < 4; ch = ch + 1)
    data_out[ch] <= 8'h00;
```

### 4.6 Named Blocks Required Inside `generate for` Loops
Any `always` block, `assign`, or `localparam` that appears inside a `generate for` loop **must** be enclosed in a named `begin : label ... end` block.

```systemverilog
// WRONG
generate
    for (genvar i = 0; i < N; i++) begin
        always_ff @(posedge clk) result[i] <= data[i];
    end
endgenerate

// CORRECT
generate
    for (genvar i = 0; i < N; i++) begin : gen_reg
        always_ff @(posedge clk) result[i] <= data[i];
    end
endgenerate
```

### 4.7 Use `integer` Not `int` for Loop Variables
`int` is a SystemVerilog 2-state type that has inconsistent support in Quartus. Always use `integer` for loop counters and declared outside `always` blocks.

```systemverilog
// WRONG
int i;

// CORRECT
integer i;
```

---

## 5. File Layout

```
src/              RTL source — synthesizable modules
  top.sv          Board top-level (clock, BRAM, VGA, GPU integration)
  gpu.sv          GPU top — cores, scheduler, memory controllers
  core.sv         Single GPU core (fetch/decode/execute per thread)
  controller.sv   Memory arbiter (throttles requests, N consumers → M channels)
  scheduler.sv    Block dispatcher (assigns thread blocks to free cores)
  fetcher.sv      Instruction fetch unit (issues reads via controller)
  dcr.sv          Device Control Register (thread/block count)
  decoder.sv      16-bit instruction decoder
  alu.sv          Arithmetic/Logic Unit
  lsu.sv          Load-Store Unit
  pc.sv           Per-thread Program Counter
  registers.sv    Per-thread register file

quartus/          Quartus project and IP
  tinygpu-de10-lite.qpf   Project file
  vga_controller.sv       VGA timing generator (640×480 @ 60 Hz)
  mock_rpi_generator.sv   Test pattern writer (bouncing box)
  framebuffer_ram.v       64 KB dual-port BRAM (Quartus IP)
  vga_pll.v               25 MHz PLL (Quartus IP)

sim/              Testbenches (to be created before synthesis)
test/             Python co-simulation helpers (Verilator legacy)
docs/             Architecture diagrams
```

// ============================================================
// framebuffer_ram.sv
//
// Behavioral SystemVerilog rewrite of the Quartus-wizard-generated
// `framebuffer_ram.v` (altsyncram, RAM:2-PORT) megafunction.
//
// Configuration reproduced from the original IP:
//   - Simple dual-port: one write port + one read port
//   - 65536 x 8-bit  (64 KB, 3:3:2 packed color)
//   - Independent write (wrclock) and read (rdclock) clock domains
//   - Read address REGISTERED (altsyncram ADDRESS_REG_B = CLOCK1)
//   - Read data UNREGISTERED  (altsyncram OUTDATA_REG_B = UNREGISTERED)
//     => exactly 1 rdclock of read latency, no output pipeline reg
//   - Mixed-port read-during-write = "don't care" (no bypass logic)
//   - Power-up contents = 0 (POWER_UP_UNINITIALIZED = FALSE)
//
// Maps to dedicated M9K block RAM on MAX 10 (same primitive the IP used),
// so this rewrite is LUT- and timing-neutral relative to the generated IP.
// ============================================================
`timescale 1 ps / 1 ps

module framebuffer_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 16,
    parameter DEPTH      = (1 << ADDR_WIDTH)
) (
    input  wire  [DATA_WIDTH-1:0] data,       // write data   (wrclock domain)
    input  wire  [ADDR_WIDTH-1:0] rdaddress,  // read address (rdclock domain)
    input  wire                   rdclock,    // read  clock  (25 MHz pixel)
    input  wire  [ADDR_WIDTH-1:0] wraddress,  // write address (wrclock domain)
    input  wire                   wrclock,    // write clock  (50 MHz board)
    input  wire                   wren,       // write enable
    output reg   [DATA_WIDTH-1:0] q           // read data, 1 rdclock latency
);

    // Force M9K block RAM and suppress read-during-write bypass logic.
    // "no_rw_check" matches the IP's "don't care" mixed-port RDW mode and
    // keeps Quartus from spending LECs/LUTs on a bypass mux.
    (* ramstyle = "M9K, no_rw_check" *)
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // POWER_UP_UNINITIALIZED = FALSE is reproduced by Quartus' default
    // zero-initialization of inferred M9K block RAM on MAX 10 — no RTL
    // initial block is needed (and one would create a second driver of
    // `mem`, which strict `always_ff` single-driver semantics forbid).
    // For defined power-up contents, add `$readmemh`/a .mif instead.

    // ---- Write port (port A) — synchronous to wrclock --------------------
    always_ff @(posedge wrclock) begin
        if (wren)
            mem[wraddress] <= data;
    end

    // ---- Read port (port B) — synchronous to rdclock ---------------------
    // Registering the array access models a registered read ADDRESS feeding a
    // combinational array read with an UNREGISTERED output: q is valid one
    // rdclock edge after rdaddress is presented.
    always_ff @(posedge rdclock) begin
        q <= mem[rdaddress];
    end

endmodule

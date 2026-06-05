// ============================================================
// framebuffer_ram_tb.sv  —  self-checking testbench
//
// Verifies the behavioral framebuffer_ram rewrite:
//   1. Write-then-read returns the written byte.
//   2. Read latency is exactly 1 rdclock edge (registered address,
//      unregistered output).
//   3. wren=0 does not modify memory.
//   4. Independent rd/wr addresses do not alias.
//
// Read and write share one clock here for deterministic latency checks;
// cross-clock-domain (50 MHz write / 25 MHz read) behavior is exercised
// at the top-level integration sim, not in this functional unit test.
//
//   vlog -sv quartus/framebuffer_ram.sv sim/framebuffer_ram_tb.sv
//   vsim -c -do "run -all; quit" work.framebuffer_ram_tb
// ============================================================
`timescale 1ns / 1ps

module framebuffer_ram_tb;

    localparam DW = 8;
    localparam AW = 16;

    logic [DW-1:0] data;
    logic [AW-1:0] rdaddress;
    logic [AW-1:0] wraddress;
    logic          clk;
    logic          wren;
    logic [DW-1:0] q;

    integer errors = 0;

    // Single clock drives both ports for deterministic checking.
    framebuffer_ram #(.DATA_WIDTH(DW), .ADDR_WIDTH(AW)) dut (
        .data      (data),
        .rdaddress (rdaddress),
        .rdclock   (clk),
        .wraddress (wraddress),
        .wrclock   (clk),
        .wren      (wren),
        .q         (q)
    );

    always #5 clk = ~clk;

    // Write one byte (synchronous to clk).
    task automatic do_write(input [AW-1:0] a, input [DW-1:0] d);
        @(negedge clk);
        wraddress = a;
        data      = d;
        wren      = 1'b1;
        @(negedge clk);
        wren      = 1'b0;
    endtask

    // Present a read address, then check q one rdclock edge later.
    task automatic check_read(input [AW-1:0] a, input [DW-1:0] expected);
        @(negedge clk);
        rdaddress = a;
        @(posedge clk);   // address registered here
        #1;               // settle after the edge (output unregistered)
        if (q !== expected) begin
            $error("addr 0x%04h: expected 0x%02h, got 0x%02h", a, expected, q);
            errors = errors + 1;
        end
    endtask

    initial begin
        clk = 1'b0;
        wren = 1'b0;
        data = '0;
        rdaddress = '0;
        wraddress = '0;

        // 1 & 2: basic write/read with 1-cycle latency
        do_write(16'h0000, 8'hA5);
        do_write(16'h0001, 8'h5A);
        do_write(16'hFFFF, 8'h3C);   // top of the 64 KB space
        check_read(16'h0000, 8'hA5);
        check_read(16'h0001, 8'h5A);
        check_read(16'hFFFF, 8'h3C);

        // 3: wren=0 must not overwrite addr 0
        @(negedge clk);
        wraddress = 16'h0000;
        data      = 8'hFF;
        wren      = 1'b0;            // disabled
        @(negedge clk);
        check_read(16'h0000, 8'hA5); // still the old value

        // 4: no aliasing between two distinct addresses
        do_write(16'h1234, 8'h11);
        do_write(16'h4321, 8'h22);
        check_read(16'h1234, 8'h11);
        check_read(16'h4321, 8'h22);

        if (errors == 0)
            $display("PASS: framebuffer_ram — all checks passed");
        else
            $display("FAIL: framebuffer_ram — %0d error(s)", errors);

        $finish;
    end

endmodule

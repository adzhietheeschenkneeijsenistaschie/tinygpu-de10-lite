// ============================================================
// vga_pll.sv
//
// SystemVerilog rewrite of the Quartus-wizard-generated `vga_pll.v`
// (altpll) megafunction wrapper. Divides the 50 MHz board clock down
// to the 25 MHz VGA pixel clock (clk0_divide_by = 2, multiply_by = 1).
//
// IMPORTANT — why the altpll primitive is still instantiated here:
// A PLL is a HARDENED analog block on the MAX 10 fabric. It has no
// behavioral RTL equivalent — you cannot express phase-locked clock
// synthesis with `always_ff`. The legitimate "modernization" is to give
// the wrapper strict SystemVerilog typing and a clean named port header
// while still instantiating `altpll`. Everything synthesizable about this
// module is the wiring around the hard block, and that is what is typed.
// ============================================================
`timescale 1 ps / 1 ps

module vga_pll (
    input  wire  inclk0,   // 50 MHz reference (MAX10_CLK1_50)
    output wire  c0        // 25 MHz pixel clock
);

    // altpll exposes a 5-bit clk[] output bus and a 2-bit inclk[] bus.
    // Only clk[0] (c0) and inclk[0] (the reference) are used here.
    logic [4:0] pll_clk;
    logic [1:0] pll_inclk;

    assign pll_inclk = {1'b0, inclk0};  // inclk[1] tied low (single ref clock)
    assign c0        = pll_clk[0];

    altpll altpll_component (
        .inclk              (pll_inclk),
        .clk                (pll_clk),
        .activeclock        (),
        .areset             (1'b0),
        .clkbad             (),
        .clkena             ({6{1'b1}}),
        .clkloss            (),
        .clkswitch          (1'b0),
        .configupdate       (1'b0),
        .enable0            (),
        .enable1            (),
        .extclk             (),
        .extclkena          ({4{1'b1}}),
        .fbin               (1'b1),
        .fbmimicbidir       (),
        .fbout              (),
        .fref               (),
        .icdrclk            (),
        .locked             (),
        .pfdena             (1'b1),
        .phasecounterselect ({4{1'b1}}),
        .phasedone          (),
        .phasestep          (1'b1),
        .phaseupdown        (1'b1),
        .pllena             (1'b1),
        .scanaclr           (1'b0),
        .scanclk            (1'b0),
        .scanclkena         (1'b1),
        .scandata           (1'b0),
        .scandataout        (),
        .scandone           (),
        .scanread           (1'b0),
        .scanwrite          (1'b0),
        .sclkout0           (),
        .sclkout1           (),
        .vcooverrange       (),
        .vcounderrange      ()
    );

    defparam
        altpll_component.bandwidth_type          = "AUTO",
        altpll_component.clk0_divide_by           = 2,
        altpll_component.clk0_duty_cycle          = 50,
        altpll_component.clk0_multiply_by         = 1,
        altpll_component.clk0_phase_shift         = "0",
        altpll_component.compensate_clock         = "CLK0",
        altpll_component.inclk0_input_frequency   = 20000,
        altpll_component.intended_device_family   = "MAX 10",
        altpll_component.lpm_hint                 = "CBX_MODULE_PREFIX=vga_pll",
        altpll_component.lpm_type                 = "altpll",
        altpll_component.operation_mode           = "NORMAL",
        altpll_component.pll_type                 = "AUTO",
        altpll_component.port_activeclock         = "PORT_UNUSED",
        altpll_component.port_areset              = "PORT_UNUSED",
        altpll_component.port_clkbad0             = "PORT_UNUSED",
        altpll_component.port_clkbad1             = "PORT_UNUSED",
        altpll_component.port_clkloss             = "PORT_UNUSED",
        altpll_component.port_clkswitch           = "PORT_UNUSED",
        altpll_component.port_configupdate        = "PORT_UNUSED",
        altpll_component.port_fbin                = "PORT_UNUSED",
        altpll_component.port_inclk0              = "PORT_USED",
        altpll_component.port_inclk1              = "PORT_UNUSED",
        altpll_component.port_locked              = "PORT_UNUSED",
        altpll_component.port_pfdena              = "PORT_UNUSED",
        altpll_component.port_phasecounterselect  = "PORT_UNUSED",
        altpll_component.port_phasedone           = "PORT_UNUSED",
        altpll_component.port_phasestep           = "PORT_UNUSED",
        altpll_component.port_phaseupdown         = "PORT_UNUSED",
        altpll_component.port_pllena              = "PORT_UNUSED",
        altpll_component.port_scanaclr            = "PORT_UNUSED",
        altpll_component.port_scanclk             = "PORT_UNUSED",
        altpll_component.port_scanclkena          = "PORT_UNUSED",
        altpll_component.port_scandata            = "PORT_UNUSED",
        altpll_component.port_scandataout         = "PORT_UNUSED",
        altpll_component.port_scandone            = "PORT_UNUSED",
        altpll_component.port_scanread            = "PORT_UNUSED",
        altpll_component.port_scanwrite           = "PORT_UNUSED",
        altpll_component.port_clk0                = "PORT_USED",
        altpll_component.port_clk1                = "PORT_UNUSED",
        altpll_component.port_clk2                = "PORT_UNUSED",
        altpll_component.port_clk3                = "PORT_UNUSED",
        altpll_component.port_clk4                = "PORT_UNUSED",
        altpll_component.port_clk5                = "PORT_UNUSED",
        altpll_component.port_clkena0             = "PORT_UNUSED",
        altpll_component.port_clkena1             = "PORT_UNUSED",
        altpll_component.port_clkena2             = "PORT_UNUSED",
        altpll_component.port_clkena3             = "PORT_UNUSED",
        altpll_component.port_clkena4             = "PORT_UNUSED",
        altpll_component.port_clkena5             = "PORT_UNUSED",
        altpll_component.port_extclk0             = "PORT_UNUSED",
        altpll_component.port_extclk1             = "PORT_UNUSED",
        altpll_component.port_extclk2             = "PORT_UNUSED",
        altpll_component.port_extclk3             = "PORT_UNUSED",
        altpll_component.width_clock              = 5;

endmodule

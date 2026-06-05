module top(
    input  logic MAX10_CLK1_50, // 50 MHz native board clock
    
    // VGA Physical Pins
    output logic [3:0] VGA_R,
    output logic [3:0] VGA_G,
    output logic [3:0] VGA_B,
    output logic VGA_HS,
    output logic VGA_VS
);

    logic clk_25mhz;
    logic rst_n = 1'b1; 
    
    logic hsync_internal, vsync_internal, blanking, game_active;
    logic [15:0] vga_read_addr;
    logic [7:0]  vga_read_data;
    
    logic        mock_write_en;
    logic [15:0] mock_write_addr;
    logic [7:0]  mock_write_data;

    // 1. 25 MHz Pixel Clock
    vga_pll pll_inst (
        .inclk0 (MAX10_CLK1_50),
        .c0     (clk_25mhz)
    );

    // 2. Dual-Port Framebuffer (64KB)
    framebuffer_ram ram_inst (
        .data       (mock_write_data),
        .wren       (mock_write_en),
        .wraddress  (mock_write_addr),
        .wrclock    (MAX10_CLK1_50),
        .rdaddress  (vga_read_addr),
        .rdclock    (clk_25mhz),
        .q          (vga_read_data)
    );

    // 3. VGA Timing Controller
    vga_controller vga_inst (
        .clk_25mhz   (clk_25mhz),
        .rst_n       (rst_n),
        .hsync       (hsync_internal),
        .vsync       (vsync_internal),
        .blanking    (blanking),
        .game_active (game_active),
        .bram_addr   (vga_read_addr)
    );

    // 4. Mock RPi Generator (Draws bouncing box)
    mock_rpi_generator test_gen_inst (
        .clk_50mhz   (MAX10_CLK1_50),
        .rst_n       (rst_n),
        .vsync       (vsync_internal), 
        .we          (mock_write_en),
        .addr        (mock_write_addr),
        .data        (mock_write_data)
    );

    // 5. Output Logic (Map 8-bit BRAM color to 12-bit VGA)
    assign VGA_HS = hsync_internal;
    assign VGA_VS = vsync_internal;

    always_comb begin
        if (game_active) begin
            VGA_R = {vga_read_data[7:5], 1'b0};
            VGA_G = {vga_read_data[4:2], 1'b0};
            VGA_B = {vga_read_data[1:0], 2'b00};
        end else begin
            VGA_R = 4'b0000;
            VGA_G = 4'b0000;
            VGA_B = 4'b0000;
        end
    end
endmodule
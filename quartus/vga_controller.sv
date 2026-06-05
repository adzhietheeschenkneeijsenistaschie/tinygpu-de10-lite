module vga_controller (
    input  logic        clk_25mhz,
    input  logic        rst_n,
    output logic        hsync,
    output logic        vsync,
    output logic        blanking,
    output logic        game_active,
    output logic [15:0] bram_addr
);
    // 640x480 @ 60Hz timing constants
    localparam H_ACTIVE = 10'd640;
    localparam H_FP     = 10'd16;
    localparam H_SYNC   = 10'd96;
    localparam H_BP     = 10'd48;
    localparam H_TOTAL  = 10'd800;

    localparam V_ACTIVE = 10'd480;
    localparam V_FP     = 10'd10;
    localparam V_SYNC   = 10'd2;
    localparam V_BP     = 10'd33;
    localparam V_TOTAL  = 10'd525;

    // 320x200 centered inside 640x480 with 40-row letterbox top/bottom
    localparam Y_OFFSET = 10'd40;
    localparam Y_END    = 10'd440;

    logic [9:0] h_cnt;
    logic [9:0] v_cnt;

    always_ff @(posedge clk_25mhz or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 10'd0;
            v_cnt <= 10'd0;
        end else begin
            if (h_cnt == H_TOTAL - 10'd1) begin
                h_cnt <= 10'd0;
                v_cnt <= (v_cnt == V_TOTAL - 10'd1) ? 10'd0 : v_cnt + 10'd1;
            end else begin
                h_cnt <= h_cnt + 10'd1;
            end
        end
    end

    assign hsync = ~((h_cnt >= (H_ACTIVE + H_FP)) && (h_cnt < (H_ACTIVE + H_FP + H_SYNC)));
    assign vsync = ~((v_cnt >= (V_ACTIVE + V_FP)) && (v_cnt < (V_ACTIVE + V_FP + V_SYNC)));

    assign blanking    = (h_cnt >= H_ACTIVE) || (v_cnt >= V_ACTIVE);
    assign game_active = !blanking && (v_cnt >= Y_OFFSET) && (v_cnt < Y_END);

    // Address calculation for 320x200 memory
    logic [8:0] lx;
    logic [7:0] ly;

    assign lx        = h_cnt[9:1];
    assign ly        = (v_cnt - Y_OFFSET) >> 1;
    assign bram_addr = ({8'd0, ly} << 8) + ({8'd0, ly} << 6) + {7'd0, lx}; // ly * 320 + lx

endmodule
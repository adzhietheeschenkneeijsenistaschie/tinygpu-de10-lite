module mock_rpi_generator (
    input  logic        clk_50mhz,
    input  logic        rst_n,
    input  logic        vsync,
    output logic        we,
    output logic [15:0] addr,
    output logic [7:0]  data
);
    localparam [7:0] COLOR_BG     = 8'b000_000_11; // Blue
    localparam [7:0] COLOR_BORDER = 8'b111_000_00; // Red
    localparam [7:0] COLOR_BOX    = 8'b000_111_00; // Green

    logic [8:0] box_x;
    logic [7:0] box_y;
    logic       dir_x, dir_y;
    logic       writing, prev_vsync;
    logic [8:0] px;
    logic [7:0] py;
    logic [7:0] pix_color;

    always_comb begin
        if (px == 9'd0 || px == 9'd319 || py == 8'd0 || py == 8'd199)
            pix_color = COLOR_BORDER;
        else if ((px >= box_x) && (px < box_x + 9'd20) && (py >= box_y) && (py < box_y + 8'd20))
            pix_color = COLOR_BOX;
        else
            pix_color = COLOR_BG;
    end

    always_ff @(posedge clk_50mhz or negedge rst_n) begin
        if (!rst_n) begin
            we <= 1'b0; addr <= 16'd0; data <= 8'd0; writing <= 1'b0;
            px <= 9'd0; py <= 8'd0; box_x <= 9'd150; box_y <= 8'd90;
            dir_x <= 1'b1; dir_y <= 1'b1; prev_vsync <= 1'b0;
        end else begin
            prev_vsync <= vsync;

            if (vsync && !prev_vsync && !writing) begin
                writing <= 1'b1; we <= 1'b1; px <= 9'd0; py <= 8'd0; addr <= 16'd0; data <= pix_color;
                
                if (dir_x) begin if (box_x >= 9'd298) dir_x <= 1'b0; else box_x <= box_x + 9'd2; end 
                else       begin if (box_x <= 9'd2)   dir_x <= 1'b1; else box_x <= box_x - 9'd2; end
                
                if (dir_y) begin if (box_y >= 8'd178) dir_y <= 1'b0; else box_y <= box_y + 8'd2; end 
                else       begin if (box_y <= 8'd2)   dir_y <= 1'b1; else box_y <= box_y - 8'd2; end
            end else if (writing) begin
                we <= 1'b1; data <= pix_color; addr <= addr + 16'd1;
                if (px == 9'd319) begin
                    px <= 9'd0;
                    if (py == 8'd199) begin writing <= 1'b0; we <= 1'b0; end 
                    else py <= py + 8'd1;
                end else begin
                    px <= px + 9'd1;
                end
            end else begin
                we <= 1'b0;
            end
        end
    end
endmodule
`timescale 1ns / 1ps

module LED(
    // input ports
    input wire      i_clk   ,
    input wire      i_rst   ,
    input wire      i_en    ,
    input wire      i_ch_color,
    output wire     [3:0] o_led_red,
    output wire     [3:0] o_led_green,
    output wire     [3:0] o_led_blue
    );
    
    // RTL Code
    reg [3:0] n, nxt_n;
    reg [3:0] led_red, led_green, led_blue;
    reg [3:0] nxt_led_red, nxt_led_green, nxt_led_blue;
    reg [1:0] color, nxt_color;    // 0:red, 1:green, 2:blue
    reg pressing_i_en, pressing_i_ch_color;
    
    // assign register to wire
    assign o_led_red = led_red;
    assign o_led_green = led_green;
    assign o_led_blue = led_blue;
    
    
    // sequential logic : operate with clock
    always_ff @ (posedge i_clk) begin
        // Update LED
        n <= nxt_n;
        color <= nxt_color;
        led_red <= nxt_led_red;
        led_green <= nxt_led_green;
        led_blue <= nxt_led_blue;
    end
    
    // combinational logic
    always_comb begin
        if (i_rst) begin
            nxt_n = 0;
            nxt_led_red = 0;
            nxt_led_green = 0;
            nxt_led_blue = 0;
            nxt_color = 0;
        end else begin
            // i_en: increase number
            if (i_en) begin                     // button is pressed
                if (~pressing_i_en) begin       // if this is the first clock while button is pressed, increase the number
                    if (n == 4'b1111) nxt_n = 0;
                    else nxt_n = n + 1;
                    pressing_i_en = 1;
                end
            end else begin                      // if the button is released, reset 'pressing_i_en'
                if (pressing_i_en) pressing_i_en = 0;
            end
            
            // i_ch_color: change color
            if (i_ch_color) begin
                if (~pressing_i_ch_color) begin
                    if (color == 2'b10) nxt_color = 0;
                    else nxt_color = color + 1;
                    pressing_i_ch_color = 1;
                end
            end else begin
                if (pressing_i_ch_color) pressing_i_ch_color = 0;
            end
        
            // Update the next LED color
            case (color)
                2'b00: begin            // red
                    nxt_led_red = n;
                    nxt_led_green = 0;
                    nxt_led_blue = 0;
                end
                2'b01: begin            // green
                    nxt_led_red = 0;
                    nxt_led_green = n;
                    nxt_led_blue = 0;
                end
                2'b10: begin            // blue
                    nxt_led_red = 0;
                    nxt_led_green = 0;
                    nxt_led_blue = n;
                end
            endcase
        end
    end

endmodule

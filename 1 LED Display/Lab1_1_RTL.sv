`timescale 1ns / 1ps

module LED(
    // input ports
    input wire      i_clk   ,
    input wire      i_rst   ,
    input wire      i_en    ,
    output wire     o_led
    );
    
    // RTL Code
    reg led;
    initial led = 0;
    
    // assign register to wire
    assign o_led = led;
    
    // sequential logic : operate with clock
    always @ (posedge i_clk) begin
        // Reset
        if (i_rst) begin
            led <= 0;
        end
        // Run
        else begin
            if (i_en) begin
                led <= 1;
            end
        end
    end
    
endmodule

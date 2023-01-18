`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/11 14:28:16
// Design Name: 
// Module Name: tb_mental_math_master
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_mental_math_master();

    localparam CLK_FREQ                                             = 100; // MHz
    localparam CLK_PERIOD                                           = (1000 / CLK_FREQ);
    localparam CLK_HALF_PERIOD                                      = (1000 / CLK_FREQ) / 2;
    
    localparam BIT_WIDTH                                     = 4;
    
    logic                                                    i_clk;
    logic                                                    i_rst;
    logic                                                    i_sel;
    logic                                                    i_ge;
    logic                                                    i_lt;
    logic [3:0][2:0]                                         o_led;
    
    mental_math_master
    #(
        .BIT_WIDTH                                                  (BIT_WIDTH)
    )
    dut
    (
        .i_clk                                                (i_clk),
        .i_rst                                                (i_rst),
        .i_sel                                                (i_sel),
        .i_ge                                                 (i_ge),
        .i_lt                                                 (i_lt),
        .o_led                                                (o_led)
    );
    
    initial begin
        i_clk                                                         = '0;
        fork
            forever #(CLK_FREQ) i_clk                                 = ~i_clk;
        join
    end

    integer i;
    
    initial begin
        i_sel = 0;
        i_ge = 0;
        i_lt = 0;
        i_rst = 1'b1;
        repeat(10) @(negedge i_clk);
        i_rst = 1'b0;
        repeat(5) @(negedge i_clk);
        
        for (i = 0; i <= 3; i++) begin
            i_sel = 1;
            repeat(5) @(negedge i_clk);
            i_sel = 0;
            repeat(5) @(negedge i_clk);
        end
        
        i_ge = 1;
        repeat(5) @(negedge i_clk);
        i_ge = 0;
        repeat(5) @(negedge i_clk);
        
        i_sel = 1;
        repeat(5) @(negedge i_clk);
        i_sel = 0;
        repeat(5) @(negedge i_clk);
        
        i_ge = 1;
        repeat(5) @(negedge i_clk);
        i_ge = 0;
        repeat(5) @(negedge i_clk);
        
        i_sel = 1;
        repeat(5) @(negedge i_clk);
        i_sel = 0;
        repeat(5) @(negedge i_clk);
        
        i_sel = 1;
        repeat(5) @(negedge i_clk);
        i_sel = 0;
        repeat(5) @(negedge i_clk);
        
        i_lt = 1;
        repeat(5) @(negedge i_clk);
        i_lt = 0;
        repeat(5) @(negedge i_clk);
        
        i_sel = 1;
        repeat(5) @(negedge i_clk);
        i_sel = 0;
        repeat(5) @(negedge i_clk);
        
        i_sel = 1;
        repeat(5) @(negedge i_clk);
        i_sel = 0;
        repeat(5) @(negedge i_clk);
        
        i_sel = 1;
        repeat(5) @(negedge i_clk);
        i_sel = 0;
        repeat(5) @(negedge i_clk);
        
        i_sel = 1;
        repeat(5) @(negedge i_clk);
        i_sel = 0;
        repeat(5) @(negedge i_clk);
        
        
        i_rst = 1;
        repeat(5) @(negedge i_clk);
        i_rst = 0;
        repeat(5) @(negedge i_clk);
        
        i_sel = 1;
        repeat(5) @(negedge i_clk);
        i_sel = 0;
        repeat(5) @(negedge i_clk);

        $finish;
    end
    
    
    
endmodule
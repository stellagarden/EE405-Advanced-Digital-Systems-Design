
// Filename      : TB_final.sv
// Author        : 
//               Seokchan Song    < ssong0410@kaist.ac.kr >
// -----------------------------------------------------------------
// Description: 


// -FHDR------------------------------------------------------------
`timescale 1ns / 1ps

import PS_pkg::*;
module TB_PS();

// Clock period
parameter CLK_PERIOD                                = 5; // 200 MHz

/* TO DO: Declare your logic here. */
logic                                               clk;
logic                                               resetn;
logic [INST_WIDTH -1:0]                             i_instruction;
logic [DATA_WIDTH*VECTOR_LENGTH -1:0]               i_data;
logic [DATA_WIDTH -1:0]               o_data;
logic                                               o_done;
logic [3:0]                                         o_pipe_status;
logic [2:0]                                         o_stall;

logic                                               mem0_cen, mem0_wen, mem1_cen, mem1_wen;
logic [ADDR_WIDTH-1:0]                              mem0_addr, mem1_addr;
logic [DATA_WIDTH*VECTOR_LENGTH-1:0]                mem0_wrdata, mem0_rddata, mem1_wrdata, mem1_rddata;
/* TO DO: Instantiate pipelined simd here. */
DUT pipe_simd_top (
      .clk                                        ( clk                      ),
       .reset                                      ( ~resetn                   ),


        .i_instruction                              ( i_instruction            ),
        .i_data                                     ( i_data                   ),
        .o_data                                     ( o_data                   ),   

      .o_done                                     ( o_done                   ),
       .o_pipe_status                              ( o_pipe_status            ),
       .o_stall                                     (o_stall)

);

// SRAM for your code
SRAM #(
   .AWIDTH                                 ( ADDR_WIDTH            ),
   .DWIDTH                                 ( VECTOR_LENGTH * DATA_WIDTH),
   .INIT_FILE                              ( "./imem_init.txt"         )
) tb_imem (
   .clk                                 ( clk                  ),
   .cen                                 ( mem0_cen               ),
   .wen                                 ( mem0_wen                ),
   .addr                                 ( mem0_addr               ),
   .wrdata                                 ( mem0_wrdata            ),
   .rddata                                 ( mem0_rddata            )
);

SRAM #(
   .AWIDTH                                 ( ADDR_WIDTH            ),
   .DWIDTH                                 ( VECTOR_LENGTH * DATA_WIDTH),
   .INIT_FILE                              ( "./wmem_init.txt"         )
) tb_wmem (
   .clk                                 ( clk                  ),
   .cen                                 ( mem1_cen               ),
   .wen                                     ( mem1_wen               ),
   .addr                                 ( mem1_addr               ),
   .wrdata                                 ( mem1_wrdata            ),
   .rddata                                 ( mem1_rddata            )
);

task stall;
begin
    while (o_stall == 1) begin
        repeat(1) @(posedge clk);
    end
end endtask

// Testbench clock declaration
initial begin
   clk = 1'b1;
    forever begin
        clk                                        = #(CLK_PERIOD/2) ~clk;
    end
end


// Reset
initial begin
    resetn                                         = 'b1;
    @(posedge clk);
    resetn                                         = 'b0;
    repeat(10) @(posedge clk);
    resetn                                         = 'b1; 
end

// Testbench
initial begin
    
    /* TO DO: Write your own Testbench here. */
    integer i;
    
    mem0_cen = 1'b0;
    mem0_wen = 1'b0;
    mem1_cen = 1'b0;
    mem1_wen = 1'b0;
    i_instruction = 0;
    repeat(13) @(posedge clk);
    
    // operation 3 (fill input memory) 
    for (int i = 0;i<64;i++) begin
        mem0_cen = 1'b1;
        mem0_addr = 13'b0_0000_0000_0000+i;
        repeat(1) @(posedge clk);
        i_data = mem0_rddata;
        i_instruction = 19'b011_0000_0000_0000_0000+i;
        repeat(1) @(posedge clk);
    end
    mem0_cen = 1'b0;
    
    // operation 4(set weight vector)
    mem1_cen = 1'b1;
    mem1_addr = 13'b0_0000_0000_0000;
    repeat(1) @(posedge clk);
    i_data = mem1_rddata;
    i_instruction = 19'b100_0000_0000_0000_0000;
    repeat(2) @(posedge clk);
    mem1_cen = 1'b0;

    // Repeat Op6 + Op2 x16
    for (int i = 0; i<16; i++) begin
        i_instruction = 19'b110_0000_0000_0000_0000 + {i, 8'b0000_0000} + i;
        repeat(1) @(posedge clk);
        stall;
        i_instruction = 19'b010_0000_0000_0000_0000 + {i, 8'b0000_0000} + i;
        repeat(1) @(posedge clk);
        stall;
    end
    
    // operation 4(change weight vector)
    repeat(5) @(posedge clk);
    mem1_cen = 1'b1;
    mem1_addr = 13'b0_0000_0000_0001;
    repeat(1) @(posedge clk);
    i_data = mem1_rddata;
    i_instruction = 19'b100_0000_0000_0000_0001;
    repeat(2) @(posedge clk);
    mem1_cen = 1'b0;
    
    // Repeat Op6 + Op2 x16
    for (int i = 0; i<16; i++) begin
        i_instruction = 19'b110_0000_0000_0000_0000 + {i+16, 8'b0000_0000} + (i+16);
        repeat(1) @(posedge clk);
        stall;
        i_instruction = 19'b010_0000_0000_0000_0000 + {i+16, 8'b0000_0000} + (i+16);
        repeat(1) @(posedge clk);
        stall;
    end
    
    // operation 4(change weight vector)
    repeat(5) @(posedge clk);
    mem1_cen = 1'b1;
    mem1_addr = 13'b0_0000_0000_0010;
    repeat(1) @(posedge clk);
    i_data = mem1_rddata;
    i_instruction = 19'b100_0000_0000_0000_0010;
    repeat(2) @(posedge clk);
    mem1_cen = 1'b0;
    
    // Repeat Op6 + Op2 x16
    for (int i = 0; i<16; i++) begin
        i_instruction = 19'b110_0000_0000_0000_0000 + {i+32, 8'b0000_0000} + (i+32);
        repeat(1) @(posedge clk);
        stall;
        i_instruction = 19'b010_0000_0000_0000_0000 + {i+32, 8'b0000_0000} + (i+32);
        repeat(1) @(posedge clk);
        stall;
    end
    
    // operation 4(change weight vector)
    repeat(5) @(posedge clk);
    mem1_cen = 1'b1;
    mem1_addr = 13'b0_0000_0000_0011;
    repeat(1) @(posedge clk);
    i_data = mem1_rddata;
    i_instruction = 19'b100_0000_0000_0000_0100;
    repeat(2) @(posedge clk);
    mem1_cen = 1'b0;
    
    // Repeat Op6 + Op2 x16
    for (int i = 0; i<16; i++) begin
        i_instruction = 19'b110_0000_0000_0000_0000 + {i+48, 8'b0000_0000} + (i+48);
        repeat(1) @(posedge clk);
        stall;
        i_instruction = 19'b010_0000_0000_0000_0000 + {i+48, 8'b0000_0000} + (i+48);
        repeat(1) @(posedge clk);
        stall;
    end 
    
    // operation 5(verification1)
    repeat(5) @(posedge clk);
    for (int i = 8'b0000_0000;i<8'b0100_0000;i=i+8'b0000_0001) begin
        i_instruction = 19'b101_0000_0000_0000_0000 + {3'b000, 8'b0000_0000 + i, 8'b0000_0000};
        repeat(2) @(posedge clk);
    end
    
    // Operation 0 (reset)
    i_instruction = 16'b000_0_0000_0000_0000;
    repeat(3) @(posedge clk);
    
    $finish();
end
 
endmodule
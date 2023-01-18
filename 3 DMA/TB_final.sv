// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : TB_final.sv
// Author        : Castlab
//				   JaeUk Kim 	< kju5789@kaist.ac.kr >
//				   Donghyuk Kim < kar02040@kaist.ac.kr>
// -----------------------------------------------------------------
// Description: Testbench for APB and DUT
//              Write your own Testbench.
//              The full version of Testbench would not be provided since it
//              emulates the fpga_top design so that could be hint for lab 3.
// -FHDR------------------------------------------------------------
`timescale 1ns / 1ps

import dma_pkg::*;
module TB_APB();
// Configuration register addr
parameter SRC_ADDR                                  = DMA_BASE_ADDR + 32'h00000000;
parameter DEST_ADDR                                 = DMA_BASE_ADDR + 32'h00000004;
parameter SIZE_ADDR                                 = DMA_BASE_ADDR + 32'h00000008;
parameter MODE_ADDR                                 = DMA_BASE_ADDR + 32'h0000000c;
parameter INT_ADDR                                  = DMA_BASE_ADDR + 32'h00000010;

// Clock period
parameter CLK_PERIOD                                = 5; // 200 MHz
parameter PPROT_WIDTH                               = 3;
parameter PSTRB_WIDTH                               = 4;
parameter ADDR_WIDTH                                = 16;
parameter DATA_WIDTH                                = 32;

/* TO DO: Declare your logic here. */
logic                                               clk;
logic                                               resetn;
logic [DATA_WIDTH-1:0]                              apb_paddr;
logic                                               apb_penable;
logic [DATA_WIDTH-1:0]                              apb_prdata;
logic                                               apb_pready;
logic                                               apb_psel;
logic [DATA_WIDTH-1:0]                              apb_pwdata;
logic                                               apb_pwrite;

logic                                               interrupt;
logic [2             -1:0]                          interrupt_LED;

logic                                               mem0_en;
logic [PSTRB_WIDTH-1:0]                             mem0_we;
logic [ADDR_WIDTH-1:0]                              mem0_addr;
logic [DATA_WIDTH-1:0]					            mem0_wrdata;
logic [DATA_WIDTH-1:0]					            mem0_rddata;
logic                                               mem1_en;
logic [PSTRB_WIDTH-1:0]                             mem1_we;
logic [ADDR_WIDTH-1:0]                              mem1_addr;
logic [DATA_WIDTH-1:0]					            mem1_wrdata;
logic [DATA_WIDTH-1:0]					            mem1_rddata;

/* TO DO: Instantiate apb_master here. */
APB_master_intf apb_master
(
    .clk							                ( clk					    ),
    .m_apb_paddr					                ( apb_paddr			        ),
    .m_apb_penable					                ( apb_penable	            ),
    .m_apb_prdata					                ( apb_prdata	            ),
    .m_apb_pready					                ( apb_pready	            ),
    .m_apb_psel						                ( apb_psel			        ),
    .m_apb_pwdata					                ( apb_pwdata	            ),
    .m_apb_pwrite					                ( apb_pwrite	            )
);

// DUT
DUT u_DUT (
	.CLK							                ( clk  						),
    .RSTN							                ( resetn				    ),
    .INTR							                ( interrupt				    ),
	.INTR_LED						                ( interrupt_LED		        ),

    .PSEL							                ( apb_psel 					),
    .PENABLE						                ( apb_penable		    	),
    .PREADY							                ( apb_pready		    	),
    .PWRITE							                ( apb_pwrite		    	),
    .PADDR							                ( apb_paddr					),
    .PWDATA							                ( apb_pwdata			    ),
    .PRDATA							                ( apb_prdata			    ),
	
	.mem0_en						                ( mem0_en 					),
	.mem0_we						                ( mem0_we					),
	.mem0_addr						                ( mem0_addr					),
	.mem0_wdata						                ( mem0_wrdata			    ),
	.mem0_rdata						                ( mem0_rddata			    ),
                                                 
	.mem1_en						                ( mem1_en					),
	.mem1_we						                ( mem1_we					),
	.mem1_addr						                ( mem1_addr					),
	.mem1_wdata						                ( mem1_wrdata      		    ),
	.mem1_rdata						                ( mem1_rddata			    )
);

// SRAM for your code
// Alternate this code with your bram instance after bram initialization.
// Note that you should use BRAM after simulation. (Synthesis...)
//Sram #(
//	.AWIDTH											( ADDR_WIDTH				),
//	.DWIDTH											( DATA_WIDTH				),
//	.WSTRB											( PSTRB_WIDTH				),
//	.INIT_FILE										( "mem0_init.txt"			)
//) u_mem0 (
//	.clk											( clk   					),
//	.en												( mem0_en					),
//	.we												( mem0_we					),
//	.addr											( mem0_addr					),
//	.wrdata											( mem0_wrdata     			),
//	.rddata											( mem0_rddata				)
//);

//Sram #(
//	.AWIDTH											( ADDR_WIDTH				),
//	.DWIDTH											( DATA_WIDTH				),
//	.WSTRB											( PSTRB_WIDTH				),
//	.INIT_FILE										( "mem1_init.txt"			)
//) u_mem1 (
//	.clk											( clk   					),
//	.en												( mem1_en					),
//	.we												( mem1_we					),
//	.addr											( mem1_addr					),
//	.wrdata											( mem1_wrdata     			),
//	.rddata											( mem1_rddata				)
//);

// BRAM instantiation
/* TO DO: Note that you could use BRAM for simulation result */
blk_mem_gen_0 u_mem0
(
    .clka           (clk        ),
    .ena            (mem0_en      ),
    .wea            (mem0_we      ),
    .addra          (mem0_addr    ),
    .dina           (mem0_wrdata   ),
    .douta          (mem0_rddata   )
);

blk_mem_gen_1 u_mem1
(
    .clka           (clk        ),
    .ena            (mem1_en      ),
    .wea            (mem1_we      ),
    .addra          (mem1_addr    ),
    .dina           (mem1_wrdata   ),
    .douta          (mem1_rddata   )
);

// Testbench clock declaration
initial begin
	clk = 1'b1;
    forever begin
        clk                                     	= #(CLK_PERIOD/2) ~clk;
    end
end

// Reset
initial begin
    resetn                                      	= 'b1;
    @(posedge clk);
    resetn                                      	= 'b0;
    repeat(10) @(posedge clk);
    resetn                                      	= 'b1; 
end

// Testbench
initial begin
    
    /* TO DO: Write your own Testbench here. */
    repeat(13) @(posedge clk);
    // Source Address
    apb_master.write(SRC_ADDR, 32'h00010004);
    $display("[Src Setting] Set source address as 0x00010004");  
     @(posedge clk);
    // Destination Address
    apb_master.write(DEST_ADDR, 32'h00020014);
    $display("[Dest Setting] Set destination address as 0x00020014");
     @(posedge clk);
    // Size
    apb_master.write(SIZE_ADDR, 32'h0000000C);
    $display("[Size Setting] Set size as 0x0000000C");
    @(posedge clk);
    // Operation
    apb_master.write(MODE_ADDR, 32'h00000001);
    $display("[DMA] Start normal DMA operation");
    @(posedge clk);
    // Detect Interrupt
    while (interrupt == 0) begin
        @(posedge clk);
    end
    $display("DMA transfer done");    
    
    // Verification
    apb_master.write(MODE_ADDR, 32'h00000002);
    $display("[DMA] Start DMA verification");
    @(posedge clk);
    // Detect Interrupt
    while (interrupt_LED == 0) begin
        @(posedge clk);
    end
    $display("DMA verification done");
    @(posedge clk);
    // Display verification result
    if (interrupt_LED == 1) $display("DMA Success");
    else if (interrupt_LED == 2) $display("DMA Fail");
    else $display("DMA No result returned");
    
    repeat(3) @(posedge clk);
    $finish();
end
 
endmodule

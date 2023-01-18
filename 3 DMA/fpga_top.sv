// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fpga_top.sv
// Author        : Castlab
//               JaeUk Kim    <kju5789@kaist.ac.kr >
//               Donghyuk Kim <kar02040@kaist.ac.kr>
// -----------------------------------------------------------------
// Description    : This is the top module of the fpga.
//               The block design shell and your DUT design
//               declared here.
// -FHDR------------------------------------------------------------
`timescale 1ns / 1ps

import dma_pkg::*;
module fpga_top
(
   input  logic                           diff_clock_rtl_clk_n,
   input  logic                           diff_clock_rtl_clk_p,
   input  logic [3:0]                        axi_gpio_tri_i,
   input  logic                           reset,
   input  logic                           usb_uart_rxd,
   output logic                            usb_uart_txd,
   output logic [3:0]                        o_led
);

/* TO DO: Logic declaration */
// Internal Clock, Reset Declaration
logic CLK;
logic RSTN;

// APB Bus Signal Declaration
logic                           psel;
logic                           penable;
logic                           pready;
logic                           pwrite;
logic [REG_ADDR_WIDTH -1:0]     paddr;
logic [REG_DATA_WIDTH -1:0]     pwdata;
logic [REG_DATA_WIDTH -1:0]     prdata;
logic                           pstrb;
logic                           pprot;
logic                           pslverr;

// Memory 0 Signal Declaration
logic                             mem0_en;
logic [MEM_STRB_WIDTH -1:0]       mem0_we;
logic [MEM_ADDR_WIDTH -1:0]       mem0_addr;
logic [MEM_DATA_WIDTH -1:0]       mem0_wdata;
logic [MEM_DATA_WIDTH -1:0]       mem0_rdata;

// Memory 1 Signal Declaration
logic                             mem1_en;
logic [MEM_STRB_WIDTH -1:0]       mem1_we;
logic [MEM_ADDR_WIDTH -1:0]       mem1_addr;
logic [MEM_DATA_WIDTH -1:0]       mem1_wdata;
logic [MEM_DATA_WIDTH -1:0]       mem1_rdata;

// Shell instantiation
/* TO DO: Declare your wrapper instance here. */
design_1_wrapper wrapper (
    .diff_clock_rtl_clk_n                           ( diff_clock_rtl_clk_n      ),      
    .diff_clock_rtl_clk_p                           ( diff_clock_rtl_clk_p     ),
    .led_4bits_tri_o                               ( axi_gpio_tri_i         ),
    .reset                                          ( reset                  ),
    .usb_uart_rxd                                   ( usb_uart_rxd            ),
    .usb_uart_txd                                   ( usb_uart_txd            ),
    .usr_rtl_apb_paddr                              ( paddr                  ),
    .usr_rtl_apb_penable                            ( penable               ),
    .usr_rtl_apb_pprot                              (                           ),
    .usr_rtl_apb_prdata                             ( prdata               ),
    .usr_rtl_apb_pready                             ( pready               ),
    .usr_rtl_apb_psel                               ( psel                  ),
    .usr_rtl_apb_pslverr                            (                          ),
    .usr_rtl_apb_pstrb                              (                          ),
    .usr_rtl_apb_pwdata                             ( pwdata               ),
    .usr_rtl_apb_pwrite                             ( pwrite               ),
    .usr_rtl_clk                                    ( CLK                  ),
    .usr_rtl_rst                                    ( RSTN                  )
);


// DUT module instantiation
DUT u_DUT (
   .CLK                                 ( CLK                  ),      // i
    .RSTN                                 ( RSTN                    ),      // i
    .INTR                                 ( o_led[0]               ),      // o
   .INTR_LED                              ( o_led[2:1]            ),      // o

    .PSEL                                 ( psel                  ),      // i
    .PENABLE                              ( penable               ),      // i
    .PREADY                                 ( pready               ),      // o
    .PWRITE                                 ( pwrite               ),      // i
    .PADDR                                 ( paddr                  ),      // i
    .PWDATA                                 ( pwdata               ),      // i
    .PRDATA                                 ( prdata               ),      // o
   
   .mem0_en                              ( mem0_en               ),      // o
   .mem0_we                              ( mem0_we               ),      // o
   .mem0_addr                              ( mem0_addr               ),      // o
   .mem0_wdata                              ( mem0_wdata            ),      // o
   .mem0_rdata                              ( mem0_rdata            ),      // i
                                                 
   .mem1_en                              ( mem1_en               ),      // o
   .mem1_we                              ( mem1_we               ),      // o
   .mem1_addr                              ( mem1_addr                  ),      // o
   .mem1_wdata                              ( mem1_wdata            ),      // o
   .mem1_rdata                              ( mem1_rdata            )      // i
);

// SRAM for your code
// Alternate this code with your bram instance after bram initialization.
// Note that you should use BRAM after simulation. (Synthesis...)
//Sram #(
//   .AWIDTH                                 ( MEM_ADDR_WIDTH         ),
//   .DWIDTH                                 ( MEM_DATA_WIDTH         ),
//   .WSTRB                                 ( MEM_STRB_WIDTH         ),
//   .INIT_FILE                              ( "mem0_init.txt"         )
//) u_mem0 (
//   .clk                                 ( CLK                  ),
//   .en                                    ( mem0_en               ),
//   .we                                    ( mem0_we               ),
//   .addr                                 ( mem0_addr               ),
//   .wrdata                                 ( mem0_wdata            ),
//   .rddata                                 ( mem0_rdata            )
//);

//Sram #(
//   .AWIDTH                                 ( MEM_ADDR_WIDTH         ),
//   .DWIDTH                                 ( MEM_DATA_WIDTH         ),
//   .WSTRB                                 ( MEM_STRB_WIDTH         ),
//   .INIT_FILE                              ( "mem1_init.txt"         )
//) u_mem1 (
//   .clk                                 ( CLK                  ),
//   .en                                    ( mem1_en               ),
//   .we                                    ( mem1_we               ),
//   .addr                                 ( mem1_addr                  ),
//   .wrdata                                 ( mem1_wdata            ),
//   .rddata                                 ( mem1_rdata            )
//);

// BRAM instantiation
/* TO DO: Instantiate your BRAM for synthesis
        Note that you could use BRAM for simulation result */
blk_mem_gen_0 u_mem0
(
    .clka           (CLK          ),
    .ena            (mem0_en      ),
    .wea            (mem0_we      ),
    .addra          (mem0_addr    ),
    .dina           (mem0_wdata   ),
    .douta          (mem0_rdata   )
);

blk_mem_gen_1 u_mem1
(
    .clka           (CLK          ),
    .ena            (mem1_en      ),
    .wea            (mem1_we      ),
    .addra          (mem1_addr    ),
    .dina           (mem1_wdata   ),
    .douta          (mem1_rdata   )
);

endmodule
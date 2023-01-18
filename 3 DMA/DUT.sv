// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : DUT.sv
// Author        : Castlab
//               JaeUk Kim    < kju5789@kaist.ac.kr >
//               Donghyuk Kim < kar02040@kaist.ac.kr>
// -----------------------------------------------------------------
// Description: DMA Top Design
//            In this module, you have to declare APB slave
//            and DMA module.
//            Luckily, APB slave module is provided... :>
// -FHDR------------------------------------------------------------
`timescale 1ns / 1ps

import dma_pkg::*;
module DUT
(
   // Global
    input  logic                           CLK,
    input  logic                           RSTN,

   // 1: Done, 0: Not Done
   output logic                           INTR,

   // 00: Idle, 10: Success, 01: Fail
   output logic [2             -1:0]            INTR_LED,

   // APB Bus Signal
   input  logic                           PSEL,
   input  logic                           PENABLE,
   output logic                           PREADY,
   input  logic                           PWRITE,
   input  logic [REG_ADDR_WIDTH -1:0]            PADDR,
   input  logic [REG_DATA_WIDTH -1:0]            PWDATA,
   output logic [REG_DATA_WIDTH -1:0]            PRDATA,

   // Memory 0 Signal
   output logic                           mem0_en,
   output logic [MEM_STRB_WIDTH -1:0]            mem0_we,
   output logic [MEM_ADDR_WIDTH -1:0]            mem0_addr,
   output logic [MEM_DATA_WIDTH -1:0]            mem0_wdata,
   input  logic [MEM_DATA_WIDTH -1:0]            mem0_rdata,

   // Memory 1 Signal
   output logic                           mem1_en,
   output logic [MEM_STRB_WIDTH -1:0]            mem1_we,
   output logic [MEM_ADDR_WIDTH -1:0]            mem1_addr,
   output logic [MEM_DATA_WIDTH -1:0]            mem1_wdata,
   input  logic [MEM_DATA_WIDTH -1:0]            mem1_rdata
   
);
   
// DMA signal declaration
logic [REG_DATA_WIDTH   -1:0]                  w_src_addr;            // DMA Source Address
logic [REG_DATA_WIDTH   -1:0]                  w_dest_addr;         // DMA Destination Address
logic [REG_DATA_WIDTH   -1:0]                  w_transfer_size;      // DMA Transfer Size
logic [MODE            -1:0]                  w_mode;               // DMA Operation Mode, 00: Idle, 01: Normal Mode Start, 10: Test Mode Start
logic                                    w_status_update;      // DMA done
logic [2            -1:0]                  w_led;

// Memory signal declaration
logic                                    w_mem_sel;            // 0: Mem0-Source, Mem1-Destination, 1: Mem0-Source, Mem1-Destination

// Source memory
logic                                    s_en;
logic [MEM_STRB_WIDTH   -1:0]                  s_we;
logic [MEM_ADDR_WIDTH   -1:0]                  s_addr;
logic [MEM_DATA_WIDTH   -1:0]                  s_wrdata;
logic [MEM_DATA_WIDTH   -1:0]                  s_rddata;

// Destination memory
logic                                    d_en;
logic [MEM_STRB_WIDTH   -1:0]                  d_we;
logic [MEM_ADDR_WIDTH   -1:0]                  d_addr;
logic [MEM_DATA_WIDTH   -1:0]                  d_wrdata;
logic [MEM_DATA_WIDTH   -1:0]                  d_rddata;

// Input, Output Signal Interconnect
/* TO DO: Connect mem0 and mem1 signal according to the w_mem_sel signal.
         Note that there exists 2 possible cases (source, dest) = (mem0, mem1), (mem1, mem0). */
always_comb begin
   if (w_mem_sel==1'b0) begin                  // Mem0: Source, Mem1: Destination
      /* TO DO: Fill out the code */
      mem0_en = s_en;
      mem0_we = s_we;
      mem0_addr = s_addr;
      mem0_wdata = s_wrdata;
      s_rddata = mem0_rdata;
      mem1_en = d_en;
      mem1_we = d_we;
      mem1_addr = d_addr;
      mem1_wdata = d_wrdata;
      d_rddata = mem1_rdata;
   end
   else begin                              // Mem0: Destination, Mem1: Source
      /* TO DO: Fill out the code */
      mem1_en = s_en;
      mem1_we = s_we;
      mem1_addr = s_addr;
      mem1_wdata = s_wrdata;
      s_rddata = mem1_rdata;
      mem0_en = d_en;
      mem0_we = d_we;
      mem0_addr = d_addr;
      mem0_wdata = d_wrdata;
      d_rddata = mem0_rdata;
   end
end

// APB Slave Instantiation
APB_slave u_APB_slave (
   .clk                                 ( CLK                  ),
   .reset                                 ( ~RSTN                  ),

   .out_intr                              ( INTR                  ),
   .out_led                              ( INTR_LED               ),

   .in_s_apb_psel                           ( PSEL                  ),
   .in_s_apb_penable                        ( PENABLE               ),
   .out_s_apb_pready                        ( PREADY               ),
   .in_s_apb_pwrite                        ( PWRITE               ),
   .in_s_apb_paddr                           ( PADDR                  ),
   .in_s_apb_pwdata                        ( PWDATA               ),
   .out_s_apb_prdata                        ( PRDATA               ),

   .out_src_addr                           ( w_src_addr            ),         
   .out_dest_addr                           ( w_dest_addr            ),         
   .out_transfer_size                        ( w_transfer_size         ),      
   .out_mode                              ( w_mode               ),            
   .in_status_update                        ( w_status_update         ),
   .in_led_update                           ( w_status_update         ),
    .in_led                                 ( w_led                  ),
   
   .out_mem_sel                           ( w_mem_sel               )   
);

/* TO DO: Connect the port of DMA. */
// DMA Instantiation
DMA u_DMA (
   .clk                                 ( CLK                   ),
   .reset                                 ( ~RSTN                  ),

   .in_src_addr                           ( w_src_addr            ),
   .in_dest_addr                           ( w_dest_addr            ),
   .in_transfer_size                        ( w_transfer_size           ),
   .in_mode                              ( w_mode               ),
   .out_done                              ( w_status_update         ),

   .out_s_en                              ( s_en                  ),
   .out_s_we                              ( s_we                  ),
   .out_s_addr                              ( s_addr               ),
   .out_s_wrdata                           ( s_wrdata               ),
   .in_s_rddata                           ( s_rddata               ),
   
   .out_d_en                              ( d_en                  ),   
   .out_d_we                              ( d_we                  ),   
   .out_d_addr                              ( d_addr               ),   
   .out_d_wrdata                           ( d_wrdata               ),   
   .in_d_rddata                           ( d_rddata               ),   

   .out_success                           ( w_led                   )
);

endmodule
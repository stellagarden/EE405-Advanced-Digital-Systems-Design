// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : SRAM.sv
// Author        : Castlab
//				   JaeUk Kim 	< kju5789@kaist.ac.kr >
//				   Donghyuk Kim < kar02040@kaist.ac.kr>
// -----------------------------------------------------------------
// Description: SRAM module
//              Note that the access granularity is 8. (byte)
//              Luckily, completed version is provided... :)
// -FHDR------------------------------------------------------------

`timescale 1ns / 1ps

module Sram
#(
    parameter AWIDTH                                = 16,
    parameter DWIDTH							    = 32,
    parameter WSTRB                                 = 4,
    parameter INIT_FILE                             = ""
)
(
    input  logic                                    clk,
    input  logic                                    en,
    input  logic [WSTRB-1:0]                        we,
    input  logic [AWIDTH-1:0]                       addr,
    input  logic [DWIDTH-1:0]					    wrdata,
    output logic [DWIDTH-1:0]					    rddata
);

    localparam WE_MASK0                             = 8'b00000000;
    localparam WE_MASK1                             = 8'b11111111;

    // We mask
    logic [DWIDTH-1:0]							    mask;

    assign mask[31:24]                              = we[3] ? WE_MASK1 : WE_MASK0;
    assign mask[23:16]                              = we[2] ? WE_MASK1 : WE_MASK0;
    assign mask[15:8]                               = we[1] ? WE_MASK1 : WE_MASK0;
    assign mask[7:0]                                = we[0] ? WE_MASK1 : WE_MASK0;

    // Memory - Size: Addr size
    logic [DWIDTH-1:0]							    Mem[0:(1<<AWIDTH)-1];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh (INIT_FILE, Mem, 0, (1<<AWIDTH)-1);
        end
    end

    // Operation
    always_ff @(posedge clk) begin
        if (en) begin
			if(|we) begin
			    Mem[addr[AWIDTH-1:0]]			    <= (Mem[addr[AWIDTH-1:0]] & ~mask) | (wrdata & mask);
			end
			else begin
			    rddata                              <= Mem[addr[AWIDTH-1:0]];
			end
		end
    end

endmodule

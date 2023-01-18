
// Filename      : SRAM.sv
// Author        : 
//				   Seokchan Song 	< ssong0410@kaist.ac.kr >
// -----------------------------------------------------------------
// Description: 


// -FHDR------------------------------------------------------------

`timescale 1ns / 1ps

import PS_pkg::*;
module SRAM
#(
    parameter AWIDTH                                = 13,
    parameter DWIDTH							    = 16,
    parameter WSTRB                                 = 4,
    parameter INIT_FILE                             = ""
)
(
    input  logic                                    clk,
    input  logic                                    cen,
    input  logic                                    wen,
    input  logic [AWIDTH-1:0]                       addr,
    input  logic [DWIDTH-1:0]					    wrdata,
    output logic [DWIDTH-1:0]					    rddata
);



    // Memory - Size: Addr size
    logic [DWIDTH-1:0]							    Mem[0:(1<<AWIDTH)-1];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh (INIT_FILE, Mem, 0, (1<<AWIDTH)-1);
        end
    end

    // Operation
    always_ff @(posedge clk) begin
        if (cen) begin
			if(|wen) begin
			    Mem[addr[AWIDTH-1:0]]			    <= wrdata ;
			end
			else begin
			    rddata                              <= Mem[addr[AWIDTH-1:0]];
			end
		end
    end

endmodule
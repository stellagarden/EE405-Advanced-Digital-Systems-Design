// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : FIFO.sv
// Author        : Castlab
//				   JaeUk Kim 	< kju5789@kaist.ac.kr >
//				   Donghyuk Kim < kar02040@kaist.ac.kr>
// -----------------------------------------------------------------
// Description: FIFO module
//				Design your own FIFO here.
// -FHDR------------------------------------------------------------
`timescale 1ns / 1ps
module FIFO
#(
    parameter FIFO_AWIDTH                           = 13,
    parameter FIFO_DWIDTH                           = 32
)
(
    input  logic                                    clk,
    input  logic                                    reset,
    input  logic                                    in_push,
    input  logic                                    in_pop,
    input  logic [FIFO_DWIDTH-1:0]                  in_data,
    output logic                                    out_empty,
    output logic                                    out_almost_empty,
    output logic                                    out_full,
    output logic                                    out_almost_full,
    output logic [FIFO_DWIDTH-1:0]                  out_data
);

	/* TO DO: Design your FIFO here.
			  Your FIFO implementation should follow provided method.
			  Note that, in ASIC design, we usually use FIFO that
			  could directly use data, then, pop to prepare next data.
			  In other word, if you want d0 at cycle c0, just use out_data
			  of FIFO, then, pop so that at cycle c1, out_data=d1
			  (next data). */
      
    reg [FIFO_DWIDTH-1:0] FIFO_ff [FIFO_AWIDTH-1:0];
    reg [FIFO_DWIDTH-1:0] FIFO_nxt [FIFO_AWIDTH-1:0];
    reg [FIFO_AWIDTH-1:0] rd_pt_ff, wr_pt_ff, nData;
    reg [FIFO_AWIDTH-1:0] rd_pt_nxt, wr_pt_nxt;
    reg [FIFO_AWIDTH-1:0] i;
    
    assign nData = wr_pt_ff - rd_pt_ff;
    assign out_empty = (nData == 0) ? 1 : 0;
    assign out_almost_empty = (nData <= 1) ? 1 : 0;
    assign out_full = (nData == FIFO_AWIDTH) ? 1 : 0;
    assign out_almost_full = (nData >= (FIFO_AWIDTH-1)) ? 1 : 0;
    assign out_data = FIFO_ff[rd_pt_ff%FIFO_AWIDTH];    
    
    always_ff @ (posedge clk) begin
        rd_pt_ff <= rd_pt_nxt;
        wr_pt_ff <= wr_pt_nxt;
        FIFO_ff <= FIFO_nxt;
    end
    
    always_comb begin
        if (reset) begin
            rd_pt_nxt = 0;
            wr_pt_nxt = 0;
        end else begin
            // Write
            if (in_push) begin
                if (wr_pt_ff > 0) FIFO_nxt[(wr_pt_ff-1)%FIFO_AWIDTH] = FIFO_ff[(wr_pt_ff-1)%FIFO_AWIDTH];
                FIFO_nxt[wr_pt_ff%FIFO_AWIDTH] = in_data;
                
                wr_pt_nxt = wr_pt_ff + 1;
            end
            
            // Read
            if (in_pop) begin
                rd_pt_nxt = rd_pt_ff + 1;
            end
        end
    end

endmodule

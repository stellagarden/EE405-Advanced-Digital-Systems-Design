
// Filename      : pipe_SIMD.sv
// Author        : 
//				   Seokchan Song 	< ssong0410@kaist.ac.kr >
// -----------------------------------------------------------------
// Description: 
//  Pipelined SIMD. It must consist 4 stage pipelined register. Refer to figure 2 of given documentaiton.
//  o_pipe_status : Each bit indicates activation of the pipeline register. {ADD2, ADD1, ADD0, MUL}

// -FHDR------------------------------------------------------------

`timescale 1ns / 1ps

import PS_pkg::*;
module PIPE_SIMD
#(
    parameter DWIDTH                =   16  ,
    parameter VECTOR_LENGTH         =   16
)
(
    input  logic								clk,
    input  logic								reset,

    input  logic                                i_run       ,

    input  logic [DWIDTH-1:0]     i_input  [0:VECTOR_LENGTH-1],
    input  logic [DWIDTH-1:0]     i_weight [0:VECTOR_LENGTH-1],
    
	output logic [DWIDTH-1:0]                   o_result    ,
    output logic [3:0]                          o_pipe_status
);

/* TO DO: Design your pipeliend SIMD here.
        Your implementation should follow provided method. */
// Declare Pipeline Registers
logic                 MUL_run_ff, ADD0_run_ff, ADD1_run_ff, ADD2_run_ff;
logic                 MUL_run_nxt, ADD0_run_nxt, ADD1_run_nxt, ADD2_run_nxt;

logic [DWIDTH*2-1:0]    MUL_data_ff       [0:VECTOR_LENGTH-1];
logic [DWIDTH*2-1:0]    MUL_data_nxt      [0:VECTOR_LENGTH-1];
logic [DWIDTH*2-1:0]  ADD0_data_ff      [0:VECTOR_LENGTH/2-1];
logic [DWIDTH*2-1:0]  ADD0_data_nxt     [0:VECTOR_LENGTH/2-1];
logic [DWIDTH*2-1:0]  ADD1_data_ff      [0:VECTOR_LENGTH/4-1];
logic [DWIDTH*2-1:0]  ADD1_data_nxt     [0:VECTOR_LENGTH/4-1];
logic [DWIDTH*2-1:0]  ADD2_data_ff      [0:VECTOR_LENGTH/8-1];
logic [DWIDTH*2-1:0]  ADD2_data_nxt     [0:VECTOR_LENGTH/8-1];

logic [DWIDTH*2-1:0]    o_result_ff;  
logic [3:0]           o_pipe_status_ff;

assign o_result = o_result_ff[DWIDTH-1:0];
assign o_pipe_status = o_pipe_status_ff;

/* TO DO: Write sequential code for your SIMD here. */
always_ff @(posedge clk) begin
    if (reset) begin
        ADD0_run_ff <= ADD0_run_nxt;
        ADD1_run_ff <= ADD1_run_nxt;
        ADD2_run_ff <= ADD2_run_nxt;
    end else begin
        // Stage 1
        ADD0_run_ff <= ADD0_run_nxt;
        ADD0_data_ff <= ADD0_data_nxt;
        // Stage 2
        ADD1_run_ff <= ADD1_run_nxt;
        ADD1_data_ff <= ADD1_data_nxt;
        // Stage 3
        ADD2_run_ff <= ADD2_run_nxt;
        ADD2_data_ff <= ADD2_data_nxt;
        // Stage 4
    end
end

/* TO DO: Write combinational code for your SIMD here. */
always_comb begin
    if (reset) begin
        ADD0_run_nxt = 0;
        ADD1_run_nxt = 0;
        ADD2_run_nxt = 0;
        for (int i=0;i<VECTOR_LENGTH;i++) begin
            if (i<VECTOR_LENGTH/2) ADD0_data_nxt[i] = 0;
            if (i<VECTOR_LENGTH/4) ADD1_data_nxt[i] = 0;
            if (i<VECTOR_LENGTH/8) ADD2_data_nxt[i] = 0;
        end
    end else begin
        // Stage 1 - (1)
        MUL_run_ff = i_run;
        for (int i = 0; i < VECTOR_LENGTH; i++) begin
            MUL_data_ff[i] = i_input[i] * i_weight[i];
        end
        // Stage 1 - (2)
        ADD0_run_nxt = MUL_run_ff;
        for (int i = 0; i < VECTOR_LENGTH/2; i++) begin
            ADD0_data_nxt[i] = MUL_data_ff[i] + MUL_data_ff[VECTOR_LENGTH - i - 1];
        end
        // Stage 2
        ADD1_run_nxt = ADD0_run_ff;
        for (int i = 0; i < VECTOR_LENGTH/4; i++) begin
            ADD1_data_nxt[i] = ADD0_data_ff[i] + ADD0_data_ff[VECTOR_LENGTH/2 - i - 1];
        end
        // Stage 3
        ADD2_run_nxt = ADD1_run_ff;
        for (int i = 0; i < VECTOR_LENGTH/8; i++) begin
            ADD2_data_nxt[i] = ADD1_data_ff[i] + ADD1_data_ff[VECTOR_LENGTH/4 - i - 1];
        end
        // Stage 4
        o_result_ff = (ADD2_run_ff) ? ADD2_data_ff[0] + ADD2_data_ff[1] : 0;
        o_pipe_status_ff = {ADD2_run_ff,ADD1_run_ff,ADD0_run_ff,MUL_run_ff};
    end
end


endmodule
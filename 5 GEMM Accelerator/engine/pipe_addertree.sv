// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : pipe_addertree.sv
// Author        : Castlab
//				         Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: Pipelined Adder-Tree module
// -FHDR------------------------------------------------------------

module pipe_addertree
  import kernel_pkg::*;
(
  input  logic                                      clk,
  input  logic                                      reset,

  // Adder-tree status
  output logic                                      at_status,    // 0 : idle, 1 : busy
  input  logic                                      at_accum,

  // Adder-tree data
  input  logic [VECTOR_LENGTH-1:0][DATA_WIDTH-1:0]  at_i_data,      // vector_length = 16, data_width = 32
  input  logic [VECTOR_LENGTH-1:0]                  at_i_valid,
  input  logic [VECTOR_LENGTH-1:0][DATA_WIDTH-1:0]  at_w_data,
  input  logic [VECTOR_LENGTH-1:0]                  at_w_valid,
  output logic [DATA_WIDTH-1:0]                     at_o_data,
  output logic                                      at_o_valid
);

//////////////////////////////////////////////////////////////////////////

localparam SIMD_LATENCY     = 6;

logic stage1_run_ff, stage2_run_ff, stage3_run_ff, stage4_run_ff, stage5_run_ff, stage6_run_ff;
logic stage2_run_nxt, stage3_run_nxt, stage4_run_nxt, stage5_run_nxt, stage6_run_nxt;
logic stage12_accum_ff, stage12_accum_nxt;
logic stage23_accum_ff, stage23_accum_nxt;
logic stage34_accum_ff, stage34_accum_nxt;
logic stage45_accum_ff, stage45_accum_nxt;
logic stage56_accum_ff, stage56_accum_nxt;
logic [VECTOR_LENGTH-1:0][DATA_WIDTH-1:0]       stage12_ff, stage12_nxt;    // 16 * 32
logic [VECTOR_LENGTH/2-1:0][DATA_WIDTH-1:0]     stage23_ff, stage23_nxt;    // 8 * 32
logic [VECTOR_LENGTH/4-1:0][DATA_WIDTH-1:0]     stage34_ff, stage34_nxt;    // 4 * 32
logic [VECTOR_LENGTH/8-1:0][DATA_WIDTH-1:0]     stage45_ff, stage45_nxt;    // 2 * 32
logic [VECTOR_LENGTH/16-1:0][DATA_WIDTH-1:0]    stage56_ff, stage56_nxt;    // 1 * 32
logic [DATA_WIDTH-1:0]                          prev_result_ff, prev_result_nxt;
logic [VECTOR_LENGTH-1:0]                  valid;

//////////////////////////////////////////////////////////////////////////
// SIMD status
//////////////////////////////////////////////////////////////////////////

assign at_status = (stage1_run_ff || stage2_run_ff || stage3_run_ff || stage4_run_ff || stage5_run_ff || stage6_run_ff) ? 1 : 0;

//////////////////////////////////////////////////////////////////////////
// Control signal
//////////////////////////////////////////////////////////////////////////

always_ff @ (posedge clk) begin
    // Stage 1
    stage12_accum_ff <= stage12_accum_nxt;
    stage12_ff <= stage12_nxt;
    // Stage 2
    stage2_run_ff <= stage2_run_nxt;
    stage23_accum_ff <= stage23_accum_nxt;
    stage23_ff <= stage23_nxt;
    // Stage 3
    stage3_run_ff <= stage3_run_nxt;
    stage34_accum_ff <= stage34_accum_nxt;
    stage34_ff <= stage34_nxt;
    // Stage 4
    stage4_run_ff <= stage4_run_nxt;
    stage45_accum_ff <= stage45_accum_nxt;
    stage45_ff <= stage45_nxt;
    // Stage 5
    stage5_run_ff <= stage5_run_nxt;
    stage56_accum_ff <= stage56_accum_nxt;
    stage56_ff <= stage56_nxt;
    // Stage 6
    stage6_run_ff <= stage6_run_nxt;
    prev_result_ff <= prev_result_nxt;
end

//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////

always_comb begin
    if (reset) begin
        stage2_run_nxt = 0;
        stage3_run_nxt = 0;
        stage4_run_nxt = 0;
        stage5_run_nxt = 0;
        stage6_run_nxt = 0;
        stage12_accum_nxt = 0;
        stage23_accum_nxt = 0;
        stage34_accum_nxt = 0;
        stage45_accum_nxt = 0;
        stage56_accum_nxt = 0;
        for (int i=0; i<VECTOR_LENGTH; i++) begin
            stage12_nxt[i] = 0;
            if (i<VECTOR_LENGTH/2) stage23_nxt[i] = 0;
            if (i<VECTOR_LENGTH/4) stage34_nxt[i] = 0;
            if (i<VECTOR_LENGTH/8) stage45_nxt[i] = 0;
            if (i<VECTOR_LENGTH/16) stage56_nxt[i] = 0;
        end
        prev_result_nxt = 0;
        valid = 0;
    end else begin
        // Stage1 : Multiplier //
        // check the input is valid
        valid = 1;
        for (int i=0; i<VECTOR_LENGTH; i++) begin
            if (at_i_valid[i] == 0) valid = 0;
            if (at_w_valid[i] == 0) valid = 0;
        end
        stage1_run_ff = (valid == 1) ? 1 : 0;
        stage2_run_nxt = stage1_run_ff;
        // Calculation
        stage12_accum_nxt = at_accum;
        for (int i=0; i<VECTOR_LENGTH; i++) begin
            stage12_nxt[i] = at_i_data[i] * at_w_data[i];
        end
        
        // Stage2 : Level1 Adder tree //
        stage3_run_nxt = stage2_run_ff;
        stage23_accum_nxt = stage12_accum_ff;
        for (int i=0; i<VECTOR_LENGTH/2; i++) begin
            stage23_nxt[i] = stage12_ff[i] + stage12_ff[VECTOR_LENGTH - i - 1];
        end
        
        // Stage3 : Level2 Adder tree //
        stage4_run_nxt = stage3_run_ff;
        stage34_accum_nxt = stage23_accum_ff;
        for (int i=0; i<VECTOR_LENGTH/4; i++) begin
            stage34_nxt[i] = stage23_ff[i] + stage23_ff[VECTOR_LENGTH/2 - i - 1];
        end
        
        // Stage4 : Level3 Adder tree //
        stage5_run_nxt = stage4_run_ff;
        stage45_accum_nxt = stage34_accum_ff;
        for (int i=0; i<VECTOR_LENGTH/8; i++) begin
            stage45_nxt[i] = stage34_ff[i] + stage34_ff[VECTOR_LENGTH/4 - i - 1];
        end
        
        // Stage5 : Level4 Adder tree //
        stage6_run_nxt = stage5_run_ff;
        stage56_accum_nxt = stage45_accum_ff;
        for (int i=0; i<VECTOR_LENGTH/16; i++) begin
            stage56_nxt[i] = stage45_ff[i] + stage45_ff[VECTOR_LENGTH/8 - i - 1];
        end
        
        // Stage6 : Accumulator //
        // Save Result
        if (stage56_accum_ff) prev_result_nxt = prev_result_ff + stage56_ff[0];
        else prev_result_nxt = stage56_ff[0];
        // Calculation
        if (stage56_accum_ff) begin
            at_o_data = stage56_ff[0] + prev_result_ff;
        end else begin
            at_o_data = stage56_ff[0];
        end
        at_o_valid = (stage6_run_ff) ? 1 : 0;
    end
end
endmodule
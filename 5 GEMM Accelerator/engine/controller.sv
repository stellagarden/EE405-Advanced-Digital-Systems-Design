// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : controller.sv
// Author        : Castlab
//				         Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: Controller for pipelined adder-tree
// -FHDR------------------------------------------------------------

module controller
  import kernel_pkg::*;
(
  input  logic                                      clk,
  input  logic                                      reset,
  
  // Engine status
  input  logic                                      ap_start,
  output logic                                      ap_idle,
  output logic                                      ap_done,

  // GEMM dimension
  input  logic [DIM_L_WIDTH-1:0]                    dim_l,
  input  logic [DIM_M_WIDTH-1:0]                    dim_m,
  input  logic [DIM_N_WIDTH-1:0]                    dim_n,

  // Control memory
  output logic                                      i_rd_en,
  output logic [IMEM_ADDR_WIDTH-1:0]                i_rd_addr,
  input  logic [IMEM_DATA_WIDTH-1:0]                i_rd_data,	  // 32 * 16
  input  logic                                      i_rd_valid,
  output logic                                      w_rd_en,
  output logic [WMEM_ADDR_WIDTH-1:0]                w_rd_addr,
  input  logic [WMEM_DATA_WIDTH-1:0]                w_rd_data,	  // 32 * 16
  input  logic                                      w_rd_valid,
  output logic                                      o_wr_en,
  output logic [OMEM_ADDR_WIDTH-1:0]                o_wr_addr,	  // 32
  output logic [OMEM_DATA_WIDTH-1:0]                o_wr_data,

  // Control pipelinied adder-tree
  input  logic                                      at_status,   // 0 : idle, 1 : busy
  output logic                                      at_accum,
  output logic [VECTOR_LENGTH-1:0][DATA_WIDTH-1:0]  at_i_data,	  // 32 * 16
  output logic [VECTOR_LENGTH-1:0]                  at_i_valid,
  output logic [VECTOR_LENGTH-1:0][DATA_WIDTH-1:0]  at_w_data,	  // 32 * 16
  output logic [VECTOR_LENGTH-1:0]                  at_w_valid,
  input  logic [DATA_WIDTH-1:0]                     at_o_data,	  // 32
  input  logic                                      at_o_valid
);

//////////////////////////////////////////////////////////////////////////

localparam SIMD_LATENCY     = 6;

logic                       ap_idle_ff, ap_idle_nxt,at_accum_ff,at_accum_nxt;
logic [DIM_L_WIDTH-1:0]     dim_l_ff, dim_l_nxt;
logic [DIM_M_WIDTH-1:0]     dim_m_ff, dim_m_nxt;
logic [DIM_N_WIDTH-1:0]     dim_n_ff, dim_n_nxt;
logic [DIM_L_WIDTH-1:0]     dim_r_ff, dim_r_nxt;
logic [DIM_L_WIDTH-1:0]     r_ff,r_nxt;
logic [DIM_M_WIDTH-1:0]     in_m_ff,in_m_nxt;
logic [DIM_N_WIDTH-1:0]     in_n_ff,in_n_nxt;
logic [DIM_M_WIDTH-1:0]     out_m_ff,out_m_nxt;
logic [DIM_N_WIDTH-1:0]     out_n_ff,out_n_nxt;
logic [DIM_L_WIDTH-1:0]     out_r_ff,out_r_nxt;
logic [VECTOR_LENGTH-1:0]   at_i_valid_ff, at_i_valid_nxt;
logic [VECTOR_LENGTH-1:0]   at_w_valid_ff, at_w_valid_nxt;


// Status
enum logic [1:0] {
    STATE_IDLE,
    STATE_RUN,
    STATE_DONE
} state_ff, state_nxt;

assign ap_idle = ap_idle_ff;
assign at_accum = at_accum_ff;
assign at_i_valid = at_i_valid_ff;
assign at_w_valid = at_w_valid_ff;

//////////////////////////////////////////////////////////////////////////

always_ff @ (posedge clk) begin
    state_ff <= state_nxt;
    ap_idle_ff <= ap_idle_nxt;
    at_accum_ff <= at_accum_nxt;
    dim_l_ff <= dim_l_nxt;
    dim_m_ff <= dim_m_nxt;
    dim_n_ff <= dim_n_nxt;
    dim_r_ff <= dim_r_nxt;
    r_ff <= r_nxt;
    in_m_ff <= in_m_nxt;
    in_n_ff <= in_n_nxt;
    out_m_ff <= out_m_nxt;
    out_n_ff <= out_n_nxt;
    out_r_ff <= out_r_nxt;
    at_i_valid_ff <= at_i_valid_nxt;
    at_w_valid_ff <= at_w_valid_nxt;
end

always_comb begin
    if (reset) begin
        state_nxt = STATE_IDLE;
        ap_idle_nxt = 1;
        at_accum_nxt = 0;
        ap_done = 0;
        dim_l_nxt = 0;
        dim_m_nxt = 0;
        dim_n_nxt = 0;
        dim_r_nxt = 0;
        r_nxt = 0;
        in_m_nxt = 0;
        in_n_nxt = 0;
        out_m_nxt = 0;
        out_n_nxt = 0;
        out_r_nxt = 0;
        i_rd_en = 0;
        i_rd_addr = 0;
        w_rd_en = 0;
        w_rd_addr = 0;
        o_wr_en = 0;
        o_wr_addr = 0;
        o_wr_data = 0;
        at_i_data = 0;
        at_i_valid_nxt = 0;
        at_w_data = 0;
        at_w_valid_nxt = 0;
    end else begin
        state_nxt = state_ff;
        ap_idle_nxt = 1;
        at_accum_nxt = 0;
        ap_done = 0;
        dim_l_nxt = dim_l_ff;
        dim_m_nxt = dim_m_ff;
        dim_n_nxt = dim_n_ff;
        dim_r_nxt = dim_r_ff;
        r_nxt = r_ff;
        in_m_nxt = in_m_ff;
        in_n_nxt = in_n_ff;
        out_m_nxt = out_m_ff;
        out_n_nxt = out_n_ff;
        out_r_nxt = out_r_ff;
        
        i_rd_en = 0;
        i_rd_addr = 0;
        w_rd_en = 0;
        w_rd_addr = 0;
        o_wr_en = 0;
        o_wr_addr = 0;
        o_wr_data = 0;
        
        at_i_data = 0;
        at_i_valid_nxt = 0;
        at_w_data = 0;
        at_w_valid_nxt = 0;
        
        case (state_ff)
            STATE_IDLE: begin
                if (ap_start) begin
                    state_nxt = STATE_RUN;
                    ap_idle_nxt = 0;
                    dim_l_nxt = dim_l;
                    dim_m_nxt = dim_m;
                    dim_n_nxt = dim_n;
                    dim_r_nxt = dim_l / VECTOR_LENGTH;
                    r_nxt = 0;
                    in_m_nxt = 0;
                    in_n_nxt = 0;
                    out_m_nxt = 0;
                    out_n_nxt = 0;
                    out_r_nxt = 0;
                end
            end
            
            STATE_RUN: begin
                ap_idle_nxt = 0;
                // Increase input matrix indeces
                if (r_ff < dim_r_ff-1) begin
                    r_nxt = r_ff + 1;
                end else begin
                    if (in_m_ff < dim_m_ff-1) begin
                        in_m_nxt = in_m_ff + 1;
                        r_nxt = 0;
                    end else begin
                        if (in_n_ff < dim_n_ff-1) begin
                            in_n_nxt = in_n_ff + 1;
                            in_m_nxt = 0;
                            r_nxt = 0;
                        end else begin
                            in_n_nxt = dim_n_ff;
                            in_m_nxt = dim_m_ff;
                            r_nxt = dim_r_ff;
                        end
                    end
                end
                // Read input values
                if (r_ff < dim_r_ff && in_m_ff < dim_m_ff && in_n_ff < dim_n_ff) begin
                    i_rd_en = 1;
                    i_rd_addr = in_n_ff*dim_r_ff + r_ff;
                    w_rd_en = 1;
                    w_rd_addr = in_m_ff*dim_r_ff + r_ff;
                    if (r_ff > 0) at_accum_nxt = 1;
                    for (int i=0;i<VECTOR_LENGTH;i++) begin
                        at_i_valid_nxt[i] = 1;
                    end
                    for (int i=0;i<VECTOR_LENGTH;i++) begin
                        at_w_valid_nxt[i] = 1;
                    end
                end
                // Insert to pipe_addertree
                if (i_rd_valid) begin
                    at_i_data[0] = i_rd_data[31:0];
                    at_i_data[1] = i_rd_data[63:32];
                    at_i_data[2] = i_rd_data[95:64];
                    at_i_data[3] = i_rd_data[127:96];
                    at_i_data[4] = i_rd_data[159:128];
                    at_i_data[5] = i_rd_data[191:160];
                    at_i_data[6] = i_rd_data[223:192];
                    at_i_data[7] = i_rd_data[255:224];
                    at_i_data[8] = i_rd_data[287:256];
                    at_i_data[9] = i_rd_data[319:288];
                    at_i_data[10] = i_rd_data[351:320];
                    at_i_data[11] = i_rd_data[383:352];
                    at_i_data[12] = i_rd_data[415:384];
                    at_i_data[13] = i_rd_data[447:416];
                    at_i_data[14] = i_rd_data[479:448];
                    at_i_data[15] = i_rd_data[511:480];
                end
                if (w_rd_valid) begin
                    at_w_data[0] = w_rd_data[31:0];
                    at_w_data[1] = w_rd_data[63:32];
                    at_w_data[2] = w_rd_data[95:64];
                    at_w_data[3] = w_rd_data[127:96];
                    at_w_data[4] = w_rd_data[159:128];
                    at_w_data[5] = w_rd_data[191:160];
                    at_w_data[6] = w_rd_data[223:192];
                    at_w_data[7] = w_rd_data[255:224];
                    at_w_data[8] = w_rd_data[287:256];
                    at_w_data[9] = w_rd_data[319:288];
                    at_w_data[10] = w_rd_data[351:320];
                    at_w_data[11] = w_rd_data[383:352];
                    at_w_data[12] = w_rd_data[415:384];
                    at_w_data[13] = w_rd_data[447:416];
                    at_w_data[14] = w_rd_data[479:448];
                    at_w_data[15] = w_rd_data[511:480];
                end
                // Save calculation result
                if (at_o_valid) begin
                    // Increase output matrix indeces
                    if (out_r_ff < dim_r_ff-1) begin
                        out_r_nxt = out_r_ff + 1;
                    end else begin
                        if (out_m_ff < dim_m_ff-1) begin
                            out_m_nxt = out_m_ff + 1;
                            out_r_nxt = 0;
                        end else begin
                            if (out_n_ff < dim_n_ff -1) begin
                                out_n_nxt = out_n_ff + 1;
                                out_m_nxt = 0;
                                out_r_nxt = 0;
                            end else begin
                                state_nxt = STATE_DONE;
                            end
                        end
                    end
                    if (out_r_ff == dim_r_ff-1) begin
                        o_wr_en = 1;
                        o_wr_addr = (out_n_ff*dim_m_ff)+out_m_ff;
                        o_wr_data = at_o_data;
                    end
                end
            end
                
            STATE_DONE: begin
                state_nxt = STATE_IDLE;
                ap_idle_nxt = 0;
                dim_l_nxt = 0;
                dim_m_nxt = 0;
                dim_n_nxt = 0;
                dim_r_nxt = 0;
                r_nxt = 0;
                in_m_nxt = 0;
                in_n_nxt = 0;
                out_m_nxt = 0;
                out_n_nxt = 0;
                out_r_nxt = 0;
                ap_done = 1;
            end
        endcase
    end
end

endmodule
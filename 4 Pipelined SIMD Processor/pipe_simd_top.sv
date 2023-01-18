
// Filename      : pipe_simd_top.sv
// Author        : 
//				   Seokchan Song 	< ssong0410@kaist.ac.kr >
// -----------------------------------------------------------------
// Description: 
// Top unit for pipelined SIMD processor 

// o_done : 1 when a value is given through o_data
// o_pipe_status : Each bit indicates activation of the pipeline register. {ADD2, ADD1, ADD0, MUL}

// -FHDR------------------------------------------------------------

`timescale 1ns / 1ps

import PS_pkg::*;
module DUT
(
    input  logic								    clk,
    input  logic								    reset,

    input  logic [INST_WIDTH -1:0]		            i_instruction   ,
    input  logic [VECTOR_LENGTH*DATA_WIDTH -1:0]    i_data          ,
    output logic [DATA_WIDTH -1:0]    o_data          ,   
    
	output logic								    o_done          ,
	output logic [3:0]		                        o_pipe_status   ,
	output logic [2:0]                              o_stall
);

/* TO DO: Declare your logic here. */

logic [INST_WIDTH -1:0]		        i_instruction_ff, i_instruction_nxt;
logic   [DATA_WIDTH-1:0]        weight_vector_ff        [0:VECTOR_LENGTH-1];
logic   [DATA_WIDTH-1:0]        weight_vector_nxt       [0:VECTOR_LENGTH-1];
logic   [DATA_WIDTH-1:0]        dot_input               [0:VECTOR_LENGTH-1];
logic                           o_imem_wen,o_imem_cen,o_omem_wen,o_omem_cen,o_ovmem_wen,o_ovmem_cen,o_run;
logic                           i_imem_wen,i_imem_cen,i_omem_wen,i_omem_cen,i_ovmem_wen,i_ovmem_cen,i_run;
logic                           reset_ff,manual_reset_ff,manual_reset_nxt,o_done_ff,o_done_op1_ff;
logic [DATA_WIDTH*VECTOR_LENGTH-1:0]          imem_rddata,imem_wrdata,omem_rddata,omem_wrdata,ovmem_rddata,ovmem_wrdata,o_data_ff;
logic   [DATA_WIDTH-1:0]                    result;
logic [ADDR_WIDTH-1:0]          imem_addr,omem_addr,ovmem_addr;
logic o_stall_ff;
logic [2:0] o_stall_count_ff,o_stall_count_nxt;

// Pipeline registers for operation 1
logic [3:0] timer_ff, timer_nxt;
logic [INST_WIDTH -1:0]		        DOT_PRODUCT_1_run_ff, DOT_PRODUCT_2_run_ff, DOT_PRODUCT_3_run_ff, DOT_PRODUCT_4_run_ff, DONE_run_ff;
logic [INST_WIDTH -1:0]		        DOT_PRODUCT_1_run_nxt, DOT_PRODUCT_2_run_nxt, DOT_PRODUCT_3_run_nxt, DOT_PRODUCT_4_run_nxt, DONE_run_nxt;
logic [INST_WIDTH -1:0]		        DOT_PRODUCT_1_inst_ff, DOT_PRODUCT_2_inst_ff, DOT_PRODUCT_3_inst_ff, DOT_PRODUCT_4_inst_ff, DONE_inst_ff;
logic [INST_WIDTH -1:0]		        DOT_PRODUCT_1_inst_nxt, DOT_PRODUCT_2_inst_nxt, DOT_PRODUCT_3_inst_nxt, DOT_PRODUCT_4_inst_nxt, DONE_inst_nxt;

// Status
enum logic [2:0] {
    STATE_ID,
    STATE_OP126,
    STATE_DONE,
    STATE_OP5_DONE
} state_ff, state_nxt;

assign reset_ff = reset | manual_reset_ff;
assign o_done = o_done_ff | DONE_run_ff;
assign o_data = o_data_ff;
assign o_stall = o_stall_ff;

// If stall, disable all the modules
//assign i_imem_wen = stall ? 0 : o_imem_wen;
//assign i_imem_cen = stall ? 0 : o_imem_cen;
//assign i_omem_wen = stall ? 0 : o_omem_wen;
//assign i_omem_cen = stall ? 0 : o_omem_cen;
//assign i_ovmem_wen = stall ? 0 : o_ovmem_wen;
//assign i_ovmem_cen = stall ? 0 : o_ovmem_cen;
//assign i_run = stall ? 0 : o_run;
assign i_imem_wen = o_imem_wen;
assign i_imem_cen = o_imem_cen;
assign i_omem_wen = o_omem_wen;
assign i_omem_cen = o_omem_cen;
assign i_ovmem_wen = o_ovmem_wen;
assign i_ovmem_cen = o_ovmem_cen;
assign i_run = o_run;

/* TO DO: Write sequential code for your design here. */
always_ff @(posedge clk) begin
    if (~o_stall_ff) begin
        i_instruction_ff <= i_instruction_nxt;
        state_ff <= state_nxt;
        weight_vector_ff <= weight_vector_nxt;
        manual_reset_ff <= manual_reset_nxt;
        
        // Op1 pipeline register
        timer_ff <= timer_nxt;
        DOT_PRODUCT_1_run_ff <= DOT_PRODUCT_1_run_nxt;
        DOT_PRODUCT_1_inst_ff <= DOT_PRODUCT_1_inst_nxt;
    end else begin
        o_stall_count_ff <= o_stall_count_nxt;
        DOT_PRODUCT_1_run_ff <= DOT_PRODUCT_1_run_nxt;
        DOT_PRODUCT_1_inst_ff <= DOT_PRODUCT_1_inst_nxt;
    end
end

/* TO DO: Write combinational code for your design here. */
always_comb begin
    if (reset_ff) begin
        manual_reset_nxt = 0;
        i_instruction_nxt = 0;
        o_done_ff = 0;
        o_data_ff = 0;
        state_nxt = STATE_ID;
        timer_nxt = 0;
        DOT_PRODUCT_1_run_nxt = 0;
        DOT_PRODUCT_1_inst_nxt = 0;
        for (int i=0;i<VECTOR_LENGTH;i++) begin
            weight_vector_nxt[i] = 0;
        end
        o_stall_ff = 0;
    end else if (o_stall_ff) begin
        o_stall_count_nxt = o_stall_count_ff - 1;
        DOT_PRODUCT_1_run_nxt = 0;
        DOT_PRODUCT_1_inst_nxt = 0;
        ovmem_addr = i_instruction[15:8];
        if (o_stall_count_ff == 0) begin
            o_stall_ff = 0;
            timer_nxt = 5;
            DOT_PRODUCT_1_run_nxt = 1;
            DOT_PRODUCT_1_inst_nxt = i_instruction;
            ovmem_addr = i_instruction[15:8];
        end
    end else begin
        i_instruction_nxt = i_instruction;
        manual_reset_nxt = 0;
        o_done_ff = 0;
        state_nxt = state_ff;
        weight_vector_nxt = weight_vector_ff;
        timer_nxt = 0;
        DOT_PRODUCT_1_run_nxt = 0;
        DOT_PRODUCT_1_inst_nxt = 0;
        
        case(state_ff)            
            STATE_ID: begin
                if (i_instruction_ff != i_instruction) begin
                    case(i_instruction[18:16])
                        // operation 0
                        3'b000: begin
                            state_nxt = STATE_DONE; // INST_DEC: state_nxt = STATE_ID
                            manual_reset_nxt = 1;
                        end
                        // operation 1
                        3'b001: begin
                            state_nxt = STATE_OP126;
                            timer_nxt = 5;
                            DOT_PRODUCT_1_run_nxt = 1;
                            DOT_PRODUCT_1_inst_nxt = i_instruction;
                            imem_addr = i_instruction[15:8];
                        end
                        // operation 2
                        3'b010: begin
                            state_nxt = STATE_OP126;
                            timer_nxt = 5;
                            DOT_PRODUCT_1_run_nxt = 1;
                            DOT_PRODUCT_1_inst_nxt = i_instruction;
                            ovmem_addr = i_instruction[15:8];
                        end
                        // operation 3
                        3'b011: begin
                            state_nxt = STATE_DONE;
                            imem_addr = i_instruction[7:0];
                            imem_wrdata = i_data;
                        end
                        // operation 4
                        3'b100: begin
                            state_nxt = STATE_DONE;
                            weight_vector_nxt[0] = i_data[15:0];
                            weight_vector_nxt[1] = i_data[31:16];
                            weight_vector_nxt[2] = i_data[47:32];
                            weight_vector_nxt[3] = i_data[63:48];
                            weight_vector_nxt[4] = i_data[79:64];
                            weight_vector_nxt[5] = i_data[95:80];
                            weight_vector_nxt[6] = i_data[111:96];
                            weight_vector_nxt[7] = i_data[127:112];
                            weight_vector_nxt[8] = i_data[143:128];
                            weight_vector_nxt[9] = i_data[159:144];
                            weight_vector_nxt[10] = i_data[175:160];
                            weight_vector_nxt[11] = i_data[191:176];
                            weight_vector_nxt[12] = i_data[207:192];
                            weight_vector_nxt[13] = i_data[223:208];
                            weight_vector_nxt[14] = i_data[239:224];
                            weight_vector_nxt[15] = i_data[255:240];
                        end
                        // operation 5
                        3'b101: begin
                            state_nxt = STATE_OP5_DONE;
                            omem_addr = i_instruction[15:8];
                        end
                        // operation 6
                        3'b110: begin
                            state_nxt = STATE_OP126;
                            timer_nxt = 5;
                            DOT_PRODUCT_1_run_nxt = 1;
                            DOT_PRODUCT_1_inst_nxt = i_instruction;
                            imem_addr = i_instruction[15:8];
                        end
                    endcase
                end
            end
            
            STATE_DONE: begin
                state_nxt = STATE_ID;
                o_done_ff = 1;
            end
            
            // Pipelined Op 1,2,6
            STATE_OP126: begin
                if (i_instruction_ff != i_instruction) begin
                    case(i_instruction[18:16])
                        // operation 1
                        3'b001: begin
                            timer_nxt = 5;
                            DOT_PRODUCT_1_run_nxt = 1;
                            DOT_PRODUCT_1_inst_nxt = i_instruction;
                            imem_addr = i_instruction[15:8];
                        end
                        // operation 2
                        3'b010: begin
                            if (DOT_PRODUCT_1_inst_ff[18:16] == 3'b110) begin
                                o_stall_ff = 1;
                                o_stall_count_nxt = 3;
                            end else if (DOT_PRODUCT_2_inst_ff[18:16] == 3'b110) begin
                                o_stall_ff = 1;
                                o_stall_count_nxt = 2;
                            end else if (DOT_PRODUCT_3_inst_ff[18:16] == 3'b110) begin
                                o_stall_ff = 1;
                                o_stall_count_nxt = 1;
                            end else if (DOT_PRODUCT_4_inst_ff[18:16] == 3'b110) begin
                                o_stall_ff = 1;
                                o_stall_count_nxt = 0;
                            end else begin
                                timer_nxt = 5;
                                DOT_PRODUCT_1_run_nxt = 1;
                                DOT_PRODUCT_1_inst_nxt = i_instruction;
                                ovmem_addr = i_instruction[15:8];
                            end
                        end
                        // operation 6
                        3'b110: begin
                            timer_nxt = 5;
                            DOT_PRODUCT_1_run_nxt = 1;
                            DOT_PRODUCT_1_inst_nxt = i_instruction;
                            imem_addr = i_instruction[15:8];
                        end
                    endcase
                end else begin
                    timer_nxt = timer_ff - 1;
                    DOT_PRODUCT_1_run_nxt = 0;
                    DOT_PRODUCT_1_inst_nxt = i_instruction;
                end
                if (timer_ff == 1) state_nxt = STATE_ID;
            end
            
            STATE_OP5_DONE: begin
                state_nxt = STATE_ID;
                o_data_ff = omem_rddata;
                o_done_ff = 1;
            end
        endcase
    end
end

// Pipelined Operation 1,2
always_ff @(posedge clk) begin
    if (reset_ff) begin
        DOT_PRODUCT_2_run_ff <= DOT_PRODUCT_2_run_nxt;
        DOT_PRODUCT_2_inst_ff <= DOT_PRODUCT_2_inst_nxt;
        DOT_PRODUCT_3_run_ff <= DOT_PRODUCT_3_run_nxt;
        DOT_PRODUCT_3_inst_ff <= DOT_PRODUCT_3_inst_nxt;
        DOT_PRODUCT_4_run_ff <= DOT_PRODUCT_4_run_nxt;
        DOT_PRODUCT_4_inst_ff <= DOT_PRODUCT_4_inst_nxt;
        DONE_run_ff <= DONE_run_nxt;
        DONE_inst_ff <= DONE_inst_nxt;
    end else begin
        if (state_ff == STATE_OP126) begin
            // cycle 2
            DOT_PRODUCT_2_run_ff <= DOT_PRODUCT_2_run_nxt;
            DOT_PRODUCT_2_inst_ff <= DOT_PRODUCT_2_inst_nxt;
            // cycle 3
            DOT_PRODUCT_3_run_ff <= DOT_PRODUCT_3_run_nxt;
            DOT_PRODUCT_3_inst_ff <= DOT_PRODUCT_3_inst_nxt;
            // cycle 4
            DOT_PRODUCT_4_run_ff <= DOT_PRODUCT_4_run_nxt;
            DOT_PRODUCT_4_inst_ff <= DOT_PRODUCT_4_inst_nxt;
            // cycle 5
            DONE_run_ff <= DONE_run_nxt;
            DONE_inst_ff <= DONE_inst_nxt;
            // cycle 6
        end
    end
end

always_comb begin
    if (reset_ff) begin
        DOT_PRODUCT_2_run_nxt = 0;
        DOT_PRODUCT_3_run_nxt = 0;
        DOT_PRODUCT_4_run_nxt = 0;
        DOT_PRODUCT_2_inst_nxt = 0;
        DOT_PRODUCT_3_inst_nxt = 0;
        DOT_PRODUCT_4_inst_nxt = 0;
        DONE_run_nxt = 0;
        DONE_inst_nxt = 0;
    end else begin
        // cycle 2
        DOT_PRODUCT_2_run_nxt = DOT_PRODUCT_1_run_ff;
        DOT_PRODUCT_2_inst_nxt = DOT_PRODUCT_1_inst_ff;
        if (DOT_PRODUCT_1_inst_ff[18:16] == 3'b001 || DOT_PRODUCT_1_inst_ff[18:16] == 3'b110) begin
            // Operation 1, 6
            dot_input[0] = imem_rddata[15:0];
            dot_input[1] = imem_rddata[31:16];
            dot_input[2] = imem_rddata[47:32];
            dot_input[3] = imem_rddata[63:48];
            dot_input[4] = imem_rddata[79:64];
            dot_input[5] = imem_rddata[95:80];
            dot_input[6] = imem_rddata[111:96];
            dot_input[7] = imem_rddata[127:112];
            dot_input[8] = imem_rddata[143:128];
            dot_input[9] = imem_rddata[159:144];
            dot_input[10] = imem_rddata[175:160];
            dot_input[11] = imem_rddata[191:176];
            dot_input[12] = imem_rddata[207:192];
            dot_input[13] = imem_rddata[223:208];
            dot_input[14] = imem_rddata[239:224];
            dot_input[15] = imem_rddata[255:240];
        end else if (DOT_PRODUCT_1_inst_ff[18:16] == 3'b010) begin
            // Operation 2
            dot_input[0] = ovmem_rddata[15:0];
            dot_input[1] = ovmem_rddata[31:16];
            dot_input[2] = ovmem_rddata[47:32];
            dot_input[3] = ovmem_rddata[63:48];
            dot_input[4] = ovmem_rddata[79:64];
            dot_input[5] = ovmem_rddata[95:80];
            dot_input[6] = ovmem_rddata[111:96];
            dot_input[7] = ovmem_rddata[127:112];
            dot_input[8] = ovmem_rddata[143:128];
            dot_input[9] = ovmem_rddata[159:144];
            dot_input[10] = ovmem_rddata[175:160];
            dot_input[11] = ovmem_rddata[191:176];
            dot_input[12] = ovmem_rddata[207:192];
            dot_input[13] = ovmem_rddata[223:208];
            dot_input[14] = ovmem_rddata[239:224];
            dot_input[15] = ovmem_rddata[255:240];
        end
        // cycle 3
        DOT_PRODUCT_3_run_nxt = DOT_PRODUCT_2_run_ff;
        DOT_PRODUCT_3_inst_nxt = DOT_PRODUCT_2_inst_ff;
        // cycle 4
        DOT_PRODUCT_4_run_nxt = DOT_PRODUCT_3_run_ff;
        DOT_PRODUCT_4_inst_nxt = DOT_PRODUCT_3_inst_ff;
        // cycle 5
        DONE_run_nxt = DOT_PRODUCT_4_run_ff;
        DONE_inst_nxt = DOT_PRODUCT_4_inst_ff;
        if (DOT_PRODUCT_4_inst_ff[18:16] == 3'b001 || DOT_PRODUCT_4_inst_ff[18:16] == 3'b010) begin
            // Operation 1,2
            omem_wrdata = result;
            omem_addr = DOT_PRODUCT_4_inst_ff[7:0];
        end else if (DOT_PRODUCT_4_inst_ff[18:16] == 3'b110) begin
            // Operation 6
            ovmem_wrdata = result;
            ovmem_addr = DOT_PRODUCT_4_inst_ff[7:0];
        end
        // cycle 6
        
    end
end


/* TO DO: Instantiate your design here. */
INST_DEC
#(
    
)
decoder
(
    .clk                                        ( clk					),
    .reset                                      ( reset_ff					),

    .i_instruction                              ( i_instruction					),

    .o_imem_wen                                 (  o_imem_wen					),
    .o_imem_cen                                 (  o_imem_cen				),

    .o_omem_wen                                 (  o_omem_wen				),
    .o_omem_cen                                 (  o_omem_cen				),
    
    .o_ovmem_wen                                 (  o_ovmem_wen				),
    .o_ovmem_cen                                 (  o_ovmem_cen				),

    .o_run                                      (  o_run                     ),
    .o_stall                                    (  stall                     )
);

// Memory
SRAM
#(
    .AWIDTH                                     (ADDR_WIDTH                 ),
    .DWIDTH                                     (VECTOR_LENGTH * DATA_WIDTH )
)
IMEM
(
    .clk                                        (  clk 						),

    .cen                                        ( i_imem_cen                   ),
    .wen                                        ( i_imem_wen                   ),
    .addr                                       ( imem_addr                          ),
    .wrdata                                     ( imem_wrdata                ),
    .rddata                                     ( imem_rddata                  )
);

SRAM
#(
    .AWIDTH                                     (ADDR_WIDTH 				),
    .DWIDTH                                     (VECTOR_LENGTH * DATA_WIDTH )
)
OMEM
(
    .clk                                        ( clk  						),

    .cen                                        ( i_omem_cen                   ),
    .wen                                        ( i_omem_wen                  ),
    .addr                                       ( omem_addr                         ),
    .wrdata                                     (  omem_wrdata               ),
    .rddata                                     (  omem_rddata              )
);

SRAM
#(
    .AWIDTH                                     (ADDR_WIDTH 				),
    .DWIDTH                                     (VECTOR_LENGTH * DATA_WIDTH )                
)
OMEM_VECTOR
(
    .clk                                        (  clk						),

    .cen                                        ( i_ovmem_cen                   ),
    .wen                                        ( i_ovmem_wen               ),
    .addr                                       ( ovmem_addr                 ),
    .wrdata                                     ( ovmem_wrdata                  ),
    .rddata                                     ( ovmem_rddata              )
);


//SIMD UNIT
PIPE_SIMD
#(
    .DWIDTH                                     (  DATA_WIDTH                         )
)
pipe_simd_unit1
(
    .clk                                        ( clk					),
    .reset                                      ( reset_ff  						),

    .i_run                                      (  i_run                      ),

    .i_input                                    ( dot_input              ),
    .i_weight                                   ( weight_vector_ff              ),

    .o_result                                   ( result                 ),
    .o_pipe_status                              ( o_pipe_status                 )

);
endmodule

// Filename      : inst_dec.sv
// Author        : 
//				   Seokchan Song 	< ssong0410@kaist.ac.kr >
// -----------------------------------------------------------------
// Description: 
// Instruction decoder 
// (recommended) 3-bit opcode + 16-bit operand
// {18-16: opcode, 15-8: read mem addr, 7-0: write mem addr}

// operation 0 : reset.
// operation 1 : read data from IMEM and run inner product with weight vector. 
//               Store result in OMEM. Operand must contain {IMEM ADDR} and {OMEM ADDR}.
// operation 2 : read data from {OMEM_VECTOR} and run inner product with weight vector. 
//               Store result in OMEM. Operand must contain {OMEM_VECTOR ADDR} and {OMEM ADDR}
// operation 3 : Fetch input from tb_imem to IMEM write i_data into IMEM. operand will be {IMEM ADDR}.
// operation 4 : Fetch weight from tb_wmem to weight register. 
// operation 5 : read data from output OMEM and assign to o_data.  operand will be {OMEM ADDR} 
// operation 6 : 16 input vectors are sequentially read from a given {IMEM ADDR} to perform an inner product with a weight vector.
//               Store result in {OMEM_VECTOR ADDR}. Operand must contain {IMEM ADDR} and {OMEM_VECTOR ADDR}


// cen : cell enable siignal for each sram. LOW ACTIVATE SIGNAL
// wen : write enable siignal for each sram. LOW ACTIVATE SIGNAL
// o_run : activate signal for pipelined SIMD
// o_stall : stall signal for pipe_SIMD. only for week 2 

// -FHDR------------------------------------------------------------

`timescale 1ns / 1ps

import PS_pkg::*;
module INST_DEC
(
    input  logic								clk,
    input  logic								reset,


    input  logic [INST_WIDTH -1:0]		        i_instruction,
    
    //OUT_SIGNALS : Add signals for your design if you need
	output logic								o_imem_cen,
	output logic								o_imem_wen,

    output logic								o_omem_cen,
	output logic								o_omem_wen,
	
    output logic								o_ovmem_cen,
	output logic								o_ovmem_wen,

    output logic								o_run,
	output logic								o_stall
);

/* TO DO: Design your INST DECODER here.
        Your implementation should follow provided method. */
enum logic [2:0] {
    STATE_ID,
    STATE_RESET,
    STATE_OP126,
    STATE_DONE,
    STATE_OP5_DONE
} state_ff, state_nxt;

logic state_ff, o_imem_cen_ff, o_imem_wen_ff, o_omem_cen_ff, o_ovmem_cen_ff, o_ovmem_wen_ff;
logic state_nxt;
logic [INST_WIDTH -1:0]              i_instruction_ff, i_instruction_nxt; 

// Pipeline registers for operation 1,2,6
logic o_run_op126_ff, o_omem_cen_op126_ff, o_omem_wen_op126_ff, o_ovmem_cen_op126_ff, o_ovmem_wen_op126_ff;
logic [3:0] timer_ff, timer_nxt;
logic [INST_WIDTH -1:0]		        DOT_PRODUCT_1_run_ff, DOT_PRODUCT_2_run_ff, DOT_PRODUCT_3_run_ff, DOT_PRODUCT_4_run_ff, DONE_run_ff;
logic [INST_WIDTH -1:0]		        DOT_PRODUCT_1_run_nxt, DOT_PRODUCT_2_run_nxt, DOT_PRODUCT_3_run_nxt, DOT_PRODUCT_4_run_nxt, DONE_run_nxt;
logic [INST_WIDTH -1:0]		        DOT_PRODUCT_1_inst_ff, DOT_PRODUCT_2_inst_ff, DOT_PRODUCT_3_inst_ff, DOT_PRODUCT_4_inst_ff, DONE_inst_ff;
logic [INST_WIDTH -1:0]		        DOT_PRODUCT_1_inst_nxt, DOT_PRODUCT_2_inst_nxt, DOT_PRODUCT_3_inst_nxt, DOT_PRODUCT_4_inst_nxt, DONE_inst_nxt;
logic o_stall_ff;
logic [2:0] o_stall_count_ff,o_stall_count_nxt;

assign o_imem_cen = o_imem_cen_ff;
assign o_imem_wen = o_imem_wen_ff;
assign o_ovmem_cen = o_ovmem_cen_ff| o_ovmem_cen_op126_ff;
assign o_ovmem_wen = o_ovmem_wen_ff| o_ovmem_wen_op126_ff;
assign o_omem_cen = o_omem_cen_ff | o_omem_cen_op126_ff;
assign o_omem_wen = o_omem_wen_op126_ff;
assign o_run = o_run_op126_ff;
assign o_stall = o_stall_ff;

/* TO DO: Write sequential code for your INST DECODER here. */
always_ff @(posedge clk) begin
    if (~o_stall_ff) begin
        state_ff <= state_nxt;
        i_instruction_ff <= i_instruction_nxt;
        
        // Op1,2,6 pipeline register
        timer_ff <= timer_nxt;
        DOT_PRODUCT_1_run_ff <= DOT_PRODUCT_1_run_nxt;
        DOT_PRODUCT_1_inst_ff <= DOT_PRODUCT_1_inst_nxt;
    end else begin
        o_stall_count_ff <= o_stall_count_nxt;
        DOT_PRODUCT_1_run_ff <= DOT_PRODUCT_1_run_nxt;
        DOT_PRODUCT_1_inst_ff <= DOT_PRODUCT_1_inst_nxt;
    end
end

/* TO DO: Write combinational code for your INST DECODER here. */
always_comb begin
    if (reset) begin
        i_instruction_nxt = 0;
        state_nxt = STATE_ID;
        timer_nxt = 0;
        DOT_PRODUCT_1_run_nxt = 0;
        DOT_PRODUCT_1_inst_nxt = 0;
        o_imem_cen_ff = 0;
        o_imem_wen_ff = 0;
        o_omem_cen_ff = 0;
        o_stall_ff = 0;     
    end else if (o_stall_ff) begin
        o_stall_count_nxt = o_stall_count_ff - 1;
        DOT_PRODUCT_1_run_nxt = 0;
        DOT_PRODUCT_1_inst_nxt = 0;
        if (o_stall_count_ff == 0) begin
            o_stall_ff = 0;
            timer_nxt = 5;
            DOT_PRODUCT_1_run_nxt = 1;
            DOT_PRODUCT_1_inst_nxt = i_instruction;
            o_ovmem_cen_ff = 1;
        end
    end else begin
        i_instruction_nxt = i_instruction;
        state_nxt = state_ff;
        timer_nxt = 0;
        DOT_PRODUCT_1_run_nxt = 0;
        DOT_PRODUCT_1_inst_nxt = 0;
        o_imem_cen_ff = 0;
        o_imem_wen_ff = 0;
        o_omem_cen_ff = 0;
        
        case(state_ff)            
            STATE_ID: begin
                if (i_instruction_ff != i_instruction) begin
                    case(i_instruction[18:16])
                        // operation 0
                        3'b000: begin
                            state_nxt = STATE_ID;
                        end
                        // operation 1
                        3'b001: begin
                            state_nxt = STATE_OP126;
                            timer_nxt = 5;
                            DOT_PRODUCT_1_run_nxt = 1;
                            DOT_PRODUCT_1_inst_nxt = i_instruction;
                            o_imem_cen_ff = 1;
                        end
                        // operation 2
                        3'b010: begin
                            state_nxt = STATE_OP126;
                            timer_nxt = 5;
                            DOT_PRODUCT_1_run_nxt = 1;
                            DOT_PRODUCT_1_inst_nxt = i_instruction;
                            o_ovmem_cen_ff = 1;
                        end
                        // operation 3
                        3'b011: begin
                            state_nxt = STATE_DONE;
                            o_imem_wen_ff = 1;
                            o_imem_cen_ff = 1;
                        end
                        // operation 4
                        3'b100: begin
                            state_nxt = STATE_DONE;
                        end
                        // operation 5
                        3'b101: begin
                            state_nxt = STATE_OP5_DONE;
                            o_omem_cen_ff = 1;
                        end
                        // operation 6
                        3'b110: begin
                            state_nxt = STATE_OP126;
                            timer_nxt = 5;
                            DOT_PRODUCT_1_run_nxt = 1;
                            DOT_PRODUCT_1_inst_nxt = i_instruction;
                            o_imem_cen_ff = 1;
                        end
                    endcase
                end
            end
            
            STATE_DONE: begin
                state_nxt = STATE_ID;
            end
            
            // Pipelined Op1,2,6
            STATE_OP126: begin
                if (i_instruction_ff != i_instruction) begin
                    case(i_instruction[18:16])
                        // operation 1
                        3'b001: begin
                            timer_nxt = 5;
                            DOT_PRODUCT_1_run_nxt = 1;
                            DOT_PRODUCT_1_inst_nxt = i_instruction;
                            o_imem_cen_ff = 1;
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
                                o_ovmem_cen_ff = 1;
                            end
                        end
                        // operation 6
                        3'b110: begin
                            timer_nxt = 5;
                            DOT_PRODUCT_1_run_nxt = 1;
                            DOT_PRODUCT_1_inst_nxt = i_instruction;
                            o_imem_cen_ff = 1;
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
            end
        endcase
    end
end

// Pipelined Operation 1,2,6
always_ff @(posedge clk) begin
    if (reset) begin
        DOT_PRODUCT_2_run_ff <= DOT_PRODUCT_2_run_nxt;
        DOT_PRODUCT_2_inst_ff <= DOT_PRODUCT_2_inst_nxt;
        DOT_PRODUCT_3_run_ff <= DOT_PRODUCT_3_run_nxt;
        DOT_PRODUCT_3_inst_ff <= DOT_PRODUCT_3_inst_nxt;
        DOT_PRODUCT_4_run_ff <= DOT_PRODUCT_4_run_nxt;
        DOT_PRODUCT_4_inst_ff <= DOT_PRODUCT_4_inst_nxt;
        DONE_run_ff <= DONE_run_nxt;
        DONE_inst_ff <= DONE_inst_nxt;
    end
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

always_comb begin
    if (reset) begin
        DOT_PRODUCT_2_run_nxt = 0;
        DOT_PRODUCT_3_run_nxt = 0;
        DOT_PRODUCT_4_run_nxt = 0;
        DOT_PRODUCT_2_inst_nxt = 0;
        DOT_PRODUCT_3_inst_nxt = 0;
        DOT_PRODUCT_4_inst_nxt = 0;
        DONE_run_nxt = 0;
        DONE_inst_nxt = 0;
        o_run_op126_ff = 0;
        o_ovmem_cen_op126_ff = 0;
        o_ovmem_wen_op126_ff = 0;
        o_omem_cen_op126_ff = 0;
        o_omem_wen_op126_ff = 0;
    end else begin
        // cycle 2
        DOT_PRODUCT_2_run_nxt = DOT_PRODUCT_1_run_ff;
        DOT_PRODUCT_2_inst_nxt = DOT_PRODUCT_1_inst_ff;
        o_run_op126_ff = DOT_PRODUCT_1_run_ff;
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
            o_omem_cen_op126_ff = DOT_PRODUCT_4_run_ff;
            o_omem_wen_op126_ff = DOT_PRODUCT_4_run_ff;
        end else if (DOT_PRODUCT_4_inst_ff[18:16] == 3'b110) begin
            // Opertion 6
            o_ovmem_cen_op126_ff = DOT_PRODUCT_4_run_ff;
            o_ovmem_wen_op126_ff = DOT_PRODUCT_4_run_ff;
        end else begin
            o_omem_wen_op126_ff = 0;
            o_ovmem_wen_op126_ff = 0;
        end
        // cycle 6
                
    end
end


endmodule
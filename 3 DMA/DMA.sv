// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : DMA.sv
// Author        : Castlab
//				   JaeUk Kim 	< kju5789@kaist.ac.kr >
//				   Donghyuk Kim < kar02040@kaist.ac.kr>
// -----------------------------------------------------------------
// Description: DMA Design
//              This module is one of the main module that you have to design.
//              Design your own DMA on this file.
//              You could write your code from the scratch, but make sure to
//              match the specification.
// -FHDR------------------------------------------------------------

`timescale 1ns / 1ps

import dma_pkg::*;
module DMA
(
    input  logic								clk,
    input  logic								reset,

	// APB Slave
    input  logic [REG_DATA_WIDTH -1:0]		    in_src_addr,
    input  logic [REG_DATA_WIDTH -1:0]		    in_dest_addr,
    input  logic [REG_DATA_WIDTH -1:0]		    in_transfer_size,
    input  logic [MODE           -1:0]		    in_mode,
    
	output logic								out_done,

	// Memory
	output logic								out_s_en,
	output logic [MEM_STRB_WIDTH -1:0]		    out_s_we,
	output logic [MEM_ADDR_WIDTH -1:0]		    out_s_addr,
	output logic [MEM_DATA_WIDTH -1:0]		    out_s_wrdata,
	input  logic [MEM_DATA_WIDTH -1:0]		    in_s_rddata,
	
	output logic								out_d_en,
	output logic [MEM_STRB_WIDTH -1:0]		    out_d_we,
	output logic [MEM_ADDR_WIDTH -1:0]		    out_d_addr,
	output logic [MEM_DATA_WIDTH -1:0]		    out_d_wrdata,
	input  logic [MEM_DATA_WIDTH -1:0]		    in_d_rddata,
	
	output logic [2				 -1:0]		    out_success
);

/* TO DO: Declare your logic here. */
// Declare Registers
reg [REG_DATA_WIDTH -1:0]		     in_src_addr_ff,in_dest_addr_ff,in_src_addr_nxt,in_dest_addr_nxt;
reg [REG_DATA_WIDTH -1:0]		     in_transfer_size_ff,in_transfer_size_nxt;
reg								     out_done_ff, out_done_nxt;
reg [2				 -1:0]		    out_success_ff, out_success_nxt;
reg								     out_s_en_ff, out_s_en_nxt;
reg								     out_d_en_ff, out_d_en_nxt;
reg [MEM_STRB_WIDTH -1:0]		     out_d_we_ff, out_d_we_nxt;

reg [MEM_ADDR_WIDTH -1:0]		     count_data_ff, count_data_nxt;
reg                                  push, pop, is_empty, is_almost_empty, is_full, is_almost_full;
reg [8 -1:0]		     push_data, pop_data, src_data, dest_data;



// Assign output
assign out_done = out_done_ff;
assign out_success = out_success_ff;
assign out_s_en = out_s_en_ff;
assign out_s_we = 0;
assign out_s_wrdata = 0;
assign out_d_en = out_d_en_ff;
assign out_d_we = out_d_we_ff;

// Status
typedef enum logic [3:0] {
	STATE_IDLE,
	STATE_OPERATION_READ_ENABLE,
	STATE_OPERATION_READ_INPUT_ADDRESS,
	STATE_OPERATION_READ,
	STATE_OPERATION_WRITE_ENABLE,
	STATE_OPERATION_WRITE_INPUT_ADDRESS,
	STATE_OPERATION_WRITE,
	STATE_VERIFICATION_ENABLE,
	STATE_VERIFICATION_INPUT_ADDRESS,
	STATE_VERIFICATION
} StatusType;
StatusType											state_ff, state_nxt;



// Verification memory
/* TO DO: Design verification mode of DMA using this memory. */
logic [8				-1:0]					Mem[0:(1<<4)-1];
logic [4				-1:0]					mem_read_ptr;
logic [4				-1:0]					mem_write_ptr;
logic											read;
logic											rst;

/* TO DO: Write sequential code for your DMA here. */
always_ff @(posedge clk) begin
    state_ff <= state_nxt;
    out_done_ff <= out_done_nxt;
    out_success_ff <= out_success_nxt;
    out_s_en_ff <= out_s_en_nxt;
    out_d_en_ff <= out_d_en_nxt;
    out_d_we_ff <= out_d_we_nxt;
    count_data_ff <= count_data_nxt;
    in_src_addr_ff <= in_src_addr_nxt;
    in_dest_addr_ff <= in_dest_addr_nxt;
    in_transfer_size_ff <= in_transfer_size_nxt;
end

/* TO DO: Write combinational code for your DMA here. */
always_comb begin
    if (reset) begin
        state_nxt = STATE_IDLE;
        out_done_nxt = 0;
        out_success_nxt = 0;
        out_s_en_nxt = 0;
        out_d_en_nxt = 0;
        out_d_we_nxt = 0;
        count_data_nxt = 0;
        in_src_addr_nxt = 0;
        in_dest_addr_nxt = 0;
        in_transfer_size_nxt = 0;
        push = 0;
        pop = 0;
        push_data = 0;
    end else begin
        state_nxt = state_ff;
        out_done_nxt = 0;
        out_success_nxt = 0;
        out_s_en_nxt = 0;
        out_d_en_nxt = 0;
        out_d_we_nxt = 0;
        count_data_nxt = 0;
        push = 0;
        pop = 0;
        push_data = 0;
        
        case (state_ff)
            STATE_IDLE: begin
                if (in_mode == 1) begin
                    state_nxt = STATE_OPERATION_READ_ENABLE;                
                end
                else if (in_mode == 2 ) begin
                    state_nxt = STATE_VERIFICATION_ENABLE;
                end
            end
            
            STATE_OPERATION_READ_ENABLE: begin
                out_s_en_nxt = 1;
                state_nxt = STATE_OPERATION_READ_INPUT_ADDRESS;
            end
            
            STATE_OPERATION_READ_INPUT_ADDRESS: begin
                state_nxt = STATE_OPERATION_READ;
                out_s_en_nxt = 1;
                out_s_addr = (in_src_addr[MEM_ADDR_WIDTH -1:0]+count_data_ff)/4;  // push the read data in the NEXT cycle
                count_data_nxt = count_data_ff + 1;
            end
            
            STATE_OPERATION_READ: begin
                if (count_data_ff < in_transfer_size) begin
                    out_s_en_nxt = 1;
                    count_data_nxt = count_data_ff + 1;
                    out_s_addr = (in_src_addr[MEM_ADDR_WIDTH -1:0]+count_data_ff)/4;  // push the read data in the NEXT cycle
                    push = 1;
                    case ((in_src_addr[MEM_ADDR_WIDTH -1:0]+count_data_ff-1)%4)
                        0: push_data = in_s_rddata[7:0];
                        1: push_data = in_s_rddata[15:8];
                        2: push_data = in_s_rddata[23:16];
                        3: push_data = in_s_rddata[31:24];
                    endcase
                end else begin
                    count_data_nxt = 0;
                    push = 1;
                    case ((in_src_addr[MEM_ADDR_WIDTH -1:0]+count_data_ff-1)%4)
                        0: push_data = in_s_rddata[7:0];
                        1: push_data = in_s_rddata[15:8];
                        2: push_data = in_s_rddata[23:16];
                        3: push_data = in_s_rddata[31:24];
                    endcase
                    state_nxt = STATE_OPERATION_WRITE_ENABLE;
                end
            end
            
            STATE_OPERATION_WRITE_ENABLE: begin
                out_d_en_nxt = 1;
                state_nxt = STATE_OPERATION_WRITE_INPUT_ADDRESS;
            end
            STATE_OPERATION_WRITE_INPUT_ADDRESS: begin
                out_d_en_nxt = 1;
                case ((in_dest_addr[MEM_ADDR_WIDTH -1:0]+count_data_ff)%4)
                    0: out_d_we_nxt = 4'b0001;
                    1: out_d_we_nxt = 4'b0010;
                    2: out_d_we_nxt = 4'b0100;
                    3: out_d_we_nxt = 4'b1000;
                endcase
                count_data_nxt = count_data_ff + 1;
                state_nxt = STATE_OPERATION_WRITE;
            end
            
            STATE_OPERATION_WRITE: begin
                if (count_data_ff < in_transfer_size) begin
                    out_d_en_nxt = 1;
                    case ((in_dest_addr[MEM_ADDR_WIDTH -1:0]+count_data_ff)%4)
                        0: out_d_we_nxt = 4'b0001;
                        1: out_d_we_nxt = 4'b0010;
                        2: out_d_we_nxt = 4'b0100;
                        3: out_d_we_nxt = 4'b1000;
                    endcase
                    count_data_nxt = count_data_ff + 1;
                    out_d_addr = (in_dest_addr[MEM_ADDR_WIDTH -1:0] + count_data_ff - 1)/4;  // write the popped data in the SAME cycle
                    
                    pop = 1;
                    case ((in_dest_addr[MEM_ADDR_WIDTH -1:0]+count_data_ff - 1)%4)
                        0: out_d_wrdata = {24'b0, pop_data};
                        1: out_d_wrdata = {16'b0, pop_data, 8'b0};
                        2: out_d_wrdata = {8'b0, pop_data, 16'b0};
                        3: out_d_wrdata = {pop_data, 24'b0};
                    endcase
                end else begin
                    count_data_nxt = 0;
                    out_d_addr = (in_dest_addr[MEM_ADDR_WIDTH -1:0] + count_data_ff - 1)/4;  // write the popped data in the SAME cycle
                    pop = 1;
                    case ((in_dest_addr[MEM_ADDR_WIDTH -1:0]+count_data_ff - 1)%4)
                        0: out_d_wrdata = {24'b0, pop_data};
                        1: out_d_wrdata = {16'b0, pop_data, 8'b0};
                        2: out_d_wrdata = {8'b0, pop_data, 16'b0};
                        3: out_d_wrdata = {pop_data, 24'b0};
                    endcase
                    state_nxt = STATE_IDLE;
                    out_done_nxt = 1;
                end
            end
            
            // Verification
            STATE_VERIFICATION_ENABLE: begin
                out_s_en_nxt = 1;
                out_d_en_nxt = 1;
                state_nxt = STATE_VERIFICATION_INPUT_ADDRESS;
            end
            
            STATE_VERIFICATION_INPUT_ADDRESS: begin
                state_nxt = STATE_VERIFICATION;
                out_s_en_nxt = 1;
                out_d_en_nxt = 1;
                count_data_nxt = count_data_ff + 1;
                out_s_addr = (in_src_addr[MEM_ADDR_WIDTH -1:0] + count_data_ff)/4;
                out_d_addr = (in_dest_addr[MEM_ADDR_WIDTH -1:0] + count_data_ff)/4;
            end
            
            STATE_VERIFICATION: begin
                if (count_data_ff < in_transfer_size) begin
                    out_s_en_nxt = 1;
                    out_d_en_nxt = 1;
                    count_data_nxt = count_data_ff + 1;  // add one line
                    
                    case ((in_src_addr[MEM_ADDR_WIDTH -1:0]+count_data_ff-1)%4)
                        0: src_data = in_s_rddata[7:0];
                        1: src_data = in_s_rddata[15:8];
                        2: src_data = in_s_rddata[23:16];
                        3: src_data = in_s_rddata[31:24];
                    endcase
                    case ((in_dest_addr[MEM_ADDR_WIDTH -1:0]+count_data_ff-1)%4)
                        0: dest_data = in_d_rddata[7:0];
                        1: dest_data = in_d_rddata[15:8];
                        2: dest_data = in_d_rddata[23:16];
                        3: dest_data = in_d_rddata[31:24];
                    endcase
                    
                    out_s_addr = (in_src_addr[MEM_ADDR_WIDTH -1:0] + count_data_ff)/4;
                    out_d_addr = (in_dest_addr[MEM_ADDR_WIDTH -1:0] + count_data_ff)/4;
                    if (src_data != dest_data) begin
                        count_data_nxt = 0;
                        state_nxt = STATE_IDLE;
                        out_done_nxt = 1;
                        out_success_nxt = 2'b10;    // Fail
                    end
                end else begin
                    if (in_s_rddata != in_d_rddata) begin
                        out_success_nxt = 2'b10;    // Fail
                    end else begin
                        out_success_nxt = 2'b01;        // Success
                    end
                    count_data_nxt = 0;
                    state_nxt = STATE_IDLE;
                    out_done_nxt = 1;
                    
                end
            end
        endcase
    end
end

/* TO DO: Instantiate your FIFO design here. */
FIFO
#(
    .FIFO_AWIDTH                                ( 32            			),    // Maximum 2^32 data
    .FIFO_DWIDTH                                ( 8						)     // Byte
)
fifo
(
    .clk                                        ( clk  						),
    .reset                                      ( reset						),
    .in_push                                    ( push      			    ),
    .in_pop                                     ( pop                       ),
    .in_data                                    ( push_data				    ),
    .out_empty                                  ( is_empty  				),
    .out_almost_empty                           ( is_almost_empty           ),
    .out_full                                   ( is_full					),
    .out_almost_full                            ( is_almost_full            ),
    .out_data                                   ( pop_data				    )
);

endmodule
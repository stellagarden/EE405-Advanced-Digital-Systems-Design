// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : APB_slave.sv
// Author        : Castlab
//				   JaeUk Kim 	< kju5789@kaist.ac.kr >
//				   Donghyuk Kim < kar02040@kaist.ac.kr>
// -----------------------------------------------------------------
// Description: APB Slave module
//              Luckily, completed version is provided... :)
// -FHDR------------------------------------------------------------

`timescale 1ns / 1ps

import dma_pkg::*;
module APB_slave
(
    input  logic									clk,
    input  logic									reset,

	output logic									out_intr,				// Interrupt
    output logic   [2               -1:0]           out_led,

	// APB
    input  logic	[REG_ADDR_WIDTH -1:0]			in_s_apb_paddr,
    input  logic									in_s_apb_penable,
    output logic	[REG_DATA_WIDTH -1:0]			out_s_apb_prdata,
    output logic									out_s_apb_pready,
    input  logic									in_s_apb_psel,
    input  logic	[REG_DATA_WIDTH -1:0]			in_s_apb_pwdata,
    input  logic									in_s_apb_pwrite,

	// DMA
	output logic	[REG_DATA_WIDTH	-1:0]			out_src_addr,			// Source Address
	output logic	[REG_DATA_WIDTH	-1:0]			out_dest_addr,			// Destination Address
	output logic	[REG_DATA_WIDTH	-1:0]			out_transfer_size,		// DMA Transfer Size
	output logic	[MODE			-1:0]			out_mode,				// DMA Operation Mode, 00: Idle, 01: Normal Mode Start, 10: Test Mode Start

	input  logic									in_status_update,		// DMA done
    input  logic                                    in_led_update,
    input  logic    [2              -1:0]           in_led,

	// Memory
	output logic									out_mem_sel				// 0: Mem0-Source, Mem1-Destination, 1: Mem0-Source, Mem1-Destination
);

// Configuration register Address
localparam SRC_ADDR                                 = DMA_BASE_ADDR + 32'h00000000;
localparam DEST_ADDR                                = DMA_BASE_ADDR + 32'h00000004;
localparam SIZE_ADDR                                = DMA_BASE_ADDR + 32'h00000008;
localparam MODE_ADDR                                = DMA_BASE_ADDR + 32'h0000000c;
localparam INT_ADDR                                 = DMA_BASE_ADDR + 32'h00000010;
localparam LED_ADDR                                 = DMA_BASE_ADDR + 32'h00000014;

// Status
typedef enum logic [1:0] {
	STATE_SETUP,
	STATE_READ_ACCESS,
	STATE_WRITE_ACCESS
} StatusType;

/* Internal Signal Declaration */
// Define configuration register
// Byte addressable addressing
// 0x00: Source register
// 0x04: Destination register
// 0x08: Transfer size register
// 0x0c: DMA operation mode register
//       0: Idle
//       1: Start Normal Transfer Operation
//       2: Start Test
// 0x10: Interrupt register
logic [REG_DATA_WIDTH   -1:0]						src_reg_ff, src_reg_nxt;
logic [REG_DATA_WIDTH   -1:0]						dest_reg_ff, dest_reg_nxt;
logic [REG_DATA_WIDTH   -1:0]						size_reg_ff, size_reg_nxt;
logic [REG_DATA_WIDTH   -1:0]						mode_reg_ff, mode_reg_nxt;
logic [REG_DATA_WIDTH   -1:0]						interrupt_reg_ff, interrupt_reg_nxt;
logic [REG_DATA_WIDTH   -1:0]						led_reg_ff, led_reg_nxt;

// Status declaration
StatusType											state_ff, state_nxt;

// APB output declaration
logic [REG_DATA_WIDTH   -1:0]						s_apb_prdata;
logic												s_apb_pready;

// Output assignment using assign
assign out_intr                                     = interrupt_reg_ff;
assign out_led                                      = led_reg_ff;

// Output assignment using combinational logic
always_comb begin
	out_s_apb_prdata								= s_apb_prdata;
	out_s_apb_pready								= 1'b1;
	out_src_addr									= src_reg_ff;
	out_dest_addr									= dest_reg_ff;
	out_transfer_size								= size_reg_ff;
	out_mode										= in_status_update ? 'b0 : mode_reg_ff[MODE-1:0];
end

always_comb begin
	out_mem_sel										= 1'b0;
	if (out_src_addr[REG_DATA_WIDTH-1:MEM_ADDR_WIDTH]=='h0001) begin
		out_mem_sel									= 1'b0;
	end else if (out_src_addr[REG_DATA_WIDTH-1:MEM_ADDR_WIDTH]=='h0002) begin
		out_mem_sel									= 1'b1;
	end
end

// Sequential logic update
always_ff @(posedge clk) begin
    state_ff                                        <= reset ? STATE_SETUP : state_nxt;

    // Configuration register
    src_reg_ff                                      <= src_reg_nxt;
    dest_reg_ff                                     <= dest_reg_nxt;
    size_reg_ff                                     <= size_reg_nxt;
    mode_reg_ff                                     <= reset ? 'b0 : (in_status_update ? 'b0 : mode_reg_nxt);
    interrupt_reg_ff                                <= reset ? 'b0 : (in_status_update ? 'b1 : interrupt_reg_nxt);
    led_reg_ff                                      <= reset ? 'b0 : (in_led_update ? {{$bits(led_reg_ff[REG_DATA_WIDTH:3]){1'b0}}, in_led} : led_reg_nxt);
end

// Combinational logic
always_comb begin
    // FSM State latching
    state_nxt                                       = state_ff;

    // Configuration register latching
    src_reg_nxt                                     = src_reg_ff;
    dest_reg_nxt                                    = dest_reg_ff;
    size_reg_nxt                                    = size_reg_ff;
    mode_reg_nxt                                    = mode_reg_ff;
    interrupt_reg_nxt                               = interrupt_reg_ff;
    led_reg_nxt                                     = led_reg_ff;

    // Latching
    s_apb_prdata                                    = 'b0;
    
    case (state_ff)
        STATE_SETUP: begin
            if (in_s_apb_psel == 'b1) begin
                case (in_s_apb_pwrite)
                    1'b0: begin
                        // APB read
                        state_nxt                   = STATE_READ_ACCESS;
                    end

                    1'b1: begin
                        // APB write
                        state_nxt                   = STATE_WRITE_ACCESS;
                    end

                    default: begin

                    end
                endcase
            end
        end

        STATE_READ_ACCESS: begin
            // APB read
            if (in_s_apb_penable == 'b1) begin
                case (in_s_apb_paddr)
                    SRC_ADDR: begin
                        s_apb_prdata                = src_reg_ff;
                    end

                    DEST_ADDR: begin
                        s_apb_prdata                = dest_reg_ff;
                    end

                    SIZE_ADDR: begin
                        s_apb_prdata                = size_reg_ff;
                    end

                    MODE_ADDR: begin
                        s_apb_prdata                = mode_reg_ff;
                    end

                    INT_ADDR: begin
                        s_apb_prdata                = interrupt_reg_ff;
                    end

                    LED_ADDR: begin
                        s_apb_prdata                = led_reg_ff;
                    end

                    default: begin
                        s_apb_prdata                = {REG_DATA_WIDTH{1'bx}};
                    end
                endcase

                state_nxt                           = STATE_SETUP;
            end
        end

        STATE_WRITE_ACCESS: begin
            // APB write
            if (in_s_apb_penable == 'b1) begin
                case (in_s_apb_paddr)
                    SRC_ADDR: begin
                        src_reg_nxt                 = in_s_apb_pwdata;
                    end

                    DEST_ADDR: begin
                        dest_reg_nxt                = in_s_apb_pwdata;
                    end

                    SIZE_ADDR: begin
                        size_reg_nxt                = in_s_apb_pwdata;
                    end

                    MODE_ADDR: begin
                        mode_reg_nxt                = in_s_apb_pwdata;
                    end

                    INT_ADDR: begin
                        interrupt_reg_nxt           = in_s_apb_pwdata;
                    end

                    default: begin
                        
                    end
                endcase

                state_nxt                           = STATE_SETUP;
            end
        end

        default: begin
            
        end
    endcase
end

endmodule
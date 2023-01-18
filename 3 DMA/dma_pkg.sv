// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : dma_pkg.sv
// Author        : Castlab
//				   JaeUk Kim 	< kju5789@kaist.ac.kr >
//				   Donghyuk Kim < kar02040@kaist.ac.kr>
// -----------------------------------------------------------------
// Description: Declare your parameter here.
// -FHDR------------------------------------------------------------

`timescale 1ns/1ps

package dma_pkg;
    parameter REG_ADDR_WIDTH						= 32;
    parameter REG_DATA_WIDTH						= 32;
	parameter MEM_ADDR_WIDTH						= 16;
	parameter MEM_DATA_WIDTH						= 32;
	parameter MEM_STRB_WIDTH						= MEM_DATA_WIDTH/8;
	parameter MODE									= 2;
	parameter MAX_TRANS_SIZE						= 5;			// Maximum Transfer Size = 16 (Represent in 5byte)

	/* TO DO: Don't forget to modify this Base Address before synthesis.
			  If you forget, just spending 1hr for acknowledging your fault would be lucky case. */
	parameter DMA_BASE_ADDR							= 32'h44A10000;

	/* TO DO: Declare your global parameter.
			  This is optional that depends on your RTL design. */

endpackage

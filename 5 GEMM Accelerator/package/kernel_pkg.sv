// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : kernel_pkg.sv
// Author        : Castlab
//				         Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: Package parameters for RTL kernel
// -FHDR------------------------------------------------------------

package kernel_pkg;

  // GEMM dimension
  parameter DIM_L_WIDTH       = 32;
  parameter DIM_M_WIDTH       = 32;
  parameter DIM_N_WIDTH       = 32;

  // SIMD
  parameter DATA_WIDTH        = 32;
  parameter PSUM_WIDTH        = 32;
  parameter VECTOR_LENGTH     = 16;

  // Buffers
  parameter BUFF_DATA_WIDTH   = 32;
  parameter BUFF_STRB_WIDTH   = BUFF_DATA_WIDTH / 8;
  parameter BUFF_ADDR_WIDTH   = 14;

  // Memory
  parameter MEM_NUM            = 3;  // 0 : input, 1 : weight, 2: output

  parameter IMEM_DATA_WIDTH    = DATA_WIDTH * VECTOR_LENGTH;	  // 32 * 16
  parameter IMEM_BANK          = IMEM_DATA_WIDTH / BUFF_DATA_WIDTH; // 16
  parameter IMEM_ADDR_WIDTH    = BUFF_ADDR_WIDTH - $clog2(MEM_NUM) - $clog2(IMEM_BANK) - $clog2(BUFF_DATA_WIDTH/8);
            // 14 - 2 - 4 - 2 = 6

  parameter WMEM_DATA_WIDTH    = DATA_WIDTH * VECTOR_LENGTH;	  // 32 * 16
  parameter WMEM_BANK          = WMEM_DATA_WIDTH / BUFF_DATA_WIDTH; // 16
  parameter WMEM_ADDR_WIDTH    = BUFF_ADDR_WIDTH - $clog2(MEM_NUM) - $clog2(WMEM_BANK) - $clog2(BUFF_DATA_WIDTH/8);
            // 14 - 2 - 4 - 2 = 6

  parameter OMEM_DATA_WIDTH    = DATA_WIDTH;        // 32
  parameter OMEM_BANK          = OMEM_DATA_WIDTH / BUFF_DATA_WIDTH; // 1
  parameter OMEM_ADDR_WIDTH    = BUFF_ADDR_WIDTH - $clog2(MEM_NUM) - $clog2(OMEM_BANK) - $clog2(BUFF_DATA_WIDTH/8);
            // 14 - 2 - 0 - 2 = 10

	/* TO DO: Declare your global parameter.
			  This is optional that depends on your RTL design. */

endpackage
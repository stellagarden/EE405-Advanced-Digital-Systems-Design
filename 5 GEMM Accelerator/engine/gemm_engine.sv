// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : gemm_engine.sv
// Author        : Castlab
//				         Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: Engine module
// -FHDR------------------------------------------------------------

module gemm_engine
  import kernel_pkg::*;
(
  input  logic                            clk,
  input  logic                            reset,
  
  // Engine status
  input  logic                            ap_start,
  output logic                            ap_idle,
  output logic                            ap_done,

  // GEMM dimension
  input  logic [DIM_L_WIDTH-1:0]          dim_l,
  input  logic [DIM_M_WIDTH-1:0]          dim_m,
  input  logic [DIM_N_WIDTH-1:0]          dim_n,

  // Memory interface
  input  logic                            mem_cen,
  input  logic                            mem_wen,
  input  logic [BUFF_ADDR_WIDTH-1:0]      mem_addr,
  input  logic [BUFF_DATA_WIDTH-1:0]      mem_din,
  output logic [BUFF_DATA_WIDTH-1:0]      mem_dout,
  output logic                            mem_valid
);

//////////////////////////////////////////////////////////////////////////

// Control memory
logic                                      i_rd_en;
logic [IMEM_ADDR_WIDTH-1:0]                i_rd_addr;
logic [IMEM_DATA_WIDTH-1:0]                i_rd_data;
logic                                      i_rd_valid;
logic                                      w_rd_en;
logic [WMEM_ADDR_WIDTH-1:0]                w_rd_addr;
logic [WMEM_DATA_WIDTH-1:0]                w_rd_data;
logic                                      w_rd_valid;
logic                                      o_wr_en;
logic [OMEM_ADDR_WIDTH-1:0]                o_wr_addr;
logic [OMEM_DATA_WIDTH-1:0]                o_wr_data;

  // Control pipelinied adder-tree
logic                                      at_status;
logic                                      at_accum;
logic [VECTOR_LENGTH-1:0][DATA_WIDTH-1:0]  at_i_data;
logic [VECTOR_LENGTH-1:0]                  at_i_valid;
logic [VECTOR_LENGTH-1:0][DATA_WIDTH-1:0]  at_w_data;
logic [VECTOR_LENGTH-1:0]                  at_w_valid;
logic [DATA_WIDTH-1:0]                     at_o_data;
logic                                      at_o_valid;

//////////////////////////////////////////////////////////////////////////
// Controller
//////////////////////////////////////////////////////////////////////////

controller
u_controller
(
  .clk            ( clk      ),
  .reset          ( reset    ),

  // Engine status
  .ap_start       ( ap_start    ),
  .ap_idle        ( ap_idle    ),
  .ap_done        ( ap_done    ),

  // GEMM dimension
  .dim_l          ( dim_l    ),
  .dim_m          ( dim_m    ),
  .dim_n          ( dim_n    ),

  // Control memory
  .i_rd_en        ( i_rd_en    ),
  .i_rd_addr      ( i_rd_addr    ),
  .i_rd_data      ( i_rd_data    ),
  .i_rd_valid     ( i_rd_valid    ),
  .w_rd_en        ( w_rd_en    ),
  .w_rd_addr      ( w_rd_addr    ),
  .w_rd_data      ( w_rd_data    ),
  .w_rd_valid     ( w_rd_valid    ),
  .o_wr_en        ( o_wr_en    ),
  .o_wr_addr      ( o_wr_addr    ),
  .o_wr_data      ( o_wr_data    ),

  // Control simd
  .at_status      ( at_status    ),
  .at_accum       ( at_accum    ),
  .at_i_data      ( at_i_data    ),
  .at_i_valid     ( at_i_valid    ),
  .at_w_data      ( at_w_data    ),
  .at_w_valid     ( at_w_valid    ),
  .at_o_data      ( at_o_data    ),
  .at_o_valid     ( at_o_valid    )
);

//////////////////////////////////////////////////////////////////////////
// Data buffer
//////////////////////////////////////////////////////////////////////////

data_buffer
u_data_buffer
(
  .clk            ( clk    ),
  .reset          ( reset    ),

  // Memory interface
  .mem_cen        ( mem_cen    ),
  .mem_wen        ( mem_wen    ),
  .mem_addr       ( mem_addr    ),
  .mem_din        ( mem_din    ),
  .mem_dout       ( mem_dout    ),
  .mem_valid      ( mem_valid    ),

  // Engine interface
  .i_rd_en        ( i_rd_en    ),
  .i_rd_addr      ( i_rd_addr    ),
  .i_rd_data      ( i_rd_data    ),
  .i_rd_valid     ( i_rd_valid    ),
  .w_rd_en        ( w_rd_en    ),
  .w_rd_addr      ( w_rd_addr    ),
  .w_rd_data      ( w_rd_data    ),
  .w_rd_valid     ( w_rd_valid    ),
  .o_wr_en        ( o_wr_en    ),
  .o_wr_addr      ( o_wr_addr    ),
  .o_wr_data      ( o_wr_data    )
);

//////////////////////////////////////////////////////////////////////////
// Pipelined Adder-Tree
//////////////////////////////////////////////////////////////////////////

pipe_addertree
u_pipe_addertree
(
  .clk            ( clk    ),
  .reset          ( reset    ),

  // Adder-tree status
  .at_status      ( at_status    ),
  .at_accum       ( at_accum    ),

  // Adder-tree data
  .at_i_data      ( at_i_data    ),
  .at_i_valid     ( at_i_valid    ),
  .at_w_data      ( at_w_data    ),
  .at_w_valid     ( at_w_valid    ),
  .at_o_data      ( at_o_data    ),
  .at_o_valid     ( at_o_valid    )
);

//////////////////////////////////////////////////////////////////////////

endmodule
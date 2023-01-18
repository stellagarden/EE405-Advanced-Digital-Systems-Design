// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : rtl_kernel_control.sv
// Author        : Castlab
//                     Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: RTL kernel top module
// -FHDR------------------------------------------------------------

module rtl_kernel
  import kernel_pkg::*;
#(
  parameter APB_BASE_ADDR               = 0,
  parameter APB_ADDR_WIDTH              = 32,
  parameter APB_DATA_WIDTH              = 32,
  parameter APB_PPROT_WIDTH             = 3,
  parameter APB_PSTRB_WIDTH             = 4
)
(
  input  logic                          clk,
  input  logic                          reset,

  // FPGA status
  output logic [3:0]                    out_led,

  // APB
  input  logic [APB_ADDR_WIDTH-1:0]     s_apb_paddr,
  input  logic                          s_apb_penable,
  input  logic [APB_PPROT_WIDTH-1:0]    s_apb_pprot,
  output logic [APB_DATA_WIDTH-1:0]     s_apb_prdata,
  output logic                          s_apb_pready,
  input  logic                          s_apb_psel,
  output logic                          s_apb_pslverr,
  input  logic [APB_PSTRB_WIDTH-1:0]    s_apb_pstrb,
  input  logic [APB_DATA_WIDTH-1:0]     s_apb_pwdata,
  input  logic                          s_apb_pwrite
);

//////////////////////////////////////////////////////////////////////////

/* TODO: your code  */
logic                            ap_start;
logic                            ap_idle;
logic                            ap_done;

logic [DIM_L_WIDTH-1:0]          dim_l;
logic [DIM_M_WIDTH-1:0]          dim_m;
logic [DIM_N_WIDTH-1:0]          dim_n;

  // Memory interface
logic                            mem_cen;
logic                            mem_wen;
logic [BUFF_ADDR_WIDTH-1:0]      mem_addr;
logic [BUFF_DATA_WIDTH-1:0]      mem_din;
logic [BUFF_DATA_WIDTH-1:0]      mem_dout;
logic                            mem_valid;
/* TODO: end        */

//////////////////////////////////////////////////////////////////////////
// AP Control
//////////////////////////////////////////////////////////////////////////

apb_slave
#(
  .APB_BASE_ADDR      ( APB_BASE_ADDR     ),
  .APB_ADDR_WIDTH     ( APB_ADDR_WIDTH    ),
  .APB_DATA_WIDTH     ( APB_DATA_WIDTH    )
)
u_apb_slave
(
  .clk                ( clk                 ),
  .reset              ( reset               ),

  // FPGA status
  .out_led            ( out_led             ),

  // Engine status
  .ap_start           ( ap_start    ),
  .ap_idle            ( ap_idle     ),
  .ap_done            ( ap_done     ),

  // GEMM dimension
  .dim_l              ( dim_l    ),
  .dim_m              ( dim_m    ),
  .dim_n              ( dim_n    ),

  // Memory interface
  .mem_cen            ( mem_cen    ),
  .mem_wen            ( mem_wen    ),
  .mem_addr           ( mem_addr   ),
  .mem_din            ( mem_din    ),
  .mem_dout           ( mem_dout   ),
  .mem_valid          ( mem_valid  ),

  // APB interface
  .s_apb_paddr        ( s_apb_paddr       ),
  .s_apb_penable      ( s_apb_penable     ),
  .s_apb_pprot        ( s_apb_pprot       ),
  .s_apb_prdata       ( s_apb_prdata      ),
  .s_apb_pready       ( s_apb_pready      ),
  .s_apb_psel         ( s_apb_psel        ),
  .s_apb_pslverr      ( s_apb_pslverr     ),
  .s_apb_pstrb        ( s_apb_pstrb       ),
  .s_apb_pwdata       ( s_apb_pwdata      ),
  .s_apb_pwrite       ( s_apb_pwrite      )
);

//////////////////////////////////////////////////////////////////////////
// GEMM Engine
//////////////////////////////////////////////////////////////////////////

gemm_engine
u_gemm_engine
(
  .clk                ( clk    ),
  .reset              ( reset  ),
  
  // Engine status
  .ap_start           ( ap_start    ),
  .ap_idle            ( ap_idle     ),
  .ap_done            ( ap_done     ),

  // GEMM dimension
  .dim_l              ( dim_l    ),
  .dim_m              ( dim_m    ),
  .dim_n              ( dim_n    ),

  // Memory interface
  .mem_cen            ( mem_cen     ),
  .mem_wen            ( mem_wen     ),
  .mem_addr           ( mem_addr    ),
  .mem_din            ( mem_din     ),
  .mem_dout           ( mem_dout    ),
  .mem_valid          ( mem_valid   )
);

//////////////////////////////////////////////////////////////////////////

endmodule
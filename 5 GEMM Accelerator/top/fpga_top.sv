// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fpga_top.sv
// Author        : Castlab
//                     Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: FPGA Top module
// -FHDR------------------------------------------------------------

module fpga_top
(
  input  logic                  diff_clock_rtl_clk_n,
   input  logic                  diff_clock_rtl_clk_p,
   input  logic [3:0]            axi_gpio_tri_i,
   input  logic                  reset,
   input  logic                  usb_uart_rxd,
   output logic                  usb_uart_txd,
   output logic [3:0]            o_led
);

//////////////////////////////////////////////////////////////////////////

// APB interface
localparam APB_BASE_ADDR        = 0;
localparam APB_ADDR_WIDTH       = 32;
localparam APB_DATA_WIDTH       = 32;
localparam APB_PPROT_WIDTH      = 3;
localparam APB_PSTRB_WIDTH      = 4;

//////////////////////////////////////////////////////////////////////////

/* TODO: your code  */
logic [APB_ADDR_WIDTH-1:0]      apb_paddr;      
logic                           apb_penable;  
logic [APB_PPROT_WIDTH-1:0]     apb_pprot; 
logic [APB_DATA_WIDTH-1:0]      apb_prdata;     
logic                           apb_pready;   
logic                           apb_psel; 
logic                           apb_pslverr; 
logic [APB_PSTRB_WIDTH-1:0]     apb_pstrb;
logic [APB_DATA_WIDTH-1:0]      apb_pwdata;
logic                           apb_pwrite;

/* TODO: end        */

//////////////////////////////////////////////////////////////////////////
// Shell Block Design
//////////////////////////////////////////////////////////////////////////

// Shell instantiation
// i for input port and o for output port;
design_1_wrapper
u_shell
(
   .axi_gpio_tri_i         ( axi_gpio_tri_i           ),    // io
   .diff_clock_rtl_clk_n   ( diff_clock_rtl_clk_n      ),    // i
   .diff_clock_rtl_clk_p   ( diff_clock_rtl_clk_p      ),    // i
   .reset                  ( reset                  ),    // i
   .usb_uart_rxd           ( usb_uart_rxd           ),    // i
   .usb_uart_txd           ( usb_uart_txd           ),    // o
   .usr_rtl_apb_paddr      ( apb_paddr              ),    // o
   .usr_rtl_apb_penable    ( apb_penable             ),    // o
   .usr_rtl_apb_prdata     ( apb_prdata              ),    // i
   .usr_rtl_apb_pready     ( apb_pready              ),    // i
   .usr_rtl_apb_psel       ( apb_psel                ),    // o
   .usr_rtl_apb_pslverr    ( apb_pslverr             ),    // i
   .usr_rtl_apb_pwdata     ( apb_pwdata              ),    // o
   .usr_rtl_apb_pwrite     ( apb_pwrite              ),    // o
   .usr_rtl_clk            ( CLK                     ),    // o
   .usr_rtl_rst            ( RESET                    )     // o
);

//////////////////////////////////////////////////////////////////////////
// RTL Kernel
//////////////////////////////////////////////////////////////////////////

rtl_kernel
#(
  .APB_BASE_ADDR          ( APB_BASE_ADDR          ),
  .APB_ADDR_WIDTH         ( APB_ADDR_WIDTH          ),
  .APB_DATA_WIDTH         ( APB_DATA_WIDTH          ),
  .APB_PPROT_WIDTH        ( APB_PPROT_WIDTH          ),
  .APB_PSTRB_WIDTH        ( APB_PSTRB_WIDTH          )
)
u_rtl_kernel
(
  .clk                    ( CLK                    ),
  .reset                  ( ~RESET                  ),

  // FPGA status
  .out_led                ( o_led                   ),

  // APB
  .s_apb_paddr            ( apb_paddr              ),
  .s_apb_penable          ( apb_penable           ),
  .s_apb_pprot            ( apb_pprot           ),
  .s_apb_prdata           ( apb_prdata             ),
  .s_apb_pready           ( apb_pready             ),
  .s_apb_psel             ( apb_psel              ),
  .s_apb_pslverr          ( apb_pslverr           ),
  .s_apb_pstrb            ( apb_pstrb           ),
  .s_apb_pwdata           ( apb_pwdata             ),
  .s_apb_pwrite           ( apb_pwrite             )
);

//////////////////////////////////////////////////////////////////////////

endmodule
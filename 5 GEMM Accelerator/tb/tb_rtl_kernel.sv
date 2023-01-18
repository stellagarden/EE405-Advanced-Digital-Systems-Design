// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : rtl_kernel_control.sv
// Author        : Castlab
//				         Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: Testbench for RTL kernel
// -FHDR------------------------------------------------------------

`timescale 1ns / 1ps
import kernel_pkg::*;

module tb_rtl_kernel();

//////////////////////////////////////////////////////////////////////////

// Clock
localparam real CLK_FREQ    = 200;
localparam real CLK_PREIOD  = (1000 / CLK_FREQ) / 2;

// APB
localparam APB_BASE_ADDR    = 0;
localparam APB_ADDR_WIDTH   = 32;
localparam APB_DATA_WIDTH   = 64;
localparam APB_PPROT_WIDTH  = 3;
localparam APB_PSTRB_WIDTH  = 5;

// Address header
localparam CTRL_BASE_ADDR   = 32'h0000_0000;
localparam IMEM_BASE_ADDR   = 32'h0000_4000;
localparam WMEM_BASE_ADDR   = 32'h0000_5000;
localparam OMEM_BASE_ADDR   = 32'h0000_6000;

//////////////////////////////////////////////////////////////////////////
// ------------------------- Address Information -------------------------
// 0x00 : ap_start                            ( write             )
// 0x04 : ap_done                             ( read              )
// 0x08 : ap_idle                             ( read              )
// 0x10 : dim_l                               ( write             )
// 0x14 : dim_m                               ( write             )
// 0x18 : dim_n                               ( write             )
// ----------------------------------------------------------------------
localparam ADDR_AP_START    = 7'h00;
localparam ADDR_AP_DONE     = 7'h04;
localparam ADDR_AP_IDLE     = 7'h08;
localparam ADDR_DIM_L       = 7'h10;
localparam ADDR_DIM_M       = 7'h14;
localparam ADDR_DIM_N       = 7'h18;

// Testbench
localparam DEBUG            = 0;    // 0 : normal mode, 1 : debug mode
localparam GEMM_DIM_L       = 16;
localparam GEMM_DIM_M       = 5;
localparam GEMM_DIM_N       = 3;

//////////////////////////////////////////////////////////////////////////

// System
logic clk;
logic reset;

// RTL kernel
logic         ap_start;
logic         ap_done;
logic         ap_idle;
logic [3:0]   out_led;

// APB interface
logic [APB_ADDR_WIDTH-1:0]    apb_paddr;
logic                         apb_penable;
logic [APB_PPROT_WIDTH-1:0]   apb_pprot;
logic [APB_DATA_WIDTH-1:0]    apb_prdata;
logic                         apb_pready;
logic                         apb_psel;
logic                         apb_pslverr;
logic [APB_PSTRB_WIDTH-1:0]   apb_pstrb;
logic [APB_DATA_WIDTH-1:0]    apb_pwdata;
logic                         apb_pwrite;

// Testbench
logic [APB_DATA_WIDTH-1:0]    rd_data;
logic [DATA_WIDTH-1:0]        i_mat[GEMM_DIM_N-1:0][GEMM_DIM_L-1:0];
logic [DATA_WIDTH-1:0]        w_mat[GEMM_DIM_L-1:0][GEMM_DIM_M-1:0];
logic [DATA_WIDTH-1:0]        o_mat[GEMM_DIM_N-1:0][GEMM_DIM_M-1:0];
logic [31:0]                  error;

//////////////////////////////////////////////////////////////////////////
// System
//////////////////////////////////////////////////////////////////////////

initial begin
  clk = 1;
  #1;
  forever clk = #(CLK_PREIOD) ~clk;
end

//////////////////////////////////////////////////////////////////////////
// RTL kernel
//////////////////////////////////////////////////////////////////////////

rtl_kernel
#(
  .APB_BASE_ADDR      ( APB_BASE_ADDR     ),
  .APB_ADDR_WIDTH     ( APB_ADDR_WIDTH    ),
  .APB_DATA_WIDTH     ( APB_DATA_WIDTH    )
)
u_rtl_kernel
(
  .clk                ( clk               ),
  .reset              ( reset             ),

  // FPGA status
  .out_led            ( out_led           ),

  // APB interface
  .s_apb_paddr        ( apb_paddr         ),
  .s_apb_penable      ( apb_penable       ),
  .s_apb_pprot        ( apb_pprot         ),
  .s_apb_prdata       ( apb_prdata        ),
  .s_apb_pready       ( apb_pready        ),
  .s_apb_psel         ( apb_psel          ),
  .s_apb_pslverr      ( apb_pslverr       ),
  .s_apb_pstrb        ( apb_pstrb         ),
  .s_apb_pwdata       ( apb_pwdata        ),
  .s_apb_pwrite       ( apb_pwrite        )
);

//////////////////////////////////////////////////////////////////////////
// APB master interface
//////////////////////////////////////////////////////////////////////////

apb_master
#(
  .BASE_ADDR          ( APB_BASE_ADDR     ),
  .ADDR_WIDTH         ( APB_ADDR_WIDTH    ),
  .DATA_WIDTH         ( APB_DATA_WIDTH    ),
  .PPROT_WIDTH        ( APB_PPROT_WIDTH   ),
  .PSTRB_WIDTH        ( APB_PSTRB_WIDTH   )
)
u_apb_master
(
  .clk                ( clk               ),
  .reset              ( reset             ),

  .m_apb_paddr        ( apb_paddr         ),
  .m_apb_penable      ( apb_penable       ),
  .m_apb_pprot        ( apb_pprot         ),
  .m_apb_prdata       ( apb_prdata        ),
  .m_apb_pready       ( apb_pready        ),
  .m_apb_psel         ( apb_psel          ),
  .m_apb_pslverr      ( apb_pslverr       ),
  .m_apb_pstrb        ( apb_pstrb         ),
  .m_apb_pwdata       ( apb_pwdata        ),
  .m_apb_pwrite       ( apb_pwrite        )
);

//////////////////////////////////////////////////////////////////////////
// Task
//////////////////////////////////////////////////////////////////////////

// Initialize kernel
task automatic kernel_init();

  reset = 1;
  error = 0;
  repeat(10) @(posedge clk); #0.01;
  reset = 0;
  repeat(10) @(posedge clk); #0.01;
  $display("==================================================");
  $display(" RTL Simulation");
  $display("==================================================");
  $display("[Info\t] rtl simulation start");

endtask

// Generate test case and golden data
task automatic golden_data();

  $display("[Info\t] generate golden data");
  
  // Input data
  for (int n = 0; n < GEMM_DIM_N; n++)
    for (int l = 0; l < GEMM_DIM_L; l++)
      i_mat[n][l] = (DEBUG == 0)? $urandom() : 1;
  // Weight data
  for (int l = 0; l < GEMM_DIM_L; l++)
    for (int m = 0; m < GEMM_DIM_M; m++)
      w_mat[l][m] = (DEBUG == 0)? $urandom() : 1;
  // Output data
  for (int n = 0; n < GEMM_DIM_N; n++) begin
    for (int m = 0; m < GEMM_DIM_M; m++) begin
      o_mat[n][m] = 0;
      for (int l = 0; l < GEMM_DIM_L; l++) begin
        o_mat[n][m] = ($signed(i_mat[n][l]) * $signed(w_mat[l][m])) + $signed(o_mat[n][m]);
      end
    end
  end

endtask
 
// Setup BRAM memory
task automatic write_bram();

  golden_data();
  // Set memory by apb protocol
  // Input data
  for (int n = 0; n < GEMM_DIM_N; n++)
    for (int l = 0; l < GEMM_DIM_L; l++)
      u_apb_master.write(IMEM_BASE_ADDR + ((n*GEMM_DIM_L) + l)*4, i_mat[n][l]);
  // Weight data
  for (int m = 0; m < GEMM_DIM_M; m++)
    for (int l = 0; l < GEMM_DIM_L; l++)
      u_apb_master.write(WMEM_BASE_ADDR + ((m*GEMM_DIM_L) + l)*4, w_mat[l][m]);

endtask

// Load BRAM memory
task automatic read_bram();

  for (int n = 0; n < GEMM_DIM_N; n++) begin
    for (int m = 0; m < GEMM_DIM_M; m++) begin
      u_apb_master.read(OMEM_BASE_ADDR + ((n*GEMM_DIM_M) + m)*4, rd_data);
      error = (rd_data != o_mat[n][m])? error + 1 : error;
    end
  end

endtask

// Kernel start
task automatic kernel_start
(
  input logic [DIM_L_WIDTH-1:0] dim_l,
  input logic [DIM_M_WIDTH-1:0] dim_m,
  input logic [DIM_N_WIDTH-1:0] dim_n
);

  // Control logics
  logic         ap_start  = 0;
  logic         ap_idle   = 0;
  logic [31:0]  read_data = 0;

  // Setup BRAM
  write_bram();

  repeat(10) @(posedge clk); #0.01;
  $display("[Info\t] start rtl kernel");
  // Break when IDLE
  while (~ap_idle) begin

    u_apb_master.read(CTRL_BASE_ADDR + ADDR_AP_IDLE, read_data);
    ap_idle  = read_data[0];
    repeat(10) @(posedge clk); #0.01;

  end

  // Setting control registers
  u_apb_master.write(CTRL_BASE_ADDR + ADDR_DIM_L,    dim_l);
  u_apb_master.write(CTRL_BASE_ADDR + ADDR_DIM_M,    dim_m);
  u_apb_master.write(CTRL_BASE_ADDR + ADDR_DIM_N,    dim_n);
  u_apb_master.write(CTRL_BASE_ADDR + ADDR_AP_START, 32'h1);
  repeat(10) @(posedge clk); #0.01;
  u_apb_master.write(CTRL_BASE_ADDR + ADDR_AP_START, 32'h0);


endtask

// Kernel done
task automatic kernel_done();

  // Control logics
  logic         ap_idle = 0;
  logic [31:0]  read_data;

  repeat(10) @(posedge clk); #0.01;
  // Break when IDLE
  while (~ap_idle) begin

    u_apb_master.read(CTRL_BASE_ADDR + ADDR_AP_IDLE, read_data);
    ap_idle = read_data[0];
    repeat(10) @(posedge clk); #0.01;

  end

  // Read BRAM
  read_bram();

  if (error == 0)
    $display("[Pass\t] output matrix is correct!");
  else
    $display("[Fail\t] output matrix is wrong!");

  u_apb_master.read(CTRL_BASE_ADDR + ADDR_AP_DONE, read_data);
  repeat(10) @(posedge clk); #0.01;
  $display("[Info\t] rtl simulation finished");
  $display("==================================================");
  $finish;

endtask

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

initial begin : main

  kernel_init();

  kernel_start(GEMM_DIM_L, GEMM_DIM_M, GEMM_DIM_N);

  kernel_done();

end

//////////////////////////////////////////////////////////////////////////

endmodule
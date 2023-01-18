// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : apb_slave.sv
// Author        : Castlab
//                     Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: Core configuration with APB Slave
// -FHDR------------------------------------------------------------

module apb_slave
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

  // Engine status
  output logic                          ap_start,
  input  logic                          ap_idle,
  input  logic                          ap_done,

  // GEMM dimension
  output logic [DIM_L_WIDTH-1:0]        dim_l,
  output logic [DIM_M_WIDTH-1:0]        dim_m,
  output logic [DIM_N_WIDTH-1:0]        dim_n,

  // Memory buffers
  output logic                          mem_cen,
  output logic                          mem_wen,
  output logic [BUFF_ADDR_WIDTH-1:0]    mem_addr,
  output logic [BUFF_DATA_WIDTH-1:0]    mem_din,
  input  logic [BUFF_DATA_WIDTH-1:0]    mem_dout,
  input  logic                          mem_valid,

  // APB interface
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

localparam ADDR_HEADER      = 2;
localparam CTRL_HEAD        = 0;
localparam DATA_HEAD        = 1;

localparam CTRL_ADDR_WIDTH  = 7;
localparam CTRL_DATA_WIDTH  = APB_DATA_WIDTH;   // 32
localparam DATA_ADDR_WIDTH  = BUFF_ADDR_WIDTH;  // 14
localparam DATA_DATA_WIDTH  = APB_DATA_WIDTH;   // 32

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

//////////////////////////////////////////////////////////////////////////
// Status
typedef enum logic [1:0] {
   STATE_SETUP,
   STATE_READ_ACCESS,
   STATE_READING,
   STATE_WRITE_ACCESS
} StatusType;

// Contol registers
logic [CTRL_DATA_WIDTH-1:0] int_ap_start,int_ap_start_nxt;
logic [CTRL_DATA_WIDTH-1:0] int_ap_done,int_ap_done_nxt;
logic [CTRL_DATA_WIDTH-1:0] int_ap_idle,int_ap_idle_nxt;
logic [CTRL_DATA_WIDTH-1:0] int_dim_l,int_dim_l_nxt;
logic [CTRL_DATA_WIDTH-1:0] int_dim_m,int_dim_m_nxt;
logic [CTRL_DATA_WIDTH-1:0] int_dim_n,int_dim_n_nxt;

// Control signal
logic                       ctrl_wr_en;
logic [CTRL_ADDR_WIDTH-1:0] ctrl_wr_addr;
logic [CTRL_DATA_WIDTH-1:0] ctrl_wr_data;
logic                       ctrl_rd_en;
logic [CTRL_ADDR_WIDTH-1:0] ctrl_rd_addr;
logic [CTRL_DATA_WIDTH-1:0] ctrl_rd_data;

// Data signal
logic                       data_wr_en;
logic [DATA_ADDR_WIDTH-1:0] data_wr_addr;
logic [DATA_DATA_WIDTH-1:0] data_wr_data;
logic                       data_rd_en;
logic [DATA_ADDR_WIDTH-1:0] data_rd_addr;
logic [DATA_DATA_WIDTH-1:0] data_rd_data;

// To-do
// Status declaration
StatusType          state_ff, state_nxt;

// APB output declaration
logic												s_apb_pready_ff;

// Output assignment using combinational logic
always_comb begin
    ap_start = int_ap_start;
    dim_l    = int_dim_l;
    dim_m    = int_dim_m;
    dim_n    = int_dim_n;
    s_apb_pslverr = 'b0;
end

// Sequential logic update
always_ff @(posedge clk) begin
    state_ff            <= reset ? STATE_SETUP : state_nxt;
    
    int_ap_start         <= int_ap_start_nxt;
    int_ap_idle         <= reset ? 'b0 : ap_idle;
    int_ap_done         <= reset ? 'b0 : ap_done;
    int_dim_l            <= int_dim_l_nxt;
    int_dim_m            <= int_dim_m_nxt;
    int_dim_n            <= int_dim_n_nxt;    
end

always_comb begin
    state_nxt               = state_ff;
    int_ap_start_nxt        = int_ap_start;
    int_dim_l_nxt           = int_dim_l;
    int_dim_m_nxt           = int_dim_m;
    int_dim_n_nxt           = int_dim_n;
    mem_cen                 = 'b0;
    mem_wen                 = 'b0;
    mem_addr                = 'b0;
    mem_din                 = 'b0;
    s_apb_prdata            = 'b0;
    s_apb_pready            = 'b0;
    ctrl_rd_en              = 'b0;
    
    case(state_ff)
        STATE_SETUP: begin
            if (s_apb_psel == 'b1) begin
                case (s_apb_pwrite)
                    1'b0: state_nxt = STATE_READ_ACCESS;
                    1'b1: state_nxt = STATE_WRITE_ACCESS;
                endcase
            end
        end
        
        STATE_READ_ACCESS: begin
            // APB read
            if (s_apb_penable == 'b1) begin
                // BRAM
                if (s_apb_paddr[15:14] == DATA_HEAD) begin
                    state_nxt = STATE_READING;
                    mem_cen = 'b1;
                    mem_wen = 'b0;
                    mem_addr = s_apb_paddr[DATA_ADDR_WIDTH-1:0];
                end
                // Register
                else if (s_apb_paddr[15:14] == CTRL_HEAD) begin
                    state_nxt = STATE_SETUP;
                    ctrl_rd_en = 'b1;
                    ctrl_rd_addr = s_apb_paddr[CTRL_ADDR_WIDTH-1:0];
                    case(s_apb_paddr[CTRL_ADDR_WIDTH-1:0])
                        ADDR_AP_START: begin
                            s_apb_prdata = int_ap_start;
                            s_apb_pready = 'b1;
                        end
                        ADDR_AP_DONE: begin
                            s_apb_prdata = int_ap_done;
                            s_apb_pready = 'b1;
                        end
                        ADDR_AP_IDLE: begin
                            s_apb_prdata = int_ap_idle;
                            s_apb_pready = 'b1;
                        end
                        ADDR_DIM_L: begin
                            s_apb_prdata = int_dim_l;
                            s_apb_pready = 'b1;
                        end
                        ADDR_DIM_M: begin
                            s_apb_prdata = int_dim_m;
                            s_apb_pready = 'b1;
                        end
                        ADDR_DIM_N: begin
                            s_apb_prdata = int_dim_n;
                            s_apb_pready = 'b1;
                        end
                        default: begin
                            s_apb_prdata = {APB_DATA_WIDTH{1'bx}};
                        end
                    endcase
                end
            end
        end
        
        STATE_READING: begin
            if(mem_valid) begin
                state_nxt = STATE_SETUP;
                s_apb_prdata = mem_dout;
                s_apb_pready = 'b1;
            end else begin
                state_nxt = STATE_READING;
            end
        end
        
        STATE_WRITE_ACCESS: begin
            // APB write
            if (s_apb_penable == 'b1) begin
                // BRAM
                if (s_apb_paddr[15:14] == DATA_HEAD) begin
                    mem_cen = 'b1;
                    mem_wen = 'b1;
                    mem_addr = s_apb_paddr[DATA_ADDR_WIDTH-1:0];
                    mem_din = s_apb_pwdata;
                end
                // Register
                else if (s_apb_paddr[15:14] == CTRL_HEAD) begin
                    case(s_apb_paddr[CTRL_ADDR_WIDTH-1:0])
                        ADDR_AP_START: begin
                            int_ap_start_nxt = s_apb_pwdata;
                        end
                        ADDR_DIM_L: begin
                            int_dim_l_nxt = s_apb_pwdata;
                        end
                        ADDR_DIM_M: begin
                            int_dim_m_nxt = s_apb_pwdata;
                        end
                        ADDR_DIM_N: begin
                            int_dim_n_nxt = s_apb_pwdata;
                        end
                    endcase
                end
                state_nxt = STATE_SETUP;
                s_apb_pready = 'b1;
            end
        end
    endcase    
end

//////////////////////////////////////////////////////////////////////////
// Control Interface
//////////////////////////////////////////////////////////////////////////

/* TODO: your code  */

/* TODO: end        */

//////////////////////////////////////////////////////////////////////////
// Control Registers
//////////////////////////////////////////////////////////////////////////

/* TODO: your code  */

/* TODO: end        */

//////////////////////////////////////////////////////////////////////////
// Memory Interface
//////////////////////////////////////////////////////////////////////////

/* TODO: your code  */

/* TODO: end        */

//////////////////////////////////////////////////////////////////////////
// APB Protocol
//////////////////////////////////////////////////////////////////////////

/* TODO: your code  */

/* TODO: end        */

//////////////////////////////////////////////////////////////////////////
// LED : Do not modify this code!
//////////////////////////////////////////////////////////////////////////

// LED[0] : access input memory
always @(posedge clk) begin
  if (reset)
    out_led[0]  <= 0;

  else if (mem_cen && mem_addr[BUFF_ADDR_WIDTH-1 -: 2] == 0)
    out_led[0]  <= 1;

  else if (ctrl_rd_en && ctrl_rd_addr == ADDR_AP_DONE)
    out_led[0]  <= 0;
end

// LED[1] : access weight memory
always @(posedge clk) begin
  if (reset)
    out_led[1]  <= 0;

  else if (mem_cen && mem_addr[BUFF_ADDR_WIDTH-1 -: 2] == 1)
    out_led[1]  <= 1;

  else if (ctrl_rd_en && ctrl_rd_addr == ADDR_AP_DONE)
    out_led[1]  <= 0;
end

// LED[2] : access output memory
always @(posedge clk) begin
  if (reset)
    out_led[2]  <= 0;

  else if (mem_cen && mem_addr[BUFF_ADDR_WIDTH-1 -: 2] == 2)
    out_led[2]  <= 1;

  else if (ctrl_rd_en && ctrl_rd_addr == ADDR_AP_DONE)
    out_led[2]  <= 0;
end

// LED[3] : ap done signal
always @(posedge clk) begin
  if (reset)
    out_led[3]  <= 0;

  else if (ap_done)
    out_led[3]  <= 1;
    
  else if (ctrl_rd_en && ctrl_rd_addr == ADDR_AP_DONE)
    out_led[3]  <= 0;
end

//////////////////////////////////////////////////////////////////////////

endmodule
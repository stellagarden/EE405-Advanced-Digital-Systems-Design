// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : data_buffer.sv
// Author        : Castlab
//				         Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: Data buffers for core
// -FHDR------------------------------------------------------------

module data_buffer
  import kernel_pkg::*;
(
  input  logic                          clk,
  input  logic                          reset,

  // Memory interface
  input  logic                          mem_cen,
  input  logic                          mem_wen,
  input  logic [BUFF_ADDR_WIDTH-1:0]    mem_addr,
  input  logic [BUFF_DATA_WIDTH-1:0]    mem_din,
  output logic [BUFF_DATA_WIDTH-1:0]    mem_dout,
  output logic                          mem_valid,

  // Engine interface
  input  logic                          i_rd_en,
  input  logic [IMEM_ADDR_WIDTH-1:0]    i_rd_addr,
  output logic [IMEM_DATA_WIDTH-1:0]    i_rd_data,	  // 32 * 16
  output logic                          i_rd_valid,
  input  logic                          w_rd_en,
  input  logic [WMEM_ADDR_WIDTH-1:0]    w_rd_addr,
  output logic [WMEM_DATA_WIDTH-1:0]    w_rd_data,	  // 32 * 16
  output logic                          w_rd_valid,
  input  logic                          o_wr_en,
  input  logic [OMEM_ADDR_WIDTH-1:0]    o_wr_addr,
  input  logic [OMEM_DATA_WIDTH-1:0]    o_wr_data	  // 32
);

//////////////////////////////////////////////////////////////////////////

logic [BUFF_DATA_WIDTH-1:0]    imem_dout,wmem_dout,omem_dout;
logic                          imem_valid,wmem_valid,omem_valid;
logic [BUFF_ADDR_WIDTH-1:0]    mem_addr_ff;

//////////////////////////////////////////////////////////////////////////
// Input Buffer
//////////////////////////////////////////////////////////////////////////

imem
#(
  .IMEM_ADDR_WIDTH  ( IMEM_ADDR_WIDTH   ),
  .IMEM_DATA_WIDTH  ( IMEM_DATA_WIDTH   )
)
u_imem
(
  .clk              ( clk    ),
  .reset            ( reset    ),

  // Memory interface
  .mem_cen          ( mem_cen    ),
  .mem_wen          ( mem_wen    ),
  .mem_addr         ( mem_addr    ),
  .mem_din          ( mem_din    ),
  .mem_dout         ( imem_dout    ),
  .mem_valid        ( imem_valid    ),

  // Engine interface
  .i_rd_en          ( i_rd_en    ),
  .i_rd_addr        ( i_rd_addr    ),
  .i_rd_data        ( i_rd_data    ),
  .i_rd_valid       ( i_rd_valid    )
);

/* TODO: your code  */

/* TODO: end        */

//////////////////////////////////////////////////////////////////////////
// Weight Buffer
//////////////////////////////////////////////////////////////////////////

wmem
#(
  .WMEM_ADDR_WIDTH  ( WMEM_ADDR_WIDTH   ),
  .WMEM_DATA_WIDTH  ( WMEM_DATA_WIDTH   )
)
u_wmem
(
  .clk              ( clk    ),
  .reset            ( reset    ),

  // Memory interface
  .mem_cen          ( mem_cen    ),
  .mem_wen          ( mem_wen    ),
  .mem_addr         ( mem_addr    ),
  .mem_din          ( mem_din    ),
  .mem_dout         ( wmem_dout    ),
  .mem_valid        ( wmem_valid    ),

  // Engine interface
  .w_rd_en          ( w_rd_en    ),
  .w_rd_addr        ( w_rd_addr    ),
  .w_rd_data        ( w_rd_data    ),
  .w_rd_valid       ( w_rd_valid    )
);

/* TODO: your code  */

/* TODO: end        */

//////////////////////////////////////////////////////////////////////////
// Output Buffer
//////////////////////////////////////////////////////////////////////////

omem
#(
  .OMEM_ADDR_WIDTH  ( OMEM_ADDR_WIDTH   ),
  .OMEM_DATA_WIDTH  ( OMEM_DATA_WIDTH   )
)
u_omem
(
  .clk              ( clk    ),
  .reset            ( reset    ),

  // Memory interface
  .mem_cen          ( mem_cen    ),
  .mem_wen          ( mem_wen    ),
  .mem_addr         ( mem_addr    ),
  .mem_din          ( mem_din    ),
  .mem_dout         ( omem_dout    ),
  .mem_valid        ( omem_valid    ),

  // Engine interface
  .o_wr_en          ( o_wr_en    ),
  .o_wr_addr        ( o_wr_addr    ),
  .o_wr_data        ( o_wr_data    )
);

/* TODO: your code  */

/* TODO: end        */

//////////////////////////////////////////////////////////////////////////
// Arbitration
//////////////////////////////////////////////////////////////////////////
always_ff @ (posedge clk) begin
    if (mem_cen) mem_addr_ff <= mem_addr;
end
always_comb begin
    case(mem_addr_ff[13:12])       // memory type
        0: begin
            // imem
            mem_dout = imem_dout;
            mem_valid = imem_valid;
        end
        1: begin
            // wmem
            mem_dout = wmem_dout;
            mem_valid = wmem_valid;
        end
        2: begin
            // omem
            mem_dout = omem_dout;
            mem_valid = omem_valid;
        end
    endcase
end

//////////////////////////////////////////////////////////////////////////

endmodule
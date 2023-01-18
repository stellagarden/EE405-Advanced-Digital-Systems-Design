// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : omem.sv
// Author        : Castlab
//				         Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: Output data buffers for core
// -FHDR------------------------------------------------------------

module omem
  import kernel_pkg::*;
#(
  parameter OMEM_ADDR_WIDTH             = 10,
  parameter OMEM_DATA_WIDTH             = DATA_WIDTH
)
(
  input  logic                          clk,
  input  logic                          reset,

  // Memory interface
  input  logic                          mem_cen,
  input  logic                          mem_wen,
  input  logic [BUFF_ADDR_WIDTH-1:0]    mem_addr,   // 14
  input  logic [BUFF_DATA_WIDTH-1:0]    mem_din,    // 32
  output logic [BUFF_DATA_WIDTH-1:0]    mem_dout,   // 32
  output logic                          mem_valid,

  // Core interface
  input  logic                          o_wr_en,
  input  logic [OMEM_ADDR_WIDTH-1:0]    o_wr_addr,  // 10
  input  logic [OMEM_DATA_WIDTH-1:0]    o_wr_data   // 32
);

//////////////////////////////////////////////////////////////////////////
// mem_addr (14bit) = mem type (2bit) + real address (10 bit) + byte (2bit)

localparam OMEM_BANK        = OMEM_DATA_WIDTH / BUFF_DATA_WIDTH;    // 1
localparam HIGH_ADDR        = OMEM_ADDR_WIDTH;                      // 10
localparam LOW_ADDR         = $clog2(OMEM_BANK);                    // 0
localparam BYTE_ADDR        = $clog2(BUFF_DATA_WIDTH / 8);          // 2

localparam BRAM_ADDR_WIDTH  = OMEM_ADDR_WIDTH;                      // 10
localparam BRAM_DATA_WIDTH  = BUFF_DATA_WIDTH;                      // 32

//////////////////////////////////////////////////////////////////////////

logic                          mem_cen0;
logic                          mem_wen0;
logic [OMEM_ADDR_WIDTH-1:0]    mem_addr0;
logic [OMEM_DATA_WIDTH-1:0]    mem_din0;

//////////////////////////////////////////////////////////////////////////
// Single Port SRAM
//////////////////////////////////////////////////////////////////////////

always_ff @(posedge clk) begin
    if (mem_cen) begin
        if (mem_addr[13:12] == 2) begin
            if(|mem_wen) begin
                mem_valid <= 0;
            end
            else begin
                mem_valid <= 1;
            end
        end
    end else begin
        mem_valid <= 0;
    end
end

always_comb begin
    mem_cen0 = 0;
    mem_wen0 = 0;
    mem_addr0 = 0;
    mem_din0 = 0;
    
    // Memory interface
    if (mem_cen) begin                      // memory enable
        if (mem_addr[13:12] == 2) begin     // omem selected
            mem_cen0 = 1;
            mem_wen0 = mem_wen;
            mem_addr0 = mem_addr[11:2];
            mem_din0 = mem_din;
        end
    // Engine Interface: Write operation result to omem
    end else if (o_wr_en) begin
        mem_cen0 = 1;
        mem_wen0 = 1;
        mem_addr0 = o_wr_addr;
        mem_din0 = o_wr_data;
    end
end

// Instantiate BRAM
blk_mem_gen_2
u_mem2
(
    .clka   ( clk    ),
    .ena    ( mem_cen0    ),
    .wea    ( mem_wen0    ),
    .addra  ( mem_addr0    ),
    .dina   ( mem_din0    ),
    .douta  ( mem_dout    )
);
//////////////////////////////////////////////////////////////////////////

endmodule
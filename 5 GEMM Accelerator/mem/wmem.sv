// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : wmem.sv
// Author        : Castlab
//				         Junsoo Kim   < junsoo999@kaist.ac.kr   >
// -----------------------------------------------------------------
// Description: Weight data buffers for core
// -FHDR------------------------------------------------------------

// mem_dout? 16 cycles or 1 cycle to read/write?
module wmem
  import kernel_pkg::*;
#(
  parameter WMEM_ADDR_WIDTH             = 10,
  parameter WMEM_DATA_WIDTH             = DATA_WIDTH * VECTOR_LENGTH
)
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
  input  logic                          w_rd_en,
  input  logic [WMEM_ADDR_WIDTH-1:0]    w_rd_addr,
  output logic [WMEM_DATA_WIDTH-1:0]    w_rd_data,
  output logic                          w_rd_valid
);

//////////////////////////////////////////////////////////////////////////
// mem_addr (14bit) = mem type (2bit) + real address (6 bit) + bank # (4bit) + byte (2bit)

localparam WMEM_BANK        = WMEM_DATA_WIDTH / BUFF_DATA_WIDTH;
localparam HIGH_ADDR        = WMEM_ADDR_WIDTH;
localparam LOW_ADDR         = $clog2(WMEM_BANK);
localparam BYTE_ADDR        = $clog2(BUFF_DATA_WIDTH / 8);

localparam BRAM_ADDR_WIDTH  = WMEM_ADDR_WIDTH;
localparam BRAM_DATA_WIDTH  = BUFF_DATA_WIDTH;

//////////////////////////////////////////////////////////////////////////

logic                          mem_cen0,mem_cen1,mem_cen2,mem_cen3,mem_cen4,mem_cen5,mem_cen6,mem_cen7,mem_cen8,mem_cen9,mem_cen10,mem_cen11,mem_cen12,mem_cen13,mem_cen14,mem_cen15;
logic                          mem_wen0,mem_wen1,mem_wen2,mem_wen3,mem_wen4,mem_wen5,mem_wen6,mem_wen7,mem_wen8,mem_wen9,mem_wen10,mem_wen11,mem_wen12,mem_wen13,mem_wen14,mem_wen15;
logic [BUFF_ADDR_WIDTH-1:0]    mem_addr0,mem_addr1,mem_addr2,mem_addr3,mem_addr4,mem_addr5,mem_addr6,mem_addr7,mem_addr8,mem_addr9,mem_addr10,mem_addr11,mem_addr12,mem_addr13,mem_addr14,mem_addr15;
logic [BUFF_DATA_WIDTH-1:0]    mem_dout0,mem_dout1,mem_dout2,mem_dout3,mem_dout4,mem_dout5,mem_dout6,mem_dout7,mem_dout8,mem_dout9,mem_dout10,mem_dout11,mem_dout12,mem_dout13,mem_dout14,mem_dout15;
logic [BUFF_ADDR_WIDTH-1:0]    mem_addr_ff;
logic                          mem_cen_ff, mem_wen_ff;

assign w_rd_data = (w_rd_valid) ? {mem_dout0,mem_dout1,mem_dout2,mem_dout3,mem_dout4,mem_dout5,mem_dout6,mem_dout7,mem_dout8,mem_dout9,mem_dout10,mem_dout11,mem_dout12,mem_dout13,mem_dout14,mem_dout15} : 0;

//////////////////////////////////////////////////////////////////////////
// Single Port SRAM
//////////////////////////////////////////////////////////////////////////

// Host interface
always_ff @(posedge clk) begin
    mem_cen_ff <= mem_cen;
    mem_wen_ff <= mem_wen;
    mem_addr_ff <= mem_addr;
end
// Engine interface
always_ff @(posedge clk) begin
    if (w_rd_en) w_rd_valid <= 1;
    else w_rd_valid <= 0;
end

always_comb begin
    mem_dout = 0;
    mem_valid = 0;
    mem_cen0 = 0;
    mem_cen1 = 0;
    mem_cen2 = 0;
    mem_cen3 = 0;
    mem_cen4 = 0;
    mem_cen5 = 0;
    mem_cen6 = 0;
    mem_cen7 = 0;
    mem_cen8 = 0;
    mem_cen9 = 0;
    mem_cen10 = 0;
    mem_cen11 = 0;
    mem_cen12 = 0;
    mem_cen13 = 0;
    mem_cen14 = 0;
    mem_cen15 = 0;
    mem_wen0 = 0;
    mem_wen1 = 0;
    mem_wen2 = 0;
    mem_wen3 = 0;
    mem_wen4 = 0;
    mem_wen5 = 0;
    mem_wen6 = 0;
    mem_wen7 = 0;
    mem_wen8 = 0;
    mem_wen9 = 0;
    mem_wen10 = 0;
    mem_wen11 = 0;
    mem_wen12 = 0;
    mem_wen13 = 0;
    mem_wen14 = 0;
    mem_wen15 = 0;
    mem_addr0 = 0;
    mem_addr1 = 0;
    mem_addr2 = 0;
    mem_addr3 = 0;
    mem_addr4 = 0;
    mem_addr5 = 0;
    mem_addr6 = 0;
    mem_addr7 = 0;
    mem_addr8 = 0;
    mem_addr9 = 0;
    mem_addr10 = 0;
    mem_addr11 = 0;
    mem_addr12 = 0;
    mem_addr13 = 0;
    mem_addr14 = 0;
    mem_addr15 = 0;
    
    // mem_cen, mem_wen connection //
    // Write in BRAM
    if (mem_cen) begin                      // memory enable
        if (mem_addr[13:12] == 1) begin     // wmem selected
            case (mem_addr[5:2])            // bank number
                0: begin
                    mem_cen0 = 1;
                    mem_wen0 = mem_wen;
                    mem_addr0 = mem_addr[11:6];
                end
                1: begin
                    mem_cen1 = 1;
                    mem_wen1 = mem_wen;
                    mem_addr1 = mem_addr[11:6];
                end
                2: begin
                    mem_cen2 = 1;
                    mem_wen2 = mem_wen;
                    mem_addr2 = mem_addr[11:6];
                end
                3: begin
                    mem_cen3 = 1;
                    mem_wen3 = mem_wen;
                    mem_addr3 = mem_addr[11:6];
                end
                4: begin
                    mem_cen4 = 1;
                    mem_wen4 = mem_wen;
                    mem_addr4 = mem_addr[11:6];
                end
                5: begin
                    mem_cen5 = 1;
                    mem_wen5 = mem_wen;
                    mem_addr5 = mem_addr[11:6];
                end
                6: begin
                    mem_cen6 = 1;
                    mem_wen6 = mem_wen;
                    mem_addr6 = mem_addr[11:6];
                end
                7: begin
                    mem_cen7 = 1;
                    mem_wen7 = mem_wen;
                    mem_addr7 = mem_addr[11:6];
                end
                8: begin
                    mem_cen8 = 1;
                    mem_wen8 = mem_wen;
                    mem_addr8 = mem_addr[11:6];
                end
                9: begin
                    mem_cen9 = 1;
                    mem_wen9 = mem_wen;
                    mem_addr9 = mem_addr[11:6];
                end
                10: begin
                    mem_cen10 = 1;
                    mem_wen10 = mem_wen;
                    mem_addr10 = mem_addr[11:6];
                end
                11: begin
                    mem_cen11 = 1;
                    mem_wen11 = mem_wen;
                    mem_addr11 = mem_addr[11:6];
                end
                12: begin
                    mem_cen12 = 1;
                    mem_wen12 = mem_wen;
                    mem_addr12 = mem_addr[11:6];
                end
                13: begin
                    mem_cen13 = 1;
                    mem_wen13 = mem_wen;
                    mem_addr13 = mem_addr[11:6];
                end
                14: begin
                    mem_cen14 = 1;
                    mem_wen14 = mem_wen;
                    mem_addr14 = mem_addr[11:6];
                end
                15: begin
                    mem_cen15 = 1;
                    mem_wen15 = mem_wen;
                    mem_addr15 = mem_addr[11:6];
                end
            endcase
        end
    // Engine Interface: Read 16 vectors from wmem
    end else if (w_rd_en) begin
        mem_cen0 = 1;
        mem_cen1 = 1;
        mem_cen2 = 1;
        mem_cen3 = 1;
        mem_cen4 = 1;
        mem_cen5 = 1;
        mem_cen6 = 1;
        mem_cen7 = 1;
        mem_cen8 = 1;
        mem_cen9 = 1;
        mem_cen10 = 1;
        mem_cen11 = 1;
        mem_cen12 = 1;
        mem_cen13 = 1;
        mem_cen14 = 1;
        mem_cen15 = 1;
        mem_addr0 = w_rd_addr;
        mem_addr1 = w_rd_addr;
        mem_addr2 = w_rd_addr;
        mem_addr3 = w_rd_addr;
        mem_addr4 = w_rd_addr;
        mem_addr5 = w_rd_addr;
        mem_addr6 = w_rd_addr;
        mem_addr7 = w_rd_addr;
        mem_addr8 = w_rd_addr;
        mem_addr9 = w_rd_addr;
        mem_addr10 = w_rd_addr;
        mem_addr11 = w_rd_addr;
        mem_addr12 = w_rd_addr;
        mem_addr13 = w_rd_addr;
        mem_addr14 = w_rd_addr;
        mem_addr15 = w_rd_addr;
    end
    
    // mem_dout connection //
    if (mem_cen_ff) begin                       // memory enable
        if (mem_addr_ff[13:12] == 1) begin      // wmem selected
            if (mem_wen_ff == 0) begin          // read
                mem_valid = 1;
                case (mem_addr_ff[5:2])         // bank number
                    0: begin
                        mem_dout = mem_dout0;
                    end
                    1: begin
                        mem_dout = mem_dout1;
                    end
                    2: begin
                        mem_dout = mem_dout2;
                    end
                    3: begin
                        mem_dout = mem_dout3;
                    end
                    4: begin
                        mem_dout = mem_dout4;
                    end
                    5: begin
                        mem_dout = mem_dout5;
                    end
                    6: begin
                        mem_dout = mem_dout6;
                    end
                    7: begin
                        mem_dout = mem_dout7;
                    end
                    8: begin
                        mem_dout = mem_dout8;
                    end
                    9: begin
                        mem_dout = mem_dout9;
                    end
                    10: begin
                        mem_dout = mem_dout10;
                    end
                    11: begin
                        mem_dout = mem_dout11;
                    end
                    12: begin
                        mem_dout = mem_dout12;
                    end
                    13: begin
                        mem_dout = mem_dout13;
                    end
                    14: begin
                        mem_dout = mem_dout14;
                    end
                    15: begin
                        mem_dout = mem_dout15;
                    end
                endcase
            end
        end
    end
end

// Instantiate BRAMs
blk_mem_gen_1
u_mem1_0
(
    .clka   ( clk    ),
    .ena    ( mem_cen0    ),
    .wea    ( mem_wen0    ),
    .addra  ( mem_addr0    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout0    )
);

blk_mem_gen_1
u_mem1_1
(
    .clka   ( clk    ),
    .ena    ( mem_cen1    ),
    .wea    ( mem_wen1    ),
    .addra  ( mem_addr1    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout1    )
);

blk_mem_gen_1
u_mem1_2
(
    .clka   ( clk    ),
    .ena    ( mem_cen2    ),
    .wea    ( mem_wen2    ),
    .addra  ( mem_addr2    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout2    )
);

blk_mem_gen_1
u_mem1_3
(
    .clka   ( clk    ),
    .ena    ( mem_cen3    ),
    .wea    ( mem_wen3    ),
    .addra  ( mem_addr3    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout3    )
);

blk_mem_gen_1
u_mem1_4
(
    .clka   ( clk    ),
    .ena    ( mem_cen4    ),
    .wea    ( mem_wen4    ),
    .addra  ( mem_addr4    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout4    )
);

blk_mem_gen_1
u_mem1_5
(
    .clka   ( clk    ),
    .ena    ( mem_cen5    ),
    .wea    ( mem_wen5    ),
    .addra  ( mem_addr5    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout5    )
);

blk_mem_gen_1
u_mem1_6
(
    .clka   ( clk    ),
    .ena    ( mem_cen6    ),
    .wea    ( mem_wen6    ),
    .addra  ( mem_addr6    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout6    )
);

blk_mem_gen_1
u_mem1_7
(
    .clka   ( clk    ),
    .ena    ( mem_cen7    ),
    .wea    ( mem_wen7    ),
    .addra  ( mem_addr7    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout7    )
);

blk_mem_gen_1
u_mem1_8
(
    .clka   ( clk    ),
    .ena    ( mem_cen8    ),
    .wea    ( mem_wen8    ),
    .addra  ( mem_addr8    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout8    )
);

blk_mem_gen_1
u_mem1_9
(
    .clka   ( clk    ),
    .ena    ( mem_cen9    ),
    .wea    ( mem_wen9    ),
    .addra  ( mem_addr9    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout9    )
);

blk_mem_gen_1
u_mem1_10
(
    .clka   ( clk    ),
    .ena    ( mem_cen10    ),
    .wea    ( mem_wen10    ),
    .addra  ( mem_addr10    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout10    )
);

blk_mem_gen_1
u_mem1_11
(
    .clka   ( clk    ),
    .ena    ( mem_cen11    ),
    .wea    ( mem_wen11    ),
    .addra  ( mem_addr11    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout11    )
);

blk_mem_gen_1
u_mem1_12
(
    .clka   ( clk    ),
    .ena    ( mem_cen12    ),
    .wea    ( mem_wen12    ),
    .addra  ( mem_addr12    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout12    )
);

blk_mem_gen_1
u_mem1_13
(
    .clka   ( clk    ),
    .ena    ( mem_cen13    ),
    .wea    ( mem_wen13    ),
    .addra  ( mem_addr13    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout13    )
);

blk_mem_gen_1
u_mem1_14
(
    .clka   ( clk    ),
    .ena    ( mem_cen14    ),
    .wea    ( mem_wen14    ),
    .addra  ( mem_addr14    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout14    )
);

blk_mem_gen_1
u_mem1_15
(
    .clka   ( clk    ),
    .ena    ( mem_cen15    ),
    .wea    ( mem_wen15    ),
    .addra  ( mem_addr15    ),
    .dina   ( mem_din    ),
    .douta  ( mem_dout15    )
);

endmodule
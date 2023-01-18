//////////////////////////////////////////////////////////////////////////
//  EE405(B)
//
//  Name: mental_math_master.sv
//  Description:
//     This module describes a top module of mental_math_master.
//
//////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module mental_math_master
#(
    parameter BIT_WIDTH                                             = 4
)
(
    input  logic                                                    i_clk,
    input  logic                                                    i_rst,
    input  logic                                                    i_sel,
    input  logic                                                    i_ge,
    input  logic                                                    i_lt,
    output logic [3:0][2:0]                                         o_led
);

    logic                                                           alu_enable;
    logic [2*BIT_WIDTH-1:0]                                           alu_operand1;
    logic [BIT_WIDTH-1:0]                                           alu_operand2;
    logic [1:0]                                                     alu_opcode;
    logic [2*BIT_WIDTH-1:0]                                         alu_res;

    logic                                                           opcode_shift;
    logic [(BIT_WIDTH-2)-1:0]                                       opcode_seed;
    logic                                                           opcode_valid;
    logic [(BIT_WIDTH-2)-1:0]                                       opcode_res;

    logic                                                           data_shift;
    logic [BIT_WIDTH-1:0]                                           data_seed;
    logic                                                           data_valid;
    logic [BIT_WIDTH-1:0]                                           data_res;

    logic [3:0][2:0]                                                led_res;

    logic                                                           button_ge;
    logic                                                           button_lt;
    logic                                                           button_sel;

    assign clk                                                      = i_clk;
    assign rstn                                                     = ~i_rst;
    assign button_ge                                                = i_ge;
    assign button_lt                                                = i_lt;
    assign button_sel                                               = i_sel;

    assign o_led                                                    = led_res;

    always_comb begin
    end

    ALU
    #(
        .BIT_WIDTH                                                  (BIT_WIDTH)
    )
    ALU_inst
    (
        .clk                                                        (clk),
        .rstn                                                       (rstn),
        .enable_in                                                  (alu_enable),
        .operand1_in                                                (alu_operand1),
        .operand2_in                                                (alu_operand2),
        .opcode_in                                                  (alu_opcode),
        .res_out                                                    (alu_res)
    );

    LSFR // LSFR that generates random opcode
    #(
        .BIT_WIDTH                                                  (BIT_WIDTH-2)
    )
    LSFR_opcode
    (
        .clk                                                        (clk),
        .rstn                                                       (rstn),
        .shift_in                                                   (opcode_shift),
        .seed_in                                                    (opcode_seed),
        .valid_out                                                  (opcode_valid),
        .res_out                                                    (opcode_res)
    );

    LSFR // LSFR that generates random operand
    #(
        .BIT_WIDTH                                                  (BIT_WIDTH)
    )
    LSFR_data
    (
        .clk                                                        (clk),
        .rstn                                                       (rstn),
        .shift_in                                                   (data_shift),
        .seed_in                                                    (data_seed),
        .valid_out                                                  (data_valid),
        .res_out                                                    (data_res)
    );

    controller
    #(
        .BIT_WIDTH                                                  (BIT_WIDTH)
    )
    controller_inst
    (
        .clk                                                        (clk),
        .rstn                                                       (rstn),
        .ge_in                                                      (button_ge),
        .lt_in                                                      (button_lt),
        .sel_in                                                     (button_sel),
        .opcode_res_in                                              (opcode_res),
        .opcode_shift_out                                           (opcode_shift),
        .opcode_seed_out                                            (opcode_seed),
        .opcode_valid_in                                            (opcode_valid),
        .data_shift_out                                             (data_shift),
        .data_seed_out                                              (data_seed),
        .data_valid_in                                              (data_valid),
        .data_res_in                                                (data_res),
        .operand1_out                                               (alu_operand1),
        .operand2_out                                               (alu_operand2),
        .enable_out                                                 (alu_enable),
        .opcode_out                                                 (alu_opcode),
        .res_in                                                     (alu_res),
        .led_out                                                    (led_res)
    );

endmodule
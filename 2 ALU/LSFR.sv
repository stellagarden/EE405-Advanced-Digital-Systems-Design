//////////////////////////////////////////////////////////////////////////
//  EE405(B)
//
//  Name: LSFR.sv
//  Description:
//     This module describes linear-feedback shift register.
//
//////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module LSFR
#(
    parameter BIT_WIDTH                                             = 4
)
(
    input  logic                                                    clk,
    input  logic                                                    rstn,
    input  logic                                                    shift_in,
    input  logic [BIT_WIDTH-1:0]                                    seed_in,
    output logic                                                    valid_out,
    output logic [BIT_WIDTH-1:0]                                    res_out
);

    // write your code below:
    reg [BIT_WIDTH-1:0] res_out_ff, res_out_nxt;
    reg valid_out_ff, valid_out_nxt;
    
    assign res_out = res_out_ff;
    assign valid_out = valid_out_ff;
    
    always_ff @ (posedge clk) begin
        res_out_ff <= res_out_nxt;
        valid_out_ff <= valid_out_nxt;
    end
    
    always_comb begin
        if (~rstn) begin
            res_out_nxt = seed_in;
            valid_out_nxt = 0;
        end else begin
            if (shift_in) begin
                if (BIT_WIDTH == 4) res_out_nxt = {(res_out_ff[1] ^ res_out_ff[0]),res_out_ff[3],res_out_ff[2],res_out_ff[1]};
                else res_out_nxt = {(res_out_ff[1] ^ res_out_ff[0]),res_out_ff[1]};
                valid_out_nxt = 1;
            end else begin
                // Default values
                res_out_nxt = res_out_ff;
                valid_out_nxt = 0;
            end
        end
    end
    
endmodule
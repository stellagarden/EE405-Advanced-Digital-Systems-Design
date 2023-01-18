//////////////////////////////////////////////////////////////////////////
//  EE405(B)
//
//  Name: ALU.sv
//  Description:
//     This module describes arithmetic logic unit that contains accumulation
//     registers.
//
//////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module ALU
#(
    parameter BIT_WIDTH                                             = 4
)
(
    input  logic                                                    clk,
    input  logic                                                    rstn,
    input  logic                                                    enable_in,      // enable signal that enables the ALU module
    input  logic signed [2*BIT_WIDTH-1:0]                             operand1_in,
    input  logic signed [BIT_WIDTH-1:0]                             operand2_in,
    input  logic [1:0]                                              opcode_in,
    output logic signed [2*BIT_WIDTH-1:0]                           res_out         // result
);
    reg signed [2*BIT_WIDTH-1:0] res_out_ff, res_out_nxt;
    
    assign res_out = res_out_ff;
    
    always_ff @ (posedge clk) begin
        res_out_ff <= res_out_nxt;
    end
    
    always_comb begin
        if (~rstn) begin
            res_out_nxt = 0;
        end else begin
            if (enable_in) begin
                case (opcode_in)
                    2'b00: begin // AND
                        res_out_nxt = (operand1_in & operand2_in) + res_out_ff;
                    end
                    2'b01: begin // multiplication
                        res_out_nxt = (operand1_in * operand2_in) + res_out_ff;
                    end
                    2'b10: begin // addition
                        res_out_nxt = (operand1_in + operand2_in) + res_out_ff;
                    end
                    2'b11: begin // subtraction
                        res_out_nxt = (operand1_in - operand2_in) + res_out_ff;
                    end
                endcase
            end else begin
                // Default output
                res_out_nxt = res_out_ff;
            end
        end
    end
    
endmodule
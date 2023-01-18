//////////////////////////////////////////////////////////////////////////
//  EE405(B)
//
//  Name: controller.sv
//  Description:
//     This module describes controller of mental_math_master.
//
//////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module controller
#(
    parameter BIT_WIDTH                                             = 4
)
(
    input logic                                                     clk,
    input logic                                                     rstn,
    input logic                                                     sel_in,
    input logic                                                     ge_in,
    input logic                                                     lt_in,

    output logic                                                    opcode_shift_out,
    output logic [(BIT_WIDTH-2)-1:0]                                opcode_seed_out,
    input  logic                                                    opcode_valid_in,
    input  logic [(BIT_WIDTH-2)-1:0]                                opcode_res_in,

    output logic                                                    data_shift_out,
    output logic [BIT_WIDTH-1:0]                                    data_seed_out,
    input  logic                                                    data_valid_in,
    input  logic [BIT_WIDTH-1:0]                                    data_res_in,

    output logic                                                    enable_out,
    output logic [2*BIT_WIDTH-1:0]                                    operand1_out,
    output logic [BIT_WIDTH-1:0]                                    operand2_out,
    output logic [1:0]                                              opcode_out,
    input  logic [2*BIT_WIDTH-1:0]                                  res_in,

    output logic [3:0][2:0]                                         led_out
);

    // Buttons
    logic [16:0] timer, timer_nxt;
    
    enum logic [1:0] {
        BT_OFF,
        BT_ON
    } sel_state_ff, sel_state_nxt, ge_state_ff, ge_state_nxt, lt_state_ff, lt_state_nxt;
    
    struct packed{
        logic sel_in;
        logic ge_in;
        logic lt_in;
    } real_buttons_ff, real_buttons_nxt, real_buttons_buffer, buttons_ff, buttons_nxt;
    
    // Controller FSM
    enum logic [4:0] {
        RESET,
        RESET_SEL1,
        RESET_SEL1_WAIT,
        RESET_SEL2,
        RESET_SEL2_WAIT,
        RESET_SEL3,
        RESET_SEL3_WAIT,
        COMPARE,
        COMPARE_WAIT,
        COMPARE_GE,
        COMPARE_LT,
        COMPARE_SEL1,
        COMPARE_SEL1_WAIT,
        COMPARE_SEL2,
        COMPARE_SEL2_WAIT,
        EXCEPTION_SEL1,
        EXCEPTION_SEL2
    } state_ff, state_nxt;
    
    struct packed{
        logic data_shift_out;
        logic opcode_shift_out;
        logic enable_out;
        logic [2*BIT_WIDTH-1:0] operand1;
        logic [BIT_WIDTH-1:0] operand2;
        logic [1:0] opcode_out;
        logic [3:0] led_red, led_green, led_blue;
    } regs_ff, regs_nxt;
    
    // output assignment
    assign data_shift_out = regs_ff.data_shift_out;
    assign opcode_shift_out = regs_ff.opcode_shift_out;
    assign enable_out = regs_ff.enable_out;
    assign operand1_out = regs_ff.operand1;
    assign operand2_out = regs_ff.operand2;
    assign opcode_out = regs_ff.opcode_out;
    assign data_seed_out = 4'b0101;
    assign opcode_seed_out = 2'b10;
    assign led_out[0] = {regs_ff.led_red[0], regs_ff.led_green[0], regs_ff.led_blue[0]};
    assign led_out[1] = {regs_ff.led_red[1], regs_ff.led_green[1], regs_ff.led_blue[1]};
    assign led_out[2] = {regs_ff.led_red[2], regs_ff.led_green[2], regs_ff.led_blue[2]};
    assign led_out[3] = {regs_ff.led_red[3], regs_ff.led_green[3], regs_ff.led_blue[3]};
    
    // Button Debouncing
    always_ff @ (posedge clk) begin
        timer <= timer_nxt;
        real_buttons_ff <= real_buttons_nxt;
    end
    always_comb begin
        if (~rstn) begin
            timer_nxt = 0;
            real_buttons_nxt = {$bits(regs_ff){1'b0}};
        end else begin
            if (timer == 1) begin
                real_buttons_buffer.sel_in = sel_in;
                real_buttons_buffer.ge_in = ge_in;
                real_buttons_buffer.lt_in = lt_in;
                timer_nxt = timer + 1;
            end else if (timer > 1) begin                       // CHANGE THE TIMER VALUE
                timer_nxt = 0;
            end else timer_nxt = timer + 1;
            real_buttons_nxt = real_buttons_buffer;
        end
    end
    
    // Button FSM
    always_ff @ (posedge clk) begin
        sel_state_ff <= rstn ? sel_state_nxt : BT_OFF;
        ge_state_ff <= rstn ? ge_state_nxt : BT_OFF;
        lt_state_ff <= rstn ? lt_state_nxt : BT_OFF;
        buttons_ff <= buttons_nxt;
    end
    // Button FSM - sel
    always_comb begin
        sel_state_nxt = sel_state_ff;
        case (sel_state_ff)
            BT_OFF: begin
                if (real_buttons_ff.sel_in == 1) begin
                    sel_state_nxt = BT_ON;
                    buttons_nxt.sel_in = 1;
                end else begin
                    buttons_nxt.sel_in = 0;
                end
            end
            BT_ON: begin
                if (real_buttons_ff.sel_in == 0) begin
                    sel_state_nxt = BT_OFF;
                end
                buttons_nxt.sel_in = 0;
            end
        endcase
    end
    // Button FSM - ge
    always_comb begin
        ge_state_nxt = ge_state_ff;
        case (ge_state_ff)
            BT_OFF: begin
                if (real_buttons_ff.ge_in == 1) begin
                    ge_state_nxt = BT_ON;
                    buttons_nxt.ge_in = 1;
                end else begin
                    buttons_nxt.ge_in = 0;
                end
            end
            BT_ON: begin
                if (real_buttons_ff.ge_in == 0) begin
                    ge_state_nxt = BT_OFF;
                end
                buttons_nxt.ge_in = 0;
            end
        endcase
    end
    // Button FSM - lt
    always_comb begin
        lt_state_nxt = lt_state_ff;
        case (lt_state_ff)
            BT_OFF: begin
                if (real_buttons_ff.lt_in == 1) begin
                    lt_state_nxt = BT_ON;
                    buttons_nxt.lt_in = 1;
                end else begin
                    buttons_nxt.lt_in = 0;
                end
            end
            BT_ON: begin
                if (real_buttons_ff.lt_in == 0) begin
                    lt_state_nxt = BT_OFF;
                end
                buttons_nxt.lt_in = 0;
            end
        endcase
    end
    
    // Controller FSM
    always_ff @ (posedge clk) begin
        state_ff <= state_nxt;
        regs_ff <= regs_nxt;
    end
    
    always_comb begin
        if (~rstn) begin
            state_nxt = RESET;
            regs_nxt = {$bits(regs_ff){1'b0}};
        end else begin
        state_nxt = state_ff;
        
        regs_nxt.data_shift_out = 0;
        regs_nxt.opcode_shift_out = 0;
        regs_nxt.enable_out = 0;
        regs_nxt.led_red = 0;
        regs_nxt.led_green = 0;
        regs_nxt.led_blue = 0;
        
        
        case (state_ff)
            RESET: begin
                regs_nxt.led_red = 4'b0;
                regs_nxt.led_green = 4'b0;
                regs_nxt.led_blue = 4'b0;
                
                if (buttons_ff.sel_in) state_nxt = RESET_SEL1;
                else state_nxt = RESET;
            end
            RESET_SEL1: begin                
                state_nxt = RESET_SEL1_WAIT; 
            end
            
            RESET_SEL1_WAIT: begin
                regs_nxt.operand1 = data_res_in;
                
                regs_nxt.led_blue = regs_nxt.operand1;
                
                if (buttons_ff.sel_in) state_nxt = RESET_SEL2;
                else if (buttons_ff.ge_in) state_nxt = RESET_SEL1_WAIT;
                else if (buttons_ff.lt_in) state_nxt = RESET_SEL1_WAIT;
            end
            
            RESET_SEL2: begin                
                state_nxt = RESET_SEL2_WAIT;
            end
            
            RESET_SEL2_WAIT: begin
                regs_nxt.opcode_out = opcode_res_in;
                
                if (regs_nxt.opcode_out == 2'b00) regs_nxt.led_green = 4'b0000;
                else if (regs_nxt.opcode_out == 2'b01) regs_nxt.led_green = 4'b0010;
                else if (regs_nxt.opcode_out == 2'b10) regs_nxt.led_green = 4'b0100;
                else if (regs_nxt.opcode_out == 2'b11) regs_nxt.led_green = 4'b1000;
                
                if (buttons_ff.sel_in) state_nxt = RESET_SEL3;
                else if(buttons_ff.ge_in) state_nxt = RESET_SEL2_WAIT;
                else if(buttons_ff.lt_in) state_nxt = RESET_SEL2_WAIT;
            end
            
            RESET_SEL3: begin
                regs_nxt.data_shift_out = 1;
                
                state_nxt = RESET_SEL3_WAIT;
            end
            
            RESET_SEL3_WAIT: begin
                if (data_valid_in) regs_nxt.operand2 = data_res_in;
                
                regs_nxt.led_blue = regs_nxt.operand2;
                
                if (buttons_ff.sel_in) state_nxt = COMPARE;
                else if(buttons_ff.ge_in) state_nxt = RESET_SEL3_WAIT;
                else if(buttons_ff.lt_in) state_nxt = RESET_SEL3_WAIT;
            end
            
            COMPARE: begin
                regs_nxt.led_red = 4'b0;
                regs_nxt.led_green = 4'b0;
                regs_nxt.led_blue = 4'b0;
                
                regs_nxt.enable_out = 1;
                
                state_nxt = COMPARE_WAIT;
            end
            
            COMPARE_WAIT: begin
                regs_nxt.led_red = 4'b0;
                regs_nxt.led_green = 4'b0;
                regs_nxt.led_blue = 4'b0;
                
                if (buttons_ff.sel_in) state_nxt = COMPARE_SEL1;
                else if(buttons_ff.ge_in) state_nxt = COMPARE_GE;
                else if(buttons_ff.lt_in) state_nxt = COMPARE_LT;
            end
            
            COMPARE_GE: begin
                // res_in maintains
                regs_nxt.led_red = ($signed(res_in) >= 0) ? 4'b0 : 4'b1111;
                regs_nxt.led_green = ($signed(res_in) >= 0) ? 4'b1111 : 4'b0;
                regs_nxt.led_blue = 4'b0;
                
                if (buttons_ff.sel_in) state_nxt = COMPARE_SEL1;
                else if(buttons_ff.ge_in) state_nxt = COMPARE_GE;
                else if(buttons_ff.lt_in) state_nxt = COMPARE_LT;
            end
            
            COMPARE_LT: begin
                // res_in maintains
                regs_nxt.led_red = ($signed(res_in) < 0) ? 4'b0 : 4'b1111;
                regs_nxt.led_green = ($signed(res_in) < 0) ? 4'b1111 : 4'b0;
                regs_nxt.led_blue = 4'b0;
                
                if (buttons_ff.sel_in) state_nxt = COMPARE_SEL1;
                else if(buttons_ff.ge_in) state_nxt = COMPARE_GE;
                else if(buttons_ff.lt_in) state_nxt = COMPARE_LT;
            end
            
            COMPARE_SEL1: begin
                regs_nxt.operand1 = res_in;
                regs_nxt.opcode_shift_out = 1;
                
                state_nxt = COMPARE_SEL1_WAIT;
            end
            
            COMPARE_SEL1_WAIT: begin
                if (opcode_valid_in) regs_nxt.opcode_out = opcode_res_in;
                
                if (regs_nxt.opcode_out == 2'b00) regs_nxt.led_green = 4'b0000;
                else if (regs_nxt.opcode_out == 2'b01) regs_nxt.led_green = 4'b0010;
                else if (regs_nxt.opcode_out == 2'b10) regs_nxt.led_green = 4'b0100;
                else if (regs_nxt.opcode_out == 2'b11) regs_nxt.led_green = 4'b1000;
                
                if (buttons_ff.sel_in) state_nxt = COMPARE_SEL2;
                else if(buttons_ff.ge_in) state_nxt = EXCEPTION_SEL1;
                else if(buttons_ff.lt_in) state_nxt = EXCEPTION_SEL1;
            end
            
            COMPARE_SEL2: begin
                regs_nxt.data_shift_out = 1;
                
                state_nxt = COMPARE_SEL2_WAIT;
            end
            
            COMPARE_SEL2_WAIT: begin
                if (data_valid_in) regs_nxt.operand2 = data_res_in;
                
                regs_nxt.led_red = 4'b0;
                regs_nxt.led_green = 4'b0;
                regs_nxt.led_blue = regs_nxt.operand2;
                
                if (buttons_ff.sel_in) state_nxt = COMPARE;
                else if(buttons_ff.ge_in) state_nxt = EXCEPTION_SEL2;
                else if(buttons_ff.lt_in) state_nxt = EXCEPTION_SEL2;
            end
            
            EXCEPTION_SEL1: begin
                regs_nxt.led_red = 4'b0101;
                regs_nxt.led_green = 4'b1010;
                regs_nxt.led_blue = 4'b0;
                
                if (buttons_ff.sel_in) state_nxt = COMPARE_SEL1_WAIT;
                else if(buttons_ff.ge_in) state_nxt = EXCEPTION_SEL1;
                else if(buttons_ff.lt_in) state_nxt = EXCEPTION_SEL1;
            end
            
            EXCEPTION_SEL2: begin
                regs_nxt.led_red = 4'b0101;
                regs_nxt.led_green = 4'b1010;
                regs_nxt.led_blue = 4'b0;
                
                if (buttons_ff.sel_in) state_nxt = COMPARE_SEL2_WAIT;
                else if(buttons_ff.ge_in) state_nxt = EXCEPTION_SEL2;
                else if(buttons_ff.lt_in) state_nxt = EXCEPTION_SEL2;
            end
            
        endcase
        end
    end
    

endmodule
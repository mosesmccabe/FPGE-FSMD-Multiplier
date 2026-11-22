`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2026 09:32:24 AM
// Design Name: 
// Module Name: multiplier_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module multiplier_controller(
    // input signals
    input logic clk,
    input logic rst,
    input logic start,
    input logic count_zero,
    input logic last_iteration,
    
    // output signals
    output logic load_operands,
    output logic run_step,
    output logic done
    );
    
    typedef enum logic [2:0]{
        IDLE, 
        LOAD, 
        CHECK, 
        RUN, 
        DONE,
        WAIT_RELEASE
    } state_t;
    
    state_t state, next_state;
    
    // 1. FSM state register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 2. Next-state logic
    always_comb begin
        next_state = state; // Default: remain in current state

    case (state)

        IDLE: begin
            if (start)
                next_state = LOAD;
        end

        LOAD: begin
            next_state = CHECK;
        end

        CHECK: begin
            if (count_zero)
                next_state = DONE;
            else
                next_state = RUN;
        end

        RUN: begin
            if (last_iteration)
                next_state = DONE;
        end

        DONE: begin
            next_state = WAIT_RELEASE;
        end
        
        WAIT_RELEASE: begin
            if(!start)
                next_state = IDLE;
        end

        default: begin
            next_state = IDLE;
        end

    endcase
    end
    
    // 3. output decoder
    assign load_operands = (state == LOAD);
    assign run_step      = (state == RUN);
    assign done          = (state == DONE);
    
endmodule

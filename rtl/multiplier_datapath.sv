`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2026 10:32:40 AM
// Design Name: 
// Module Name: multiplier_datapath
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


module multiplier_datapath(
    // input signals
    input logic clk,
    input logic rst,
    input logic [3:0] A,
    input logic [3:0] B,
    
    input logic load_operands,
    input logic run_step,
    
    // output signals
    output logic count_zero,
    output logic last_iteration,
    output logic [7:0] product
    );
    
    logic [3:0] A_reg; 
    logic [7:0] product_reg;
    logic [3:0] count;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            A_reg <= '0; 
            product_reg <= '0;
            count <= '0;
        end
        else if (load_operands) begin
            A_reg <= A; 
            product_reg <= '0;
            count <= B;
        end
        else if (run_step) begin
            product_reg <= product_reg + {4'b0000, A_reg};
            count <= count - 4'b0001;
        end
    end
    
    
    assign count_zero = (count == 4'b0000);
    assign last_iteration = (count == 4'b0001);
    assign product = product_reg;
endmodule

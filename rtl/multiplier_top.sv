`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2026 11:44:16 AM
// Design Name: 
// Module Name: multiplier_top
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


module multiplier_top (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    input  logic [3:0] A,
    input  logic [3:0] B,

    output logic [7:0] product,
    output logic       done
);

    // Controller --> Datapath
    logic load_operands;
    logic run_step;

    // Datapath --> Controller
    logic count_zero;
    logic last_iteration;

    // Controller instance
    multiplier_controller u_controller (
        .clk             (clk),
        .rst             (rst),
        .start           (start),

        .count_zero      (count_zero),
        .last_iteration  (last_iteration),

        .load_operands   (load_operands),
        .run_step        (run_step),

        .done            (done)
    );

    // Datapath instance
    multiplier_datapath u_datapath (
        .clk             (clk),
        .rst             (rst),
        .A               (A),
        .B               (B),

        .load_operands   (load_operands),
        .run_step        (run_step),

        .count_zero      (count_zero),
        .last_iteration  (last_iteration),

        .product         (product)
    );

endmodule

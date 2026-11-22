`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2026 04:25:23 PM
// Design Name: 
// Module Name: tb_multiplier_top
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


module tb_multiplier_top;
    logic clk;
    logic rst;
    logic start;
    logic [3:0] A;
    logic [3:0] B;
    
    logic [7:0] product;
    logic done;
    
    multiplier_top DUT (
        .clk (clk),
        .rst (rst),
        .start (start),
        .A (A),
        .B (B),
        
        .product (product),
        .done (done)
    );
    
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    int unsigned pass_count;
    int unsigned fail_count;
    
    initial begin
        int unsigned i, j;
        
        // Initialize inputs
        start = 1'b0;
        A     = 4'd0;
        B     = 4'd0;
        
        pass_count = 0;
        fail_count = 0;
       
    
        // Reset the DUT once
        #1 rst = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        
       
    
        // Run multiple transactions without resetting
//        run_case(4'd7,  4'd0);
//        run_case(4'd9,  4'd1);
//        run_case(4'd5,  4'd3);
//        run_case(4'd15, 4'd15);

         //loop goes here
        

        // Outer loop: operand A
        for (i = 0; i < 16; i++) begin
            // Inner loop: operand B
            for (j = 0; j < 16; j++) begin
                run_case(i[3:0], j[3:0]);
            end
        end
    
        $display("================================");
        $display("  MULTIPLIER VERIFICATION");
        $display("================================");
        $display("Tests executed : %0d", pass_count + fail_count);
        $display("Tests passed   : %0d", pass_count);
        $display("Tests failed   : %0d", fail_count);
        $display("================================");
        
        if ((pass_count == 256) && (fail_count == 0)) begin
            $display("OVERALL RESULT: PASS");
        end
        else begin
            $fatal(1, "OVERALL RESULT: FAIL");
        end
        
        // DUT.u_datapath.count --> This is a hierarchical reference. It allows our testbench to observe the internal count register inside the datapath.
        
        // =====================================================
        // TEST: Asynchronous RESET during multiplication
        // =====================================================
        
        $display("Starting asynchronous reset test...");
        
        // Step 1: Start multiplication: 15 x 15
        @(negedge clk);
        A     = 4'd15;
        B     = 4'd15;
        start = 1'b1;
        
        // Step 2: Remove START after one cycle
        @(negedge clk);
        start = 1'b0;
        
        // Step 3: Wait until five additions are complete
        // Expected: product = 75, count = 10
        wait (DUT.u_datapath.count == 4'd10);
        
        // Verify the operation is in progress
        if (product !== 8'd75)
            $fatal(1, "PRE-RESET FAIL: unexpected product");
        
        if (DUT.u_controller.state !== 3'd3)
            $fatal(1, "PRE-RESET FAIL: FSM not in RUN");
        
        // Step 4: Assert reset between rising clock edges
        @(negedge clk);
        rst = 1'b1;
        
        // Allow nonblocking assignments to complete
        #1;
        
        // Step 5: Verify accumulator reset
        if (product !== 8'd0)
            $fatal(1, "RESET FAIL: product was not cleared");
        else
            $display("PASS: accumulator cleared");
        
        // Step 6: Verify counter reset
        if (DUT.u_datapath.count !== 4'd0)
            $fatal(1, "RESET FAIL: count was not cleared");
        else
            $display("PASS: counter cleared");
        
        // Step 7: Verify FSM returned to IDLE
        // IDLE = 3'd0 in our existing enum
        if (DUT.u_controller.state !== 3'd0)
            $fatal(1, "RESET FAIL: FSM not in IDLE");
        else
            $display("PASS: FSM returned to IDLE");
        
        // Step 8: Verify DONE is inactive
        if (done !== 1'b0)
            $fatal(1, "RESET FAIL: done was not cleared");
        else
            $display("PASS: done remained LOW");
        
        // Step 9: Release reset
        @(negedge clk);
        rst = 1'b0;
        
        $display("ASYNCHRONOUS RESET TEST: PASS");
        
        // Verify that the multiplier recovers
        $display("Starting post-reset recovery test...");
        
        run_case(4'd9, 4'd7);
        
        $display("POST-RESET RECOVERY TEST: PASS");
        
        // ======================================================
        // TEST: START held HIGH after multiplication completes
        // ======================================================
        
        begin : held_start_test
        
            int unsigned cycles_waited;
        
            $display("Starting held-START test...");
        
            // Ensure previous operation has returned to IDLE
            wait (DUT.u_controller.state == 3'd0);
        
            // Begin multiplication: 9 x 7
            @(negedge clk);
            A     = 4'd9;
            B     = 4'd7;
            start = 1'b1;
        
            // IMPORTANT: Do NOT deassert START yet!
        
            // Wait for first completion, with timeout
            cycles_waited = 0;
        
            while ((done !== 1'b1) &&
                   (cycles_waited < 20)) begin
        
                @(negedge clk);
                cycles_waited++;
        
            end
        
            if (done !== 1'b1)
                $fatal(1, "TIMEOUT: multiplication did not finish");
        
            if (product !== 8'd63)
                $fatal(1, "FAIL: incorrect product");
        
            $display("PASS: first multiplication completed");
        
            // Keep START HIGH for 50 additional cycles
            repeat (50) begin
        
                @(negedge clk);
        
                if (DUT.u_controller.state !== 3'd5)
                    $fatal(1, "FAIL: FSM left WAIT_RELEASE");
        
                if (product !== 8'd63)
                    $fatal(1, "FAIL: product changed");
        
                if (done !== 1'b0)
                    $fatal(1, "FAIL: unexpected DONE pulse");
        
                if (DUT.u_datapath.count !== 4'd0)
                    $fatal(1, "FAIL: counter changed");
        
            end
        
            $display("PASS: no retrigger during 50 cycles");
        
            // Release START
            start = 1'b0;
        
            // Wait for controller to transition to IDLE
            @(negedge clk);
        
            if (DUT.u_controller.state !== 3'd0)
                $fatal(1, "FAIL: FSM did not return to IDLE");
        
            $display("PASS: controller returned to IDLE");
        
            $display("HELD-START TEST: PASS");
        
        end
        
        $finish;
    end

    
    task automatic run_case(
        input logic [3:0] test_A,
        input logic [3:0] test_B
    );
    
        logic [7:0] expected;
        int unsigned cycles_waited;
    
        // 1. Calculate expected result
        expected = test_A * test_B;
    
        // 2. Apply inputs at falling edge
        @(negedge clk);
        A     = test_A;
        B     = test_B;
        start = 1'b1;
    
        // 3. Deassert START after one cycle
        @(negedge clk);
        start = 1'b0;
    
        cycles_waited = 0;

        // Wait for DONE, with a maximum of 20 cycles
        while ((done !== 1'b1) && (cycles_waited < 20)) begin
            @(negedge clk);
            cycles_waited++;
        end
        
        // Check whether the multiplication completed
        if (done !== 1'b1) begin
            $fatal(1, "TIMEOUT: %0d x %0d did not finish",
                   test_A, test_B);
        end
    
        if (product !== expected) begin
            fail_count++;
            $error("FAIL: %0d x %0d produced %0d, expected %0d",
                   test_A, test_B, product, expected);
        end
        else begin
            pass_count++;
            $display("PASS: %0d x %0d = %0d",
                     test_A, test_B, product);
        end
    
        // 6. Allow controller to return to IDLE
        @(negedge clk);
    
    endtask

    
endmodule

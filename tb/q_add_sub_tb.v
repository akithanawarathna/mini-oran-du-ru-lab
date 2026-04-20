//`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////////////////
////                          Company: UnderDogSi                                        //
////                          Engineer: AKitha Anupriya                                  //
////                          Create Date: 03/16/2026 10:57:40 AM                        //
////                          Design Name: FFT ACCELERATOR                               //    
////                          Module Name: q_add_sub_tb                                  //
////                          Project Name: DU/RU LAB                                    //
////                          Target Devices: ASIC                                       //
////                          Description: A parameterized model for q bit adds & subs   //
///////////////////////////////////////////////////////////////////////////////////////////

//module q_add_sub_tb;

//    // ── Parameters 
//    parameter integer WIDTH = 16;

//    localparam signed [WIDTH-1:0] MAX_VAL =  (1 << (WIDTH-1)) - 1;  // +32767
//    localparam signed [WIDTH-1:0] MIN_VAL = -(1 << (WIDTH-1));       // -32768

//    // ── DUT signals 
//    reg                       clk;
//    reg                       rst_n;
//    reg                       valid;
//    reg                       op_select;
//    reg  signed [WIDTH-1:0]   op_1;
//    reg  signed [WIDTH-1:0]   op_2;
//    wire signed [WIDTH-1:0]   result;
//    wire                      sat_hi;
//    wire                      sat_lo;
//    wire signed [WIDTH-1:0]   b_mod_value;

//    // ── Instantiate DUT
//    q_add_sub #(
//        .WIDTH(WIDTH)
//    ) DUT (
//        .clk       (clk),
//        .rst_n     (rst_n),
//        .valid     (valid),
//        .op_select (op_select),
//        .op_1      (op_1),
//        .op_2      (op_2),
//        .result    (result),
//        .sat_hi    (sat_hi),
//        .sat_lo    (sat_lo),
//        .b_mod_value (b_mod_value)
//    );

//    // ── Clock: 10ns period (100 MHz) ─────────────────────────
//    initial clk = 0;
//    always #5 clk = ~clk;

//initial begin
//    // ── t=0: everything defined immediately ──────────────
//    rst_n     = 1'b0;        // reset active from the start
//    valid     = 1'b0;        //no valid during reset
//    op_select = 1'b0;
//    op_1      = 16'sd0;
//    op_2      = 16'sd0;

//    // ── Hold reset for 2 falling edges ───────────────────
//    @(negedge clk);
//    @(negedge clk);
//    rst_n = 1'b1;            //release reset cleanly

//    // ── Apply stimulus AFTER reset released ──────────────
//    @(negedge clk);
//    op_1      = -16'sd32750;
//    op_2      = -16'sd47;
//    op_select = 1'b0;        // addition
//    valid     = 1'b1;        // valid only now

//    // ── Capture result after one clock cycle ─────────────
//    @(posedge clk); #1;
//    $display("t=%0t | ADD 1+1 | result=%0d | sat_hi=%b | sat_lo=%b",
//              $time, result, sat_hi, sat_lo);

//    @(negedge clk);
//    valid = 1'b0;

//    #20; $finish;
//end

//endmodule


//`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////////////////
////                          Company: UnderDogSi                                        //
////                          Engineer: AKitha Anupriya                                  //
////                          Create Date: 03/16/2026 10:57:40 AM                        //
////                          Design Name: FFT ACCELERATOR                               //    
////                          Module Name: q_add_sub_tb                                  //
////                          Project Name: DU/RU LAB                                    //
////                          Target Devices: ASIC                                       //
////                          Description: Test bench for q_add_sub                      //
///////////////////////////////////////////////////////////////////////////////////////////
//module q_add_sub_tb;

//    localparam signed [15:0] MAX_VAL =  (1 << 15) - 1;  // +32767
//    localparam signed [15:0] MIN_VAL = -(1 << 15);       // -32768 
//    reg                       clk;
//    reg                       rst_n;
//    reg                       valid;
//    reg                       op_select;
//    reg  signed [15:0]        op_1;
//    reg  signed [15:0]        op_2;
//    wire signed [15:0]        result;
//    wire                      sat_hi;
//    wire                      sat_lo;
   
//    q_add_sub DUT (
//        .clk       (clk),
//        .rst_n     (rst_n),
//        .valid     (valid),
//        .op_select (op_select),
//        .op_1      (op_1),
//        .op_2      (op_2),
//        .result    (result),
//        .sat_hi    (sat_hi),
//        .sat_lo    (sat_lo)
//    );
    
//    initial clk = 0;
//    always #5 clk = ~clk;
//initial begin
    
//    rst_n     = 1'b0;        // reset active from the start
//    valid     = 1'b0;        //no valid during reset
//    op_select = 1'b0;
//    op_1      = 16'sd0;
//    op_2      = 16'sd0;
   
//    @(negedge clk);
//    @(negedge clk);
//    rst_n = 1'b1;            
  
//    @(negedge clk);
//    op_1      = -16'sd32750;
//    op_2      = -16'sd47;
//    op_select = 1'b0;        // addition
//    valid     = 1'b1;        // valid only now
//    @(posedge clk); #1;
//    $display("t=%0t | ADD 1+1 | result=%0d | sat_hi=%b | sat_lo=%b",
//              $time, result, sat_hi, sat_lo);
//    @(negedge clk);
//    valid = 1'b0;
//    #20; $finish;
//end
//endmodule

`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////
//                          Company: UnderDogSi                                        //
//                          Engineer: AKitha Anupriya                                  //
//                          Create Date: 03/16/2026 10:57:40 AM                        //
//                          Design Name: FFT ACCELERATOR                               //
//                          Module Name: q_add_sub_tb                                  //
//                          Project Name: DU/RU LAB                                    //
//                          Target Devices: ASIC                                       //
//                          Description: Test bench for q_add_sub                      //
/////////////////////////////////////////////////////////////////////////////////////////
module q_add_sub_tb;

    localparam signed [15:0] MAX_VAL =  16'sh7FFF;  // +32767
    localparam signed [15:0] MIN_VAL =  16'sh8000;  // -32768

    reg                  clk;
    reg                  rst_n;
    reg                  valid;
    reg                  op_select;
    reg  signed [15:0]   op_1;
    reg  signed [15:0]   op_2;
    wire signed [15:0]   result;
    wire                 sat_hi;
    wire                 sat_lo;

    // Pass/Fail counters
    integer pass_count;
    integer fail_count;

    q_add_sub DUT (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid     (valid),
        .op_select (op_select),
        .op_1      (op_1),
        .op_2      (op_2),
        .result    (result),
        .sat_hi    (sat_hi),
        .sat_lo    (sat_lo)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ─── Task Definition ────────────────────────────────────────────────────────
    task apply_test;
        input signed [15:0] in_op1;
        input signed [15:0] in_op2;
        input               in_op_select;       // 0:add  1:sub
        input signed [15:0] exp_result;
        input               exp_sat_hi;
        input               exp_sat_lo;
        input [127:0]       test_name;          // label for display
        begin
            // --- Drive inputs ---
            @(negedge clk);
            op_1      = in_op1;
            op_2      = in_op2;
            op_select = in_op_select;
            valid     = 1'b1;

            // --- Capture result one cycle after posedge ---
            @(posedge clk); #1;

            // --- Deassert valid ---
            @(negedge clk);
            valid = 1'b0;

            // --- Check ---
            if (result  === exp_result  &&
                sat_hi  === exp_sat_hi  &&
                sat_lo  === exp_sat_lo) begin
                $display("PASS | %-20s | op1=%0d  op2=%0d  %s | result=%0d  sat_hi=%b  sat_lo=%b",
                          test_name,
                          in_op1, in_op2, in_op_select ? "SUB" : "ADD",
                          result, sat_hi, sat_lo);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %-20s | op1=%0d  op2=%0d  %s",
                          test_name,
                          in_op1, in_op2, in_op_select ? "SUB" : "ADD");
                $display("       got  result=%0d  sat_hi=%b  sat_lo=%b",
                          result, sat_hi, sat_lo);
                $display("       exp  result=%0d  sat_hi=%b  sat_lo=%b",
                          exp_result, exp_sat_hi, exp_sat_lo);
                fail_count = fail_count + 1;
            end
        end
    endtask
    // ────────────────────────────────────────────────────────────────────────────

    initial begin
        pass_count = 0;
        fail_count = 0;

        // ---------- Reset sequence ----------
        rst_n     = 1'b0;
        valid     = 1'b0;
        op_select = 1'b0;
        op_1      = 16'sd0;
        op_2      = 16'sd0;

        @(negedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        $display("------------------------------------------------------------");
        $display("              q_add_sub Testbench Starting                  ");
        $display("------------------------------------------------------------");

        // ======================== ADD TESTS ========================

        // Normal addition
        apply_test( 16'sd100,    16'sd200,    1'b0,  16'sd300,    1'b0, 1'b0, "ADD: normal"        );
        apply_test( 16'sd0,      16'sd0,      1'b0,  16'sd0,      1'b0, 1'b0, "ADD: zero+zero"     );
        apply_test(-16'sd100,   -16'sd200,    1'b0, -16'sd300,    1'b0, 1'b0, "ADD: neg+neg"       );
        apply_test( 16'sd500,   -16'sd500,    1'b0,  16'sd0,      1'b0, 1'b0, "ADD: cancel"        );

        // Positive saturation (your original stimulus)
        apply_test(-16'sd32750, -16'sd47,     1'b0,  MIN_VAL,     1'b0, 1'b1, "ADD: neg sat_lo"    );
        apply_test( 16'sd32750,  16'sd47,     1'b0,  MAX_VAL,     1'b1, 1'b0, "ADD: pos sat_hi"    );

        // Boundary: exactly at MAX / MIN — no overflow
        apply_test( MAX_VAL,     16'sd0,      1'b0,  MAX_VAL,     1'b0, 1'b0, "ADD: MAX+0"         );
        apply_test( MIN_VAL,     16'sd0,      1'b0,  MIN_VAL,     1'b0, 1'b0, "ADD: MIN+0"         );

        // One step past boundary — saturate
        apply_test( MAX_VAL,     16'sd1,      1'b0,  MAX_VAL,     1'b1, 1'b0, "ADD: MAX+1 sat"     );
        apply_test( MIN_VAL,    -16'sd1,      1'b0,  MIN_VAL,     1'b0, 1'b1, "ADD: MIN-1 sat"     );

        // ======================== SUB TESTS ========================

        // Normal subtraction
        apply_test( 16'sd500,    16'sd200,    1'b1,  16'sd300,    1'b0, 1'b0, "SUB: normal"        );
        apply_test( 16'sd0,      16'sd0,      1'b1,  16'sd0,      1'b0, 1'b0, "SUB: zero-zero"     );
        apply_test(-16'sd100,    16'sd200,    1'b1, -16'sd300,    1'b0, 1'b0, "SUB: neg-pos"       );
        apply_test( 16'sd100,   -16'sd200,    1'b1,  16'sd300,    1'b0, 1'b0, "SUB: pos-neg"       );

        // Positive saturation via subtraction: MIN - 1
        apply_test( MIN_VAL,     16'sd1,      1'b1,  MIN_VAL,     1'b0, 1'b1, "SUB: MIN-1 sat"     );

        // Negative saturation via subtraction: MAX - (-1)
        apply_test( MAX_VAL,    -16'sd1,      1'b1,  MAX_VAL,     1'b1, 1'b0, "SUB: MAX-(-1) sat"  );

        // Self subtraction
        apply_test( 16'sd12345,  16'sd12345,  1'b1,  16'sd0,      1'b0, 1'b0, "SUB: self"          );
        apply_test( MAX_VAL,     MAX_VAL,     1'b1,  16'sd0,      1'b0, 1'b0, "SUB: MAX-MAX"       );

        // ======================== Summary ========================
        $display("------------------------------------------------------------");
        $display("  TOTAL: %0d tests | PASS: %0d | FAIL: %0d",
                  pass_count + fail_count, pass_count, fail_count);
        $display("------------------------------------------------------------");

        #20;
        $finish;
    end

endmodule
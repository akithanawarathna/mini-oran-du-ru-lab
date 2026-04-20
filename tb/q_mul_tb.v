`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////
//                          Company: UnderDogSi                                        //
//                          Engineer: AKitha Anupriya                                  //
//                          Create Date: 03/16/2026 10:57:40 AM                        //
//                          Design Name: FFT ACCELERATOR                               //
//                          Module Name: q_mul_tb                                      //
//                          Project Name: DU/RU LAB                                    //
//                          Target Devices: ASIC                                       //
//                          Description: Test bench for q_mul                          //
/////////////////////////////////////////////////////////////////////////////////////////
module q_mul_tb;
    reg                  clk;
    reg                  rst_n;
    reg                  valid;
    reg  signed [15:0]   op_1;
    reg  signed [15:0]   op_2;
    wire signed [15:0]   result;

    q_mul DUT (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid     (valid),
        .op_1      (op_1),
        .op_2      (op_2),
        .result    (result)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ─── Task Definition ────────────────────────────────────────────────────────
    task apply_test;
        input signed [15:0] in_op1;
        input signed [15:0] in_op2;
        input signed [15:0] expected;
        begin
            @(negedge clk);
            op_1  = in_op1;
            op_2  = in_op2;
            valid = 1'b1;

            @(negedge clk);          // wait one cycle for result
            valid = 1'b0;

            @(negedge clk);          // extra settle cycle
            if (result === expected)
                $display("PASS | op1=%0d  op2=%0d  =>  result=%0d",
                          in_op1, in_op2, result);
            else
                $display("FAIL | op1=%0d  op2=%0d  =>  got=%0d  expected=%0d",
                          in_op1, in_op2, result, expected);
        end
    endtask
    // ────────────────────────────────────────────────────────────────────────────

    initial begin
        // ---------- Reset sequence ----------
        rst_n = 1'b0;
        valid = 1'b0;
        op_1  = 16'sd0;
        op_2  = 16'sd0;

        @(negedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // ---------- Test cases ----------
        // Q15 format: 1.0 = 32767 (0x7FFF), 0.5 = 16384 (0x4000)
        //             result = (op1 * op2) >> 15

        // 0.5 * 0.5 = 0.25  =>  16384 * 16384 >> 15 = 8192
        apply_test(16'sd16384, 16'sd16384, 16'sd8192);

        // 1.0 * 0.5 = 0.5   =>  32767 * 16384 >> 15 = 16383
        apply_test(16'sd32767, 16'sd16384, 16'sd16383);

        // 0.5 * -0.5 = -0.25  =>  16384 * -16384 >> 15 = -8192
        apply_test(16'sd16384, -16'sd16384, -16'sd8192);

        // 0 * anything = 0
        apply_test(16'sd0, 16'sd16384, 16'sd0);

        $display("Simulation done.");
        $finish;
    end

endmodule

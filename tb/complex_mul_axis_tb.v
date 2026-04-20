`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////
//                          Company: UnderDogSi                                        //
//                          Engineer: AKitha Anupriya                                  //
//                          Create Date: 03/28/2026 10:40:40 AM                        //
//                          Design Name: FFT ACCELERATOR                               //    
//                          Module Name: complex_mul_axis_tb                           //
//                          Project Name: DU/RU LAB                                    //
//                          Target Devices: ASIC                                       //
//                          Description: Test bench for complex_mul_axis               //
/////////////////////////////////////////////////////////////////////////////////////////
module complex_mul_axis_tb;
    reg                  clk;
    reg                  rst_n;
    reg                  valid;
    reg  [31:0]          op_1;
    reg  [31:0]          op_2;
    wire signed [31:0]   result;
    wire                 out_valid;

    complex_mul_axis DUT (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid     (valid),
        .op_1      (op_1),
        .op_2      (op_2),
        .result    (result),
        .out_valid (out_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ─── Task Definition ────────────────────────────────────────────────────────
    // op_1 = {imag[31:16], real[15:0]}
    // op_2 = {imag[31:16], real[15:0]}
    // result = {imag_out[31:16], real_out[15:0]}
    task apply_test;
        input [31:0]        in_op1;
        input [31:0]        in_op2;
        input signed [15:0] exp_real;
        input signed [15:0] exp_imag;
        integer timeout;
        begin
            // --- Drive inputs on negedge ---
            @(negedge clk);
            op_1  = in_op1;
            op_2  = in_op2;
            valid = 1'b1;

            @(negedge clk);
            valid = 1'b0;           // deassert after one cycle

            // --- Wait for out_valid with timeout ---
            timeout = 0;
            while (!out_valid && timeout < 20) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            // --- Check result ---
            if (timeout >= 20) begin
                $display("TIMEOUT | op1=0x%08h  op2=0x%08h  =>  out_valid never asserted",
                          in_op1, in_op2);
            end else if (result[15:0]  === exp_real &&
                         result[31:16] === exp_imag) begin
                $display("PASS | op1=0x%08h  op2=0x%08h  =>  real=%0d  imag=%0d",
                          in_op1, in_op2,
                          $signed(result[15:0]), $signed(result[31:16]));
            end else begin
                $display("FAIL | op1=0x%08h  op2=0x%08h",
                          in_op1, in_op2);
                $display("       got  real=%0d  imag=%0d",
                          $signed(result[15:0]), $signed(result[31:16]));
                $display("       exp  real=%0d  imag=%0d",
                          exp_real, exp_imag);
            end
        end
    endtask
    // ────────────────────────────────────────────────────────────────────────────

    initial begin
        // ---------- Reset sequence ----------
        rst_n = 1'b0;
        valid = 1'b0;
        op_1  = 32'd0;
        op_2  = 32'd0;

        @(negedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // ---------- Test cases ----------
        // op format : {imag[31:16], real[15:0]}  (Q15 fixed-point)
        //
        // Complex multiply: (a+jb)(c+jd) = (ac-bd) + j(ad+bc)
        // All values Q15: 1.0 = 16384 (0x4000), -1.0 = -16384 (0xC000)

        // Test 1 - from your original stimulus
        // op1 = {16'hF5CC, 16'hDF6D}  op2 = {16'h7BCC, 16'hF5C5}
        apply_test(
            32'b1111_0101_1100_1100_1101_1111_0110_1101,
            32'b0111_1011_1100_1100_1111_0101_1100_0101,
            16'sd0,     // <-- replace with actual expected real
            16'sd0      // <-- replace with actual expected imag
        );

        // Test 2 - (1+j0)(1+j0) = 1+j0
        // 1.0 in Q15 = 16384 = 0x4000
        apply_test(
            {16'h0000, 16'h4000},   // op1: imag=0,      real=0.5 (0x4000 = 16384)
            {16'h0000, 16'h4000},   // op2: imag=0,      real=0.5
            16'sd8192,              // expected real: 0.5*0.5 = 0.25 => 8192
            16'sd0                  // expected imag: 0
        );

        // Test 3 - (0+j1)(0+j1) = -1+j0
        apply_test(
            {16'h4000, 16'h0000},   // op1: imag=0.5, real=0
            {16'h4000, 16'h0000},   // op2: imag=0.5, real=0
            -16'sd8192,             // expected real: -(0.5*0.5) = -0.25 => -8192
            16'sd0                  // expected imag: 0
        );

        // Test 4 - zero operand
        apply_test(
            32'd0,
            {16'h4000, 16'h4000},
            16'sd0,
            16'sd0
        );

        $display("Simulation done.");
        $finish;
    end

endmodule

//`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////////////////
////                          Company: UnderDogSi                                        //
////                          Engineer: AKitha Anupriya                                  //
////                          Create Date: 04/01/2026 03:32:32 PM                        //
////                          Design Name: FFT ACCELERATOR                               //    
////                          Module Name: complex_mul_axis_wrap_tb                      //
////                          Project Name: DU/RU LAB                                    //
////                          Target Devices: ASIC                                       //
////                          Description: Test bench for complex_mul_axis_w             //
///////////////////////////////////////////////////////////////////////////////////////////


//module complex_mul_axis_wrap_tb;

//reg aclk;
//reg aresetn;

//reg s_axis_tvalid;
//wire s_axis_tready;
//reg [63:0] s_axis_tdata;   // {op_1[31:0], op_2[31:0]}
//reg s_axis_tlast;

//wire m_axis_tvalid;
//reg  m_axis_tready;
//wire [31:0] m_axis_tdata;   // {result_re[15:0], result_im[15:0]}
//wire m_axis_tlast;

//complex_mul_axis_wrap DUT(
//    .aclk(aclk),
//    .aresetn(aresetn),
//    .s_axis_tvalid(s_axis_tvalid),
//    .s_axis_tready(s_axis_tready),
//    .s_axis_tdata(s_axis_tdata),
//    .s_axis_tlast(s_axis_tlast),
//    .m_axis_tvalid(m_axis_tvalid),
//    .m_axis_tready(m_axis_tready),
//    .m_axis_tdata(m_axis_tdata),
//    .m_axis_tlast(m_axis_tlast)
//);

//initial aclk = 0;
//always #5 aclk = ~aclk;

//initial begin
//    @(negedge aclk);
//    aresetn = 1'b0;
//    @(negedge aclk);
//    aresetn = 1'b1;
//    s_axis_tvalid = 1'b1;
//    s_axis_tdata = 64'b111101011101010101111111010111111101010101111111111;
//    s_axis_tlast = 1'b1;
//    m_axis_tready = 1'b1; 
    
//end





//endmodule



`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////
//                          Company: UnderDogSi                                        //
//                          Engineer: AKitha Anupriya                                  //
//                          Create Date: 04/01/2026 03:32:32 PM                        //
//                          Design Name: FFT ACCELERATOR                               //    
//                          Module Name: complex_mul_axis_wrap_tb                      //
//                          Project Name: DU/RU LAB                                    //
//                          Target Devices: ASIC                                       //
//                          Description: Test bench for complex_mul_axis_wrap          //
/////////////////////////////////////////////////////////////////////////////////////////
module complex_mul_axis_wrap_tb;

    // ─────────────────────────────────────────────
    // DUT ports
    // ─────────────────────────────────────────────
    reg         aclk;
    reg         aresetn;
    reg         s_axis_tvalid;
    wire        s_axis_tready;
    reg  [63:0] s_axis_tdata;
    reg         s_axis_tlast;
    wire        m_axis_tvalid;
    reg         m_axis_tready;
    wire [31:0] m_axis_tdata;
    wire        m_axis_tlast;

    // ─────────────────────────────────────────────
    // DUT instantiation
    // ─────────────────────────────────────────────
    complex_mul_axis_wrap DUT (
        .aclk          (aclk),
        .aresetn       (aresetn),
        .s_axis_tvalid (s_axis_tvalid),
        .s_axis_tready (s_axis_tready),
        .s_axis_tdata  (s_axis_tdata),
        .s_axis_tlast  (s_axis_tlast),
        .m_axis_tvalid (m_axis_tvalid),
        .m_axis_tready (m_axis_tready),
        .m_axis_tdata  (m_axis_tdata),
        .m_axis_tlast  (m_axis_tlast)
    );

    // ─────────────────────────────────────────────
    // Clock - 10ns period (100 MHz)
    // ─────────────────────────────────────────────
    initial aclk = 0;
    always #5 aclk = ~aclk;

    // ─────────────────────────────────────────────
    // Q1.15 helpers
    // 1.0  = 32767  (0x7FFF)
    // 0.5  = 16384  (0x4000)
    // -1.0 = -32768 (0x8000)
    // ─────────────────────────────────────────────
    // Pack {re1, im1, re2, im2} into 64-bit TDATA
    // TDATA[63:32] = op_1 = {re1[15:0], im1[15:0]}
    // TDATA[31: 0] = op_2 = {re2[15:0], im2[15:0]}
    function [63:0] pack;
        input signed [15:0] re1, im1, re2, im2;
        pack = {re1, im1, re2, im2};
    endfunction

    // ─────────────────────────────────────────────
    // Expected result scoreboard
    // ─────────────────────────────────────────────
    // re_out = re1*re2 - im1*im2  (Q1.15)
    // im_out = re1*im2 + im1*re2  (Q1.15)
    // We store expected values pushed in order
    // ─────────────────────────────────────────────
    reg signed [15:0] exp_re_q [0:31];
    reg signed [15:0] exp_im_q [0:31];
    integer           exp_wr_ptr;
    integer           exp_rd_ptr;
    integer           pass_count;
    integer           fail_count;

    // Compute expected Q1.15 result (truncated, matches DUT rounding)
    function signed [15:0] q_mul_ref;
        input signed [15:0] a, b;
        reg signed [31:0] raw;
        reg signed [31:0] rounded;
        begin
            raw     = a * b;
            rounded = (raw + 32'sd16384) >>> 15;
            if      (rounded >  32'sd32767)  q_mul_ref = 16'sd32767;
            else if (rounded < -32'sd32768)  q_mul_ref = -16'sd32768;
            else                             q_mul_ref = rounded[15:0];
        end
    endfunction

    function signed [15:0] q_add_ref;
        input signed [15:0] a, b;
        reg signed [16:0] s;
        begin
            s = {a[15], a} + {b[15], b};
            if      (s >  17'sd32767)  q_add_ref = 16'sd32767;
            else if (s < -17'sd32768)  q_add_ref = -16'sd32768;
            else                       q_add_ref = s[15:0];
        end
    endfunction

    function signed [15:0] q_sub_ref;
        input signed [15:0] a, b;
        reg signed [16:0] s;
        begin
            s = {a[15], a} - {b[15], b};
            if      (s >  17'sd32767)  q_sub_ref = 16'sd32767;
            else if (s < -17'sd32768)  q_sub_ref = -16'sd32768;
            else                       q_sub_ref = s[15:0];
        end
    endfunction

    task compute_expected;
        input signed [15:0] re1, im1, re2, im2;
        reg   signed [15:0] r1r2, i1i2, r1i2, i1r2;
        begin
            r1r2 = q_mul_ref(re1, re2);
            i1i2 = q_mul_ref(im1, im2);
            r1i2 = q_mul_ref(re1, im2);
            i1r2 = q_mul_ref(im1, re2);
            exp_re_q[exp_wr_ptr] = q_sub_ref(r1r2, i1i2);
            exp_im_q[exp_wr_ptr] = q_add_ref(r1i2, i1r2);
            exp_wr_ptr = exp_wr_ptr + 1;
        end
    endtask

    // ─────────────────────────────────────────────
    // Output monitor - checks every M_AXIS transfer
    // ─────────────────────────────────────────────
    always @(posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            if (exp_rd_ptr < exp_wr_ptr) begin
                if (m_axis_tdata[31:16] === exp_re_q[exp_rd_ptr] &&
                    m_axis_tdata[15: 0] === exp_im_q[exp_rd_ptr]) begin
                    $display("[PASS] result %0d | got re=%0d im=%0d | expected re=%0d im=%0d",
                        exp_rd_ptr,
                        $signed(m_axis_tdata[31:16]),
                        $signed(m_axis_tdata[15:0]),
                        exp_re_q[exp_rd_ptr],
                        exp_im_q[exp_rd_ptr]);
                    pass_count = pass_count + 1;
                end else begin
                    $display("[FAIL] result %0d | got re=%0d im=%0d | expected re=%0d im=%0d",
                        exp_rd_ptr,
                        $signed(m_axis_tdata[31:16]),
                        $signed(m_axis_tdata[15:0]),
                        exp_re_q[exp_rd_ptr],
                        exp_im_q[exp_rd_ptr]);
                    fail_count = fail_count + 1;
                end
                exp_rd_ptr = exp_rd_ptr + 1;
            end else begin
                $display("[ERROR] unexpected output at time %0t", $time);
            end
        end
    end

    // ─────────────────────────────────────────────
    // Task: send one AXI-Stream transaction
    // ─────────────────────────────────────────────
    task send_sample;
        input signed [15:0] re1, im1, re2, im2;
        input               tlast;
        begin
            // wait for slave to be ready
            @(negedge aclk);
            while (!s_axis_tready) @(negedge aclk);

            s_axis_tvalid = 1'b1;
            s_axis_tdata  = pack(re1, im1, re2, im2);
            s_axis_tlast  = tlast;
            compute_expected(re1, im1, re2, im2);

            @(negedge aclk);
            s_axis_tvalid = 1'b0;
            s_axis_tdata  = 64'd0;
            s_axis_tlast  = 1'b0;
        end
    endtask

    // ─────────────────────────────────────────────
    // Task: wait for N output transactions
    // ─────────────────────────────────────────────
    task wait_outputs;
        input integer n;
        integer count;
        begin
            count = 0;
            while (count < n) begin
                @(posedge aclk);
                if (m_axis_tvalid && m_axis_tready)
                    count = count + 1;
            end
        end
    endtask

    // ─────────────────────────────────────────────
    // MAIN TEST
    // ─────────────────────────────────────────────
    integer i;

    initial begin
        // init
        aresetn       = 1'b0;
        s_axis_tvalid = 1'b0;
        s_axis_tdata  = 64'd0;
        s_axis_tlast  = 1'b0;
        m_axis_tready = 1'b1;
        exp_wr_ptr    = 0;
        exp_rd_ptr    = 0;
        pass_count    = 0;
        fail_count    = 0;

        // ── Reset ──────────────────────────────
        repeat(3) @(negedge aclk);
        aresetn = 1'b1;
        repeat(2) @(negedge aclk);

        $display("\n=== TEST 1: Basic single transaction ===");
        // (1+0j) * (1+0j) = 1+0j
        // re1=32767 im1=0 re2=32767 im2=0
        send_sample(16'sd32767, 16'sd0, 16'sd32767, 16'sd0, 1'b1);
        wait_outputs(1);
        repeat(2) @(negedge aclk);

        $display("\n=== TEST 2: Continuous stream, TREADY always high ===");
        m_axis_tready = 1'b1;
        // (0.5 + 0.5j) * (0.5 - 0.5j) = 0.5 + 0j
        send_sample(16'sd16384, 16'sd16384,  16'sd16384, -16'sd16384, 1'b0);
        // (1 + 0j) * (0 + 1j) = 0 + 1j
        send_sample(16'sd32767, 16'sd0,       16'sd0,     16'sd32767, 1'b0);
        // (-1 + 0j) * (1 + 0j) = -1 + 0j
        send_sample(-16'sd32768, 16'sd0,      16'sd32767, 16'sd0,     1'b0);
        // (0.5 + 0j) * (0.5 + 0j) = 0.25 + 0j
        send_sample(16'sd16384, 16'sd0,       16'sd16384, 16'sd0,     1'b1);
        wait_outputs(4);
        repeat(2) @(negedge aclk);

        $display("\n=== TEST 3: Backpressure - TREADY toggles ===");
        // Send 4 samples but toggle TREADY every 2 cycles
        fork
            begin
                send_sample(16'sd16384,  16'sd8192,  16'sd16384, -16'sd8192, 1'b0);
                send_sample(16'sd8192,   16'sd16384, 16'sd8192,   16'sd16384, 1'b0);
                send_sample(-16'sd16384, 16'sd16384, 16'sd16384,  16'sd16384, 1'b0);
                send_sample(16'sd32767,  16'sd32767, 16'sd16384, -16'sd16384, 1'b1);
            end
            begin
                // Toggle TREADY - simulate slow downstream
                repeat(20) begin
                    m_axis_tready = 1'b0;
                    repeat(2) @(negedge aclk);
                    m_axis_tready = 1'b1;
                    repeat(2) @(negedge aclk);
                end
            end
        join
        m_axis_tready = 1'b1;
        wait_outputs(4);
        repeat(5) @(negedge aclk);

        $display("\n=== TEST 4: TVALID gaps - master not always valid ===");
        m_axis_tready = 1'b1;
        // Send with gaps between transactions
        send_sample(16'sd16384, 16'sd0,  16'sd16384, 16'sd0, 1'b0);
        repeat(4) @(negedge aclk);   // gap
        send_sample(16'sd32767, 16'sd0,  16'sd0,     16'sd0, 1'b0);
        repeat(6) @(negedge aclk);   // longer gap
        send_sample(16'sd0,     16'sd0,  16'sd32767, 16'sd0, 1'b1);
        wait_outputs(3);
        repeat(2) @(negedge aclk);

        $display("\n=== TEST 5: Saturation - overflow inputs ===");
        m_axis_tready = 1'b1;
        // (1 + 1j) * (1 + 1j) = 0 + 2j  → im saturates to +1
        send_sample(16'sd32767, 16'sd32767, 16'sd32767, 16'sd32767, 1'b1);
        wait_outputs(1);
        repeat(2) @(negedge aclk);

        $display("\n=== TEST 6: Zero inputs ===");
        send_sample(16'sd0, 16'sd0, 16'sd0, 16'sd0, 1'b1);
        wait_outputs(1);
        repeat(2) @(negedge aclk);

        // ── Final report ───────────────────────
        repeat(5) @(negedge aclk);
        $display("\n==========================================");
        $display(" RESULTS: %0d PASSED  |  %0d FAILED", pass_count, fail_count);
        $display("==========================================\n");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED - check waveform");

        $finish;
    end

    // ─────────────────────────────────────────────
    // Timeout watchdog - prevents infinite hang
    // ─────────────────────────────────────────────
    initial begin
        #50000;
        $display("[TIMEOUT] simulation exceeded 50us");
        $finish;
    end

    // ─────────────────────────────────────────────
    // Waveform dump
    // ─────────────────────────────────────────────
    initial begin
        $dumpfile("complex_mul_axis_wrap_tb.vcd");
        $dumpvars(0, complex_mul_axis_wrap_tb);
    end

endmodule



`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////
//                          Company: UnderDogSi                                        //
//                          Engineer: Akitha Anupriya                                  //
//                          Create Date: 04/22/2026 01:47:30 PM                        //
//                          Design Name: FFT ACCELERATOR                               //
//                          Module Name: tb_complex_mul_axis_wrap                      //
//                          Testbench for complex_mul_axis_wrap_updated                //
//                          Project Name: DU/RU LAB                                    //
//                          Target Devices: ASIC                                       //
/////////////////////////////////////////////////////////////////////////////////////////

module complex_mul_axis_wrap_tb;

    // -----------------------------------------------------------------------
    //  Parameters - must match DUT
    // -----------------------------------------------------------------------
    parameter integer PIPE_LAT   = 2;
    parameter integer FIFO_DEPTH = 8;
    parameter integer CLK_HALF   = 5;   // 5 ns half-period = 100 MHz

    // -----------------------------------------------------------------------
    //  DUT signals
    // -----------------------------------------------------------------------
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

    // -----------------------------------------------------------------------
    //  Test counters 
    // -----------------------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer test_num;

    // -----------------------------------------------------------------------
    //  Storage for receive_beat outputs
    // -----------------------------------------------------------------------
    reg [31:0] rx_data;
    reg        rx_last;

    // -----------------------------------------------------------------------
    //  Loop / scratch variables
    // -----------------------------------------------------------------------
    integer k;
    integer accepted;

    reg [63:0] beat_data;
    reg        beat_last;

    // -----------------------------------------------------------------------
    //  DUT instantiation
    // -----------------------------------------------------------------------
    complex_mul_axis_wrap #(
        .PIPE_LAT   (PIPE_LAT),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) dut (
        .aclk           (aclk),
        .aresetn        (aresetn),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tlast   (s_axis_tlast),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tlast   (m_axis_tlast)
    );

    // -----------------------------------------------------------------------
    //  Clock
    // -----------------------------------------------------------------------
    initial aclk = 1'b0;
    always #(CLK_HALF) aclk = ~aclk;

    // -----------------------------------------------------------------------
    //  Task : apply_reset
    //  Puts all inputs in a known idle state, holds aresetn low for 4 cycles,
    //  then releases it and waits one extra cycle for the DUT to settle.
    // -----------------------------------------------------------------------
    task apply_reset;
        begin
            aresetn       = 1'b0;
            s_axis_tvalid = 1'b0;
            s_axis_tdata  = 64'd0;
            s_axis_tlast  = 1'b0;
            m_axis_tready = 1'b0;
            repeat(4) @(posedge aclk);
            #1;
            aresetn = 1'b1;
            @(posedge aclk);
            $display("[%0t ns] Reset released.", $time);
        end
    endtask

    // -----------------------------------------------------------------------
    //  Task : send_beat
    //  Drives tvalid + tdata + tlast, then waits for tready (handshake).
    //  After the handshake it drops tvalid for one idle cycle.
    // -----------------------------------------------------------------------
    task send_beat;
        input [63:0] data;
        input        last;
        begin
            s_axis_tvalid = 1'b1;
            s_axis_tdata  = data;
            s_axis_tlast  = last;
            @(posedge aclk);
            while (s_axis_tready === 1'b0)
                @(posedge aclk);
            #1;
            s_axis_tvalid = 1'b0;
            s_axis_tlast  = 1'b0;
        end
    endtask

    // -----------------------------------------------------------------------
    //  Task : receive_beat
    //  Asserts tready and waits until the DUT presents tvalid.
    //  Captures tdata / tlast into output ports, then drops tready.
    //
    //  HOW TO CALL:
    //    receive_beat (rx_data, rx_last);
    // -----------------------------------------------------------------------
    task receive_beat;
        output [31:0] data;
        output        last;
        begin
            m_axis_tready = 1'b1;
            @(posedge aclk);
            while (m_axis_tvalid === 1'b0)
                @(posedge aclk);
            data = m_axis_tdata;
            last = m_axis_tlast;
            #1;
            m_axis_tready = 1'b0;
        end
    endtask

    // -----------------------------------------------------------------------
    //  Task : wait_cycles
    //  Waits exactly n rising edges of aclk.
    // -----------------------------------------------------------------------
    task wait_cycles;
        input integer n;
        begin
            repeat(n) @(posedge aclk);
        end
    endtask

    // -----------------------------------------------------------------------
    //  Task : check
    //  Prints PASS / FAIL and updates counters.
    //  msg is a wide packed reg treated as a Verilog string.
    // -----------------------------------------------------------------------
    task check;
        input             condition;
        input [320*8-1:0] msg;
        begin
            test_num = test_num + 1;
            if (condition) begin
                $display("  [PASS] Test %0d : %s", test_num, msg);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] Test %0d : %s  (time = %0t ns)",
                          test_num, msg, $time);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    //  Main test sequence
    // -----------------------------------------------------------------------
    initial begin

        pass_count = 0;
        fail_count = 0;
        test_num   = 0;

        $display("======================================================");
        $display("  PIPE_LAT   = %0d", PIPE_LAT);
        $display("  FIFO_DEPTH = %0d", FIFO_DEPTH);
        $display("======================================================");

        // ==================================================================
        //  TEST 1 : Reset State
        //  After reset: FIFO empty → m_axis_tvalid = 0
        //               FIFO free  → s_axis_tready = 1
        // ==================================================================
        $display("\n--- Test 1 : Reset State ---");
        apply_reset;
        #1;
        check(m_axis_tvalid === 1'b0, "m_axis_tvalid=0 after reset");
        check(s_axis_tready === 1'b1, "s_axis_tready=1 after reset");

        // ==================================================================
        //  TEST 2 : Single Transaction
        //  One beat, tlast=1. After PIPE_LAT+margin cycles the output
        //  must be valid and tlast must be propagated correctly.
        // ==================================================================
        $display("\n--- Test 2 : Single Transaction ---");
        m_axis_tready = 1'b1;

        beat_data = 64'hAABBCCDD11223344;
        beat_last = 1'b1;
        send_beat (beat_data, beat_last);

        wait_cycles (PIPE_LAT + 4);
        //wait_cycles (PIPE_LAT + 10);
        check(m_axis_tvalid === 1'b1, "Output valid after single beat");
        check(m_axis_tlast  === 1'b1, "TLAST=1 for single-beat packet");

        @(posedge aclk);
        m_axis_tready = 1'b0;
        wait_cycles (2);

        // ==================================================================
        //  TEST 3 : Back-to-Back 4 Beats (one packet)
        // ==================================================================
        $display("\n--- Test 3 : Back-to-Back 4 Beats ---");
        apply_reset;
        m_axis_tready = 1'b1;

        beat_data = 64'h0001000200030004; beat_last = 1'b0; send_beat (beat_data, beat_last);
        beat_data = 64'h0005000600070008; beat_last = 1'b0; send_beat (beat_data, beat_last);
        beat_data = 64'h00090000A000B000; beat_last = 1'b0; send_beat (beat_data, beat_last);
        beat_data = 64'h000D000E000F0010; beat_last = 1'b1; send_beat (beat_data, beat_last);

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b0, "BB Beat 1 : tlast=0");

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b0, "BB Beat 2 : tlast=0");

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b0, "BB Beat 3 : tlast=0");

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b1, "BB Beat 4 : tlast=1");

        wait_cycles (4);

        // ==================================================================
        //  TEST 4 : Backpressure
        //  Hold tready=0 while sending 4 beats → results pile up in FIFO.
        // ==================================================================
        $display("\n--- Test 4 : Backpressure (tready held low) ---");
        apply_reset;
        m_axis_tready = 1'b0;

        beat_data = 64'hDEADBEEFCAFEBABE; beat_last = 1'b0; send_beat (beat_data, beat_last);
        beat_data = 64'h123456789ABCDEF0; beat_last = 1'b0; send_beat (beat_data, beat_last);
        beat_data = 64'hAAAABBBBCCCCDDDD; beat_last = 1'b0; send_beat (beat_data, beat_last);
        beat_data = 64'hEEEEFFFF00001111; beat_last = 1'b1; send_beat (beat_data, beat_last);

        wait_cycles (PIPE_LAT + 4);
        check(m_axis_tvalid === 1'b1, "FIFO non-empty under backpressure");

        m_axis_tready = 1'b1;

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b0, "BP Beat 1 : tlast=0");

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b0, "BP Beat 2 : tlast=0");

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b0, "BP Beat 3 : tlast=0");

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b1, "BP Beat 4 : tlast=1");

        wait_cycles (4);

        // ==================================================================
        //  TEST 5 : FIFO Overflow Protection
        // ==================================================================
        $display("\n--- Test 5 : FIFO Overflow Protection ---");
        apply_reset;
        m_axis_tready = 1'b0;

        accepted = 0;
        for (k = 0; k < FIFO_DEPTH + 2; k = k + 1) begin
            s_axis_tvalid = 1'b1;
            s_axis_tdata  = {16'hABCD, k[15:0], 16'h1234, k[15:0]};
            s_axis_tlast  = (k == FIFO_DEPTH + 1) ? 1'b1 : 1'b0;
            @(posedge aclk);
            if (s_axis_tready === 1'b1)
                accepted = accepted + 1;
        end
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;

        wait_cycles (PIPE_LAT + 4);
        check((accepted <= FIFO_DEPTH), "tready throttled: accepted <= FIFO_DEPTH");
        $display("    Accepted %0d of %0d attempted (FIFO_DEPTH=%0d)",
                  accepted, FIFO_DEPTH + 2, FIFO_DEPTH);

        // Drain FIFO before next test
        m_axis_tready = 1'b1;
        wait_cycles (FIFO_DEPTH + 4);
        m_axis_tready = 1'b0;

        // ==================================================================
        //  TEST 6 : Mid-Transfer Reset Recovery
        //  Send two beats, assert reset while they are still in-flight.
        //  After reset FIFO must be empty, then fresh data must work.
        // ==================================================================
        $display("\n--- Test 6 : Mid-Transfer Reset Recovery ---");
        m_axis_tready = 1'b1;

        beat_data = 64'hFACEBACE12345678; beat_last = 1'b0; send_beat (beat_data, beat_last);
        beat_data = 64'hDEADCAFEABCDEF01; beat_last = 1'b0; send_beat (beat_data, beat_last);

        // Assert reset mid-flight
        aresetn = 1'b0;
        repeat(3) @(posedge aclk);
        aresetn = 1'b1;
        @(posedge aclk);
        #1;

        check(m_axis_tvalid === 1'b0, "FIFO empty after mid-xfer reset");

        // Send one fresh beat after recovery
        beat_data = 64'h1111222233334444; beat_last = 1'b1; send_beat (beat_data, beat_last);
        wait_cycles (PIPE_LAT + 4);
        check(m_axis_tvalid === 1'b1, "DUT alive after reset recovery");

        m_axis_tready = 1'b1;
        @(posedge aclk);
        m_axis_tready = 1'b0;
        wait_cycles (4);

        // ==================================================================
        //  TEST 7 : Non-Continuous Input (gaps between beats)
        //  3 beats with idle cycles between them.
        //  inflight_sr must track gaps; tlast must land on correct output.
        // ==================================================================
        $display("\n--- Test 7 : Non-Continuous Input (Gaps) ---");
        apply_reset;
        m_axis_tready = 1'b1;

        beat_data = 64'h1111222233334444; beat_last = 1'b0; send_beat (beat_data, beat_last);
        wait_cycles (3);
        beat_data = 64'h5555666677778888; beat_last = 1'b0; send_beat (beat_data, beat_last);
        wait_cycles (2);
        beat_data = 64'h9999AAAABBBBCCCC; beat_last = 1'b1; send_beat (beat_data, beat_last);

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b0, "Gap Beat 1 : tlast=0");

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b0, "Gap Beat 2 : tlast=0");

        receive_beat (rx_data, rx_last);
        check(rx_last === 1'b1, "Gap Beat 3 : tlast=1");

        wait_cycles (4);

        // ==================================================================
        //  TEST 8 : tready Gated by aresetn
        //  With aresetn=0, tready must be 0 regardless of FIFO state.
        //  When aresetn=1 and FIFO is free, tready must return to 1.
        // ==================================================================
        $display("\n--- Test 8 : tready Gated by aresetn ---");
        apply_reset;
        aresetn = 1'b0;
        #1;
        check(s_axis_tready === 1'b0, "tready=0 when aresetn=0");
        aresetn = 1'b1;
        @(posedge aclk);
        #1;
        check(s_axis_tready === 1'b1, "tready=1 after aresetn released");

        wait_cycles (2);

        // ==================================================================
        //  Final report
        // ==================================================================
        $display("\n======================================================");
        $display("  RESULTS : %0d Passed,  %0d Failed,  %0d Total",
                  pass_count, fail_count, test_num);
        $display("======================================================");
        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** %0d TEST(S) FAILED - review log above ***",
                      fail_count);

        $finish;
    end

    // -----------------------------------------------------------------------
    //  Watchdog - kills simulation after 100 us to catch any deadlocks
    // -----------------------------------------------------------------------
    initial begin
        #100000;
        $display("[TIMEOUT] Simulation exceeded 100 us - possible deadlock.");
        $finish;
    end

endmodule
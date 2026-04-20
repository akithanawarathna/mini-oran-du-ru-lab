module fir3_q15 (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        in_valid,
    input  wire signed [15:0] x_in,     // Q1.15 two's complement
    output reg         out_valid,
    output reg  signed [15:0] y_out     // Q1.15
);

    // Delay line: x[n], x[n-1], x[n-2]
    reg signed [15:0] x0, x1, x2;

    // Q1.15 coefficients (example low-pass: 0.25, 0.5, 0.25)
    localparam signed [15:0] C0 = 16'sd8192;   // 0.25 in Q1.15
    localparam signed [15:0] C1 = 16'sd16384;  // 0.5  in Q1.15
    localparam signed [15:0] C2 = 16'sd8192;   // 0.25 in Q1.15

    // Products: Q1.15 * Q1.15 = Q2.30 (32-bit signed)
    wire signed [31:0] p0 = x0 * C0;
    wire signed [31:0] p1 = x1 * C1;
    wire signed [31:0] p2 = x2 * C2;

    // Accumulator with headroom (sum of 3x 32-bit)
    wire signed [33:0] acc = {{2{p0[31]}}, p0} + {{2{p1[31]}}, p1} + {{2{p2[31]}}, p2};

    // ---- Rescale back to Q1.15 ----
    // acc is Q2.30. To convert to Q1.15, shift right by 15 bits.
    // Add rounding before shift:
    // rounding constant = 2^(15-1) = 2^14
    wire signed [33:0] acc_rounded = acc + 34'sd16384; // 2^14

    // Shift right by 15 (arithmetic shift keeps sign)
    wire signed [18:0] y_q15_wide = acc_rounded >>> 15; // keep extra bits for saturation check

    // ---- Saturation to 16-bit signed range ----
    // Q1.15 output still lives in signed 16-bit integer range [-32768, 32767]
    function automatic signed [15:0] sat16(input signed [18:0] v);
        begin
            if (v > 19'sd32767)      sat16 = 16'sd32767;
            else if (v < -19'sd32768) sat16 = -16'sd32768;
            else                      sat16 = v[15:0];
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x0 <= 16'sd0;
            x1 <= 16'sd0;
            x2 <= 16'sd0;
            y_out <= 16'sd0;
            out_valid <= 1'b0;
        end else begin
            out_valid <= 1'b0;

            if (in_valid) begin
                // Shift in new sample
                x2 <= x1;
                x1 <= x0;
                x0 <= x_in;

                // Output is valid one cycle later *if you want fully registered pipeline*.
                // For this simple version, we register immediately on same cycle.
                y_out <= sat16(y_q15_wide);
                out_valid <= 1'b1;
            end
        end
    end

endmodule
    `timescale 1ns / 1ps
    /////////////////////////////////////////////////////////////////////////////////////////
    //                          Company: UnderDogSi                                        //
    //                          Engineer: AKitha Anupriya                                  //
    //                          Create Date: 03/16/2026 10:57:40 AM                        //
    //                          Design Name: FFT ACCELERATOR                               //
    //                          Module Name: q_mul                                         //
    //                          Project Name: DU/RU LAB                                    //
    //                          Target Devices: ASIC                                       //
    //                          Description: A parameterized model for q bit adds & subs   //
    /////////////////////////////////////////////////////////////////////////////////////////
    module q_mul
    (
        input  wire                      clk,
        input  wire                      rst_n,
        input  wire                      valid,
        input  wire signed [15:0]        op_1,
        input  wire signed [15:0]        op_2,
        output reg  signed [15:0]        result
    );
    
        // Constants
        localparam signed [15:0] BIAS    = 16'sd16384;              // 0.5 in Q1.15 (rounding bias)
        localparam signed [15:0] MAX_VAL = 16'sb0111_1111_1111_1111; //  32767 → +1 in Q1.15
        localparam signed [15:0] MIN_VAL = 16'sb1000_0000_0000_0000; // -32768 → -1 in Q1.15
    
        wire signed [31:0] level_1 = op_1 * op_2;
        wire signed [31:0] level_2 = level_1 + {{16{BIAS[15]}}, BIAS}; // sign-extend bias to 32 bits
        wire signed [31:0] level_3_full = level_2 >>> 15;
        wire signed [15:0] level_3 = level_3_full[15:0];
    
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n)
                result <= 16'sb0;
            else if (valid) begin
                if      (level_3_full > $signed({{16{MAX_VAL[15]}}, MAX_VAL}))
                    result <= MAX_VAL;                               // Positive overflow --> clamp to +MAX
                else if (level_3_full < $signed({{16{MIN_VAL[15]}}, MIN_VAL}))
                    result <= MIN_VAL;                               // Negative overflow --> clamp to -MAX
                else
                    result <= level_3;   
            end
        end
    
    endmodule

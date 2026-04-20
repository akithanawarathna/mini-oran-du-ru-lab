    `timescale 1ns / 1ps
    /////////////////////////////////////////////////////////////////////////////////////////
    //                          Company: UnderDogSi                                        //
    //                          Engineer: AKitha Anupriya                                  //
    //                          Create Date: 03/16/2026 10:57:40 AM                        //
    //                          Design Name: FFT ACCELERATOR                               //    
    //                          Module Name: q_add_sub                                     //
    //                          Project Name: DU/RU LAB                                    //
    //                          Target Devices: ASIC                                       //
    //                          Description: A parameterized model for q bit adds & subs   //
    /////////////////////////////////////////////////////////////////////////////////////////
    
    
    module q_add_sub
    (
        input  wire                      clk,
        input  wire                      rst_n,
        input  wire                      valid,
        input  wire                      op_select,          // 0:add, 1:sub
        input  wire signed [15:0]        op_1,
        input  wire signed [15:0]        op_2,
        output reg  signed [15:0]        result,
        output reg                       sat_hi,
        output reg                       sat_lo       
    );
    
        // Sign-extend both operands to WIDTH+1
        wire signed [16:0] a_ext = {op_1[15], op_1};
        wire signed [16:0] b_ext = {op_2[15], op_2};
    
        // Two's complement negation for subtraction
        wire signed [16:0] b_mod = op_select ? (~b_ext + 1'b1) : b_ext;
        wire signed [16:0] sum_w = a_ext + b_mod;
    
        wire overflow_pos = (~sum_w[16]) & ( sum_w[15]); // > MAX
        wire overflow_neg = ( sum_w[16]) & (~sum_w[15]); // < MIN
    
        // Saturation values (safe: plain bit-concat, no signed localparam)
        wire signed [15:0] MAX_VAL = {1'b0, {(15){1'b1}}};  // +2^(W-1)-1
        wire signed [15:0] MIN_VAL = {1'b1, {(15){1'b0}}};  // -2^(W-1)
    
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                result  <= {16{1'b0}};
                sat_hi  <= 1'b0;
                sat_lo  <= 1'b0;
            end else if (valid) begin
                if (overflow_pos) begin          // Positive saturation
                    result  <= MAX_VAL;
                    sat_hi  <= 1'b1;
                    sat_lo  <= 1'b0;
                end else if (overflow_neg) begin // Negative saturation
                    result  <= MIN_VAL;
                    sat_hi  <= 1'b0;
                    sat_lo  <= 1'b1;
                end else begin                   // No overflow
                    result  <= sum_w[15:0];
                    sat_hi  <= 1'b0;
                    sat_lo  <= 1'b0;
                end
            end else begin
                sat_hi <= 1'b0;
                sat_lo <= 1'b0;
            end
        end
    
    endmodule
    

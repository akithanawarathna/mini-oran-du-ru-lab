    `timescale 1ns / 1ps
    /////////////////////////////////////////////////////////////////////////////////////////
    //                          Company: UnderDogSi                                        //
    //                          Engineer: AKitha Anupriya                                  //
    //                          Create Date: 03/16/2026 10:57:40 AM                        //
    //                          Design Name: FFT ACCELERATOR                               //
    //                          Module Name: complex_mul_axis                              //
    //                          Project Name: DU/RU LAB                                    //
    //                          Target Devices: ASIC                                       //
    //                          Description: Q1.15 complex multiplier (core, AXI-ready)    //
    /////////////////////////////////////////////////////////////////////////////////////////
    
    module complex_mul_axis
    (
        input  wire               clk,
        input  wire               rst_n,
        input  wire               valid,      // input-valid for op_1/op_2
        input  wire [31:0]        op_1,       // {re1[15:0], im1[15:0]}
        input  wire [31:0]        op_2,       // {re2[15:0], im2[15:0]}
        output wire [31:0]        result,     // {re[15:0], im[15:0]}
        output reg                out_valid   // pulses when result registers update
    );
    
        // Make these SIGNED (they are Q1.15 signed results)
        wire signed [15:0] re_1_re_2;
        wire signed [15:0] re_1_im_2;
        wire signed [15:0] im_1_re_2;
        wire signed [15:0] im_1_im_2;
    
        // Pipeline regs to align multiplier results into add/sub stage
        reg signed [15:0] op_r1_r2;
        reg signed [15:0] op_i1_i2;
        reg signed [15:0] op_r1_i2;
        reg signed [15:0] op_i1_r2;
    
        wire signed [15:0] result_re;
        wire signed [15:0] result_im;
        assign result = {result_re, result_im};
    
        // VALID PIPELINE
        reg [1:0] valid_sr;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n)
                valid_sr <= 2'b00;
            else
                valid_sr <= {valid_sr[0], valid};
        end
    
        wire valid_d1 = valid_sr[0];
        wire valid_d2 = valid_sr[1];
    
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n)
                out_valid <= 1'b0;
            else
                out_valid <= valid_d2;
        end
    
        q_mul mul_inst_1 (
            .clk    (clk),
            .rst_n  (rst_n),
            .valid  (valid),
            .op_1   ($signed(op_1[31:16])),  // real_1
            .op_2   ($signed(op_2[31:16])),  // real_2
            .result (re_1_re_2)
        );
    
        q_mul mul_inst_2 (
            .clk    (clk),
            .rst_n  (rst_n),
            .valid  (valid),
            .op_1   ($signed(op_1[15:0])),   // im_1
            .op_2   ($signed(op_2[15:0])),   // im_2
            .result (im_1_im_2)
        );
    
        q_mul mul_inst_3 (
            .clk    (clk),
            .rst_n  (rst_n),
            .valid  (valid),
            .op_1   ($signed(op_1[31:16])),  // real_1
            .op_2   ($signed(op_2[15:0])),   // im_2
            .result (re_1_im_2)
        );
    
        q_mul mul_inst_4 (
            .clk    (clk),
            .rst_n  (rst_n),
            .valid  (valid),
            .op_1   ($signed(op_1[15:0])),   // im_1
            .op_2   ($signed(op_2[31:16])),  // real_2
            .result (im_1_re_2)
        );
    
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                op_r1_r2 <= 16'sd0;
                op_i1_i2 <= 16'sd0;
                op_r1_i2 <= 16'sd0;
                op_i1_r2 <= 16'sd0;
            end else if (valid_d1) begin
                op_r1_r2 <= re_1_re_2;
                op_i1_i2 <= im_1_im_2;
                op_r1_i2 <= re_1_im_2;
                op_i1_r2 <= im_1_re_2;
            end
        end
    
        localparam op_select_sub = 1'b1; // 1=sub
        localparam op_select_add = 1'b0; // 0=add
    
        q_add_sub ads_inst_1 (
            .clk       (clk),
            .rst_n     (rst_n),
            .valid     (valid_d2),
            .op_select (op_select_sub),
            .op_1      (op_r1_r2),
            .op_2      (op_i1_i2),
            .result    (result_re),
            .sat_hi    (),
            .sat_lo    ()
        );
    
        q_add_sub ads_inst_2 (
            .clk       (clk),
            .rst_n     (rst_n),
            .valid     (valid_d2),
            .op_select (op_select_add),
            .op_1      (op_r1_i2),
            .op_2      (op_i1_r2),
            .result    (result_im),
            .sat_hi    (),
            .sat_lo    ()
        );
    
    endmodule

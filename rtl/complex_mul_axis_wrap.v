        `timescale 1ns / 1ps
        
    /////////////////////////////////////////////////////////////////////////////////////////
    //                          Company: UnderDogSi                                        //
    //                          Engineer: AKitha Anupriya                                  //
    //                          Create Date: 04/01/2026 02:56:10 PM                        //
    //                          Design Name: FFT ACCELERATOR                               //
    //                          Module Name: complex_mul_axis_wrap                         //
    //                          Project Name: DU/RU LAB                                    //
    //                          Target Devices: ASIC                                       //
    //                          Description: AXIS wrap forcomplex multiplier               //
    /////////////////////////////////////////////////////////////////////////////////////////
        
        module complex_mul_axis_wrap
        (
            input  wire        aclk,
            input  wire        aresetn,
        
            // Slave port (input)
            input  wire        s_axis_tvalid,
            output wire        s_axis_tready,
            input  wire [63:0] s_axis_tdata,   // {op_1[31:0], op_2[31:0]}
            input  wire        s_axis_tlast,
        
            // Master port (output)
            output reg         m_axis_tvalid,
            input  wire        m_axis_tready,
            output reg  [31:0] m_axis_tdata,   // {result_re[15:0], result_im[15:0]}
            output reg         m_axis_tlast
        );
        
            //  INPUT HANDSHAKE
            //  Only accept data when pipeline is not stalled
            wire pipe_stall;   // goes high when output buffer is full
            wire pipe_en = s_axis_tvalid && s_axis_tready;
        
            assign s_axis_tready = ~pipe_stall;
        
            //  TLAST PIPELINE (must track through 3 cycles)
            reg [2:0] tlast_sr;
            always @(posedge aclk or negedge aresetn) begin
                if (!aresetn)
                    tlast_sr <= 3'b000;
                else if (pipe_en)
                    tlast_sr <= {tlast_sr[1:0], s_axis_tlast};
            end
            wire tlast_d3 = tlast_sr[2];  // 3-cycle delayed TLAST
        
            //  CORE PIPELINE (your existing complex_mul_axis)
            wire [31:0] core_result;
            wire        core_out_valid;
        
            complex_mul_axis core (
                .clk       (aclk),
                .rst_n     (aresetn),
                .valid     (pipe_en),          // only run when handshake fires
                .op_1      (s_axis_tdata[63:32]),
                .op_2      (s_axis_tdata[31:0]),
                .result    (core_result),
                .out_valid (core_out_valid)
            );
        
            //  OUTPUT SKID BUFFER
            //  Absorbs one result if downstream stalls.
            //  Signals pipe_stall back to input when full.
        
            // Skid buffer registers
            reg  [31:0] skid_data;
            reg         skid_last;
            reg         skid_valid;
        
            // pipe_stall: stall input when skid buffer is occupied
            // and downstream is not consuming
            assign pipe_stall = skid_valid && !m_axis_tready;
        
            always @(posedge aclk or negedge aresetn) begin
                if (!aresetn) begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tdata  <= 32'd0;
                    m_axis_tlast  <= 1'b0;
                    skid_valid    <= 1'b0;
                    skid_data     <= 32'd0;
                    skid_last     <= 1'b0;
                end else begin
        
                    //  New result arriving from pipeline
                    if (core_out_valid) begin
                        if (!m_axis_tvalid || m_axis_tready) begin
                            // Output port is free - drive directly
                            m_axis_tvalid <= 1'b1;
                            m_axis_tdata  <= core_result;
                            m_axis_tlast  <= tlast_d3;
                        end else begin
                            // Output port busy - park in skid buffer
                            skid_valid <= 1'b1;
                            skid_data  <= core_result;
                            skid_last  <= tlast_d3;
                        end
                    end
        
                    //  Downstream accepted output 
                    if (m_axis_tready && m_axis_tvalid) begin
                        if (skid_valid) begin
                            // Drain skid buffer into output
                            m_axis_tdata  <= skid_data;
                            m_axis_tlast  <= skid_last;
                            m_axis_tvalid <= 1'b1;
                            skid_valid    <= 1'b0;
                        end else if (!core_out_valid) begin
                            // Nothing pending
                            m_axis_tvalid <= 1'b0;
                        end
                    end
        
                end
            end
        
        endmodule

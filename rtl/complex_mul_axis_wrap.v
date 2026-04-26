`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////
//                          Company: UnderDogSi                                        //
//                          Engineer: Akitha Anupriya                                  //
//                          Design Name: FFT ACCELERATOR                               //
//                          Module Name: complex_mul_axis_wrap                         //
//                          Project Name: DU/RU LAB                                    //
//                          Target Devices: ASIC / FPGA                                //
//                          Description: AXIS wrapper with output FIFO                 //
//                                       No drops under backpressure                   //
/////////////////////////////////////////////////////////////////////////////////////////

module complex_mul_axis_wrap #(
    //parameter integer PIPE_LAT   = 2,   // complex_mul_axis latency in cycles
    parameter integer PIPE_LAT   = 3,
    parameter integer FIFO_DEPTH = 8  
)(
    input  wire        aclk,
    input  wire        aresetn,

    // Slave port (input)
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [63:0] s_axis_tdata,   // {op_1[31:0], op_2[31:0]}
    input  wire        s_axis_tlast,

    // Master port (output)
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [31:0] m_axis_tdata,   // {result_re[15:0], result_im[15:0]}
    output wire        m_axis_tlast
);

    localparam integer ADDR_W = $clog2(FIFO_DEPTH);

    reg [PIPE_LAT-1:0] inflight_sr; //shift reegister
//    wire [ADDR_W:0] inflight_cnt = (PIPE_LAT == 1) ? inflight_sr[0] :
//                                   (PIPE_LAT == 2) ? (inflight_sr[0] + inflight_sr[1]) :
//                                   inflight_sr[0] + inflight_sr[1] + inflight_sr[2]; // extend if needed
wire [ADDR_W:0] inflight_cnt =
    (PIPE_LAT == 1) ? inflight_sr[0] :
    (PIPE_LAT == 2) ? (inflight_sr[0] + inflight_sr[1]) :
    (inflight_sr[0] + inflight_sr[1] + inflight_sr[2]); // PIPE_LAT==3

    // -----------------------------------------------------------------------
    //  TLAST alignment: shift TLAST alongside accepted inputs.
    //  When core_out_valid asserts, use tlast_pipe[PIPE_LAT-1].
    // -----------------------------------------------------------------------
    reg [PIPE_LAT-1:0] tlast_pipe;

    reg [31:0] fifo_data [0:FIFO_DEPTH-1];
    reg        fifo_last [0:FIFO_DEPTH-1];

    reg [ADDR_W-1:0] wr_ptr, rd_ptr;
    reg [ADDR_W:0]   fifo_count; // 0..FIFO_DEPTH

    wire fifo_full  = (fifo_count == FIFO_DEPTH);
    wire fifo_empty = (fifo_count == 0);

    wire [31:0] core_result;
    wire        core_out_valid;

    // Input accept
    wire pipe_en = s_axis_tvalid && s_axis_tready;

    complex_mul_axis core (
        .clk       (aclk),
        .rst_n     (aresetn),
        .valid     (pipe_en),
        .op_1      (s_axis_tdata[63:32]),
        .op_2      (s_axis_tdata[31:0]),
        .result    (core_result),
        .out_valid (core_out_valid)
    );

    wire [ADDR_W:0] fifo_free = FIFO_DEPTH - fifo_count;
    assign s_axis_tready = aresetn && (fifo_free > inflight_cnt);

    //  Push/pop control

    wire push = core_out_valid;                       // a result is arriving from the core
    wire pop  = m_axis_tvalid && m_axis_tready;       // downstream consumes one FIFO item

    assign m_axis_tvalid = !fifo_empty;
    assign m_axis_tdata  = fifo_data[rd_ptr];
    assign m_axis_tlast  = fifo_last[rd_ptr];

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            inflight_sr <= {PIPE_LAT{1'b0}};
            tlast_pipe  <= {PIPE_LAT{1'b0}};

            wr_ptr      <= {ADDR_W{1'b0}};
            rd_ptr      <= {ADDR_W{1'b0}};
            fifo_count  <= {(ADDR_W+1){1'b0}};
            
        end else begin
            // Track in-flight accepts
            inflight_sr <= {inflight_sr[PIPE_LAT-2:0], pipe_en};

            // TLAST alignment with accepted inputs
            tlast_pipe  <= {tlast_pipe[PIPE_LAT-2:0], (pipe_en ? s_axis_tlast : 1'b0)};

            // PUSH: write core result into FIFO
            if (push) begin
                fifo_data[wr_ptr] <= core_result;
                fifo_last[wr_ptr] <= tlast_pipe[PIPE_LAT-1];
                wr_ptr            <= wr_ptr + 1'b1;
            end

            // POP: advance read pointer
            if (pop) begin
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Update FIFO count
            case ({push, pop})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: ; // 00 or 11 -> no change
            endcase
        end
    end

endmodule

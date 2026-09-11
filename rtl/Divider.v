`timescale 1ns / 1ps

module Divider (
    input  wire        clk,
    input  wire        reset,
    input  wire        clk_en,
    input  wire        start,
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    input  wire [1:0]  div_op,
    output reg  [31:0] div_result,
    output reg         busy,
    output reg         valid
);

    wire is_signed = (div_op == 2'b00 || div_op == 2'b10);
    wire is_rem    = (div_op == 2'b10 || div_op == 2'b11);

    wire sign_rs1 = is_signed & rs1_data[31];
    wire sign_rs2 = is_signed & rs2_data[31];
    
    wire sign_quotient  = sign_rs1 ^ sign_rs2;
    wire sign_remainder = sign_rs1;

    wire [31:0] abs_rs1 = sign_rs1 ? (~rs1_data + 1) : rs1_data;
    wire [31:0] abs_rs2 = sign_rs2 ? (~rs2_data + 1) : rs2_data;

    wire is_div_by_zero = (rs2_data == 32'b0);

    reg latched_sign_quotient;
    reg latched_sign_remainder;
    reg latched_is_div_by_zero;
    reg [31:0] latched_rs1_data;

    reg [1:0]  state;
    reg [5:0]  count;
    reg [31:0] Q;
    reg [32:0] A;
    reg [31:0] M;

    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            busy  <= 1'b0;
            valid <= 1'b0;
            count <= 6'b0;
            Q     <= 32'b0;
            A     <= 33'b0;
            M     <= 32'b0;
            latched_sign_quotient  <= 1'b0;
            latched_sign_remainder <= 1'b0;
            latched_is_div_by_zero <= 1'b0;
            latched_rs1_data       <= 32'b0;
            
        end else if (clk_en) begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    if (start && !busy) begin
                        busy  <= 1'b1;
                        state <= CALC;
                        count <= 6'd32;
                        Q     <= abs_rs1;
                        A     <= 33'b0;
                        M     <= abs_rs2;
                        
                        latched_sign_quotient  <= sign_quotient;
                        latched_sign_remainder <= sign_remainder;
                        latched_is_div_by_zero <= is_div_by_zero;
                        latched_rs1_data       <= rs1_data;
                        
                        if (is_div_by_zero) begin
                            state <= DONE;
                            count <= 6'd0;
                        end
                    end
                end

                CALC: begin
                    if (count > 0) begin
                        count <= count - 1;
                        if ({A[31:0], Q[31]} >= M) begin
                            A <= {A[31:0], Q[31]} - M;
                            Q <= {Q[30:0], 1'b1};
                        end else begin
                            A <= {A[31:0], Q[31]};
                            Q <= {Q[30:0], 1'b0};
                        end
                    end else begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    busy  <= 1'b0;
                    valid <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

    wire [31:0] final_quotient  = (latched_sign_quotient  && !latched_is_div_by_zero) ? (~Q + 1) : Q;
    wire [31:0] final_remainder = (latched_sign_remainder && !latched_is_div_by_zero) ? (~A[31:0] + 1) : A[31:0];

    wire [31:0] res_q = latched_is_div_by_zero ? 32'hFFFFFFFF : final_quotient;
    wire [31:0] res_r = latched_is_div_by_zero ? latched_rs1_data : final_remainder;

    always @(*) begin
        if (is_rem) begin
            div_result = res_r;
        end else begin
            div_result = res_q;
        end
    end

endmodule
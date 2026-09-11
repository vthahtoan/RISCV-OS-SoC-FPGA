`timescale 1ns / 1ps

module Multiplier (
    input  wire        clk,
    input  wire        reset,
    input  wire        clk_en,
    input  wire        start,
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    input  wire [1:0]  mul_op,
    output reg  [31:0] mul_result,
    output reg         busy,
    output reg         valid
);

    wire is_rs1_signed = (mul_op == 2'b00 || mul_op == 2'b01 || mul_op == 2'b10);
    wire is_rs2_signed = (mul_op == 2'b00 || mul_op == 2'b01);

    wire signed [32:0] ext_A = is_rs1_signed ? {rs1_data[31], rs1_data} : {1'b0, rs1_data};
    wire signed [32:0] ext_B = is_rs2_signed ? {rs2_data[31], rs2_data} : {1'b0, rs2_data};

    wire signed [65:0] product_raw = ext_A * ext_B;

    reg [65:0] product_reg;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            busy        <= 1'b0;
            valid       <= 1'b0;
            product_reg <= 66'b0;
        end else if (clk_en) begin
            if (start && !busy) begin
                busy        <= 1'b1;
                valid       <= 1'b0;
                product_reg <= product_raw;
            end else if (busy) begin
                busy        <= 1'b0;
                valid       <= 1'b1;
            end else begin
                valid       <= 1'b0;
            end
        end
    end

    always @(*) begin
        if (mul_op == 2'b00) begin
            mul_result = product_reg[31:0];
        end else begin
            mul_result = product_reg[63:32];
        end
    end

endmodule
`timescale 1ns / 1ps

module ForwardingUnit(
    input  wire [4:0] ex_rs1,
    input  wire [4:0] ex_rs2,
    input  wire [4:0] mem_rd,
    input  wire       mem_RegWrite,
    input  wire [4:0] wb_rd,
    input  wire       wb_RegWrite,
    output reg  [1:0] ForwardA,
    output reg  [1:0] ForwardB
);

    always @(*) begin
        ForwardA = 2'b00;
        ForwardB = 2'b00;

        if (mem_RegWrite && (mem_rd != 5'b0) && (mem_rd == ex_rs1)) begin
            ForwardA = 2'b10;
        end else if (wb_RegWrite && (wb_rd != 5'b0) && (wb_rd == ex_rs1)) begin
            ForwardA = 2'b01;
        end

        if (mem_RegWrite && (mem_rd != 5'b0) && (mem_rd == ex_rs2)) begin
            ForwardB = 2'b10;
        end else if (wb_RegWrite && (wb_rd != 5'b0) && (wb_rd == ex_rs2)) begin
            ForwardB = 2'b01;
        end
    end

endmodule
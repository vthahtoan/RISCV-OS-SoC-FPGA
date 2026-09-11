`timescale 1ns / 1ps

module EX_MEM_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        clear,

    input  wire [31:0] ex_ALUResult,
    input  wire [31:0] ex_RD2,
    input  wire [31:0] ex_PC_Plus_4,
    input  wire [4:0]  ex_rd,
    input  wire [2:0]  ex_funct3,

    input  wire        ex_RegWrite,
    input  wire        ex_MemRead,
    input  wire        ex_MemWrite,
    input  wire [1:0]  ex_MemtoReg,

    output reg  [31:0] mem_ALUResult,
    output reg  [31:0] mem_RD2,
    output reg  [31:0] mem_PC_Plus_4,
    output reg  [4:0]  mem_rd,
    output reg  [2:0]  mem_funct3,
    
    output reg         mem_RegWrite,
    output reg         mem_MemRead,
    output reg         mem_MemWrite,
    output reg  [1:0]  mem_MemtoReg
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            mem_ALUResult <= 32'b0;
            mem_RD2       <= 32'b0;
            mem_PC_Plus_4 <= 32'b0;
            mem_rd        <= 5'b0;
            mem_funct3    <= 3'b0;

            mem_RegWrite  <= 1'b0;
            mem_MemRead   <= 1'b0;
            mem_MemWrite  <= 1'b0;
            mem_MemtoReg  <= 2'b0;
        end else if (en) begin
            mem_ALUResult <= ex_ALUResult;
            mem_RD2       <= ex_RD2;
            mem_PC_Plus_4 <= ex_PC_Plus_4;
            mem_rd        <= ex_rd;
            mem_funct3    <= ex_funct3;

            mem_RegWrite  <= ex_RegWrite;
            mem_MemRead   <= ex_MemRead;
            mem_MemWrite  <= ex_MemWrite;
            mem_MemtoReg  <= ex_MemtoReg;
        end
    end

endmodule
`timescale 1ns / 1ps

module ID_EX_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        clear,

    input  wire [31:0] id_PC,
    input  wire [31:0] id_RD1,
    input  wire [31:0] id_RD2,
    input  wire [31:0] id_Imm,
    input  wire [4:0]  id_rs1,
    input  wire [4:0]  id_rs2,
    input  wire [4:0]  id_rd,
    input  wire [2:0]  id_funct3,
    input  wire        id_op5,
    input  wire        id_bit30,
    input  wire        id_is_jalr,
    input  wire        id_is_m_ext,
    input  wire        id_is_compressed,

    input  wire        id_RegWrite,
    input  wire        id_MemRead,
    input  wire        id_MemWrite,
    input  wire        id_Branch,
    input  wire        id_Jump,
    input  wire        id_ALUSrc,
    input  wire [1:0]  id_MemtoReg,
    input  wire [1:0]  id_ALUOp,
    input  wire [1:0]  id_ALUSrcA,

    output reg  [31:0] ex_PC,
    output reg  [31:0] ex_RD1,
    output reg  [31:0] ex_RD2,
    output reg  [31:0] ex_Imm,
    output reg  [4:0]  ex_rs1,
    output reg  [4:0]  ex_rs2,
    output reg  [4:0]  ex_rd,
    output reg  [2:0]  ex_funct3,
    output reg         ex_op5,
    output reg         ex_bit30,
    output reg         ex_is_jalr,
    output reg         ex_is_m_ext,
    output reg         ex_is_compressed,

    output reg         ex_RegWrite,
    output reg         ex_MemRead,
    output reg         ex_MemWrite,
    output reg         ex_Branch,
    output reg         ex_Jump,
    output reg         ex_ALUSrc,
    output reg  [1:0]  ex_MemtoReg,
    output reg  [1:0]  ex_ALUOp,
    output reg  [1:0]  ex_ALUSrcA
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_PC            <= 32'b0;
            ex_RD1           <= 32'b0;
            ex_RD2           <= 32'b0;
            ex_Imm           <= 32'b0;
            ex_rs1           <= 5'b0;
            ex_rs2           <= 5'b0;
            ex_rd            <= 5'b0;
            ex_funct3        <= 3'b0;
            ex_op5           <= 1'b0;
            ex_bit30         <= 1'b0;
            ex_is_jalr       <= 1'b0;
            ex_is_m_ext      <= 1'b0;
            ex_is_compressed <= 1'b0;

            ex_RegWrite      <= 1'b0;
            ex_MemRead       <= 1'b0;
            ex_MemWrite      <= 1'b0;
            ex_Branch        <= 1'b0;
            ex_Jump          <= 1'b0;
            ex_ALUSrc        <= 1'b0;
            ex_MemtoReg      <= 2'b0;
            ex_ALUOp         <= 2'b0;
            ex_ALUSrcA       <= 2'b0;
        end else if (en) begin
            if (clear) begin
                ex_PC            <= 32'b0;
                ex_RD1           <= 32'b0;
                ex_RD2           <= 32'b0;
                ex_Imm           <= 32'b0;
                ex_rs1           <= 5'b0;
                ex_rs2           <= 5'b0;
                ex_rd            <= 5'b0;
                ex_funct3        <= 3'b0;
                ex_op5           <= 1'b0;
                ex_bit30         <= 1'b0;
                ex_is_jalr       <= 1'b0;
                ex_is_m_ext      <= 1'b0;
                ex_is_compressed <= 1'b0;

                ex_RegWrite      <= 1'b0;
                ex_MemRead       <= 1'b0;
                ex_MemWrite      <= 1'b0;
                ex_Branch        <= 1'b0;
                ex_Jump          <= 1'b0;
                ex_ALUSrc        <= 1'b0;
                ex_MemtoReg      <= 2'b0;
                ex_ALUOp         <= 2'b0;
                ex_ALUSrcA       <= 2'b0;
            end else begin
                ex_PC            <= id_PC;
                ex_RD1           <= id_RD1;
                ex_RD2           <= id_RD2;
                ex_Imm           <= id_Imm;
                ex_rs1           <= id_rs1;
                ex_rs2           <= id_rs2;
                ex_rd            <= id_rd;
                ex_funct3        <= id_funct3;
                ex_op5           <= id_op5;
                ex_bit30         <= id_bit30;
                ex_is_jalr       <= id_is_jalr;
                ex_is_m_ext      <= id_is_m_ext;
                ex_is_compressed <= id_is_compressed;
                
                ex_RegWrite      <= id_RegWrite;
                ex_MemRead       <= id_MemRead;
                ex_MemWrite      <= id_MemWrite;
                ex_Branch        <= id_Branch;
                ex_Jump          <= id_Jump;
                ex_ALUSrc        <= id_ALUSrc;
                ex_MemtoReg      <= id_MemtoReg;
                ex_ALUOp         <= id_ALUOp;
                ex_ALUSrcA       <= id_ALUSrcA;
            end
        end
    end

endmodule
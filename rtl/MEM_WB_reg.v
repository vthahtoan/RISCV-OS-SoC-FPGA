`timescale 1ns / 1ps

module MEM_WB_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        clear,

    input  wire [31:0] mem_ALUResult,
    input  wire [31:0] mem_ReadData,
    input  wire [31:0] mem_PC_Plus_4,
    input  wire [4:0]  mem_rd,
    
    input  wire        mem_RegWrite,
    input  wire [1:0]  mem_MemtoReg,

    output reg  [31:0] wb_ALUResult,
    output reg  [31:0] wb_ReadData,
    output reg  [31:0] wb_PC_Plus_4,
    output reg  [4:0]  wb_rd,
    
    output reg         wb_RegWrite,
    output reg  [1:0]  wb_MemtoReg
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            wb_ALUResult <= 32'b0;
            wb_ReadData  <= 32'b0;
            wb_PC_Plus_4 <= 32'b0;
            wb_rd        <= 5'b0;
            
            wb_RegWrite  <= 1'b0;
            wb_MemtoReg  <= 2'b0;
        end else if (en) begin
            wb_ALUResult <= mem_ALUResult;
            wb_ReadData  <= mem_ReadData;
            wb_PC_Plus_4 <= mem_PC_Plus_4;
            wb_rd        <= mem_rd;
            
            wb_RegWrite  <= mem_RegWrite;
            wb_MemtoReg  <= mem_MemtoReg;
        end
    end

endmodule
`timescale 1ns / 1ps

module BranchUnit(
    input  wire       Branch,
    input  wire [2:0] funct3,
    input  wire       Zero,
    input  wire       ALU_LSB,  // Bit cuoi cung ALUResult[0] (Dung cho BLT, BGE...)
    
    output reg        PCSrc     // Lenh gat MUX cho Program Counter (1 la nhay, 0 la di tiep)
);

    always @(*) begin
        // Mac dinh khong nhay
        PCSrc = 1'b0; 

        if (Branch == 1'b1) begin
            case (funct3)
                // Nhom xai co Zero (Do ALU da lam phep TRU)
                3'b000: PCSrc = Zero;       // BEQ: Nhay neu Zero = 1 (A - B = 0)
                3'b001: PCSrc = ~Zero;      // BNE: Nhay neu Zero = 0 (A - B khac 0)
                
                // Nhom xai co LSB (Do ALU da lam phep SLT/SLTU)
                3'b100: PCSrc = ALU_LSB;    // BLT: Nhay neu LSB = 1 (A < B co dau)
                3'b101: PCSrc = ~ALU_LSB;   // BGE: Nhay neu LSB = 0 (A >= B co dau)
                
                3'b110: PCSrc = ALU_LSB;    // BLTU: Nhay neu LSB = 1 (A < B khong dau)
                3'b111: PCSrc = ~ALU_LSB;   // BGEU: Nhay neu LSB = 0 (A >= B khong dau)
            endcase
        end
    end
endmodule
`timescale 1ns / 1ps

module ControlUnit(
    input  wire [6:0] opcode,   
    
    output reg        Branch,   
    output reg        Jump,
    output reg        MemRead,  
    output reg [1:0]  MemtoReg,  // 00 = ALU, 01 = RAM, 10 = PC+4
    output reg [1:0]  ALUOp,     // 00 = Cong, 01 = Tru (Branch), 10 = Tinh toan (R/I)
    output reg        MemWrite, 
    output reg        ALUSrc,    // Ngo B cua ALU: 0 = rs2, 1 = Imm
    output reg [1:0]  ALUSrcA,   // Ngo A cua ALU: 00 = rs1, 01 = PC, 10 = So 0
    output reg        RegWrite  
);

    always @(*) begin
        // Trang thai mac dinh
        Branch   = 1'b0;
        Jump     = 1'b0;
        MemRead  = 1'b0;
        MemtoReg = 2'b00;
        ALUOp    = 2'b00;
        MemWrite = 1'b0;
        ALUSrc   = 1'b0;
        ALUSrcA  = 2'b00;   // Mac dinh lay rs1
        RegWrite = 1'b0;

        case(opcode)
            // 1. Nhom R-Type
            7'b0110011: begin
                RegWrite = 1'b1;
                ALUOp    = 2'b10; 
            end

            // 2. Nhom I-Type
            7'b0010011: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;  
                ALUOp    = 2'b10;
            end

            // 3. Nhom Load
            7'b0000011: begin
                ALUSrc   = 1'b1;
                MemtoReg = 2'b01;
                RegWrite = 1'b1;
                MemRead  = 1'b1;
            end

            // 4. Nhom Store
            7'b0100011: begin
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;     
            end

            // 5. Nhom Branch
            7'b1100011: begin
                Branch   = 1'b1;
                ALUOp    = 2'b01;
            end

            // 6. Nhom J-Type (JAL)
            7'b1101111: begin
                Jump     = 1'b1;
                MemtoReg = 2'b10;
                RegWrite = 1'b1;
            end

            // 7. Nhom I-Type re nhanh (JALR)
            7'b1100111: begin
                Jump     = 1'b1;
                MemtoReg = 2'b10;    
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;     
            end

            // 8. Nhom U-Type: LUI (Load Upper Immediate)
            7'b0110111: begin
                ALUSrcA  = 2'b10;    // Ep ngo A lay so 0 (0 + Imm)
                ALUSrc   = 1'b1;     // Ngo B lay so Imm
                RegWrite = 1'b1;
            end

            // 9. Nhom U-Type: AUIPC (Add Upper Immediate to PC)
            7'b0010111: begin
                ALUSrcA  = 2'b01;    // Ep ngo A lay PC (PC + Imm)
                ALUSrc   = 1'b1;     // Ngo B lay so Imm
                RegWrite = 1'b1;
            end
        endcase
    end
endmodule
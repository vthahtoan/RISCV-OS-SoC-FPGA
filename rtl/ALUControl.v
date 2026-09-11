`timescale 1ns / 1ps

module ALUControl(
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,   // inst[14:12]
    input  wire       bit30,    // inst[30]
    input  wire       op5,      // inst[5]
    output reg  [3:0] ALU_Ctrl
);

    always @(*) begin
        case (ALUOp)
            2'b00: ALU_Ctrl = 4'b0010; 
            2'b01: begin
                case (funct3)
                    3'b000, 3'b001: ALU_Ctrl = 4'b0110; // BEQ, BNE -> Dung tru
                    3'b100, 3'b101: ALU_Ctrl = 4'b1000; // BLT, BGE -> Dung SLT
                    3'b110, 3'b111: ALU_Ctrl = 4'b1001; // BLTU, BGEU -> Dung SLTU
                    default: ALU_Ctrl = 4'b0110;
                endcase
            end 
            2'b10: begin
                case (funct3)
                    // ADD, SUB, ADDI
                    3'b000: begin
                        // Chi tru khi là R-Type (op5=1) VÀ bit30=1
                        if (op5 == 1'b1 && bit30 == 1'b1)
                            ALU_Ctrl = 4'b0110; // SUB
                        else
                            ALU_Ctrl = 4'b0010; // ADD và ADDI
                    end
                    
                    // SLL, SLLI (Dich trái)
                    3'b001: ALU_Ctrl = 4'b0100;
                    
                    // SLT, SLTI (So sanh nho hon có dau)
                    3'b010: ALU_Ctrl = 4'b1000;
                    
                    // SLTU, SLTIU (So sanh nho hon không dau)
                    3'b011: ALU_Ctrl = 4'b1001;
                    
                    // XOR, XORI
                    3'b100: ALU_Ctrl = 4'b0011;
                    
                    // SRL, SRA, SRLI, SRAI (Dich phai)
                    3'b101: begin
                        // Lenh dich bit thì bit30 co tác dung phân biet Logic/Arithmetic
                        if (bit30 == 1'b1)
                            ALU_Ctrl = 4'b0111; // SRA, SRAI
                        else
                            ALU_Ctrl = 4'b0101; // SRL, SRLI
                    end
                    
                    // OR, ORI
                    3'b110: ALU_Ctrl = 4'b0001;
                    
                    // AND, ANDI
                    3'b111: ALU_Ctrl = 4'b0000;
                endcase
            end
            default: ALU_Ctrl = 4'b0000;
        endcase
    end
endmodule
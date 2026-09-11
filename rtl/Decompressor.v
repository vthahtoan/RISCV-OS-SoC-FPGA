`timescale 1ns / 1ps

module Decompressor (
    input  wire [31:0] instr_in,      
    output reg  [31:0] instr_out,     
    output wire        is_compressed  
);

    wire [15:0] cinstr = instr_in[15:0];
    
    wire [1:0] op     = cinstr[1:0];
    wire [2:0] funct3 = cinstr[15:13];
    
    assign is_compressed = (op != 2'b11);

    wire [4:0] rs1_p = {2'b01, cinstr[9:7]};
    wire [4:0] rs2_p = {2'b01, cinstr[4:2]};
    
    wire [4:0] rd_rs1 = cinstr[11:7];
    wire [4:0] rs2    = cinstr[6:2];

    localparam OPC_LOAD   = 7'b0000011;
    localparam OPC_STORE  = 7'b0100011;
    localparam OPC_IMM    = 7'b0010011;
    localparam OPC_OP     = 7'b0110011;
    localparam OPC_JAL    = 7'b1101111;
    localparam OPC_JALR   = 7'b1100111;
    localparam OPC_BRANCH = 7'b1100011;
    localparam OPC_LUI    = 7'b0110111;
    localparam OPC_SYSTEM = 7'b1110011;

    // Format CI (C.ADDI, C.LI, C.LUI)
    wire [31:0] imm_CI = {{26{cinstr[12]}}, cinstr[12], cinstr[6:2]};
    
    // Format CJ (C.J, C.JAL)
    wire [31:0] imm_CJ = {{20{cinstr[12]}}, cinstr[12], cinstr[8], cinstr[10:9], cinstr[6], cinstr[7], cinstr[2], cinstr[11], cinstr[5:3], 1'b0};
    
    // Format CB (C.BEQZ, C.BNEZ)
    wire [31:0] imm_CB = {{23{cinstr[12]}}, cinstr[12], cinstr[6:5], cinstr[2], cinstr[11:10], cinstr[4:3], 1'b0};
    
    // Format CSS (C.LWSP, C.SWSP)
    wire [31:0] imm_CSS_LWSP = {24'b0, cinstr[3:2], cinstr[12], cinstr[6:4], 2'b00};
    wire [31:0] imm_CSS_SWSP = {24'b0, cinstr[8:7], cinstr[12:9], 2'b00};
    
    // Format CL/CS (C.LW, C.SW)
    wire [31:0] imm_CLW_CSW = {25'b0, cinstr[5], cinstr[12:10], cinstr[6], 2'b00};
    
    // Format dac biet cho C.ADDI16SP va C.ADDI4SPN
    wire [31:0] imm_ADDI16SP = {{22{cinstr[12]}}, cinstr[12], cinstr[4:3], cinstr[5], cinstr[2], cinstr[6], 4'b0000};
    wire [31:0] imm_ADDI4SPN = {22'b0, cinstr[10:7], cinstr[12:11], cinstr[5], cinstr[6], 2'b00};

    always @(*) begin
        instr_out = 32'h00000013; 
        if (!is_compressed) begin
            instr_out = instr_in; //32-bit
        end else begin
            case (op)
                2'b00: begin
                    case (funct3)
                        3'b000: // C.ADDI4SPN (addi rd_p, x2, imm)
                            if (cinstr[12:5] != 8'b0)
                                instr_out = {imm_ADDI4SPN[11:0], 5'b00010, 3'b000, rs2_p, OPC_IMM};
                        3'b010: // C.LW (lw rd_p, imm(rs1_p))
                            instr_out = {imm_CLW_CSW[11:0], rs1_p, 3'b010, rs2_p, OPC_LOAD};
                        3'b110: // C.SW (sw rs2_p, imm(rs1_p))
                            instr_out = {imm_CLW_CSW[11:5], rs2_p, rs1_p, 3'b010, imm_CLW_CSW[4:0], OPC_STORE};
                        default: instr_out = 32'h00000013; // NOP
                    endcase
                end

                2'b01: begin
                    case (funct3)
                        3'b000: // C.NOP / C.ADDI (addi rd, rd, imm)
                            if (rd_rs1 != 5'b0)
                                instr_out = {imm_CI[11:0], rd_rs1, 3'b000, rd_rs1, OPC_IMM};
                        3'b001: // C.JAL (jal x1, imm)
                            instr_out = {imm_CJ[20], imm_CJ[10:1], imm_CJ[11], imm_CJ[19:12], 5'b00001, OPC_JAL};
                        3'b010: // C.LI (addi rd, x0, imm)
                            if (rd_rs1 != 5'b0)
                                instr_out = {imm_CI[11:0], 5'b00000, 3'b000, rd_rs1, OPC_IMM};
                        3'b011: begin
                            if (rd_rs1 == 5'b00010) // C.ADDI16SP (addi x2, x2, imm)
                                instr_out = {imm_ADDI16SP[11:0], 5'b00010, 3'b000, 5'b00010, OPC_IMM};
                            else if (rd_rs1 != 5'b0) // C.LUI (lui rd, imm)
                                instr_out = {imm_CI[19:0], rd_rs1, OPC_LUI};
                        end
                        3'b100: begin
                            case (cinstr[11:10])
                                2'b00: // C.SRLI (srli rd_p, rd_p, shamt)
                                    instr_out = {7'b0000000, imm_CI[4:0], rs1_p, 3'b101, rs1_p, OPC_IMM};
                                2'b01: // C.SRAI (srai rd_p, rd_p, shamt)
                                    instr_out = {7'b0100000, imm_CI[4:0], rs1_p, 3'b101, rs1_p, OPC_IMM};
                                2'b10: // C.ANDI (andi rd_p, rd_p, imm)
                                    instr_out = {imm_CI[11:0], rs1_p, 3'b111, rs1_p, OPC_IMM};
                                2'b11: begin
                                    case ({cinstr[12], cinstr[6:5]})
                                        3'b000: // C.SUB (sub rd_p, rd_p, rs2_p)
                                            instr_out = {7'b0100000, rs2_p, rs1_p, 3'b000, rs1_p, OPC_OP};
                                        3'b001: // C.XOR (xor rd_p, rd_p, rs2_p)
                                            instr_out = {7'b0000000, rs2_p, rs1_p, 3'b100, rs1_p, OPC_OP};
                                        3'b010: // C.OR (or rd_p, rd_p, rs2_p)
                                            instr_out = {7'b0000000, rs2_p, rs1_p, 3'b110, rs1_p, OPC_OP};
                                        3'b011: // C.AND (and rd_p, rd_p, rs2_p)
                                            instr_out = {7'b0000000, rs2_p, rs1_p, 3'b111, rs1_p, OPC_OP};
                                        default: instr_out = 32'h00000013;
                                    endcase
                                end
                            endcase
                        end
                        3'b101: // C.J (jal x0, imm)
                            instr_out = {imm_CJ[20], imm_CJ[10:1], imm_CJ[11], imm_CJ[19:12], 5'b00000, OPC_JAL};
                        3'b110: // C.BEQZ (beq rs1_p, x0, imm)
                            instr_out = {imm_CB[12], imm_CB[10:5], 5'b00000, rs1_p, 3'b000, imm_CB[4:1], imm_CB[11], OPC_BRANCH};
                        3'b111: // C.BNEZ (bne rs1_p, x0, imm)
                            instr_out = {imm_CB[12], imm_CB[10:5], 5'b00000, rs1_p, 3'b001, imm_CB[4:1], imm_CB[11], OPC_BRANCH};
                    endcase
                end

                2'b10: begin
                    case (funct3)
                        3'b000: // C.SLLI (slli rd, rd, shamt)
                            if (rd_rs1 != 5'b0)
                                instr_out = {7'b0000000, imm_CI[4:0], rd_rs1, 3'b001, rd_rs1, OPC_IMM};
                        3'b010: // C.LWSP (lw rd, imm(x2))
                            if (rd_rs1 != 5'b0)
                                instr_out = {imm_CSS_LWSP[11:0], 5'b00010, 3'b010, rd_rs1, OPC_LOAD};
                        3'b100: begin
                            if (cinstr[12] == 0) begin
                                if (rs2 == 5'b0) // C.JR (jalr x0, rd/rs1, 0)
                                    instr_out = {12'b0, rd_rs1, 3'b000, 5'b00000, OPC_JALR};
                                else // C.MV (add rd, x0, rs2)
                                    instr_out = {7'b0000000, rs2, 5'b00000, 3'b000, rd_rs1, OPC_OP};
                            end else begin
                                if (rs2 == 5'b0) begin
                                    if (rd_rs1 == 5'b0) // C.EBREAK
                                        instr_out = {12'b000000000001, 5'b00000, 3'b000, 5'b00000, OPC_SYSTEM};
                                    else // C.JALR (jalr x1, rd/rs1, 0)
                                        instr_out = {12'b0, rd_rs1, 3'b000, 5'b00001, OPC_JALR};
                                end else begin
                                    // C.ADD (add rd, rd, rs2)
                                    instr_out = {7'b0000000, rs2, rd_rs1, 3'b000, rd_rs1, OPC_OP};
                                end
                            end
                        end
                        3'b110: // C.SWSP (sw rs2, imm(x2))
                            instr_out = {imm_CSS_SWSP[11:5], rs2, 5'b00010, 3'b010, imm_CSS_SWSP[4:0], OPC_STORE};
                        default: instr_out = 32'h00000013; // NOP
                    endcase
                end
                
                default: instr_out = 32'h00000013;
            endcase
        end
    end
endmodule
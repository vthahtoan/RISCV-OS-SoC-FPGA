`timescale 1ns / 1ps

module Datapath(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [31:0] bram_rdata, 
    output wire [31:0] dbg_pc,     
    output wire [31:0] dbg_result  
);

    wire        PC_en, IF_ID_en;          
    wire        IF_ID_clear, ID_EX_clear; 
    wire [1:0]  ForwardA, ForwardB;        

    wire        ex_is_m_ext; 
    wire [2:0]  ex_funct3; 

    wire        mul_busy, mul_valid;
    wire        div_busy, div_valid;

    wire        mul_clk_en = en;
    wire        div_clk_en = en;

    wire        is_mul_op = ex_is_m_ext & ~ex_funct3[2];
    wire        is_div_op = ex_is_m_ext &  ex_funct3[2];
    wire        m_stall   = (is_mul_op & ~mul_valid) | (is_div_op & ~div_valid); 

    // IF
    (* mark_debug = "true" *) wire [31:0] if_PC;
    wire [31:0] if_PC_Next;
    
    wire [31:0] instr_aligned;
    wire [31:0] instr_decompressed;
    wire        is_compressed;

    wire        force_c;
    wire        if_flush = (ex_Jump || ex_PCSrc);

    Fetch_Aligner u_Aligner (
        .clk(clk),
        .rst_n(rst_n),
        .en(en & PC_en & ~m_stall),
        .flush(if_flush),
        .pc(if_PC), 
        .rdata_32(bram_rdata),
        .instr_aligned(instr_aligned),
        .force_c(force_c)
    );

    Decompressor u_Decompressor (
        .instr_in(instr_aligned),
        .instr_out(instr_decompressed),
        .is_compressed(is_compressed)
    );

    wire [31:0] if_PC_Plus_4 = if_PC + ((is_compressed | force_c) ? 32'd2 : 32'd4);
    (* mark_debug = "true" *) wire [31:0] if_Instruction = instr_decompressed;

    PC u_PC (
        .clk(clk),
        .rst_n(rst_n),
        .en(en & PC_en & ~m_stall),
        .PC_Next(if_PC_Next), 
        .PC(if_PC)            
    );

    // IF/ID
    wire [31:0] id_PC, id_Instruction;
    wire        id_is_compressed;
    
    IF_ID_reg u_IF_ID (
        .clk(clk), 
        .rst_n(rst_n), 
        .en(en & IF_ID_en & ~m_stall),
        .clear(IF_ID_clear | if_flush),     
        .if_PC(force_c ? (if_PC - 32'd2) : if_PC), 
        .if_Instruction(if_Instruction),
        .if_is_compressed(is_compressed),
        .id_PC(id_PC), 
        .id_Instruction(id_Instruction),
        .id_is_compressed(id_is_compressed)
    );

    // ID
    wire [6:0]  id_opcode = id_Instruction[6:0];
    wire [4:0]  id_rd     = id_Instruction[11:7];
    wire [2:0]  id_funct3 = id_Instruction[14:12];
    wire [4:0]  id_rs1    = id_Instruction[19:15];
    wire [4:0]  id_rs2    = id_Instruction[24:20];
    wire        id_op5    = id_Instruction[5];
    wire        id_bit30  = id_Instruction[30];
    wire [6:0]  id_funct7 = id_Instruction[31:25];

    wire id_is_m_ext = (id_opcode == 7'b0110011) && (id_funct7 == 7'b0000001);
    wire id_is_jalr  = (id_opcode == 7'b1100111);

    wire        id_Branch, id_Jump, id_MemRead, id_MemWrite, id_ALUSrc, id_RegWrite;
    wire [1:0]  id_MemtoReg, id_ALUOp, id_ALUSrcA;

    ControlUnit u_ControlUnit (
        .opcode(id_opcode),
        .Branch(id_Branch), 
        .Jump(id_Jump), 
        .MemRead(id_MemRead), 
        .MemtoReg(id_MemtoReg),
        .ALUOp(id_ALUOp), 
        .MemWrite(id_MemWrite), 
        .ALUSrc(id_ALUSrc), 
        .ALUSrcA(id_ALUSrcA),
        .RegWrite(id_RegWrite)
    );

    wire [31:0] id_RD1_raw, id_RD2_raw, wb_WD3;          
    wire [4:0]  wb_rd;             
    wire        wb_RegWrite;

    RegFile u_RegFile (
        .clk(clk),
        .rst_n(rst_n),
        .WE(wb_RegWrite),    
        .RR1(id_rs1),            
        .RR2(id_rs2),            
        .WR(wb_rd),              
        .WD(wb_WD3),             
        .RD1(id_RD1_raw),
        .RD2(id_RD2_raw)
    );

    wire [31:0] id_RD1 = (wb_RegWrite && (wb_rd != 5'b0) && (wb_rd == id_rs1)) ? wb_WD3 : id_RD1_raw;
    wire [31:0] id_RD2 = (wb_RegWrite && (wb_rd != 5'b0) && (wb_rd == id_rs2)) ? wb_WD3 : id_RD2_raw;

    wire [31:0] id_ImmOut;

    ImmGen u_ImmGen (
        .inst(id_Instruction),
        .ImmOut(id_ImmOut)
    );

    wire        ex_MemRead, ex_Jump, ex_PCSrc;
    wire [4:0]  ex_rd;

    HazardDetectionUnit u_HazardUnit (
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .ex_rd(ex_rd),
        .ex_MemRead(ex_MemRead),
        .ex_Jump(ex_Jump),
        .ex_PCSrc(ex_PCSrc),
        .PC_en(PC_en),             
        .IF_ID_en(IF_ID_en),       
        .IF_ID_clear(IF_ID_clear), 
        .ID_EX_clear(ID_EX_clear)  
    );

    // ID/EX
    wire [31:0] ex_PC, ex_RD1, ex_RD2, ex_Imm;
    wire [4:0]  ex_rs1, ex_rs2;
    wire        ex_op5, ex_bit30, ex_is_jalr;
    wire        ex_RegWrite, ex_MemWrite, ex_Branch, ex_ALUSrc;
    wire [1:0]  ex_MemtoReg, ex_ALUOp, ex_ALUSrcA;
    wire        ex_is_compressed; 

    ID_EX_reg u_ID_EX (
        .clk(clk), 
        .rst_n(rst_n), 
        .en(en & ~m_stall),
        .clear(ID_EX_clear | if_flush), 
        .id_is_m_ext(id_is_m_ext),
        .ex_is_m_ext(ex_is_m_ext),
        .id_PC(id_PC), 
        .id_RD1(id_RD1), 
        .id_RD2(id_RD2), 
        .id_Imm(id_ImmOut),
        .id_rs1(id_rs1), 
        .id_rs2(id_rs2), 
        .id_rd(id_rd), 
        .id_funct3(id_funct3), 
        .id_op5(id_op5), 
        .id_bit30(id_bit30),
        .id_is_jalr(id_is_jalr),
        .id_RegWrite(id_RegWrite), 
        .id_MemRead(id_MemRead), 
        .id_MemWrite(id_MemWrite), 
        .id_Branch(id_Branch), 
        .id_Jump(id_Jump), 
        .id_ALUSrc(id_ALUSrc), 
        .id_MemtoReg(id_MemtoReg), 
        .id_ALUOp(id_ALUOp), 
        .id_ALUSrcA(id_ALUSrcA),
        .id_is_compressed(id_is_compressed),
        .ex_is_compressed(ex_is_compressed), 
        .ex_PC(ex_PC), 
        .ex_RD1(ex_RD1), 
        .ex_RD2(ex_RD2), 
        .ex_Imm(ex_Imm),
        .ex_rs1(ex_rs1), 
        .ex_rs2(ex_rs2), 
        .ex_rd(ex_rd),
        .ex_funct3(ex_funct3), 
        .ex_op5(ex_op5), 
        .ex_bit30(ex_bit30),
        .ex_is_jalr(ex_is_jalr),
        .ex_RegWrite(ex_RegWrite), 
        .ex_MemRead(ex_MemRead), 
        .ex_MemWrite(ex_MemWrite), 
        .ex_Branch(ex_Branch), 
        .ex_Jump(ex_Jump), 
        .ex_ALUSrc(ex_ALUSrc), 
        .ex_MemtoReg(ex_MemtoReg), 
        .ex_ALUOp(ex_ALUOp), 
        .ex_ALUSrcA(ex_ALUSrcA)
    );

    // EX
    wire [3:0]  ex_ALU_Ctrl;
    wire [31:0] ex_ALUResult;
    wire        ex_Zero;
    wire [31:0] ex_PC_Branch = ex_PC + ex_Imm;

    ALUControl u_ALUControl (
        .ALUOp(ex_ALUOp), 
        .funct3(ex_funct3), 
        .bit30(ex_bit30), 
        .op5(ex_op5),
        .ALU_Ctrl(ex_ALU_Ctrl)
    );

    wire [4:0]  mem_rd;
    wire        mem_RegWrite;

    ForwardingUnit u_ForwardUnit (
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .mem_rd(mem_rd),             
        .mem_RegWrite(mem_RegWrite), 
        .wb_rd(wb_rd),               
        .wb_RegWrite(wb_RegWrite),   
        .ForwardA(ForwardA),         
        .ForwardB(ForwardB)          
    );

    (* mark_debug = "true" *) wire [31:0] mem_ALUResult; 

    wire [31:0] ex_SrcA_base = (ex_ALUSrcA == 2'b00) ? ex_RD1 : 
                               (ex_ALUSrcA == 2'b01) ? ex_PC : 32'b0; 
    
    wire [31:0] ex_SrcA = (ex_ALUSrcA != 2'b00) ? ex_SrcA_base :
                          (ForwardA == 2'b10)   ? mem_ALUResult : 
                          (ForwardA == 2'b01)   ? wb_WD3 : ex_RD1;                        
                          
    wire [31:0] ex_Forwarded_RD2 = (ForwardB == 2'b10) ? mem_ALUResult : 
                                   (ForwardB == 2'b01) ? wb_WD3 :        
                                   ex_RD2;

    wire [31:0] ex_SrcB = (ex_ALUSrc == 1'b1) ? ex_Imm : ex_Forwarded_RD2;

    ALU u_ALU (
        .SrcA(ex_SrcA), 
        .SrcB(ex_SrcB), 
        .ALUControl(ex_ALU_Ctrl),
        .ALUResult(ex_ALUResult), 
        .wireZero(ex_Zero)
    );

    wire [31:0] mul_result;

    Multiplier u_Mul (
        .clk(clk),
        .reset(~rst_n), 
        .clk_en(mul_clk_en),
        .start(is_mul_op && !mul_valid && !mul_busy),
        .rs1_data(ex_SrcA),
        .rs2_data(ex_SrcB),
        .mul_op(ex_funct3[1:0]),
        .mul_result(mul_result),
        .busy(mul_busy),
        .valid(mul_valid)
    );

    wire [31:0] div_result;

    Divider u_Div (
        .clk(clk),
        .reset(~rst_n),
        .clk_en(div_clk_en),
        .start(is_div_op && !div_valid && !div_busy),
        .rs1_data(ex_SrcA),
        .rs2_data(ex_SrcB),
        .div_op(ex_funct3[1:0]),
        .div_result(div_result),
        .busy(div_busy),
        .valid(div_valid)
    );

    wire [31:0] ex_FinalResult = is_mul_op ? mul_result :
                                 is_div_op ? div_result :
                                 ex_ALUResult;

    BranchUnit u_BranchUnit (
        .Branch(ex_Branch), 
        .funct3(ex_funct3), 
        .Zero(ex_Zero),
        .ALU_LSB(ex_FinalResult[0]),
        .PCSrc(ex_PCSrc) 
    );

    wire [31:0] ex_PC_Target = ex_is_jalr ? {ex_FinalResult[31:1], 1'b0} : ex_PC_Branch;
    wire [31:0] ex_PC_Plus_4 = ex_PC + (ex_is_compressed ? 32'd2 : 32'd4);
    
    assign if_PC_Next = (ex_Jump || ex_PCSrc) ? ex_PC_Target : if_PC_Plus_4; 

    // EX/MEM
    (* mark_debug = "true" *) wire [31:0] mem_RD2;
    wire [31:0] mem_PC_Plus_4;
    wire [2:0]  mem_funct3;
    
    (* mark_debug = "true" *) wire        mem_MemRead;
    (* mark_debug = "true" *) wire        mem_MemWrite;
    wire [1:0]  mem_MemtoReg;

    EX_MEM_reg u_EX_MEM (
        .clk(clk), 
        .rst_n(rst_n), 
        .en(en), 
        .clear(en & m_stall),
        .ex_ALUResult(ex_FinalResult),
        .ex_RD2(ex_Forwarded_RD2), 
        .ex_PC_Plus_4(ex_PC_Plus_4), 
        .ex_rd(ex_rd),
        .ex_funct3(ex_funct3),
        .ex_RegWrite(ex_RegWrite), 
        .ex_MemRead(ex_MemRead), 
        .ex_MemWrite(ex_MemWrite), 
        .ex_MemtoReg(ex_MemtoReg),
        .mem_ALUResult(mem_ALUResult), 
        .mem_RD2(mem_RD2), 
        .mem_PC_Plus_4(mem_PC_Plus_4), 
        .mem_rd(mem_rd),
        .mem_funct3(mem_funct3),
        .mem_RegWrite(mem_RegWrite), 
        .mem_MemRead(mem_MemRead), 
        .mem_MemWrite(mem_MemWrite), 
        .mem_MemtoReg(mem_MemtoReg)
    );

    // MEM
    wire [31:0] mem_ReadData;

    DataMemory u_DMEM (
        .clk(clk),
        .MemWrite(mem_MemWrite), 
        .MemRead(mem_MemRead),
        .funct3(mem_funct3),
        .Address(mem_ALUResult), 
        .WriteData(mem_RD2),     
        .ReadData(mem_ReadData)  
    );

    // MEM/WB
    wire [31:0] wb_ALUResult, wb_ReadData, wb_PC_Plus_4;
    wire [1:0]  wb_MemtoReg;

    MEM_WB_reg u_MEM_WB (
        .clk(clk), 
        .rst_n(rst_n), 
        .en(en), 
        .clear(1'b0),
        .mem_ALUResult(mem_ALUResult), 
        .mem_ReadData(mem_ReadData), 
        .mem_PC_Plus_4(mem_PC_Plus_4), 
        .mem_rd(mem_rd),
        .mem_RegWrite(mem_RegWrite), 
        .mem_MemtoReg(mem_MemtoReg),
        .wb_ALUResult(wb_ALUResult), 
        .wb_ReadData(wb_ReadData), 
        .wb_PC_Plus_4(wb_PC_Plus_4), 
        .wb_rd(wb_rd),
        .wb_RegWrite(wb_RegWrite), 
        .wb_MemtoReg(wb_MemtoReg)
    );

    // WB
    assign wb_WD3 = (wb_MemtoReg == 2'b00) ? wb_ALUResult :   
                    (wb_MemtoReg == 2'b01) ? wb_ReadData  :    
                    wb_PC_Plus_4;

    reg [31:0] gpio_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_out <= 32'b0;
        end else if (mem_MemWrite) begin
            if (mem_ALUResult == 32'h00000804) begin
                gpio_out <= mem_RD2;
            end 
        end
    end

    assign dbg_pc     = if_PC;
    assign dbg_result = (gpio_out != 32'b0) ? gpio_out : wb_WD3; 

endmodule
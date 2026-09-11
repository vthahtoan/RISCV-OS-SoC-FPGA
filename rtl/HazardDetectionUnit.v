`timescale 1ns / 1ps

module HazardDetectionUnit(
    input  wire [4:0] id_rs1,
    input  wire [4:0] id_rs2,
    input  wire [4:0] ex_rd,
    input  wire       ex_MemRead,
    input  wire       ex_Jump,
    input  wire       ex_PCSrc,

    output reg        PC_en,
    output reg        IF_ID_en,
    output reg        IF_ID_clear,
    output reg        ID_EX_clear
);

    always @(*) begin
        PC_en       = 1'b1;
        IF_ID_en    = 1'b1;
        IF_ID_clear = 1'b0;
        ID_EX_clear = 1'b0;

        if (ex_MemRead && (ex_rd != 5'b0) && ((ex_rd == id_rs1) || (ex_rd == id_rs2))) begin
            PC_en       = 1'b0;
            IF_ID_en    = 1'b0;
            ID_EX_clear = 1'b1;
        end

        if (ex_Jump || ex_PCSrc) begin
            IF_ID_clear = 1'b1;
            ID_EX_clear = 1'b1;
        end
    end

endmodule
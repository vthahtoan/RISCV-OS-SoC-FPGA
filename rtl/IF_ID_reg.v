`timescale 1ns / 1ps

module IF_ID_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        clear,
    
    input  wire [31:0] if_PC,
    input  wire [31:0] if_Instruction,
    input  wire        if_is_compressed,
    
    output reg  [31:0] id_PC,
    output reg  [31:0] id_Instruction,
    output reg         id_is_compressed
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_PC            <= 32'b0;
            id_Instruction   <= 32'h00000013;
            id_is_compressed <= 1'b0;
        end else if (en) begin
            if (clear) begin
                id_PC            <= 32'b0;
                id_Instruction   <= 32'h00000013;
                id_is_compressed <= 1'b0;
            end else begin
                id_PC            <= if_PC;
                id_Instruction   <= if_Instruction;
                id_is_compressed <= if_is_compressed;
            end
        end
    end

endmodule
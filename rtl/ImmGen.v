`timescale 1ns / 1ps

module ImmGen(
    input  wire [31:0] inst,
    output reg  [31:0] ImmOut
);

    wire [6:0] opcode = inst[6:0];

    always @(*) begin
        case (opcode)
            // Nhom I-Type
            7'b0010011, 7'b0000011, 7'b1100111: begin
                ImmOut = {{20{inst[31]}}, inst[31:20]};
            end
            
            // Nhom S-Type
            7'b0100011: begin
                ImmOut = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end
            
            // Nhom B-Type
            7'b1100011: begin
                ImmOut = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            end
            
            // Nhom J-Type
            7'b1101111: begin
                ImmOut = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            end
            
            // Nhom U-Type 
            7'b0110111, 7'b0010111: begin
                ImmOut = {inst[31:12], 12'b0};
            end
            default: ImmOut = 32'b0;
        endcase
    end
endmodule
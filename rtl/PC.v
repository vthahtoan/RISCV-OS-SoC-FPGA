`timescale 1ns / 1ps

module PC (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [31:0] PC_Next,   
    output reg  [31:0] PC         
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'h00000000; 
        end else if (en) begin
            PC <= PC_Next;      
        end
    end

endmodule
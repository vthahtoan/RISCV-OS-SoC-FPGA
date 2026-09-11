`timescale 1ns / 1ps

module Fetch_Aligner (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        flush,
    input  wire [31:0] pc,
    input  wire [31:0] rdata_32,
    output wire [31:0] instr_aligned,
    output wire        force_c
);
    reg [15:0] saved_half;
    reg        is_crossing;

    wire [15:0] upper_half = rdata_32[31:16]; 
    wire is_32b_inst = (upper_half[1:0] == 2'b11);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_crossing <= 1'b0;
            saved_half  <= 16'b0;
        end else if (flush) begin
            is_crossing <= 1'b0;
        end else if (en) begin
            if (!is_crossing && (pc[1] == 1'b1) && is_32b_inst) begin
                is_crossing <= 1'b1;
                saved_half  <= upper_half;
            end else if (is_crossing) begin
                is_crossing <= 1'b0;  
            end
        end
    end

    assign instr_aligned = (is_crossing) ? {rdata_32[15:0], saved_half} :
                           (!is_crossing && (pc[1] == 1'b1) && is_32b_inst) ? 32'h00000001 :
                           (pc[1] == 1'b0) ? rdata_32[31:0] :
                                             {16'h0000, upper_half};

    assign force_c = is_crossing;

endmodule
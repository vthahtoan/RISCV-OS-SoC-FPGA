`timescale 1ns / 1ps

module RegFile(
    input  wire        clk,   // Xung nhip he thong
    input  wire        rst_n, // Reset tich cuc muc thap
    input  wire        WE,    // Tin hieu cho phep ghi
    
    input  wire [4:0]  RR1,   // Dia chi thanh ghi 1
    input  wire [4:0]  RR2,   // Dia chi thanh ghi 2
    input  wire [4:0]  WR,    // Dia chi thanh ghi can ghi
    
    input  wire [31:0] WD,    // Du lieu can ghi
    
    output wire [31:0] RD1,   // Du lieu doc ra tu thanh ghi 1
    output wire [31:0] RD2    // Du lieu doc ra tu thanh ghi 2
);

    reg [31:0] rf [31:0]; 
    integer i;

    assign RD1 = (RR1 == 5'b00000) ? 32'b0 : rf[RR1];
    assign RD2 = (RR2 == 5'b00000) ? 32'b0 : rf[RR2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'b0;
            end
        end else begin
            if (WE == 1'b1 && WR != 5'b00000) begin
                rf[WR] <= WD;
            end
        end
    end

endmodule
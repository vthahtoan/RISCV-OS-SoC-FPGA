`timescale 1ns / 1ps

module DataMemory(
    input  wire        clk,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [2:0]  funct3,
    input  wire [31:0] Address,
    input  wire [31:0] WriteData,
    output reg  [31:0] ReadData
);

    reg [7:0] RAM0 [0:4095];
    reg [7:0] RAM1 [0:4095];
    reg [7:0] RAM2 [0:4095];
    reg [7:0] RAM3 [0:4095];

    wire [11:0] word_addr = Address[13:2];
    wire [31:0] current_word = {RAM3[word_addr], RAM2[word_addr], RAM1[word_addr], RAM0[word_addr]};

    always @(*) begin
        if (MemRead) begin
            case (funct3)
                3'b000: begin 
                    case (Address[1:0])
                        2'b00: ReadData = {{24{current_word[7]}},  current_word[7:0]};
                        2'b01: ReadData = {{24{current_word[15]}}, current_word[15:8]};
                        2'b10: ReadData = {{24{current_word[23]}}, current_word[23:16]};
                        2'b11: ReadData = {{24{current_word[31]}}, current_word[31:24]};
                    endcase
                end
                3'b001: begin 
                    case (Address[1])
                        1'b0: ReadData = {{16{current_word[15]}}, current_word[15:0]};
                        1'b1: ReadData = {{16{current_word[31]}}, current_word[31:16]};
                    endcase
                end
                3'b010: ReadData = current_word; 
                3'b100: begin 
                    case (Address[1:0])
                        2'b00: ReadData = {24'b0, current_word[7:0]};
                        2'b01: ReadData = {24'b0, current_word[15:8]};
                        2'b10: ReadData = {24'b0, current_word[23:16]};
                        2'b11: ReadData = {24'b0, current_word[31:24]};
                    endcase
                end
                3'b101: begin 
                    case (Address[1])
                        1'b0: ReadData = {16'b0, current_word[15:0]};
                        1'b1: ReadData = {16'b0, current_word[31:16]};
                    endcase
                end
                default: ReadData = 32'b0;
            endcase
        end else begin
            ReadData = 32'b0;
        end
    end

    always @(posedge clk) begin
        if (MemWrite) begin
            case (funct3)
                3'b000: begin // SB
                    case (Address[1:0])
                        2'b00: RAM0[word_addr] <= WriteData[7:0];
                        2'b01: RAM1[word_addr] <= WriteData[7:0];
                        2'b10: RAM2[word_addr] <= WriteData[7:0];
                        2'b11: RAM3[word_addr] <= WriteData[7:0];
                    endcase
                end
                3'b001: begin // SH
                    case (Address[1])
                        1'b0: begin
                            RAM0[word_addr] <= WriteData[7:0];
                            RAM1[word_addr] <= WriteData[15:8];
                        end
                        1'b1: begin
                            RAM2[word_addr] <= WriteData[7:0];
                            RAM3[word_addr] <= WriteData[15:8];
                        end
                    endcase
                end
                3'b010: begin // SW
                    RAM0[word_addr] <= WriteData[7:0];
                    RAM1[word_addr] <= WriteData[15:8];
                    RAM2[word_addr] <= WriteData[23:16];
                    RAM3[word_addr] <= WriteData[31:24];
                end
            endcase
        end
    end
endmodule
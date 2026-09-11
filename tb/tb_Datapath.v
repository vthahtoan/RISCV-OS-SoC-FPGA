`timescale 1ns / 1ps

module tb_Datapath();
    reg         clk, rst_n, en;
    wire [31:0] dbg_pc, dbg_result;

    wire [31:0] pure_pc = {16'h0000, dbg_pc[15:0]};
    
    wire [31:0] bram_rdata;
    reg  [31:0] imem [0:2047];

    wire [10:0] word_idx = pure_pc[12:2]; 
    assign bram_rdata = imem[word_idx];  

    Datapath u_DUT (
        .clk(clk), .rst_n(rst_n), .en(en),
        .bram_rdata(bram_rdata),
        .dbg_pc(dbg_pc), .dbg_result(dbg_result)
    );

    always #5 clk = ~clk; 

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_Datapath);
        clk = 0; rst_n = 0; en = 1;

        for (integer i = 0; i < 2048; i = i + 1) imem[i] = 32'h0;
        for (integer i = 0; i < 4096; i = i + 1) begin
            u_DUT.u_DMEM.RAM0[i] = 8'h0;
            u_DUT.u_DMEM.RAM1[i] = 8'h0;
            u_DUT.u_DMEM.RAM2[i] = 8'h0;
            u_DUT.u_DMEM.RAM3[i] = 8'h0;
        end

        $readmemh("program.hex", imem);

        repeat(5) @(posedge clk); #1;
        rst_n = 1;
    end

    integer cycle_count = 0;

    always @(posedge clk) begin
        if (rst_n && en)
            cycle_count <= cycle_count + 1;
    end

    always @(posedge clk) begin
        if (rst_n && en && u_DUT.mem_MemWrite) begin
            if (u_DUT.mem_ALUResult == 32'h00000804) begin
                $display("");
                $display("--------------------------------------------------");
                $display("  KET QUA SAU %0d CYCLE", cycle_count);
                $display("--------------------------------------------------");

                if (u_DUT.mem_RD2 == 32'h600DCAFE) begin
                    $display("  >>> [PASS] 0x600DCAFE TAI PC: 0x%08X", pure_pc);
                    $display("  >>> CPU DA VUOT QUA BAI TEST VA DUNG LAI!");
                end else if (u_DUT.mem_RD2 == 32'hDEADBEEF) begin
                    $display("  >>> [FAIL] CPU BAO LOI (DEADBEEF) TAI PC: 0x%08X", pure_pc);
                end else begin
                    $display("  >>> [CHECK] CPU xuat tin hieu: 0x%08X", u_DUT.mem_RD2);
                end

                $display("==================================================");
                $display("");
                #100;
                $finish;
            end
        end
    end

    reg [31:0] last_pc = 32'hFFFFFFFF;
    reg [31:0] same_pc_count = 0;

    always @(posedge clk) begin
        if (rst_n && en) begin
            if (pure_pc != last_pc) begin
                $display("[Cycle %5d] PC=0x%08X", cycle_count, pure_pc);
                last_pc <= pure_pc;
                same_pc_count <= 0;
            end else begin
                same_pc_count <= same_pc_count + 1;
                if (same_pc_count == 1000) begin
                    $display("");
                    $display("[TRAP] PC bi ket tai 0x%08X sau %0d cycle.", pure_pc, cycle_count);                    
                    $display("");
                    #100;
                    $finish;
                end
            end
        end
    end

    initial begin
        #2000000;
        $display("");
        $display("[TIMEOUT] CPU TREO sau 200000 cycle!");
        $display("  Last PC = 0x%08X", pure_pc);
        $display("");
        $finish;
    end

endmodule
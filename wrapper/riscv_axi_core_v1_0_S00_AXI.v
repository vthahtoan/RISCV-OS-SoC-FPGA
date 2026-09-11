`timescale 1 ns / 1 ps

module riscv_axi_core_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)
(
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire [2:0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire S_AXI_WREADY,
    output wire [1:0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire [2:0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire  S_AXI_RREADY,

    output wire [31:0] bram_addr,
    input  wire [31:0] bram_rdata,
    output wire        bram_en
);

    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg  axi_awready;
    reg  axi_wready;
    reg [1:0] axi_bresp;
    reg  axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg  axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0] axi_rresp;
    reg  axi_rvalid;
    reg  aw_en;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    localparam integer ADDR_LSB = 2;
    localparam integer OPT_MEM_ADDR_BITS = 1;

    reg [31:0] slv_reg2;
    reg [31:0] slv_reg3;

    wire slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
    wire slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin 
            axi_awready <= 1'b0;
            aw_en <= 1'b1; 
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else 
                axi_awready <= 1'b0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) 
            axi_awaddr <= 0;
        else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            axi_awaddr <= S_AXI_AWADDR;
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) 
            axi_wready <= 1'b0;
        else if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) 
            axi_wready <= 1'b1;
        else 
            axi_wready <= 1'b0;
    end

    // =========================================================================
    // FIX L?I S? 2: X? LÝ AXI WRITE STROBE ?? CH?NG GHI ?È PARTIAL WRITE
    // =========================================================================
    integer byte_index;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin 
            slv_reg2 <= 0;
            slv_reg3 <= 0; 
        end else if (slv_reg_wren) begin
            case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                2'h2: begin
                    for (byte_index = 0; byte_index <= 3; byte_index = byte_index + 1) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                    end
                end
                2'h3: begin
                    for (byte_index = 0; byte_index <= 3; byte_index = byte_index + 1) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                    end
                end
                default: ;
            endcase
        end
    end
    // =========================================================================

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin 
            axi_bvalid <= 0;
            axi_bresp <= 2'b0; 
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
                axi_bresp <= 2'b0;
            end else if (S_AXI_BREADY && axi_bvalid) 
                axi_bvalid <= 1'b0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin 
            axi_arready <= 1'b0;
            axi_araddr <= 0; 
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr <= S_AXI_ARADDR;
            end else 
                axi_arready <= 1'b0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin 
            axi_rvalid <= 0;
            axi_rresp <= 0; 
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp <= 2'b0;
            end else if (axi_rvalid && S_AXI_RREADY) 
                axi_rvalid <= 1'b0;
        end
    end

    wire [31:0] cpu_pc;
    wire [31:0] cpu_result;
    reg [31:0] reg_data_out;

    always @(*) begin
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            2'h0:    reg_data_out = cpu_pc;
            2'h1:    reg_data_out = cpu_result;
            2'h2:    reg_data_out = slv_reg2;
            2'h3:    reg_data_out = slv_reg3;
            default: reg_data_out = 32'b0;
        endcase
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) 
            axi_rdata <= 0;
        else if (slv_reg_rden) 
            axi_rdata <= reg_data_out;
    end

    wire soft_en = slv_reg2[0]; 
    reg phase_reg;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            phase_reg <= 1'b0;
        end else if (soft_en) begin
            phase_reg <= ~phase_reg; 
        end else begin
            phase_reg <= 1'b0;
        end
    end

    wire datapath_en = soft_en & phase_reg;
    wire cpu_reset_n = S_AXI_ARESETN & (~slv_reg3[0]);

    Datapath u_cpu (
        .clk(S_AXI_ACLK),
        .rst_n(cpu_reset_n),
        .en(datapath_en),
        .bram_rdata(bram_rdata),
        .dbg_pc(cpu_pc),
        .dbg_result(cpu_result)
    );

    assign bram_en   = 1'b1;
    assign bram_addr = {cpu_pc[31:2], 2'b00};

endmodule
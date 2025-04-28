`timescale 1ns / 1ns

module SDRAM_tb;

    parameter ClockFrequency = 50_000_000;
    parameter WordLength = 16;
    parameter BankAddrLen = 2;
    parameter RowAddrLen = 13;
    parameter ColAddrLen = 9;
    parameter AddressWidth = 24;
    parameter BurstLength = 8;

    reg CLK;
    reg RST;
    reg i_enable;
    reg i_rw;
    reg [AddressWidth-1:0] i_addr;
    reg [WordLength-1:0] i_data;
    wire [WordLength-1:0] o_sdram_data; // From SDRAM to module
    reg [WordLength-1:0] i_sdram_data;  // To SDRAM from module
    wire o_clk_en;
    wire o_cs_n;
    wire o_ras_n;
    wire o_cas_n;
    wire o_we_n;
    wire [12:0] o_addr;
    wire [1:0] o_bank;
    wire [1:0] o_dqm;
    wire [WordLength-1:0] o_data;
    wire o_valid_wr;
    wire o_valid_rd;
    wire o_busy;

    reg [WordLength-1:0] write_data [BurstLength-1:0];
    reg [WordLength-1:0] read_data [BurstLength-1:0];
    reg [WordLength-1:0] expected_read_data [BurstLength-1:0];

    integer i;

    SDRAM #(
        .ClockFrequency(ClockFrequency),
        .WordLength(WordLength),
        .BankAddrLen(BankAddrLen),
        .RowAddrLen(RowAddrLen),
        .ColAddrLen(ColAddrLen),
        .AddressWidth(AddressWidth),
        .BurstLength(BurstLength)
    ) dut (
        .CLK(CLK),
        .RST(RST),
        .i_enable(i_enable),
        .i_rw(i_rw),
        .i_addr(i_addr),
        .i_data(i_data),
        .i_sdram_data(i_sdram_data),
        .o_sdram_data(o_sdram_data),
        .o_clk_en(o_clk_en),
        .o_cs_n(o_cs_n),
        .o_ras_n(o_ras_n),
        .o_cas_n(o_cas_n),
        .o_we_n(o_we_n),
        .o_addr(o_addr),
        .o_bank(o_bank),
        .o_dqm(o_dqm),
        .o_data(o_data),
        .o_valid_wr(o_valid_wr),
        .o_valid_rd(o_valid_rd),
        .o_busy(o_busy)
    );

    initial begin
        CLK = 0;
        forever #10 CLK = ~CLK;
    end

    initial begin
        RST = 1;
        i_enable = 0;
        i_rw = 0;
        i_addr = 0;
        i_data = 0;
        i_sdram_data = 16'bz;

        RST = 1;
        #10;
        RST = 0;
        #20;
        RST = 1;
        #10000;

        $display("-------------------Write Burst--------------------");
        i_addr = 24'h000000; // Starting address for write
        i_rw = 0;

        for (i = 0; i < BurstLength; i = i + 1) begin
            write_data[i] = $random;
        end

        i_enable = 1;
        i_data = write_data[0];
        #20;
        i_enable = 0;

        for (i = 0; i < BurstLength; i = i + 1) begin
            wait(o_valid_wr);
            $display("Write valid signal received for word %0d", i);
            if (i < BurstLength - 1) begin
                i_data = write_data[i+1];
            end
            #20;
        end
        $display("Write burst completed.");
        #100;

        $display("---------------------Read Burst---------------------");
        i_addr = 24'h000000;
        i_rw = 1;

        i_enable = 1;
        #20;
        i_enable = 0;

        for (i = 0; i < BurstLength; i = i + 1) begin
            wait(o_valid_rd);
            $display("Read valid signal received for word %0d", i);
            read_data[i] = o_data;
            expected_read_data[i] = write_data[i];
            #20;
        end
        $display("Read burst completed.");

        $display("-------------------- Verify Read Data --------------------");
        for (i = 0; i < BurstLength; i = i + 1) begin
            if (read_data[i] == expected_read_data[i]) begin
                $display("Word %0d: Read data = %h, Expected data = %h - PASS", i, read_data[i], expected_read_data[i]);
            end else begin
                $error("Word %0d: Read data = %h, Expected data = %h - FAIL", i, read_data[i], expected_read_data[i]);
            end
        end

        $display("--------------------- Simulation End ----------------------");
        $finish;
    end

    reg [WordLength-1:0] sdram_memory [2**AddressWidth-1:0];

    always @(posedge CLK) begin
        if (!RST) begin
        end else begin
            if (!o_cs_n && o_ras_n && !o_cas_n && !o_we_n && o_clk_en) begin // Write
                if (!o_dqm[0]) sdram_memory[{o_bank, o_addr}] [7:0] <= i_sdram_data[7:0];
                if (!o_dqm[1]) sdram_memory[{o_bank, o_addr}] [15:8] <= i_sdram_data[15:8];
            end else if (!o_cs_n && o_ras_n && !o_cas_n && o_we_n && o_clk_en) begin // Read
                i_sdram_data <= sdram_memory[{o_bank, o_addr}];
            end
        end
    end

endmodule
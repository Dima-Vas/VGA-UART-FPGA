`timescale 1ns / 1ps

module VGA_wrapper #(
    parameter ClockFrequency = 50_000_000,
    parameter FrameWidth = 640,
    parameter FrameHeight = 480,
    parameter PixelBitWidth = 16,
    parameter BaudRateUART = 115200,
    parameter WordLengthSDRAM = 16
)(
    input wire CLK, RST,
    inout [WordLengthSDRAM-1:0] io_data,
    output wire o_clk_en,                // Clock Enable
    output wire o_cs_n,                  // Select SDRAM signal
    output wire o_ras_n,                 // Select a row #o_addr
    output wire o_cas_n,                 // Select a column #o_addr
    output wire o_we_n,                  // On 1, write selected data, on 0 - read it
    output wire [12:0] o_addr,           // SDRAM's address bus
    output wire [1:0] o_bank,            // SDRAM's bank selector
    output wire [1:0] o_dqm,
    input wire h_sync, v_sync, p_clk,
    input [7:0] i_data,
    output wire o_data
);

    localparam WordLenSDRAM         = 16,
               BankAddrLenSDRAM     = 2,
               RowAddrLenSDRAM      = 13,
               ColAddrLenSDRAM      = 9,
               AddressWidthSDRAM    = BankAddrLenSDRAM + RowAddrLenSDRAM + ColAddrLenSDRAM,
               ReadBurstLenSDRAM    = 8;
    

    wire [PixelBitWidth - 1:0] CurrPixelVGA;
    wire [PixelBitWidth - 1:0] CurrPixelCompressor;
    
    wire Switch_PixelReady;

    wire [7:0] CompressedFrame;
    wire Switch_SendFrameUART;    
    
    wire Switch_FIFOFull;
    wire Switch_FIFOEmpty;
    
    reg Switch_EnableSDRAM;
    reg Switch_EnableReadSDRAM; // 0 - write, 1 - read
    reg [AddressWidthSDRAM-1:0] AddressSDRAM;
    wire [WordLengthSDRAM-1:0] InputDataSRAM;
    wire Switch_PixelForCompressorReady;
    wire Switch_BusySDRAM;
    
    VGA #(PixelBitWidth) vga(
        .p_clk(p_clk),
        .RST(RST),
        .h_sync(h_sync),
        .i_data(i_data),
        .o_data(CurrPixelVGA),
        .o_ready(Switch_PixelReady)
    );
    
    UART #(ClockFrequency, BaudRateUART) uart(
        .CLK(CLK),
        .RST(RST),
        .i_send(Switch_SendFrameUART),
        .i_frame(CompressedFrame),
        .o_data(o_data)
    );
    
    Compressor #(FrameWidth, PixelBitWidth) compressor (
        .CLK(CLK),
        .RST(RST),
        .i_pixel(CurrPixelCompressor),
        .i_ready(Switch_PixelForCompressorReady),
        .o_frame(CompressedFrame),
        .o_ready(Switch_SendFrameUART)
    );
    
    fifo_generator_0 PCLK_CLK_FIFO (
        .wr_clk(p_clk),
        .rd_clk(CLK),
        .wr_en(Switch_PixelReady & ~Switch_FIFOFull),
        .rd_en(Switch_EnableSDRAM & Switch_EnableReadSDRAM & ~Switch_BusySDRAM),
        .din(CurrPixelVGA),
        .dout(InputDataSRAM),
        .full(Switch_FIFOFull),
        .empty(Switch_FIFOEmpty)
    );
    
    SDRAM #(ClockFrequency, 
            WordLenSDRAM,
            BankAddrLenSDRAM,
            RowAddrLenSDRAM,
            ColAddrLenSDRAM,
            AddressWidthSDRAM,
            ReadBurstLenSDRAM) sdram (
        .CLK(CLK),
        .RST(RST),
        .i_enable(Switch_EnableSDRAM),
        .i_rw(Switch_EnableReadSDRAM),
        .i_addr(AddressSDRAM),
        .i_data(InputDataSRAM),
        .io_data(io_data),
        .o_clk_en(o_clk_en),
        .o_cs_n(o_cs_n),
        .o_ras_n(o_ras_n),
        .o_cas_n(o_cas_n),
        .o_we_n(o_we_n),
        .o_addr(o_addr),
        .o_bank(o_bank),
        .o_dqm(o_dqm),
        .o_data(CurrPixelCompressor),
        .o_valid(Switch_PixelForCompressorReady),
        .o_busy(Switch_BusySDRAM)
    );
    
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            Switch_EnableSDRAM <= 1'b0;
            Switch_EnableReadSDRAM <= 1'b0;
            AddressSDRAM <= 0;
        end else begin
            
        end
    end
    
endmodule

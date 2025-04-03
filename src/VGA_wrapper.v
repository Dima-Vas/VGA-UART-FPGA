`timescale 1ns / 1ps

module VGA_wrapper #(
    parameter ClockFrequency = 50_000_000,
    parameter FrameWidth = 640,
    parameter FrameHeight = 480,
    parameter PixelBitWidth = 16,
    parameter BaudRateUART = 115200,
    parameter WordLengthSDRAM = 16,
    parameter BankAddrLengthSDRAM = 2,
    parameter RowAddrLengthSDRAM = 13,
    parameter ColAddrLengthSDRAM = 9,
    parameter AddressWidthSDRAM = BankAddrLengthSDRAM + RowAddrLengthSDRAM + ColAddrLengthSDRAM
)(
    input wire CLK, RST,
    input wire p_clk,
    inout [WordLengthSDRAM-1:0] io_data,
    input wire h_sync, v_sync,
    input [7:0] i_data,
    output wire x_clk,                   // For OV7670
    output wire o_sio_c, o_sio_d,        // SCCB wires
    output wire o_clk_en,                // SDRAM Clock Enable
    output wire o_cs_n,                  // Select SDRAM signal
    output wire o_ras_n,                 // Select a row #o_addr
    output wire o_cas_n,                 // Select a column #o_addr
    output wire o_we_n,                  // On 1, write selected data, on 0 - read it
    output wire [12:0] o_addr,           // SDRAM's address bus
    output wire [1:0] o_bank,            // SDRAM's bank selector
    output wire [1:0] o_dqm,
    output wire o_data
);

    localparam BurstLengthSDRAM = 8;
    localparam MaxBurstsWritten = (1<<AddressWidthSDRAM)/BurstLengthSDRAM;
    
    localparam ClockFrequencySCCB = 400_000; 
    
    wire [PixelBitWidth - 1:0] PixelFromVGA;
    wire [PixelBitWidth - 1:0] PixelFromSDRAM;
    reg [AddressWidthSDRAM-1:0] AddressToSDRAM;
    reg [WordLengthSDRAM-1:0] InputDataToSDRAM;
    
    wire Switch_PixelFromVGAReady;

    wire [7:0] CompressedFrame;
    wire Switch_SendFrameUART;    
    
    reg Switch_EnableReadFromFIFO;
    wire Switch_FIFOFull;
    wire Switch_FIFOEmpty;
    wire [PixelBitWidth-1:0] PixelFromFIFO;
    
    wire Switch_ValidWriteToSDRAM;
    wire Switch_ValidReadFromSDRAM;
    wire Switch_BusySDRAM;
    
    assign io_data = (Switch_EnableSDRAM) ? InputDataToSDRAM : {WordLengthSDRAM{1'bz}};

    integer i;
    
    reg [PixelBitWidth-1:0] PixelsForSDRAM [BurstLengthSDRAM-1:0];
    reg [$clog2(BurstLengthSDRAM)-1:0] Counter_PixelsForSDRAM;
    reg [$clog2(MaxBurstsWritten)-1:0] CurrBurstsWritten;
    reg Switch_BurstOngoing;
    reg [$clog2(BurstLengthSDRAM)-1:0] Counter_CurrBurstWord;
    
    // Need to implement a read into a burst I will write to an SDRAM
    always @(posedge CLK) begin
        if (!RST) begin
            Counter_CurrBurstWord <= 0;
            Counter_PixelsForSDRAM <= 0;
            CurrBurstsWritten <= 0;
            Switch_BurstOngoing <= 1'b0;
            Switch_EnableReadFromFIFO <= 1'b0;
            InputDataToSDRAM <= 0;
            for (i = 0; i < BurstLengthSDRAM; i = i + 1) begin
                PixelsForSDRAM[i] <= {PixelBitWidth{1'b0}};
            end
        end else begin
            Switch_EnableReadFromFIFO <= 1'b1; // to stop the messages
        end
    end
    
    VGA #(PixelBitWidth) vga(
        .p_clk(p_clk),
        .RST(RST),
        .h_sync(h_sync),
        .o_sio_c(o_sio_c),
        .o_sio_d(o_sio_d),
        .i_data(i_data),
        .o_data(PixelFromVGA),
        .o_ready(Switch_PixelFromVGAReady)
    );
    
    fifo_generator_0 PCLK_CLK_FIFO (
        .wr_clk(p_clk),
        .rd_clk(CLK),
        .wr_en(Switch_PixelFromVGAReady),
        .din(PixelFromVGA),
        .rd_en(Switch_EnableReadFromFIFO),
        .dout(PixelFromFIFO),
        .full(Switch_FIFOFull),
        .empty(Switch_FIFOEmpty)
    );
    
    SDRAM #(ClockFrequency, 
            WordLengthSDRAM,
            BankAddrLengthSDRAM,
            RowAddrLengthSDRAM,
            ColAddrLengthSDRAM,
            AddressWidthSDRAM,
            BurstLengthSDRAM) sdram (
        .CLK(CLK),
        .RST(RST),
        .i_enable(Switch_EnableSDRAM),
        .i_rw(Switch_EnableReadSDRAM),
        .i_addr(AddressToSDRAM),
        .i_data(InputDataToSDRAM),
        .io_data(io_data),
        .o_clk_en(o_clk_en),
        .o_cs_n(o_cs_n),
        .o_ras_n(o_ras_n),
        .o_cas_n(o_cas_n),
        .o_we_n(o_we_n),
        .o_addr(o_addr),
        .o_bank(o_bank),
        .o_dqm(o_dqm),
        .o_data(PixelFromSDRAM),
        .o_valid_wr(Switch_ValidWriteToSDRAM),
        .o_valid_rd(Switch_ValidReadFromSDRAM),
        .o_busy(Switch_BusySDRAM)
    );
    
    Compressor #(FrameWidth, PixelBitWidth) compressor (
        .CLK(CLK),
        .RST(RST),
        .i_pixel(PixelFromSDRAM),
        .i_ready(Switch_PixelForCompressorReady),
        .o_frame(CompressedFrame),
        .o_ready(Switch_SendFrameUART)
    );
    
    UART #(ClockFrequency, BaudRateUART) uart(
        .CLK(CLK),
        .RST(RST),
        .i_send(Switch_SendFrameUART),
        .i_frame(CompressedFrame),
        .o_data(o_data)
    );
    
endmodule

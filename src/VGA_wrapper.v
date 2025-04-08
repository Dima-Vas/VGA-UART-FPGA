`timescale 1ns / 1ps

module VGA_wrapper #(
    parameter ClockFrequency = 50_000_000,
    parameter ClockFrequencyXCLK = 12_500_000,
    parameter ClockFrequencyPCLK = 6_144_000,
    parameter ClockFrequencySCCB = 200_000,
    parameter FrameWidth = 640,
    parameter FrameHeight = 480,
    parameter ActiveFrameWidth = 512,
    parameter ActiveFrameHeight = 384,
    parameter PixelBitWidth = 16,
    parameter BaudRateUART = 115200,
    parameter BufferSizeUART = 256,
    parameter WordLengthSDRAM = 16,
    parameter BurstLengthSDRAM = 8,
    parameter BankAddrLengthSDRAM = 2,
    parameter RowAddrLengthSDRAM = 13,
    parameter ColAddrLengthSDRAM = 9,
    parameter AddressWidthSDRAM = BankAddrLengthSDRAM + RowAddrLengthSDRAM + ColAddrLengthSDRAM
)(
    input wire CLK, RST,
    input wire p_clk,
    input wire h_sync, v_sync,
    input [7:0] i_data,
    inout [WordLengthSDRAM-1:0] io_data,
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

    localparam COLLECT_CURR_ROW = 2'b00, COLLECT_LAST_ROW = 2'b01, IDLE = 2'b10;
    reg [1:0] CurrentState;
    
    wire [PixelBitWidth - 1:0] PixelFromVGA;
    wire [PixelBitWidth - 1:0] PixelFromSDRAM;
    wire [WordLengthSDRAM-1:0] InputDataToSDRAM;
    wire [AddressWidthSDRAM-1:0] AddressToSDRAM;
    
    wire Switch_PixelFromVGAReady;

    wire [7:0] CompressedFrame;
    wire Switch_SendFrameUART;  
    wire Switch_CanSendFrameUART;  
    
    reg Switch_EnableReadFromFIFO;
    wire Switch_FullFIFO;
    wire Switch_EmptyFIFO;
    wire [PixelBitWidth-1:0] PixelFromFIFO;
    
    wire Switch_ValidWriteToSDRAM;
    wire Switch_ValidReadFromSDRAM;
    wire Switch_BusySDRAM;
    
    wire Switch_EnableSDRAM;
    wire Switch_EnableReadSDRAM;
    
    wire [WordLengthSDRAM-1:0] i_sdram_data;
    wire [WordLengthSDRAM-1:0] o_sdram_data;
    
    wire [7:0] FrameForUART;
    wire Switch_ReadFrameForUART;
    wire Switch_FrameEmptyUART;
    wire Switch_FrameFullUART;
    
    genvar i;
    generate
      for (i = 0; i < WordLengthSDRAM; i = i + 1) begin
        IOBUF iobuf_inst (
          .IO(io_data[i]),
          .I(i_sdram_data[i]),
          .O(o_sdram_data[i]),
          .T(Switch_EnableReadSDRAM)
        );
      end
    endgenerate
    
    wire Switch_FacadeReadBusy;
    wire Switch_FacadeWriteBusy;
    
    reg [PixelBitWidth-1:0] FacadeInput;
    reg Switch_FacadeWriteRequested;
    wire [PixelBitWidth-1:0] FacadeOutput;
    wire Switch_FacadeOutputReady;
    reg Switch_FacadeReadRequested;
    
    wire [PixelBitWidth-1:0] CompressorCurrInput;
    wire [PixelBitWidth-1:0] CompressorLastInput;
    
    wire Switch_CompressorCurrRowFull;
    wire Switch_CompressorLastRowFull;
    wire Switch_CompressorCurrEmptyFIFO;
    wire Switch_CompressorLastEmptyFIFO;
    wire Switch_CompressorReady;
    reg Switch_FirstFrame;
    
    reg [$clog2(FrameWidth)-1:0] j;
    
    reg [$clog2(FrameHeight)-1:0] CurrY, MinY = FrameHeight - ActiveFrameHeight, MaxY = ActiveFrameHeight;
    reg [$clog2(FrameWidth)-1:0] CurrX, MinX = FrameWidth - ActiveFrameWidth, MaxX = ActiveFrameWidth;
    wire Switch_ActiveRow = (CurrY < MaxY) && (CurrY > MinY) && (CurrX < MaxX) && (CurrX > MinX);
    
        
    // TODO : add a switch to track the drop of a frame in case SDRAM is "full"
    always @(posedge CLK) begin
        if (!RST) begin
            Switch_EnableReadFromFIFO <= 1'b0;
            Switch_FacadeReadRequested <= 1'b0;
            CurrentState <= COLLECT_CURR_ROW;
            Switch_FirstFrame <= 1'b1;
            CurrY <= 0;
        end else begin
            Switch_EnableReadFromFIFO <= 1'b0;
            Switch_FacadeWriteRequested <= 1'b0;
            Switch_FacadeReadRequested <= 1'b0;
            
            if (v_sync) begin
                CurrY <= 0;
            end else if (CurrX == FrameWidth) begin
                CurrY <= CurrY + 1;
                CurrX <= 0;
            end else if (Switch_PixelFromVGAReady) begin
                CurrX <= CurrX + 1;
            end
            case (CurrentState)
                COLLECT_CURR_ROW : begin
                    if (Switch_CompressorCurrRowFull) begin
                        CurrentState <= COLLECT_LAST_ROW;
                    end else if (!Switch_FacadeWriteBusy && !Switch_EmptyFIFO) begin
                        Switch_EnableReadFromFIFO <= 1'b1; 
                        FacadeInput <= PixelFromFIFO; // this FIFO is FWFT
                        Switch_FacadeWriteRequested <= 1'b1;
                    end
                end
                COLLECT_LAST_ROW : begin
                    if (Switch_CompressorLastRowFull || Switch_FirstFrame) begin
                        CurrentState <= IDLE;
                    end else if (!Switch_FacadeReadBusy) begin
                        Switch_FacadeReadRequested <= 1'b1;
                    end
                end
                IDLE : begin // while compressor is transferring data to UART
                    Switch_FirstFrame <= 1'b0;
                    if (Switch_CompressorReady) begin
                        CurrentState <= COLLECT_CURR_ROW;
                    end
                end
            endcase        
        end
    end
    
    clk_wiz_0 WIZ_XCLK (
        .i_clk(CLK),
        .o_clk(x_clk)
    );
        
    VGA #(ClockFrequency,
          ClockFrequencyPCLK,
          ClockFrequencySCCB,
          PixelBitWidth,
          FrameWidth,
          FrameHeight,
          ActiveFrameWidth,
          ActiveFrameHeight) vga(
        .CLK(CLK),
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
        .wr_en(Switch_PixelFromVGAReady && Switch_ActiveRow),
        .din(PixelFromVGA),
        .rd_en(Switch_EnableReadFromFIFO),
        .dout(PixelFromFIFO),
        .full(Switch_FullFIFO),
        .empty(Switch_EmptyFIFO)
    );
    
    FacadeSDRAM #(FrameWidth,
                  FrameHeight,
                  BurstLengthSDRAM,
                  PixelBitWidth,
                  AddressWidthSDRAM) facade (
        .CLK(CLK),
        .RST(RST),
        .i_write_req(Switch_FacadeWriteRequested),
        .i_pixel(FacadeInput),
        .i_read_req(Switch_FacadeReadRequested),
        .i_sdram_busy(Switch_BusySDRAM),
        .i_sdram_valid_wr(Switch_ValidWriteToSDRAM),
        .i_sdram_valid_rd(Switch_ValidReadFromSDRAM),
        .i_sdram_pixel(PixelFromSDRAM),
        .o_sdram_enable(Switch_EnableSDRAM),
        .o_sdram_read(Switch_EnableReadSDRAM),
        .o_sdram_pixel(InputDataToSDRAM),
        .o_sdram_addr(AddressToSDRAM),
        .o_pixel(FacadeOutput),
        .o_ready(Switch_FacadeOutputReady),
        .o_busy_rd(Switch_FacadeReadBusy),
        .o_busy_wr(Switch_FacadeWriteBusy)
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
        .o_data(PixelFromSDRAM),
        .o_valid_wr(Switch_ValidWriteToSDRAM),
        .o_valid_rd(Switch_ValidReadFromSDRAM),
        .o_busy(Switch_BusySDRAM)
    );
    
    fifo_generator_1 SDRAM_COMPRESSOR_CURR_FIFO (
        .clk(CLK),
        .srst(RST),
        .wr_en(Switch_EnableReadFromFIFO),
        .din(PixelFromFIFO),
        .rd_en(Switch_CompressorCurrInput),
        .dout(CompressorCurrInput),
        .empty(Switch_CompressorCurrEmptyFIFO),
        .full()
    );
    
    fifo_generator_1 SDRAM_COMPRESSOR_LAST_FIFO (
        .clk(CLK),
        .srst(RST),
        .wr_en(Switch_FacadeOutputReady),
        .din(FacadeOutput),
        .rd_en(Switch_CompressorLastInput),
        .dout(CompressorLastInput),
        .empty(Switch_CompressorLastEmptyFIFO),
        .full()
    );
    
    Compressor #(FrameWidth, PixelBitWidth) compressor (
        .CLK(CLK),
        .RST(RST),
        .i_pixel_curr(CompressorCurrInput),
        .i_pixel_last(CompressorLastInput),
        .i_curr_empty(Switch_CompressorCurrEmptyFIFO),
        .i_uart_allowed(Switch_FrameFullUART),
        .i_last_empty(Switch_CompressorLastEmptyFIFO),
        .o_fetch_curr(Switch_CompressorCurrInput),
        .o_fetch_last(Switch_CompressorLastInput),
        .o_curr_row_full(Switch_CompressorCurrRowFull),
        .o_last_row_full(Switch_CompressorLastRowFull),
        .o_ready_for_next(Switch_CompressorReady),
        .o_frame(CompressedFrame),
        .o_uart_ready(Switch_SendFrameUART)
    );
    
    fifo_generator_2 COMPRESSOR_UART_FIFO (
        .clk(CLK),
        .srst(RST),
        .wr_en(Switch_SendFrameUART),
        .din(CompressedFrame),
        .rd_en(Switch_CanSendFrameUART),
        .dout(FrameForUART),
        .empty(Switch_FrameEmptyUART),
        .full(Switch_FrameFullUART)
    );
    
    UART #(ClockFrequency, BaudRateUART, BufferSizeUART) uart(
        .CLK(CLK),
        .RST(RST),
        .i_ready(~Switch_FrameEmptyUART),
        .i_frame(FrameForUART),
        .o_data(o_data),
        .o_ready(Switch_CanSendFrameUART)
    );
    
endmodule

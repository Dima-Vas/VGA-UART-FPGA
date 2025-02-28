`timescale 1ns / 1ps

module VGA_wrapper #(
    parameter FrameWidth = 640,
    parameter FrameHeight = 480,
    parameter PixelBitWidth = 16,
    parameter UARTBaudRate = 115200
)(
    input wire CLK, RST,
    input wire h_sync, v_sync, p_clk,
    input [7:0] i_data,
    output wire o_data
);

    wire [PixelBitWidth - 1:0] CurrPixelVGA;
    wire [PixelBitWidth - 1:0] CurrPixelCompressor;
    wire Switch_PixelReady;
    wire Switch_PixelForCompressionReady;
    wire Switch_SendFrameUART;
    wire Switch_FIFOFull;
    wire Switch_FIFOEmpty;
    wire [7:0] CompressedFrame;
    
    
    VGA #(PixelBitWidth) vga(
        .p_clk(p_clk),
        .RST(RST),
        .h_sync(h_sync),
        .i_data(i_data),
        .o_data(CurrPixelVGA),
        .o_ready(Switch_PixelReady)
    );
    
    UART #(50_000_000 / UARTBaudRate) uart(
        .CLK(CLK),
        .RST(RST),
        .i_send(Switch_SendFrameUART),
        .i_frame(CompressedFrame),
        .o_data(o_data)
    );
    
    Compressor #(FrameWidth, PixelBitWidth)(
        .CLK(CLK),
        .RST(RST),
        .i_pixel(CurrPixelCompressor),
        .i_ready(Switch_PixelForCompressionReady),
        .o_frame(CompressedFrame),
        .o_ready(Switch_SendFrameUART)
    );
    
    fifo_generator_0 PCLK_CLK_FIFO (
        .wr_clk(p_clk),
        .rd_clk(CLK),
        .wr_en(Switch_PixelReady),
        .rd_en(Switch_PixelForCompressionReady),
        .din(CurrPixelVGA),
        .dout(CurrPixelCompressor),
        .full(Switch_FIFOFull),
        .empty(Switch_FIFOEmpty)
    );
    
//    always @(posedge CLK or negedge RST) begin
//        if (!RST) begin
            
//        end else begin
            
//        end
//    end
    
endmodule

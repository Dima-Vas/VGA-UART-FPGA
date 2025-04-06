`timescale 1ns / 1ps

// ----------
// Data compressor for real-time UART video transferring. Input is a pixel, which, accumulated
// with other pixels, represents a frame row that is being compressed afterwards using RLE.
// ----------

module Compressor #(
    parameter RowPixelWidth = 640,
    parameter PixelSize = 16 // for YUV422
)(
    input wire CLK, RST,
    input [PixelSize-1:0] i_pixel_curr,
    input [PixelSize-1:0] i_pixel_last,
    input wire i_curr_empty,
    input wire i_last_empty,
    input wire i_uart_allowed,
    output reg o_fetch_curr,
    output reg o_fetch_last,
    output reg o_curr_row_full,
    output reg o_last_row_full,
    output reg [7:0] o_frame,
    output reg o_ready,
    output reg o_uart_ready
);
    

    always @(posedge CLK) begin
        if (!RST) begin
            o_frame <= 0;
        end else begin
            
        end
    end
endmodule

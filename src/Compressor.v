`timescale 1ns / 1ps

// ----------
// Data compressor for real-time UART video transferring. Input is a pixel, which, accumulated
// with other pixels, represents a frame row that is being compressed afterwards using RLE.
// ----------
module Compressor #(
    parameter RowPixelWidth = 640,
    parameter PixelBitWidth = 16
)(
    input wire CLK, RST,
    input [15:0] i_pixel,
    input wire i_ready, // input is ready to be read
    output [7:0] o_frame,
    output reg o_ready
);
    reg [PixelBitWidth-1:0] FrameRow [RowPixelWidth-1:0];
    reg Switch_FrameRowFull;
    reg [$clog2(RowPixelWidth):0] Counter_CurrCol;

    reg [$clog2(RowPixelWidth):0] Counter_AccumRLE;

    integer i;
    
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            Counter_CurrRow <= 0;
            for (i = 0; i < RowPixelWidth-1; i=i+1) begin
                FrameRow[i] <= 0;
            end
        end else begin
            if (Counter_CurrCol > RowPixelWidth) begin
                Switch_FrameRowFull <= 1'b1;
            end
        end
    end
    
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            Counter_AccumRLE <= 0;
        end else begin
            
        end
    end
endmodule

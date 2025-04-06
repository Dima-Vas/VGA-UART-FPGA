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
    output wire o_curr_row_full,
    output wire o_last_row_full,
    output reg [7:0] o_frame,
    output reg o_ready_for_next,
    output reg o_uart_ready
);

    (* ram_style = "block" *) reg [7:0] CurrY [0:RowPixelWidth-1];
    (* ram_style = "block" *) reg [7:0] CurrU [0:(RowPixelWidth/2)-1];
    (* ram_style = "block" *) reg [7:0] CurrV [0:(RowPixelWidth/2)-1];
    
    (* ram_style = "block" *) reg [7:0] LastY [0:RowPixelWidth-1];
    (* ram_style = "block" *) reg [7:0] LastU [0:(RowPixelWidth/2)-1];
    (* ram_style = "block" *) reg [7:0] LastV [0:(RowPixelWidth/2)-1];
    
    reg [$clog2(RowPixelWidth)-1:0] Counter_CurrPixel;
    reg [$clog2(RowPixelWidth)-1:0] Counter_LastPixel;
    
    assign o_curr_row_full = (Counter_CurrPixel == RowPixelWidth) ? 1'b1 : 1'b0;
    assign o_last_row_full = (Counter_LastPixel == RowPixelWidth) ? 1'b1 : 1'b0;
    
    reg Switch_IsCurrU;
    reg Switch_IsLastU;

    always @(posedge CLK) begin
        if (!RST) begin
            o_frame <= 0;
            o_fetch_curr <= 1'b0;
            o_fetch_last <= 1'b0;
            o_ready_for_next <= 1'b0;
            o_uart_ready <= 1'b0;
            Switch_IsCurrU <= 1'b1;
            Switch_IsLastU <= 1'b1;
            Counter_CurrPixel <= 0;
            Counter_LastPixel <= 0;
        end else begin
            if (!i_curr_empty) begin
                o_fetch_curr <= 1'b1;
                CurrY[Counter_CurrPixel] <= i_pixel_curr[15:8]; // FWFT
                if (Switch_IsCurrU) begin
                    CurrU[Counter_CurrPixel / 2] <= i_pixel_curr[7:0];
                end else begin
                    CurrV[Counter_CurrPixel / 2 - 1] <= i_pixel_curr[7:0];
                end
                Switch_IsCurrU <= ~Switch_IsCurrU;
                Counter_CurrPixel <= Counter_CurrPixel + 1;
            end
            
            if (!i_last_empty) begin
                o_fetch_last <= 1'b1;
                LastY[Counter_LastPixel] <= i_pixel_last[15:8]; // FWFT
                if (Switch_IsLastU) begin
                    LastU[Counter_LastPixel / 2] <= i_pixel_last[7:0];
                end else begin
                    LastV[Counter_LastPixel / 2 - 1] <= i_pixel_last[7:0];
                end
                Switch_IsLastU <= ~Switch_IsLastU;
                Counter_LastPixel <= Counter_LastPixel + 1;
            end
        end
    end
endmodule

`timescale 1ns / 1ps

// ----------
// Data compressor for real-time UART video transferring. Input is a pixel, which, accumulated
// with other pixels, represents a frame row that is being compressed afterwards using RLE.
// ----------

// * TODO : CREATE AN ENCODING-AGNOSTIC MODULE THAT WILL TAKE THE PROVIDED NUMBER OF DIFFERENT
// * TYPED CHANNELS AND COMPRESS THEM 
module Compressor #(
    parameter RowPixelWidth = 640,
    parameter PixelSize = 16 // for YUV422
)(
    input wire CLK, RST,
    input [PixelSize-1:0] i_pixel,
    input wire i_ready, // a pixel is ready to be read from the FIFO
    output reg [7:0] o_frame,
    output reg o_ready
);

    reg [7:0] CurrYVal;
    reg [7:0] CurrUVal;
    reg [7:0] CurrVVal;
    
    reg [$clog2(RowPixelWidth):0] Counter_CurrYVal;
    reg [$clog2(RowPixelWidth/2):0] Counter_CurrUVal;
    reg [$clog2(RowPixelWidth/2):0] Counter_CurrVVal;
    
    reg Switch_ReadingU; // if 1, reading U in the Y+U/V pair
    
//    RLE #(2) rle_y(
//        .CLK(CLK),
//        .RST(RST),
//        .i_ready((Counter_CurrYVal > 0)),
//        .i_val(CurrYVal),
//        .o_val(),
//        .o_count(),
//        .o_ready()
//    );
    
//    RLE #(2) rle_u(
//        .CLK(CLK),
//        .RST(RST),
//        .i_ready((Counter_CurrUVal > 0)),
//        .i_val(CurrUVal),
//        .o_val(),
//        .o_count(),
//        .o_ready()
//    );
    
//    RLE #(2) rle_v(
//        .CLK(CLK),
//        .RST(RST),
//        .i_ready((Counter_CurrVVal > 0)),
//        .i_val(CurrVVal),
//        .o_val(),
//        .o_count(),
//        .o_ready()
//    );

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            o_frame <= 0;
            o_ready <= 1'b0;
            CurrYVal <= 0;
            CurrUVal <= 0;
            CurrVVal <= 0;
            Counter_CurrYVal <= 0;   
            Counter_CurrUVal <= 0;
            Counter_CurrVVal <= 0;
            Switch_ReadingU <= 1'b1; // U comes first
        end else begin
            if (i_ready) begin // TODO : the pixel WILL BE HERE NEXT TICK - MAYBE WILL HAVE TO HAVE A SWITCH FOR THE NEXT TICK
                CurrYVal <= i_pixel[15:8];
                if (Switch_ReadingU) begin
                    CurrUVal <= i_pixel[7:0];
                    Counter_CurrUVal <= Counter_CurrUVal + 1;
                end else begin
                    CurrVVal <= i_pixel[7:0];
                    Counter_CurrVVal <= Counter_CurrVVal + 1;
                end
                Switch_ReadingU <= ~Switch_ReadingU;
                Counter_CurrYVal <= Counter_CurrYVal + 1;
            end
        end
    end
endmodule

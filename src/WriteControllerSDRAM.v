`timescale 1ns / 1ps

module WriteControllerSDRAM #(
    parameter FrameWidth = 640,
    parameter FrameHeight = 480,
    parameter BurstLengthSDRAM = 8,
    parameter PixelBitWidth = 16,
    parameter AddressWidthSDRAM = 24
)(
    input wire CLK, RST,
    input wire i_write_req,
    input wire i_sdram_valid_wr,
    input [PixelBitWidth-1:0] i_pixel,

    output reg [PixelBitWidth-1:0] o_sdram_pixel,
    output reg [AddressWidthSDRAM-1:0] o_sdram_addr,
    
    output reg o_bursting,
    output reg o_busy_wr
);

    localparam  IDLE        = 2'b00,
                BURST_START = 2'b01,
                BURST_WRITE = 2'b10,
                BURST_DONE  = 2'b11;
            
    reg [1:0] CurrentState;

    localparam BoundarySDRAM = FrameWidth * FrameHeight * 2;
    reg [$clog2(BoundarySDRAM)-1:0] HeadAddressSDRAM;
    reg [$clog2(BurstLengthSDRAM)-1:0] Counter_PixelsForSDRAM;
    reg [$clog2(BurstLengthSDRAM)-1:0] Counter_CurrBurstItem;

    reg [PixelBitWidth-1:0] PixelsForSDRAM [BurstLengthSDRAM-1:0];
    reg [$clog2(BurstLengthSDRAM):0] i;

    always @(posedge CLK) begin
        if (!RST) begin
            Counter_PixelsForSDRAM <= 0;
            Counter_CurrBurstItem <= 0;
            HeadAddressSDRAM <= 0;
            CurrentState <= IDLE;
            o_sdram_pixel <= 0;
            o_busy_wr <= 1'b0;
            for (i = 0; i < BurstLengthSDRAM; i = i + 1) begin
                PixelsForSDRAM[i] <= 0;
            end
        end else begin
            case (CurrentState)
                IDLE : begin
                    if (i_write_req) begin
                        PixelsForSDRAM[Counter_PixelsForSDRAM] <= i_pixel;
                        Counter_PixelsForSDRAM <= Counter_PixelsForSDRAM + 1;
                        if (Counter_PixelsForSDRAM + 1 == BurstLengthSDRAM) begin
                            CurrentState <= BURST_START;
                            o_busy_wr <= 1'b1;
                        end
                    end
                end
                BURST_START : begin
                    o_sdram_pixel <= PixelsForSDRAM[0];
                    o_sdram_addr <= HeadAddressSDRAM;
                    Counter_CurrBurstItem <= 1;
                    HeadAddressSDRAM <= HeadAddressSDRAM + BurstLengthSDRAM;
                    CurrentState <= BURST_WRITE;
                end
                BURST_WRITE : begin
                    if (i_sdram_valid_wr) begin
                        o_bursting <= 1'b1;
                        o_sdram_pixel <= PixelsForSDRAM[Counter_CurrBurstItem];
                        Counter_CurrBurstItem <= Counter_CurrBurstItem + 1;
                        CurrentState <= (Counter_CurrBurstItem + 1 == BurstLengthSDRAM) ? BURST_DONE : BURST_WRITE;
                    end
                end
                BURST_DONE : begin
                    o_bursting <= 1'b0;
                    Counter_PixelsForSDRAM <= 0;
                    Counter_CurrBurstItem <= 0;
                    CurrentState <= IDLE;
                    o_busy_wr <= 1'b0;
                    if (HeadAddressSDRAM == BoundarySDRAM) begin
                        HeadAddressSDRAM <= 0;
                    end
                end
            endcase
        end
    end
endmodule
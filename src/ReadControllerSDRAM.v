`timescale 1ns / 1ps


module ReadControllerSDRAM #(
    parameter FrameWidth = 640,
    parameter FrameHeight = 480,
    parameter BurstLengthSDRAM = 8,
    parameter PixelBitWidth = 16,
    parameter AddressWidthSDRAM = 24
)(
    input wire CLK, RST,
    input wire i_read_req,
    input wire i_sdram_valid_rd,
    input [PixelBitWidth-1:0] i_sdram_pixel,

    output reg [AddressWidthSDRAM-1:0] o_sdram_addr,
    output reg [PixelBitWidth-1:0] o_pixel,
    output reg o_ready,
    
    output reg o_busy_rd
);

    localparam BoundarySDRAM = FrameWidth * FrameHeight * 2;
    reg [$clog2(BoundarySDRAM)-1:0] TailAddressSDRAM;
    reg [$clog2(BurstLengthSDRAM)-1:0] Counter_CurrBurstItem;

    localparam  IDLE        = 2'b00,
                BURST_READ  = 2'b01,
                BURST_DONE  = 2'b10;
    
    reg [1:0] CurrentState;

    always @(posedge CLK) begin
        if (!RST) begin
            CurrentState <= IDLE;
            Counter_CurrBurstItem <= 0;
            TailAddressSDRAM <= 0;
            o_ready <= 1'b0;
            o_pixel <= 0;
        end else begin
            case (CurrentState)
                IDLE: begin
                    o_ready <= 1'b0;
                    if (i_read_req) begin
                        o_sdram_addr <= TailAddressSDRAM;
                        TailAddressSDRAM <= TailAddressSDRAM + BurstLengthSDRAM;
                        CurrentState <= BURST_READ;
                    end
                end
                BURST_READ: begin
                    if (i_sdram_valid_rd) begin
                        o_pixel <= i_sdram_pixel;
                        o_ready <= 1'b1;
                        Counter_CurrBurstItem <= Counter_CurrBurstItem + 1;
                        CurrentState <= (Counter_CurrBurstItem + 1 == BurstLengthSDRAM) ? BURST_DONE : BURST_READ;
                    end else begin
                        o_ready <= 1'b0;
                    end
                end
                BURST_DONE: begin
                    o_ready <= 1'b0;
                    Counter_CurrBurstItem <= 0;
                    CurrentState <= IDLE;
                    if (TailAddressSDRAM == BoundarySDRAM) begin
                        TailAddressSDRAM <= 0;
                    end
                end
            endcase
        end
    end
    
    always @(posedge CLK) begin
        if (!RST) begin
            o_busy_rd <= 1'b0;
        end else begin
            o_busy_rd <= (CurrentState != IDLE) ? 1'b1 : 1'b0;
        end
    end
endmodule

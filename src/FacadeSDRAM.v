`timescale 1ns / 1ps

module FacadeSDRAM #(
    parameter FrameWidth = 640,
    parameter FrameHeight = 480,
    parameter BurstLengthSDRAM = 8,
    parameter PixelBitWidth = 16,
    parameter AddressWidthSDRAM = 24
)(
    input wire CLK, RST,
    input wire i_write_req, // i_pixel is ready to be read
    input [PixelBitWidth-1:0] i_pixel, // pixels to write
    input wire i_read_req, // user requests a read
    
    input wire i_sdram_busy, // SDRAM is in state other than IDLE
    input wire i_sdram_valid_wr, // facade can set the data for WRITE to SDRAM
    input wire i_sdram_valid_rd, // facade can read the data from SDRAM's READ
    input [PixelBitWidth-1:0] i_sdram_pixel, // pixel read from SDRAM
    output wire o_sdram_enable, // passing the command to SDRAM
    output wire o_sdram_read, // r/w command for SDRAM
    output wire [PixelBitWidth-1:0] o_sdram_pixel, // pixel to write to SDRAM
    output wire [AddressWidthSDRAM-1:0] o_sdram_addr, // address for SDRAM
    
    output wire [PixelBitWidth-1:0] o_pixel, // pixel for user from SDRAM
    output wire o_ready, // user can latch the read pixel
    
    output wire o_busy_rd, // user cannot request read
    output wire o_busy_wr // user cannot request write
);

    localparam WRITE = 2'b00, READ =  2'b01, IDLE = 2'b10;
    
    wire [AddressWidthSDRAM-1:0] o_sdram_addr_rd;
    wire [AddressWidthSDRAM-1:0] o_sdram_addr_wr;
    
    wire WriteOngoing;
    wire ReadOngoing;

    wire o_bursting_wr;

    reg [1:0] CurrentOperation = IDLE;
    
    always @(posedge CLK) begin
        if (!RST) begin
            CurrentOperation <= IDLE;
        end else begin
            case (CurrentOperation)
                IDLE: begin
                    if (!i_sdram_busy) begin
                        if (i_write_req) begin
                            CurrentOperation <= WRITE;
                        end else if (i_read_req) begin
                            CurrentOperation <= READ;
                        end else begin
                            CurrentOperation <= IDLE;
                        end
                    end
                end
                WRITE: begin
                    if (!i_sdram_busy) begin
                        CurrentOperation <= IDLE;
                    end
                end
                READ: begin
                    if (!i_sdram_busy) begin
                        CurrentOperation <= IDLE;
                    end
                end
            endcase
        end
    end
    
    assign o_sdram_addr = (CurrentOperation == READ) ? o_sdram_addr_rd : o_sdram_addr_wr;

    assign o_sdram_read = (CurrentOperation == READ) ? 1'b1 : 1'b0;
    
    assign o_sdram_enable = (CurrentOperation == READ || (CurrentOperation == WRITE && o_bursting_wr)) ? 1'b1 : 1'b0; 
        
    assign o_busy_wr = (~i_sdram_busy && ~WriteOngoing);
    assign o_busy_rd = (~i_sdram_busy && ~ReadOngoing);
        
    ReadControllerSDRAM #(
        FrameWidth,
        FrameHeight,
        BurstLengthSDRAM,
        PixelBitWidth,
        AddressWidthSDRAM
    ) read (
        .CLK(CLK),
        .RST(RST),
        .i_read_req(i_read_req),
        .i_sdram_valid_rd(i_sdram_valid_rd && CurrentOperation == READ),
        .i_sdram_pixel(i_sdram_pixel),
        .o_sdram_addr(o_sdram_addr_rd),
        .o_pixel(o_pixel),
        .o_ready(o_ready),
        .o_busy_rd(ReadOngoing)
    );
    
    WriteControllerSDRAM #(
        FrameWidth,
        FrameHeight,
        BurstLengthSDRAM,
        PixelBitWidth,
        AddressWidthSDRAM
    ) write (
        .CLK(CLK),
        .RST(RST),
        .i_write_req(i_write_req),
        .i_sdram_valid_wr(i_sdram_valid_wr && CurrentOperation == WRITE),
        .i_pixel(i_pixel),
        .o_sdram_pixel(o_sdram_pixel),
        .o_sdram_addr(o_sdram_addr_wr),
        .o_busy_wr(WriteOngoing),
        .o_bursting(o_bursting_wr)
    );
    
endmodule

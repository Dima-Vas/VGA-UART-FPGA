`timescale 1ns / 1ps


// ----------
// A simple value-counting module that outputs the VALUE-AMOUNT pair with a limit of
// 8 bits for the AMOUNT. 
// ----------
module RLE #(
    parameter ChannelLength = 640,
    parameter TolerDiff = 2,
    parameter TolerRLE = 5,
    parameter MaxRunLength = 12
)(
    input wire CLK, RST,
    input wire i_ready,
    input [7:0] i_curr_val, // value from current frame
    input [7:0] i_prev_val, // value from the previous frame 
    output reg [7:0] o_val, // the value for the next o_count values
    output reg [MaxRunLength-1:0] o_count, // the number of o_val values
    output reg [$clog2(ChannelLength)-1:0] o_start_x, // starting x value of the change
    output reg o_ready, // output can be read
    output wire o_busy // user cannot send the next value pair
);

    localparam  IDLE        = 3'b000, // waiting for input
                SEND_INFO   = 3'b001, // sending the val, amount and CurrX
                RESET       = 3'b010, // setting the registers to 0, preparing for the next run
                CHECK_DIFF  = 3'b011, // checking if the last-curr difference is significant enough
                CHECK_RLE   = 3'b100; // the last-curr pair is different, so we check the tolerance
    
    localparam MaxRunElements = 2**MaxRunLength;
    
    reg [3:0] CurrentState;
    
    reg [$clog2(ChannelLength)-1:0] CurrX;
    
    reg [7:0] CurrVal;
    reg [MaxRunLength-1:0] CurrCount;
    reg [$clog2(ChannelLength)-1:0] CurrStartX;
    
    wire [7:0] DiffDiff = (i_curr_val > i_prev_val) ? i_curr_val - i_prev_val : i_prev_val - i_curr_val;
    wire [7:0] DiffRLE = (i_curr_val > CurrVal) ? i_curr_val - CurrVal : CurrVal - i_curr_val;
    
    assign o_busy = (CurrentState != IDLE);
    
    always @(posedge CLK) begin
        if (!RST) begin
            o_val <= 0;
            o_count <= 0;
            o_start_x <= 0;
            o_ready <= 1'b0;
            CurrX <= 0;
            CurrStartX <= 0;
            CurrVal <= 0;
            CurrCount <= 1;
            CurrentState <= IDLE;
        end else begin
            case (CurrentState)
                IDLE : begin
                    if (i_ready) begin
                        if (CurrCount == 1) begin
                            CurrVal <= i_curr_val;
                            CurrStartX <= CurrX;
                        end
                        CurrentState <= CHECK_DIFF;
                        CurrX <= CurrX + 1;
                    end
                end
                CHECK_DIFF : begin
                    if (DiffDiff <= TolerDiff) begin
                        CurrentState <= (CurrCount > 1) ? SEND_INFO : IDLE;
                    end else begin
                        CurrentState <= CHECK_RLE;
                    end
                end
                CHECK_RLE : begin
                    if (DiffRLE <= TolerRLE && CurrCount < MaxRunElements) begin
                        CurrCount <= CurrCount + 1;
                        CurrentState <= IDLE;
                    end else begin
                        CurrentState <= SEND_INFO;
                    end
                end
                SEND_INFO : begin
                    o_val <= CurrVal;
                    o_count <= CurrCount;
                    o_start_x <= CurrStartX;
                    o_ready <=  1'b1;
                    CurrentState <= RESET;
                end
                RESET : begin
                    CurrCount <= 1;
                    CurrVal <= 0;
                    CurrStartX <= 0;
                    o_start_x <= 0;
                    o_val <= 0;
                    o_count <= 0;
                    o_ready <= 1'b0;
                    if (CurrX + CurrCount == ChannelLength) begin
                        CurrX <= 0;
                    end
                    CurrentState <= IDLE;
                end
            endcase
        end
    end
endmodule

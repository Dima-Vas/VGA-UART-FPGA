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
    output reg [$clog2(MaxRunLength)-1:0] o_count, // the number of o_val values
    output reg [$clog2(ChannelLength)-1:0] o_start_x, // starting x value of the change
    output reg o_ready, // output can be read
    output wire o_busy // user cannot send the next value pair
);

    localparam  IDLE        = 3'b000, // waiting for input
                SEND_INFO   = 3'b001, // sending the val, amount and CurrX
                RESET       = 3'b010, // setting the registers to 0, preparing for the next run
                CHECK_DIFF  = 3'b011, // checking if the last-curr difference is significant enough
                CHECK_RLE   = 3'b100; // the last-curr pair is different, so we check the tolerance
    
    reg [3:0] CurrentState;
    
    reg [$clog2(ChannelLength)-1:0] CurrX;
    
    // WE RECEIVE TWO VALUES - PREVIOUS FRAME'S and CURRENT FRAME'S CHANNEL VAL
    // IF THE TWO VALUES ARE EQUAL TO THE TOLLERACE EXTENT, WE SEND THE ALREADY RECORDED INFO OR IGNORE THEM IF NO INFO RECORDED
    // IF THEY ARE DIFFERENT, WE CHECK, HOW MUCH THE NEW VALUE DIFFERS FROM PREVIOUS NEW VALUE
    // -- IF MORE THAN Toler, WE SEND THE ALREADY RECORDED INFO AND WRITE THE NEW ONE
    // -- IF LESS THAN Toler, WE INCREMENT THE COUNT AND THE CurrX AND PROCEED TO THE NEXT VAL
    // REPEAT UNTIL CurrX != ChannelLength
    
    wire [7:0] DiffDiff = (i_curr_val > i_prev_val) ? i_curr_val - i_prev_val : i_prev_val - i_curr_val;
    wire [7:0] DiffRLE = (i_curr_val > o_val) ? i_curr_val - o_val : o_val - i_curr_val;
    
    assign o_busy = (CurrentState != IDLE);
    
    wire Switch_RowNotOver = CurrX < ChannelLength;
    
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            o_val <= 0;
            o_count <= 0;
            o_ready <= 1'b0;
            CurrX <= 0;
            CurrentState <= IDLE;
            o_start_x <= 0;
        end else if (Switch_RowNotOver) begin
            case (CurrentState)
                IDLE : begin
                    if (i_ready) begin
                        o_val <= i_curr_val;
                        o_count <= 1;
                        CurrentState <= CHECK_DIFF;
                        CurrX <= CurrX + 1;
                    end
                end
                CHECK_DIFF : begin
                    if (DiffDiff <= TolerDiff) begin
                        CurrentState <= (o_count > 0) ? SEND_INFO : IDLE;
                    end else begin
                        CurrentState <= CHECK_RLE;
                    end
                end
                CHECK_RLE : begin
                    if (DiffRLE <= TolerRLE) begin
                        o_count <= o_count + 1;
                        CurrentState <= (i_ready) ? CHECK_DIFF : IDLE;
                    end else begin
                        CurrentState <= SEND_INFO;
                    end
                end
                SEND_INFO : begin
                    o_ready <=  1'b1;
                    CurrentState <= RESET;
                end
                RESET : begin
                    o_count <= 0;
                    o_start_x <= 0;
                    o_ready <= 1'b0;
                    CurrentState <= (i_ready) ? CHECK_DIFF : IDLE;
                end
            endcase
        end else begin
            CurrX <= 0;
            CurrentState <= IDLE;
        end
    end
endmodule

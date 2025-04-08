`timescale 1ns / 1ps

// ----------
// Data compressor for real-time UART video transferring. Input is a pixel, which, accumulated
// with other pixels, represents a frame row that is being compressed afterwards using RLE.
// Structure for UART - 5 bytes per transaction :
// x[7:0] -> y[7:0] -> Y/U/V -> RLE_len[7:0] -> RLE_len[7:4]+Y/U/V_id[3:2]+y[1]+x[0]
// ----------

module Compressor #(
    parameter RowPixelWidth = 640,
    parameter PixelSize = 16, // for YUV422
    parameter RunLimit = 12
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

    localparam LOADING_CHANNELS = 2'b00, COMPRESS = 2'b01, IDLE = 2'b10;
    
    reg [1:0] CurrentState;
    
    localparam SENDING_LUMA = 1'b0, SENDING_CHROMA = 1'b1;
    
    reg CurrSendingState;

    (* ram_style = "block", rw_addr_collision = "yes" *) reg [7:0] CurrY [0:RowPixelWidth-1];
    (* ram_style = "block", rw_addr_collision = "yes" *) reg [7:0] CurrU [0:(RowPixelWidth/2)-1];
    (* ram_style = "block", rw_addr_collision = "yes" *) reg [7:0] CurrV [0:(RowPixelWidth/2)-1];
    
    (* ram_style = "block", rw_addr_collision = "yes" *) reg [7:0] LastY [0:RowPixelWidth-1];
    (* ram_style = "block", rw_addr_collision = "yes" *) reg [7:0] LastU [0:(RowPixelWidth/2)-1];
    (* ram_style = "block", rw_addr_collision = "yes" *) reg [7:0] LastV [0:(RowPixelWidth/2)-1];
    
    reg Switch_IsCurrU;
    reg Switch_IsLastU;
    
    reg [$clog2(RowPixelWidth)-1:0] Counter_CurrPixel;
    reg [$clog2(RowPixelWidth)-1:0] Counter_LastPixel;
    
    assign o_curr_row_full = (Counter_CurrPixel == RowPixelWidth) ? 1'b1 : 1'b0;
    assign o_last_row_full = (Counter_LastPixel == RowPixelWidth) ? 1'b1 : 1'b0;
    
    reg [$clog2(RowPixelWidth)-1:0] Counter_CurrElemY;
    reg [$clog2(RowPixelWidth/2)-1:0] Counter_CurrElemU;
    reg [$clog2(RowPixelWidth/2)-1:0] Counter_CurrElemV;
    
//    wire signed [8:0] DiffY = $signed(CurrY[Counter_CurrElemY]) - $signed(LastY[Counter_CurrElemY]);
//    wire signed [8:0] DiffU = $signed(CurrU[Counter_CurrElemU]) - $signed(LastU[Counter_CurrElemU]);
//    wire signed [8:0] DiffV = $signed(CurrV[Counter_CurrElemV]) - $signed(LastV[Counter_CurrElemV]);
    
    reg Switch_SendingU;
    
    always @(*) begin
        o_frame = 0;
        if (CurrentState == COMPRESS) begin
            case (CurrSendingState)
                SENDING_LUMA : begin
                    o_frame = CurrY[Counter_CurrElemY];
                end
                SENDING_CHROMA : begin
                    o_frame = (Switch_SendingU) ? CurrU[Counter_CurrElemU] : CurrV[Counter_CurrElemV];
                end
            endcase
        end
    end

    always @(posedge CLK) begin
        if (!RST) begin
            o_fetch_curr <= 1'b0;
            o_fetch_last <= 1'b0;
            o_ready_for_next <= 1'b0;
            o_uart_ready <= 1'b0;
            Switch_IsCurrU <= 1'b1;
            Switch_IsLastU <= 1'b1;
            Counter_CurrPixel <= 0;
            Counter_LastPixel <= 0;
            CurrentState <= LOADING_CHANNELS;
            CurrSendingState <= SENDING_LUMA;
            Switch_SendingU <= 1'b0;
        end else begin
            o_fetch_curr <= 1'b0;
            o_fetch_last <= 1'b0;
            case (CurrentState)
                LOADING_CHANNELS : begin
                    if (!i_curr_empty) begin
                        o_fetch_curr <= 1'b1;
                        CurrY[Counter_CurrPixel] <= i_pixel_curr[15:8]; // FWFT
                        if (Switch_IsCurrU) begin
                            CurrU[Counter_CurrPixel / 2] <= i_pixel_curr[7:0];
                        end else begin
                            CurrV[Counter_CurrPixel / 2] <= i_pixel_curr[7:0];
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
                            LastV[Counter_LastPixel / 2] <= i_pixel_last[7:0];
                        end
                        Switch_IsLastU <= ~Switch_IsLastU;
                        Counter_LastPixel <= Counter_LastPixel + 1;
                    end
                end
                COMPRESS : begin
                    if (Counter_CurrElemV == RowPixelWidth / 2) begin
                        o_ready_for_next <= 1'b1;
                        CurrentState <= LOADING_CHANNELS;
                        o_uart_ready <= 1'b0;
                    end else if (i_uart_allowed) begin
                        o_uart_ready <= 1'b1;
                        case (CurrSendingState) 
                            SENDING_LUMA : begin
                                Counter_CurrElemY <= Counter_CurrElemY + 1;
                                CurrSendingState <= SENDING_CHROMA;
                            end
                            SENDING_CHROMA : begin
                                if (Switch_SendingU) begin
                                    Counter_CurrElemU <= Counter_CurrElemU + 1;
                                end else begin
                                    Counter_CurrElemV <= Counter_CurrElemV + 1;
                                end
                                Switch_SendingU <= ~Switch_SendingU;
                                CurrSendingState <= SENDING_LUMA;
                            end
                        endcase
                    end                    
                end
            endcase
        end
    end
endmodule

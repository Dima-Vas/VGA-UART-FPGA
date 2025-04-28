`timescale 1ns / 1ps

// ----------
// Data compressor for real-time UART video transferring. Input is a pixel, which, accumulated
// with other pixels, represents a frame row that is being compressed afterwards using RLE.
// Structure for UART - 6 bytes per transaction :
// |  ID  | Ycoord | Xcoord |   Misc   |  Value  |  Amount  |
// |   Misc   | = |    RLE MSBs    | Channel Type | Ycoord LSB | Xcoord LSB | 
//     8 bits            4 bits          2 bits        1 bit        1 bit 
// ----------

module Compressor #(
    parameter RowPixelWidth = 640,
    parameter FramePixelHeight = 480,
    parameter PixelSize = 16,
    parameter MaxRunLength = 12,
    parameter TolerRLE = 5,
    parameter TolerDiff = 2
)(
    input wire CLK, RST,
    input [PixelSize-1:0] i_pixel_curr,
    input [$clog2(FramePixelHeight)-1:0] i_curr_y,
    input [PixelSize-1:0] i_pixel_last,
    input wire i_curr_empty,
    input wire i_last_empty,
    input wire i_uart_allowed,
    output reg o_fetch_curr,
    output reg o_fetch_last,
    output reg o_curr_row_full,
    output reg o_last_row_full,
    output reg [7:0] o_frame,
    output reg o_ready_for_next,
    output reg o_uart_ready
);

    localparam LOADING_CHANNELS = 1'b0, ITERATE = 1'b1;
    localparam PacketLength = 6;
    
    reg CurrentState;

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
    
    reg [$clog2(RowPixelWidth)-1:0] Counter_CurrElemY;
    reg [$clog2(RowPixelWidth/2)-1:0] Counter_CurrElemU;
    reg [$clog2(RowPixelWidth/2)-1:0] Counter_CurrElemV;
    
    reg Switch_FirstFrame;
    
    reg [7:0] Register_CurrElemY;
    reg [7:0] Register_CurrElemU;
    reg [7:0] Register_CurrElemV;
    
    reg [7:0] Register_LastElemY;
    reg [7:0] Register_LastElemU;
    reg [7:0] Register_LastElemV;
    
    reg [7:0] CurrPacketY [0:PacketLength-1];
    reg [7:0] CurrPacketU [0:PacketLength-1];
    reg [7:0] CurrPacketV [0:PacketLength-1];
    
    reg Switch_PacketReadyY;
    reg Switch_PacketReadyU;
    reg Switch_PacketReadyV;
    
    wire [7:0] Register_CurrPacketY_o_val;
    wire [7:0] Register_CurrPacketU_o_val;
    wire [7:0] Register_CurrPacketV_o_val; 
    wire [MaxRunLength-1:0] Register_CurrPacketY_o_count;
    wire [MaxRunLength-1:0] Register_CurrPacketU_o_count;
    wire [MaxRunLength-1:0] Register_CurrPacketV_o_count;
    wire [$clog2(RowPixelWidth)-1:0] Register_CurrPacketY_o_start_x;
    wire [$clog2(RowPixelWidth)-1:0] Register_CurrPacketU_o_start_x;
    wire [$clog2(RowPixelWidth)-1:0] Register_CurrPacketV_o_start_x;
    
    reg Switch_InputReadyY;
    reg Switch_InputReadyU;
    reg Switch_InputReadyV;
    
    wire Switch_OutputReadyY;
    wire Switch_OutputReadyU;
    wire Switch_OutputReadyV;
    
    wire Switch_BusyY;
    wire Switch_BusyU;
    wire Switch_BusyV;
    
    reg [3:0] i;
    
    wire Switch_RowCompressed = Counter_CurrElemY == RowPixelWidth &&
                                Counter_CurrElemU == RowPixelWidth/2 && 
                                Counter_CurrElemV == RowPixelWidth/2 ;

    always @(posedge CLK) begin
        if (!RST) begin
            o_fetch_curr <= 1'b0;
            o_fetch_last <= 1'b0;
            o_ready_for_next <= 1'b0;
            Switch_IsCurrU <= 1'b1;
            Switch_IsLastU <= 1'b1;
            Counter_CurrPixel <= 0;
            Counter_LastPixel <= 0;
            CurrentState <= LOADING_CHANNELS;
            o_curr_row_full <= 1'b0;
            o_last_row_full <= 1'b0;
            Counter_CurrElemY <= 0;
            Counter_CurrElemU <= 0;
            Counter_CurrElemV <= 0;
            Switch_FirstFrame <= 1'b1;
            Register_CurrElemY <= 0;
            Register_CurrElemU <= 0;
            Register_CurrElemV <= 0;
            Register_LastElemY <= 0;
            Register_LastElemU <= 0;
            Register_LastElemV <= 0;
            Switch_InputReadyY <= 1'b0;
            Switch_InputReadyU <= 1'b0;
            Switch_InputReadyV <= 1'b0;
        end else begin
            Register_CurrElemY <= CurrY[Counter_CurrElemY];
            Register_CurrElemU <= CurrU[Counter_CurrElemU];
            Register_CurrElemV <= CurrV[Counter_CurrElemV];
            Register_LastElemY <= LastY[Counter_CurrElemY];
            Register_LastElemU <= LastU[Counter_CurrElemU];
            Register_LastElemV <= LastV[Counter_CurrElemV];
            o_fetch_curr <= 1'b0;
            o_fetch_last <= 1'b0;
            Switch_FirstFrame <= (i_curr_y != FramePixelHeight) && Switch_FirstFrame;
            case (CurrentState)
                LOADING_CHANNELS : begin
                    if (o_curr_row_full && o_last_row_full) begin
                        CurrentState <= ITERATE;
                    end else begin
                        if (Counter_CurrPixel == RowPixelWidth) begin
                            o_curr_row_full <= 1'b1;
                        end else if (!i_curr_empty) begin
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
                        
                        if (Counter_LastPixel == RowPixelWidth) begin
                            o_last_row_full <= 1'b1;
                        end else if (!i_last_empty) begin
                            o_fetch_last <= 1'b1;
                            LastY[Counter_LastPixel] <= (Switch_FirstFrame) ? 8'd0 : i_pixel_last[15:8]; // FWFT
                            if (Switch_IsLastU) begin
                                LastU[Counter_LastPixel / 2] <= (Switch_FirstFrame) ? 8'd0 : i_pixel_last[7:0];
                            end else begin
                                LastV[Counter_LastPixel / 2] <= (Switch_FirstFrame) ? 8'd0 : i_pixel_last[7:0];
                            end
                            Switch_IsLastU <= ~Switch_IsLastU;
                            Counter_LastPixel <= Counter_LastPixel + 1;
                        end
                    end
                end
                ITERATE : begin // each channel in parallel   
                    Switch_InputReadyY <= 1'b0;
                    Switch_InputReadyU <= 1'b0;  
                    Switch_InputReadyV <= 1'b0;
                    if (Switch_RowCompressed) begin
                        CurrentState <= LOADING_CHANNELS;
                        Counter_LastPixel <= 0;
                        Counter_CurrPixel <= 0;
                        Counter_CurrElemY <= 0;
                        Counter_CurrElemU <= 0;
                        Counter_CurrElemV <= 0;
                        o_curr_row_full <= 1'b0;
                        o_last_row_full <= 1'b0;
                        o_ready_for_next <= 1'b1;
                    end
                    
                    if (!Switch_PacketReadyY && Counter_CurrElemY != RowPixelWidth && !Switch_BusyY) begin
                        Switch_InputReadyY <= 1'b1;
                        Counter_CurrElemY <= Counter_CurrElemY + 1;
                    end
                    if (!Switch_PacketReadyU && Counter_CurrElemU != RowPixelWidth/2 && !Switch_BusyU) begin
                        Switch_InputReadyU <= 1'b1;
                        Counter_CurrElemU <= Counter_CurrElemU + 1;
                    end
                    if (!Switch_PacketReadyV && Counter_CurrElemV != RowPixelWidth/2 && !Switch_BusyV) begin
                        Switch_InputReadyV <= 1'b1;
                        Counter_CurrElemV <= Counter_CurrElemV + 1;
                    end
                   
                    if (Switch_OutputReadyY) begin
                        CurrPacketY[1] <= i_curr_y[8:1];
                        CurrPacketY[2] <= Register_CurrPacketY_o_start_x[8:1];
                        CurrPacketY[3][7:4] <= Register_CurrPacketY_o_count[11:8];
                        CurrPacketY[3][3:2] <= 2'b00;
                        CurrPacketY[3][1] <= i_curr_y[0];
                        CurrPacketY[3][0] <= Register_CurrPacketY_o_start_x[0];
                        CurrPacketY[4] <= Register_CurrPacketY_o_val;
                        CurrPacketY[5] <= Register_CurrPacketY_o_count[7:0];
                    end
                    if (Switch_OutputReadyU) begin
                        CurrPacketU[1] <= i_curr_y[8:1];
                        CurrPacketU[2] <= Register_CurrPacketU_o_start_x[8:1];
                        CurrPacketU[3][7:4] <= Register_CurrPacketU_o_count[11:8];
                        CurrPacketU[3][3:2] <= 2'b01;
                        CurrPacketU[3][1] <= i_curr_y[0];
                        CurrPacketU[3][0] <= Register_CurrPacketU_o_start_x[0];
                        CurrPacketU[4] <= Register_CurrPacketU_o_val;
                        CurrPacketU[5] <= Register_CurrPacketU_o_count[7:0];
                    end
                    if (Switch_OutputReadyV) begin
                        CurrPacketV[1] <= i_curr_y[8:1];
                        CurrPacketV[2] <= Register_CurrPacketV_o_start_x[8:1];
                        CurrPacketV[3][7:4] <= Register_CurrPacketV_o_count[11:8];
                        CurrPacketV[3][3:2] <= 2'b10;
                        CurrPacketV[3][1] <= i_curr_y[0];
                        CurrPacketV[3][0] <= Register_CurrPacketV_o_start_x[0];
                        CurrPacketV[4] <= Register_CurrPacketV_o_val;
                        CurrPacketV[5] <= Register_CurrPacketV_o_count[7:0];
                    end
                end
            endcase
        end
    end
    
    reg[1:0] CurrentStateSend;
    reg[3:0] Counter_CurrFrame;
    reg [7:0] CurrId;
    
    always @(posedge CLK) begin
        if (!RST) begin
            CurrentStateSend <= 0;
            Counter_CurrFrame <= 0;
            CurrId <= 0;
            Switch_PacketReadyY <= 1'b0;
            Switch_PacketReadyU <= 1'b0;
            Switch_PacketReadyV <= 1'b0;
        end else begin
            if (Switch_OutputReadyY) begin
                Switch_PacketReadyY <= 1'b1;
            end
            if (Switch_OutputReadyU) begin
                Switch_PacketReadyU <= 1'b1;
            end 
            if (Switch_OutputReadyV) begin
                Switch_PacketReadyV <= 1'b1;
            end 
            if (Counter_CurrFrame == PacketLength) begin
                CurrId <= (CurrId + 1) % 255;
            end
            if (i_curr_y == FramePixelHeight && Switch_RowCompressed) begin
                o_frame <= 8'd255;
            end
            o_uart_ready <= 1'b0;
            case (CurrentStateSend)
                0 : begin
                    if (!Switch_PacketReadyY || Counter_CurrFrame == PacketLength) begin
                        CurrentStateSend <= 1;
                        Counter_CurrFrame <= 0;
                    end else if (i_uart_allowed) begin
                        o_frame <= (Counter_CurrFrame == 0) ? CurrId : CurrPacketY[Counter_CurrFrame];
                        Counter_CurrFrame <= Counter_CurrFrame + 1;
                        o_uart_ready <= 1'b1;
                        if (Counter_CurrFrame + 1 == PacketLength) begin
                            Switch_PacketReadyY <= 1'b0;
                        end
                    end
                end
                1 : begin
                    if (!Switch_PacketReadyU || Counter_CurrFrame == PacketLength) begin
                        CurrentStateSend <= 2;
                        Counter_CurrFrame <= 0;
                    end else if (i_uart_allowed) begin
                        o_frame <= (Counter_CurrFrame == 0) ? CurrId : CurrPacketU[Counter_CurrFrame];
                        Counter_CurrFrame <= Counter_CurrFrame + 1;
                        o_uart_ready <= 1'b1;
                        if (Counter_CurrFrame + 1 == PacketLength) begin
                            Switch_PacketReadyU <= 1'b0;
                        end
                    end
                end
                2 : begin
                    if (!Switch_PacketReadyV || Counter_CurrFrame == PacketLength) begin
                        CurrentStateSend <= 0;
                        Counter_CurrFrame <= 0;
                    end else if (i_uart_allowed) begin
                        o_frame <= (Counter_CurrFrame == 0) ? CurrId : CurrPacketV[Counter_CurrFrame];
                        Counter_CurrFrame <= Counter_CurrFrame + 1;
                        o_uart_ready <= 1'b1;
                        if (Counter_CurrFrame + 1 == PacketLength) begin
                            Switch_PacketReadyV <= 1'b0;
                        end
                    end
                end
            endcase
        end
    end
    
    RLE #(RowPixelWidth,
          TolerDiff,
          TolerRLE,
          MaxRunLength
    ) rle_y (
        .CLK(CLK),
        .RST(RST),
        .i_ready(Switch_InputReadyY),
        .i_curr_val(Register_CurrElemY),
        .i_prev_val(Register_LastElemY),
        .o_val(Register_CurrPacketY_o_val),
        .o_count(Register_CurrPacketY_o_count),
        .o_start_x(Register_CurrPacketY_o_start_x),
        .o_ready(Switch_OutputReadyY),
        .o_busy(Switch_BusyY)
    );
    
    RLE #(RowPixelWidth/2,
          TolerDiff,
          TolerRLE,
          MaxRunLength
    ) rle_u (
        .CLK(CLK),
        .RST(RST),
        .i_ready(Switch_InputReadyU),
        .i_curr_val(Register_CurrElemU),
        .i_prev_val(Register_LastElemU),
        .o_val(Register_CurrPacketU_o_val),
        .o_count(Register_CurrPacketU_o_count),
        .o_start_x(Register_CurrPacketU_o_start_x),
        .o_ready(Switch_OutputReadyU),
        .o_busy(Switch_BusyU)
    );
    
    RLE #(RowPixelWidth/2,
          TolerDiff,
          TolerRLE,
          MaxRunLength
    ) rle_v (
        .CLK(CLK),
        .RST(RST),
        .i_ready(Switch_InputReadyV),
        .i_curr_val(Register_CurrElemV),
        .i_prev_val(Register_LastElemV),
        .o_val(Register_CurrPacketV_o_val),
        .o_count(Register_CurrPacketV_o_count),
        .o_start_x(Register_CurrPacketV_o_start_x),
        .o_ready(Switch_OutputReadyV),
        .o_busy(Switch_BusyV)
    );
    
endmodule

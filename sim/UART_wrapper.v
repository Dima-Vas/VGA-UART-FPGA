`timescale 1ns / 1ps

module UART_wrapper #(
    parameter ClockFrequency = 50_000_000,
    parameter ActiveFrameWidth = 512,
    parameter ActiveFrameHeight = 384,
    parameter BaudRateUART = 115200,
    parameter BufferSizeUART = 32768)(
    input wire CLK, RST,
    output wire o_data
);
    localparam PauseBetweenMeasures = 1 * ClockFrequency;
    localparam MeasurePeriod = 10 * ClockFrequency;

    wire [5:0] RUN_LENGTH = 8;
    
    localparam  ID = 0,
                YCOORD = 1,
                XCOORD = 2,
                MISC = 3,
                VALUE = 4,
                AMOUNT = 5;
    
    reg [$clog2(ActiveFrameWidth)-1:0] CurrX = 0;
    reg [$clog2(ActiveFrameHeight)-1:0] CurrY = 0;
    reg [7:0] CurrId = 0;
    
    reg Switch_FrameEmptyUART;
    reg [7:0] FrameForUART;
    
    
    reg Switch_FrameEmptyUART1;
    wire [7:0] FrameForUART1 = FrameForUART;
    wire Switch_CanSendFrameUART1;
    
    reg Switch_FrameEmptyUART2;
    wire [7:0] FrameForUART2 = FrameForUART;
    wire Switch_CanSendFrameUART2;
    
    reg Switch_FrameEmptyUART3;
    wire [7:0] FrameForUART3 = FrameForUART;
    wire Switch_CanSendFrameUART3;
    
    reg Switch_FrameEmptyUART4;
    wire [7:0] FrameForUART4 = FrameForUART;
    wire Switch_CanSendFrameUART4;
    
    wire Switch_CanSendFrameUART = Switch_CanSendFrameUART1 || Switch_CanSendFrameUART2 || Switch_CanSendFrameUART3 || Switch_CanSendFrameUART4;
    
    reg [2:0] CurrentByte;
    reg Switch_Pause;

    always @(posedge CLK) begin
        if (!RST) begin
            CurrX <= 0;
            CurrY <= 0;
            CurrId <= 0;
            CurrentByte <= 0;
            FrameForUART <= 0;
            Switch_FrameEmptyUART<= 1'b1;
        end else begin
            FrameForUART <= 8'd0;
            Switch_FrameEmptyUART <= 1'b1;
            if (Switch_CanSendFrameUART && !Switch_Pause) begin
                if (CurrY == ActiveFrameHeight) begin
                    FrameForUART <= 8'd255;
                    CurrY <= 0;
                    CurrX <= 0;
                    Switch_FrameEmptyUART <= 1'b0;
                    CurrentByte <= ID;
                end else begin
                    case (CurrentByte)
                        ID : begin
                            FrameForUART <= CurrId;
                            CurrentByte <= YCOORD;
                        end
                        YCOORD : begin
                            FrameForUART <= (CurrY >> 1);
                            CurrentByte <= XCOORD;
                        end
                        XCOORD : begin
                            FrameForUART <= (CurrX >> 1);
                            CurrentByte <= MISC;
                        end
                        MISC : begin
                            FrameForUART <= ((0 & 8'h0F)) |
                                            ((0 & 2'b11) << 4) |
                                            ((CurrY & 1) << 6) |
                                            ((CurrX & 1) << 7);
                            CurrentByte <= VALUE;
                        end
                        VALUE : begin
                            FrameForUART <= CurrId % 8'd255;
                            CurrentByte <= AMOUNT;
                        end
                        AMOUNT : begin
                            FrameForUART <= RUN_LENGTH;
                            CurrentByte <= ID;
                            if (CurrX + RUN_LENGTH == ActiveFrameWidth) begin
                                CurrY <= CurrY + 1;
                                CurrX <= 0;
                            end else begin
                                CurrX <= CurrX + RUN_LENGTH;
                            end
                            CurrId <= (CurrId == 8'hFE) ? 0 : CurrId + 1;
                        end
                    endcase
                    Switch_FrameEmptyUART <= 1'b0;
                end
            end
        end
    end
    
    reg [2:0] CurrModule;
    
    reg [$clog2(MeasurePeriod)-1:0] CurrTick;
    
    wire o_data1, o_data2, o_data3, o_data4;
    
    assign o_data = (CurrModule==0) ? o_data1 :
              (CurrModule==1) ? o_data2 :
              (CurrModule==2) ? o_data3 :
                                o_data4;
    
    always @(posedge CLK) begin
        if (!RST) begin
            CurrModule <= 0;
            CurrTick <= 0;
            Switch_Pause <= 1'b0;
        end else begin
            CurrTick <= CurrTick + 1;
            if (CurrTick + 1 == MeasurePeriod && !Switch_Pause) begin
                Switch_Pause <= 1'b1;
                CurrTick <= 0;
                CurrModule <= CurrModule + 1;
            end else if (CurrTick + 1 == PauseBetweenMeasures && Switch_Pause) begin
                Switch_Pause <= 1'b0;
                CurrTick <= 0;
            end
            Switch_FrameEmptyUART1 <= 1'b1;
            Switch_FrameEmptyUART2 <= 1'b1;
            Switch_FrameEmptyUART3 <= 1'b1;
            Switch_FrameEmptyUART4 <= 1'b1;
            if (!Switch_FrameEmptyUART) begin
                case (CurrModule) 
                    0: begin
                        if (Switch_CanSendFrameUART1) begin
                            Switch_FrameEmptyUART1 <= 1'b0;
                        end
                    end
                    1: begin
                        if (Switch_CanSendFrameUART2) begin
                            Switch_FrameEmptyUART2 <= 1'b0;
                        end
                    end
                    2: begin
                        if (Switch_CanSendFrameUART3) begin
                            Switch_FrameEmptyUART3 <= 1'b0;
                        end
                    end
                    3: begin
                        if (Switch_CanSendFrameUART4) begin
                            Switch_FrameEmptyUART4 <= 1'b0;
                        end
                    end
                    4: begin
                        
                    end
                endcase
            end
            
        end
    end

    UART #(ClockFrequency, 115200, BufferSizeUART) uart_115200(
        .CLK(CLK),
        .RST(RST),
        .i_ready(~Switch_FrameEmptyUART1),
        .i_frame(FrameForUART1),
        .o_data(o_data1),
        .o_ready(Switch_CanSendFrameUART1)
    );
    
    UART #(ClockFrequency, 921600, BufferSizeUART) uart_921600(
        .CLK(CLK),
        .RST(RST),
        .i_ready(~Switch_FrameEmptyUART2),
        .i_frame(FrameForUART2),
        .o_data(o_data2),
        .o_ready(Switch_CanSendFrameUART2)
    );
    
    UART #(ClockFrequency, 2343750, BufferSizeUART) uart_2343750(
        .CLK(CLK),
        .RST(RST),
        .i_ready(~Switch_FrameEmptyUART3),
        .i_frame(FrameForUART3),
        .o_data(o_data3),
        .o_ready(Switch_CanSendFrameUART3)
    );
    
    UART #(ClockFrequency, 4687500, BufferSizeUART) uart_4687500(
        .CLK(CLK),
        .RST(RST),
        .i_ready(~Switch_FrameEmptyUART4),
        .i_frame(FrameForUART4),
        .o_data(o_data4),
        .o_ready(Switch_CanSendFrameUART4)
    );
    
endmodule

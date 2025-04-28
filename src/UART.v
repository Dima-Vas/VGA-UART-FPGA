`timescale 1ns / 1ps

// ----------
// A Simplex UART hardware management module with FPGA as master. 
// ----------
module UART #(
    parameter ClockFrequency = 50_000_000,
    parameter BaudRate = 115200,
    parameter BufferSize = 256 // must be a power of 2, i.e. FT232R's 256 byte
)(
    input wire CLK, RST,
    input wire i_ready,
    input [7:0] i_frame,
    output reg o_data,
    output wire o_ready
);

    localparam FrameWidth = 10;
    localparam TicksPerBit = ClockFrequency / BaudRate;
    
    reg Switch_Sending = 1'b0;
    
    (* ram_style = "block" *) reg [7:0] FrameBuffer [0:BufferSize-1]; // circular buffer
    reg [$clog2(BufferSize)-1:0] Counter_BufferHead;
    reg [$clog2(BufferSize)-1:0] Counter_BufferTail;
    reg [7:0] CurrentFrameToSend;

    reg [9:0] ShiftRegister = 0;
    reg [$clog2(FrameWidth)-1:0] Counter_CurrRegisterBit = 0;
    reg [$clog2(TicksPerBit)-1:0] Counter_CurrTick = 0;
    
    assign o_ready = ((Counter_BufferHead + 1) != Counter_BufferTail);
    
    reg Switch_Reading;
        
    always @(posedge CLK) begin
        if (!RST) begin        
            ShiftRegister <= 10'b1111111111;
            Counter_CurrRegisterBit <= 0;
            Counter_CurrTick <= 0;
            Switch_Sending <= 0;
            o_data <= 1'b1;
            Counter_BufferTail <= 0;
            Counter_BufferHead <= 0;
            CurrentFrameToSend <= 0;
            Switch_Reading <= 1'b0;
        end else begin
            CurrentFrameToSend <= FrameBuffer[Counter_BufferTail];
            if (i_ready && o_ready) begin
                FrameBuffer[Counter_BufferHead] <= i_frame;
                Counter_BufferHead <= Counter_BufferHead + 1;
            end
            if (!Switch_Sending && (Counter_BufferHead != Counter_BufferTail)) begin
                Switch_Sending <= 1'b1;
                Switch_Reading <= 1'b1;
            end else if (Switch_Sending && Switch_Reading) begin
                ShiftRegister <= {1'b1, CurrentFrameToSend, 1'b0};
                Counter_BufferTail <= Counter_BufferTail + 1;
                Switch_Reading <= 1'b0;
            end else if (Switch_Sending) begin
                if (Counter_CurrTick < TicksPerBit - 1) begin
                    Counter_CurrTick <= Counter_CurrTick + 1;
                end else begin // enough ticks, transmit
                    Counter_CurrTick <= 0;
                    o_data <= ShiftRegister[0];
                    ShiftRegister <= {1'b1, ShiftRegister[9:1]};
                    Counter_CurrRegisterBit <= Counter_CurrRegisterBit + 1;
                    if (Counter_CurrRegisterBit == FrameWidth - 1) begin
                        Switch_Sending <= 0;
                        Counter_CurrRegisterBit <= 0;
                    end
                end
            end
        end
    end
endmodule
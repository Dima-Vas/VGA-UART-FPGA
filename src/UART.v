`timescale 1ns / 1ps

// ----------
// A Simplex UART hardware management module with FPGA as master. 
// ----------
module UART #(
    parameter ClockFrequency = 50_000_000,
    parameter BaudRate = 115200
)(
    input wire CLK, RST,
    input wire i_send,
    input [7:0] i_frame,
    output reg o_data
);

    localparam FrameWidth = 10;
    localparam TicksPerBit = ClockFrequency / BaudRate;
    
    reg Switch_Sending = 1'b0;

    reg [9:0] ShiftRegister = 0;
    reg [$clog2(FrameWidth)-1:0] Counter_CurrRegisterBit = 0;
    reg [$clog2(TicksPerBit)-1:0] Counter_CurrTick = 0;
    
    always @(posedge CLK) begin
        if (!RST) begin        
            ShiftRegister <= 10'b1111111111;
            Counter_CurrRegisterBit <= 0;
            Counter_CurrTick <= 0;
            Switch_Sending <= 0;
            o_data <= 1'b1;
        end else begin
            if (i_send && !Switch_Sending) begin
                ShiftRegister <= {1'b1, i_frame[7:0], 1'b0};
                Switch_Sending <= 1;
            end else if (Switch_Sending) begin
                if (Counter_CurrTick < TicksPerBit - 1) begin
                    Counter_CurrTick <= Counter_CurrTick + 1;
                end else begin // enough ticks, transmit
                    Counter_CurrTick <= 0;
                    o_data <= ShiftRegister[0];
                    ShiftRegister <= ShiftRegister >> 1;
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

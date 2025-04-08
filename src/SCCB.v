`timescale 1ns / 1ps

// ----------
// A module for configuring devices via SCCB. Output-only, 2-wire, 3-phase transmission with hi-Z support.
// ----------
module SCCB #(
    parameter ClockFrequency = 50_000_000,
    parameter ClockFrequencySCCB = 100_000
)(
    input wire CLK, RST,
    input [7:0] i_data,
    input [7:0] i_addr,
    input wire i_ready,
    inout o_sio_d, // SCCB data
    output reg o_sio_c, // SCCB clock
    output reg o_busy // user cannot send commands
);
    localparam AddressOV7670 = 8'h42;

    localparam ClockHalfPeriodSCCB = ClockFrequency / ClockFrequencySCCB / 2;
    reg [$clog2(ClockHalfPeriodSCCB)-1:0] Counter_SystemClockTick;
    reg Switch_ClockPhaseSCCB;
    
    reg Switch_TristateWrite;
    reg Register_o_sio_d;
    assign o_sio_d = (Switch_TristateWrite) ? Register_o_sio_d : 1'bz;
    
    localparam  IDLE        = 4'b0000,
                SETUP       = 4'b0001,
                START       = 4'b0010,
                DATA_RISE   = 4'b0011,
                DATA_FALL   = 4'b0100,
                ACK         = 4'b0101,
                ACK_DONE    = 4'b0110,
                STOP_RISE   = 4'b0111,
                STOP_FALL   = 4'b1000;
    
    reg [3:0] CurrentState;
    
    reg [3:0] Counter_CurrTransferCycle;
    
    reg [7:0] Register_i_data;
    reg [7:0] Register_i_addr;
    reg [7:0] CurrDataToTransfer;
    localparam FrameLength = 8;
    reg [$clog2(FrameLength):0] Counter_CurrBit;
    
    always @(posedge CLK) begin
        if (!RST) begin
            Counter_SystemClockTick <= 0;
            Switch_ClockPhaseSCCB <= 1'b1;
            o_sio_c <= 1'b0;
        end else begin
            if (CurrentState != IDLE) begin // action in progress
                if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin // SCCB clock edge
                    Counter_SystemClockTick <= 0;
                    if (CurrentState == SETUP) begin
                        Switch_ClockPhaseSCCB <= 1'b1; // always high during setup
                    end else begin
                        Switch_ClockPhaseSCCB <= ~Switch_ClockPhaseSCCB;
                    end
                end else begin 
                    Counter_SystemClockTick <= Counter_SystemClockTick + 1;
                end
                o_sio_c <= Switch_ClockPhaseSCCB;
            end else begin
                o_sio_c <= 1'b1; // high during IDLE
                Counter_SystemClockTick <= 0;
                Switch_ClockPhaseSCCB <= 1'b1;
            end
            o_busy <= (CurrentState != IDLE) ? 1'b1 : 1'b0;
        end
    end
    
    always @(posedge CLK) begin
        if (!RST) begin
            CurrentState <= IDLE;
            Register_o_sio_d <= 1'b1;
            Switch_TristateWrite <= 1'b1;
            Counter_CurrBit <= 0;
            Counter_CurrTransferCycle <= 0;
        end else begin
            case (CurrentState)
                SETUP : begin
                    Register_o_sio_d <= 1'b1;
                    Switch_TristateWrite <= 1'b1;
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin // to stabilize the clock before the setup
                        CurrentState <= START;
                    end
                end
                START : begin
                    Switch_TristateWrite <= 1'b1;
                    Register_o_sio_d <= 1'b0;
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB / 2) begin
                        CurrentState <= DATA_FALL;
                        Counter_CurrBit <= 0;
                    end
                end
                DATA_FALL : begin // clock is 0, set the data
                    Switch_TristateWrite <= 1'b1;                    
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin
                        CurrentState <= DATA_RISE;
                    end
                end
                DATA_RISE : begin // clock is 1, 'shift' the data
                    Switch_TristateWrite <= 1'b1;
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin
                        if (Counter_CurrBit == FrameLength) begin // all 8 bits are transfered
                            Counter_CurrBit <= 0;
                            CurrentState <= ACK;
                            Switch_TristateWrite <= 1'b0; // wait for the ACK answer
                        end else begin
                            Register_o_sio_d <= CurrDataToTransfer[FrameLength - Counter_CurrBit - 1]; // MSB first
                            Counter_CurrBit <= Counter_CurrBit + 1;
                            CurrentState <= DATA_FALL;
                        end
                    end
                end
                ACK : begin
                    Switch_TristateWrite <= 1'b0;
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin 
                        CurrentState <= ACK_DONE;
                    end
                end
                ACK_DONE : begin // SCCB does not check the ACK signal
                    Switch_TristateWrite <= 1'b0;
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin
                        case (Counter_CurrTransferCycle) 
                            0 : begin // transferred the AddressOV7670
                                CurrentState <= DATA_FALL;
                                CurrDataToTransfer <= Register_i_addr;
                                Counter_CurrTransferCycle <= 2'b01;
                            end
                            1 : begin // the register address
                                CurrentState <= DATA_FALL;
                                CurrDataToTransfer <= Register_i_data;
                                Counter_CurrTransferCycle <= 2'b10;
                            end
                            2 : begin // the register value, now STOP
                                CurrentState <= STOP_RISE;
                                Counter_CurrTransferCycle <= 2'b00;
                            end
                        endcase
                    end
                end
                STOP_RISE : begin
                    Switch_TristateWrite <= 1'b1;
                    Register_o_sio_d <= 1'b0;
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin 
                        CurrentState <= STOP_FALL;
                    end
                end
                STOP_FALL : begin
                    Switch_TristateWrite <= 1'b1;
                    Register_o_sio_d <= 1'b1;
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin
                        CurrentState <= IDLE;
                    end
                end
                IDLE : begin
                    Switch_TristateWrite <= 1'b1;
                    Register_o_sio_d <= 1'b1;
                    if (i_ready) begin
                        Register_i_data <= i_data; // latch data
                        Register_i_addr <= i_addr;
                        Counter_CurrTransferCycle <= 2'b00;
                        CurrDataToTransfer <= AddressOV7670; // additionally, latch addr immediately
                        CurrentState <= SETUP; // starting the data transfer process
                    end
                end
            endcase
        end
    end
    
endmodule
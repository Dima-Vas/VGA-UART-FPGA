`timescale 1ns / 1ps

// ----------
// A module for configuring devices via SCCB. Output-only, 2-phase transmission, with hi-Z support.
// ----------
module SCCB #(
    parameter ClockFrequency = 50_000_000,
    parameter ClockFrequencySCCB = 400_000
)(
    input wire CLK, RST,
    input [7:0] i_data,
    input wire i_ready,
    inout o_sio_d, // SCCB data
    output reg o_sio_c, // SCCB clock
    output reg o_busy // user cannot send commands
);

    localparam ClockHalfPeriodSCCB = ClockFrequency / ClockFrequencySCCB / 2;
    reg [$clog2(ClockHalfPeriodSCCB):0] Counter_SystemClockTick;
    reg Switch_ClockPhaseSCCB;
    
    reg Switch_TristateWrite;
    reg Register_o_sio_d;
    assign o_sio_d = (Switch_TristateWrite) ? Register_o_sio_d : 1'bz;
    
    localparam  IDLE        = 3'b000,
                SETUP_RISE  = 3'b001,
                SETUP_FALL  = 3'b010,
                START       = 3'b011,
                ADDRESS     = 3'b100,
                DATA        = 3'b101;
    
    reg CurrentState, NextState;
    
    always @(posedge CLK) begin
        if (!RST) begin
            Counter_SystemClockTick <= 0;
            Switch_ClockPhaseSCCB <= 1'b1;
            o_sio_c <= 1'b1;
        end else begin
            if (CurrentState != IDLE) begin // action in progress
                if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin // SCCB clock edge
                    Counter_SystemClockTick <= 0;
                    if (CurrentState > 3'b011) begin // action is not setup
                        Switch_ClockPhaseSCCB <= ~Switch_ClockPhaseSCCB;
                    end else begin // action is setup
                        Switch_ClockPhaseSCCB <= 1'b1; // always high during setup
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
        end
    end
    
    // FSM for this bullshit
    always @(posedge CLK) begin
        if (!RST) begin
            CurrentState <= START;
            Register_o_sio_d <= 1'b1;
            Switch_TristateWrite <= 1'b1;
        end else begin
            case (CurrentState)
                START : begin
                    Register_o_sio_d <= 1'b1;
                    Switch_TristateWrite <= 1'b1;
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB / 2) begin // to stabilize the clock before the setup
                        CurrentState <= SETUP_FALL;
                    end
                end
                SETUP_RISE : begin
                    Switch_TristateWrite <= 1'b1;
                    Register_o_sio_d <= 1'b0;
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin
                        CurrentState <= SETUP_FALL;
                    end
                end
                SETUP_FALL : begin
                    Switch_TristateWrite <= 1'b1;
                    Register_o_sio_d <= 1'b1;
                    if (Counter_SystemClockTick + 1 == ClockHalfPeriodSCCB) begin
                        CurrentState <= IDLE;
                    end
                end
            endcase
        end
    end
    
endmodule

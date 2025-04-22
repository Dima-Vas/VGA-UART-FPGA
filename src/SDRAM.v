`timescale 1ns / 1ns


// ----------
// A minimalistic SDRAM controller, originally written for Winbond W9825G6KH
// To Write a burst of 8 words:
// - set the i_enable to 1, i_rw to 0 and i_data with the first word to write
// - set the i_enable to 0 and wait for o_valid_wr to go 1
// - switch the i_data to the next value to write until all 8 are written
// To Read a burst of 8 words:
// - set the i_enable to 1, i_rw to 1 and i_addr with the first address to read
// - set the i_enable to 0 and wait for o_valid_rd to go 1
// - read the 8 words, one for each of the 8 subsequent clock ticks
// ----------
module SDRAM #(
    parameter ClockFrequency = 50_000_000,
    parameter WordLength = 16,
    parameter BankAddrLen = 2,
    parameter RowAddrLen = 13,
    parameter ColAddrLen = 9,
    parameter AddressWidth = 24,
    parameter BurstLength = 8
)(
    input CLK, RST,
    input i_enable,                     // User passes a signal to controller
    input i_rw,                         // 0 for write, 1 for read
    input [AddressWidth-1:0] i_addr,    // Address to read from - 2 bank bits, 13 row bits, 9 col bits
    input [WordLength-1:0] i_data,      // Data to write to SDRAM
    input [WordLength-1:0] i_sdram_data,
    output [WordLength-1:0] o_sdram_data,
    output reg o_clk_en,                // Clock Enable
    output reg o_cs_n,                  // Select SDRAM signal
    output reg o_ras_n,                 // Select a row #o_addr
    output reg o_cas_n,                 // Select a column #o_addr
    output reg o_we_n,                  // On 1, write selected data, on 0 - read it
    output reg [12:0] o_addr,           // SDRAM's address bus
    output reg [1:0] o_bank,            // SDRAM's bank selector
    output reg [1:0] o_dqm,             // SDRAM's mask for input/output
    output wire [WordLength-1:0] o_data,// Data read from SDRAM
    output wire o_valid_wr,             // Signals user that they can set the data to write
    output wire o_valid_rd,             // Signals user that they can latch the read data
    output wire o_busy                  // User cannot send commands to the controller
);

    task SetNOP;
        begin
            o_cs_n = 1'b0;  o_ras_n = 1'b1; o_cas_n = 1'b1; o_we_n = 1'b1;
        end
    endtask
    
    task SetPrecharge;
        begin
            o_cs_n = 1'b0; o_ras_n = 1'b0; o_cas_n = 1'b1; o_we_n = 1'b0;
        end
    endtask
    
    task SetMode;
        begin
            o_cs_n = 1'b0;
            o_ras_n = 1'b0;
            o_cas_n = 1'b0;
            o_we_n = 1'b0;
            o_addr[2:0] = 3'b011; // Burst length : 8
            o_addr[3] = 1'b0; // Sequential addressing
            o_addr[6:4] = 3'b011; // CAS latency : 3
            o_addr[8:7] = 2'b00; // Reserved
            o_addr[9] = 1'b0; // Burst read and burst write
            o_addr[12:10] = 3'b000; // Reserved
            o_bank[1:0] = 2'b00; // Reserved
        end
    endtask
    
    task SetRefresh;
        begin
            o_clk_en = 1'b1; o_cs_n = 1'b0; o_ras_n = 1'b0; o_cas_n = 1'b0; o_we_n = 1'b1;
        end
    endtask
    
    task SetActivate;
        begin
            o_cs_n = 1'b0; o_ras_n = 1'b0; o_cas_n = 1'b1; o_we_n = 1'b1;
        end
    endtask
    
    task SetRead;
        begin
            o_clk_en = 1'b1; o_cs_n = 1'b0; o_ras_n = 1'b1; o_cas_n = 1'b0; o_we_n = 1'b1;
        end
    endtask
    
    task SetWrite;
        begin
            o_clk_en = 1'b1; o_cs_n = 1'b0; o_ras_n = 1'b1; o_cas_n = 1'b0; o_we_n = 1'b0;
        end
    endtask
    
    localparam  IDLE              = 4'b0000, // 
                PRECHARGE_ALL     = 4'b0001, //
                SET_MODE          = 4'b0010, //
                REFRESH           = 4'b0011, //
                ACTIVATE          = 4'b0100, //
                RW_WORD           = 4'b0101, //
                RW_CMD            = 4'b0110, //
                INIT_PAUSE        = 4'b0111, //
                TRCD_PAUSE        = 4'b1000,// An addition to respect the wait between activate and read/write
                TCL_PAUSE         = 4'b1001,
                TRP_PAUSE         = 4'b1010,
                REFRESH_MSR_PAUSE = 4'b1011,
                REFRESH_PAUSE     = 4'b1100;
              
    localparam integer ClockPeriod = 1_000_000_000 / ClockFrequency; // in ns
    localparam integer INIT_PAUSE_WAIT     = 200_000 / ClockPeriod, // 200μs of powerup time
                PRECHARGE_ALL_WAIT  = 20 / ClockPeriod, // 20ns of precharge time
                SET_MODE_WAIT       = 2, // 2 clock cycles
                REFRESH_PAUSE_WAIT  = 60 / ClockPeriod + 1, // 60ns + 1 for safety 
                TRCD_PAUSE_WAIT     = 20 / ClockPeriod, // 20ns between ACTIVATE and READ/WRITE + 1 for safety
                TCL_PAUSE_WAIT      = 2, // for CL = 3
                TRP_PAUSE_WAIT      = PRECHARGE_ALL_WAIT; // 20ns between PRECHARGE and ACTIVE
    
    localparam REFRESH_AFTER_MSR_CYCLE = 8; // for W9825G6KH
    localparam integer REFRESH_REGULAR_PERIOD = 7800 / ClockPeriod;
    reg [$clog2(REFRESH_REGULAR_PERIOD)-1:0] Counter_TimeToNextRefresh;
    reg [$clog2(REFRESH_AFTER_MSR_CYCLE):0] Counter_RefreshCyclesDone;
    reg Switch_RefreshIsMSR;
    wire Switch_NeedToRefresh;
  
    reg [15:0] Counter_WaitClocks, Counter_NextWaitClocks; // I guess max of 2**16 NOPS
    
    reg [3:0] CurrentState, NextState;
    
    reg [$clog2(BurstLength):0] Counter_BurstWordsLeft;
    reg [WordLength-1:0] Register_o_data;

    wire [WordLength-1:0] DataToReadFromSDRAM; // controller writes to SDRAM from here
    wire [WordLength-1:0] DataToWriteToSDRAM; // controller reads from SDRAM into here
    reg Switch_OperationRead;
    
    // Multiplexed addresses requested by user on the i_addr
    reg [BankAddrLen-1:0] Register_BankAddrReq;
    reg [RowAddrLen-1:0] Register_RowAddrReq;
    reg [ColAddrLen-1:0] Register_ColAddrReq;
    
    reg Register_o_valid_wr;
    reg Register_o_valid_rd;
    
    reg Register_o_busy;
    
    assign o_valid_wr = Register_o_valid_wr;
    assign o_valid_rd = Register_o_valid_rd;
    assign o_busy = Register_o_busy;

    assign o_sdram_data = i_data;
    assign o_data = Register_o_data;
    
    assign Switch_NeedToRefresh = (Counter_TimeToNextRefresh >= REFRESH_REGULAR_PERIOD) ? 1'b1 : 1'b0;
    
    always @(posedge CLK) begin
        if (!RST) begin
            CurrentState <= INIT_PAUSE;
            Counter_WaitClocks <= INIT_PAUSE_WAIT; // 200ns for the initial pause
            Counter_BurstWordsLeft <= 0;
            Register_o_data <= 0;
            Switch_OperationRead <= 1'b0;
            Register_BankAddrReq <= 0;
            Register_RowAddrReq <= 0;
            Register_ColAddrReq <= 0;
            Switch_RefreshIsMSR <= 1'b0;
            Counter_RefreshCyclesDone <= 0;
            Counter_TimeToNextRefresh <= 0;
            Register_o_busy <= 1'b0;
        end else begin
            if (CurrentState == IDLE && NextState == ACTIVATE) begin
                Register_BankAddrReq <= i_addr[AddressWidth-1 : AddressWidth-BankAddrLen];
                Register_RowAddrReq <= i_addr[AddressWidth-BankAddrLen-1 : AddressWidth-BankAddrLen-RowAddrLen];
                Register_ColAddrReq <= i_addr[AddressWidth-BankAddrLen-RowAddrLen-1 : AddressWidth-BankAddrLen-RowAddrLen-ColAddrLen]; 
                Counter_BurstWordsLeft <= BurstLength;
                Switch_OperationRead <= i_rw;
            end else if (CurrentState == RW_WORD) begin
                if (Counter_BurstWordsLeft > 0) begin
                    Counter_BurstWordsLeft <= Counter_BurstWordsLeft - 1;
                    if (Switch_OperationRead) begin // READ latches into RW_WORD, WRITE latches always
                        Register_o_data <= i_sdram_data;
                    end
                end
            end
            if (CurrentState == SET_MODE && NextState == REFRESH) begin
                Switch_RefreshIsMSR <= 1'b1;
            end else if (CurrentState == REFRESH_MSR_PAUSE && NextState == IDLE) begin
                Switch_RefreshIsMSR <= 1'b0;
            end
            if (Counter_WaitClocks == 0) begin
                Counter_WaitClocks <= Counter_NextWaitClocks;
                if (CurrentState == SET_MODE) begin
                    Counter_RefreshCyclesDone <= 0;
                end else if (CurrentState == REFRESH && Switch_RefreshIsMSR) begin
                    Counter_RefreshCyclesDone <= Counter_RefreshCyclesDone + 1;
                end
            end else begin
                Counter_WaitClocks <= Counter_WaitClocks - 1;
            end
            Register_o_busy <= (CurrentState != IDLE || Switch_NeedToRefresh);
            CurrentState <= NextState;
            Counter_TimeToNextRefresh <= (Counter_TimeToNextRefresh >= REFRESH_REGULAR_PERIOD) ? 0 : Counter_TimeToNextRefresh + 1;
        end
    end

    always @(*) begin
        Counter_NextWaitClocks = 0;
        NextState = CurrentState;
        SetNOP();
        o_addr = 0;
        o_bank = 0;
        o_clk_en = 1;
        o_dqm = 0;
        Register_o_valid_rd = 1'b0;
        Register_o_valid_wr = 1'b0;
        case (CurrentState)
            INIT_PAUSE : begin
                SetNOP();
                o_dqm = 2'b11;
                if (Counter_WaitClocks == 0) begin
                    NextState = PRECHARGE_ALL;
                    Counter_NextWaitClocks = PRECHARGE_ALL_WAIT;
                end
            end
            PRECHARGE_ALL : begin
                SetPrecharge();
                o_addr[10] = 1'b1;
                if (Counter_WaitClocks == 0) begin
                    NextState = SET_MODE;
                    Counter_NextWaitClocks = SET_MODE_WAIT;
                end
            end
            SET_MODE : begin
                SetMode();
                if (Counter_WaitClocks == 0) begin
                    NextState = REFRESH;
                    Counter_NextWaitClocks = 0;
                end
            end
            REFRESH : begin
                SetRefresh();
                if (Counter_WaitClocks == 0) begin
                    NextState = (Switch_RefreshIsMSR) ? REFRESH_MSR_PAUSE : REFRESH_PAUSE;
                    Counter_NextWaitClocks = REFRESH_PAUSE_WAIT;
                end
                
            end
            REFRESH_MSR_PAUSE : begin
                SetNOP();
                if (Counter_WaitClocks == 0) begin
                    if (Counter_RefreshCyclesDone < REFRESH_AFTER_MSR_CYCLE) begin
                        NextState = REFRESH;
                        Counter_NextWaitClocks = 1;
                    end else begin
                        NextState = IDLE;
                        Counter_NextWaitClocks = 0;
                    end
                end
            end
            REFRESH_PAUSE : begin
                SetNOP();
                if (Counter_WaitClocks == 0) begin
                    NextState = IDLE;
                    Counter_NextWaitClocks = 0;
                end
            end
            IDLE : begin
                SetNOP();
                o_dqm = 2'b11;
                if (Switch_NeedToRefresh) begin
                    NextState = REFRESH;
                    Counter_NextWaitClocks = 0;
                end else if (i_enable) begin
                    NextState = ACTIVATE;
                    Counter_NextWaitClocks = 0; // just launch ACTIVATE
                end
            end
            ACTIVATE : begin
                SetActivate();
                o_dqm = 2'b11;
                o_bank = Register_BankAddrReq;
                o_addr = Register_RowAddrReq;
                if (Counter_WaitClocks == 0) begin
                    NextState = TRCD_PAUSE;
                    Counter_NextWaitClocks = TRCD_PAUSE_WAIT;
                end
            end
            TRCD_PAUSE : begin
                SetNOP();
                o_dqm = 2'b11;
                if (Counter_WaitClocks == 0) begin
                    NextState = RW_CMD;
                    Counter_NextWaitClocks = 0; // Just launch READ_BURST
                end
            end
            RW_CMD : begin
                o_addr[ColAddrLen-1:0] = Register_ColAddrReq;
                o_addr[10] = 1; // reading with auto-precharge
                o_dqm = 2'b00;
                if (Switch_OperationRead) begin
                    SetRead();
                    NextState = TCL_PAUSE;
                    Counter_NextWaitClocks = TCL_PAUSE_WAIT;
                end else begin 
                    SetWrite();
                    Register_o_valid_wr = 1'b1;
                    NextState = RW_WORD;
                    Counter_NextWaitClocks = 0;
                end
            end
            TCL_PAUSE : begin
                SetNOP();
                o_dqm = 2'b11;
                if (Counter_WaitClocks == 0) begin
                    NextState = RW_WORD;
                    Counter_NextWaitClocks = 0;
                end
            end
            RW_WORD : begin
                SetNOP();
                o_bank = Register_BankAddrReq; // just to be on the safe side
                o_dqm = 2'b00;
                if (Counter_BurstWordsLeft > 0) begin 
                    Register_o_valid_wr = ~Switch_OperationRead;
                    Register_o_valid_rd = Switch_OperationRead;
                end else begin
                    NextState = TRP_PAUSE;
                    Counter_NextWaitClocks = (Switch_OperationRead) ?  TRP_PAUSE_WAIT : TRP_PAUSE_WAIT + SET_MODE_WAIT; // + 2*TCK for burst write
                end
            end
            TRP_PAUSE : begin
                SetNOP();
                o_dqm = 2'b11;
                if (Counter_WaitClocks == 0) begin
                    NextState = IDLE;
                    Counter_NextWaitClocks = 0;
                end
            end
            default : begin
            end
        endcase
    end
    
endmodule

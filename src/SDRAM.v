`timescale 1ns / 1ns


// ----------
// A minimalistic SDRAM controller, originally written for Winbond W9825G6KH
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
    inout [WordLength-1:0] io_data,     // SDRAM's data bus
    output reg o_clk_en,                // Clock Enable
    output reg o_cs_n,                  // Select SDRAM signal
    output reg o_ras_n,                 // Select a row #o_addr
    output reg o_cas_n,                 // Select a column #o_addr
    output reg o_we_n,                  // On 1, write selected data, on 0 - read it
    output reg [12:0] o_addr,           // SDRAM's address bus
    output reg [1:0] o_bank,            // SDRAM's bank selector
    output reg [1:0] o_dqm,             // SDRAM's mask for input/output
    output wire [WordLength-1:0] o_data,// Data read from SDRAM
    output wire o_valid,                // Signals user that they can set the data to write/read the data
    output wire o_busy                  // User cannot send commands to the controller
);
    
    localparam  IDLE          = 4'b0000, // 
                PRECHARGE_ALL = 4'b0001, //
                SET_MODE      = 4'b0010, //
                REFRESH       = 4'b0011, //
                ACTIVATE      = 4'b0100, //
                RW_WORD       = 4'b0101, //
                RW_CMD        = 4'b0110, //
                INIT_PAUSE    = 4'b0111, //
                TRCD_PAUSE    = 4'b1000,// An addition to respect the wait between activate and read/write
                TCL_PAUSE     = 4'b1001,
                TRP_PAUSE     = 4'b1010,
                REFRESH_PAUSE = 4'b1011;
              
    
    localparam  INIT_PAUSE_WAIT     = ClockFrequency / 50_000_000 * 10_000, // 200μs of powerup time
                PRECHARGE_ALL_WAIT  = ClockFrequency / 50_000_000, // 20ns of precharge time
                SET_MODE_WAIT       = ClockFrequency / 50_000_000 + 1, // 2 * 10ns for W9825G6KH-6, +1 for safety
                REFRESH_PAUSE_WAIT        = ClockFrequency / 50_000_000 * 3, // 60ns each for 8 times
                TRCD_PAUSE_WAIT     = ClockFrequency / 50_000_000, // 20ns between ACTIVATE and READ/WRITE
                TCL_PAUSE_WAIT      = 3, // three clock cycles since using CAS latency of 3
                TRP_PAUSE_WAIT      = PRECHARGE_ALL_WAIT; // 20ns between PRECHARGE and ACTIVE
    
    localparam REFRESH_AFTER_MSR_CYCLE = 8; // for W9825G6KH
    reg [$clog2(REFRESH_AFTER_MSR_CYCLE)-1:0] Counter_RefreshCyclesDone;
    reg [$clog2(REFRESH_AFTER_MSR_CYCLE)-1:0] CurrRefreshRequired = REFRESH_AFTER_MSR_CYCLE;
    reg Switch_RefreshIsAfterMSR;

    reg [15:0] Counter_WaitClocks, Counter_NextWaitClocks; // I guess max of 2**16 NOPS
    
    task SetNOP;
        begin
            o_cs_n = 1'b0;
            o_ras_n = 1'b1;
            o_cas_n = 1'b1;
            o_we_n = 1'b1;
        end
    endtask
    
    task SetPrecharge;
        begin
            o_cs_n = 1'b0;
            o_ras_n = 1'b0;
            o_cas_n = 1'b1;
            o_we_n = 1'b0;
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
            o_clk_en = 1'b1;
            o_cs_n = 1'b0;
            o_ras_n = 1'b0;
            o_cas_n = 1'b0;
            o_we_n = 1'b1;
        end
    endtask
    
    task SetActivate;
        begin
            o_cs_n = 1'b0;
            o_ras_n = 1'b0; 
            o_cas_n = 1'b1;     
            o_we_n = 1'b1;
        end
    endtask
    
    task SetRead;
        begin
            o_clk_en = 1'b1;
            o_cs_n = 1'b0;
            o_ras_n = 1'b1;
            o_cas_n = 1'b0;
            o_we_n = 1'b1;
        end
    endtask
    
    task SetWrite;
        begin
            o_clk_en = 1'b1;
            o_cs_n = 1'b0;
            o_ras_n = 1'b1;
            o_cas_n = 1'b0;
            o_we_n = 1'b0;
        end
    endtask
    
    reg [3:0] CurrentState, NextState;
    
    // Multiplexed addresses requested by user on the i_addr
    reg [BankAddrLen-1:0] Register_BankAddrReq; // i_addr[AddressWidth-1 : AddressWidth-BankAddrLen]
    reg [RowAddrLen-1:0] Register_RowAddrReq; // i_addr[AddressWidth-BankAddrLen-1 : AddressWidth-BankAddrLen-RowAddrLen];
    reg [ColAddrLen-1:0] Register_ColAddrReq; // i_addr[AddressWidth-BankAddrLen-RowAddrLen-1 : AddressWidth-BankAddrLen-RowAddrLen-ColAddrLen];

    reg [1:0] Switch_OperationRead; // 0 for write, 1 for read
    reg [$clog2(BurstLength)-1:0] Counter_BurstWordsLeft;
    reg [WordLength-1:0] Register_o_data;
    reg Register_o_valid;
    
    assign o_busy = (CurrentState != IDLE || (CurrentState == IDLE && NextState == ACTIVATE));
    assign o_data = Register_o_data;
    assign o_valid = Register_o_valid;

    wire [WordLength-1:0] DataToReadFromSDRAM; // controller writes to SDRAM from here
    reg [WordLength-1:0] DataToWriteToSDRAM; // controller reads from SDRAM into here
    reg Switch_TristateWriteToSDRAM;

    assign io_data = Switch_TristateWriteToSDRAM ? DataToWriteToSDRAM : {WordLength{1'bz}};

    assign DataToReadFromSDRAM = io_data;
    
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            CurrentState <= INIT_PAUSE;
            Counter_WaitClocks <= INIT_PAUSE_WAIT; // 200ns for the initial pause
            Counter_BurstWordsLeft <= 0;
            Register_o_data <= 0;
            Register_o_valid <= 1'b0;
            Switch_TristateWriteToSDRAM <= 1'b0;
        end else begin
            if (NextState == ACTIVATE) begin
                Register_BankAddrReq <= i_addr[AddressWidth-1 : AddressWidth-BankAddrLen];
                Register_RowAddrReq <= i_addr[AddressWidth-BankAddrLen-1 : AddressWidth-BankAddrLen-RowAddrLen];
                Register_ColAddrReq <= i_addr[AddressWidth-BankAddrLen-RowAddrLen-1 : AddressWidth-BankAddrLen-RowAddrLen-ColAddrLen]; 
            end else if (NextState == RW_WORD && CurrentState != RW_WORD) begin
                Switch_TristateWriteToSDRAM <= (Switch_OperationRead) ? 1'b0 : 1'b1;
                Counter_BurstWordsLeft <= BurstLength;
            end else if (CurrentState == RW_WORD) begin
                if (Switch_OperationRead) begin
                    Register_o_data <= DataToReadFromSDRAM;
                end else begin
                    DataToWriteToSDRAM <= i_data;
                end 
                Counter_BurstWordsLeft <= Counter_BurstWordsLeft - 1;
                if (Counter_BurstWordsLeft > 0) begin
                    Register_o_valid <= 1'b1;
                end
            end else begin
                Register_o_valid <= 1'b0;
                Register_o_data <= 0;
            end
            Counter_WaitClocks <= Counter_WaitClocks - 1;
            if (Counter_WaitClocks == 0) begin
                Counter_WaitClocks <= Counter_NextWaitClocks;
                if (CurrentState == REFRESH) begin
                    Counter_RefreshCyclesDone <= Counter_RefreshCyclesDone + 1;
                end
            end
            CurrentState <= NextState;
        end
    end

    always @(*) begin
        Counter_NextWaitClocks = 0;
        NextState = 0;
        Switch_OperationRead = 0;
        o_addr = 0;
        o_bank = 0;
        o_cas_n = 0;
        o_clk_en = 1;
        o_cs_n = 0;
        o_dqm = 0;
        o_ras_n = 0;
        o_we_n = 0;
        Switch_RefreshIsAfterMSR = 0;
        case (CurrentState)
            INIT_PAUSE : begin
                SetNOP();
                o_clk_en = 1'b1;
                o_dqm = 2'b11;
                if (Counter_WaitClocks == 0) begin
                    NextState = PRECHARGE_ALL;
                    Counter_NextWaitClocks = PRECHARGE_ALL_WAIT;
                end else begin
                    NextState = INIT_PAUSE;
                end
            end
            PRECHARGE_ALL : begin
                SetPrecharge();
                o_addr[10] = 1'b1;
                if (Counter_WaitClocks == 0) begin
                    NextState = SET_MODE;
                    Counter_NextWaitClocks = SET_MODE_WAIT;
                end else begin
                    NextState = PRECHARGE_ALL;
                end
            end
            SET_MODE : begin
                SetMode();
                if (Counter_WaitClocks == 0) begin
                    NextState = REFRESH;
                    Counter_NextWaitClocks = 0;
                    Switch_RefreshIsAfterMSR = 1;
                end else begin
                    NextState = SET_MODE;
                end
            end
            REFRESH : begin
                SetRefresh();
                NextState = REFRESH_PAUSE;
                Counter_NextWaitClocks = REFRESH_PAUSE_WAIT;
            end
            REFRESH_PAUSE : begin
                SetNOP();
                if (Counter_WaitClocks == 0) begin
                    if (Counter_RefreshCyclesDone < CurrRefreshRequired) begin // might be 8 for MSR or 1 for casual
                        NextState = REFRESH;
                        Counter_NextWaitClocks = 0;
                    end else begin
                        NextState = IDLE;
                        Counter_NextWaitClocks = 0;
                    end
                end else begin
                    NextState = REFRESH_PAUSE;
                end
            end
            IDLE : begin
                SetNOP();
                o_dqm = 2'b11;
                if (i_enable && !o_busy) begin
                    Switch_OperationRead = i_rw;
                    NextState = ACTIVATE;
                    Counter_NextWaitClocks = 0; // just launch ACTIVATE
                end else begin
                    NextState = IDLE;
                end
            end
            ACTIVATE : begin
                SetActivate();
                o_dqm = 2'b11;
                o_bank = Register_BankAddrReq;
                o_addr = Register_RowAddrReq;
                if (Counter_WaitClocks == 0) begin
                    NextState = TRCD_PAUSE;
                    Counter_NextWaitClocks = TRCD_PAUSE_WAIT; // Activated, now waiting for 
                end else begin
                    NextState = ACTIVATE;
                end
            end
            TRCD_PAUSE : begin
                SetNOP();
                o_dqm = 2'b11;
                if (Counter_WaitClocks == 0) begin
                    NextState = RW_CMD;
                    Counter_NextWaitClocks = 1; // Just launch READ_BURST
                end else begin
                    NextState = TRCD_PAUSE;
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
                end else begin
                    NextState = TCL_PAUSE;
                end
            end
            RW_WORD : begin
                o_dqm = 2'b00;
                if (Counter_BurstWordsLeft == 0) begin
                    NextState = TRP_PAUSE;
                    Counter_NextWaitClocks = (Switch_OperationRead) ?  TRP_PAUSE_WAIT : TRP_PAUSE_WAIT + SET_MODE_WAIT; // + 2*TCK for burst write
                end else begin
                    NextState = RW_WORD;
                end
            end
            TRP_PAUSE : begin
                SetNOP();
                o_dqm = 2'b11;
                if (Counter_WaitClocks == 0) begin
                    NextState = IDLE;
                    Counter_NextWaitClocks = 0;
                end else begin
                    NextState = TRP_PAUSE;
                end
            end
            default : begin
            end
        endcase
    end
    
endmodule

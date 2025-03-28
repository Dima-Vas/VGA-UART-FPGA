`timescale 1ns / 1ps

// READ IN BURST THE ENTIRE ROW
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
    parameter ReadBurstLength = 8
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
    output wire [WordLength-1:0] o_data, // Data read from SDRAM
    output wire o_valid,                 // Data is valid
    output wire o_busy                  // User cannot send commands to the controller
);
    
    localparam  IDLE          = 4'b0000, // 
                PRECHARGE_ALL = 4'b0001, //
                SET_MODE      = 4'b0010, //
                REFRESH       = 4'b0011, //
                ACTIVATE      = 4'b0100, //
                WRITE_WORD    = 4'b0101, //
                READ_CMD      = 4'b0110, //
                INIT_PAUSE    = 4'b0111, //
                TRCD_PAUSE    = 4'b1000,// An addition to respect the wait between activate and read/write
                TCL_PAUSE     = 4'b1001,
                READ_WORD     = 4'b1010;
              
    
    localparam  INIT_PAUSE_WAIT     = ClockFrequency / 5_000_000, // 200ns
                PRECHARGE_ALL_WAIT  = ClockFrequency / 50_000_000, // 20ns of precharge time
                SET_MODE_WAIT       = ClockFrequency / 50_000_000, // 2 * 10ns for W9825G6KH
                REFRESH_WAIT        = 8 * (ClockFrequency * 60 / 1_000_000_000 ), // needs exactly 8 refresh cycles, 60ns each
                TRCD_PAUSE_WAIT     = ClockFrequency / 50_000_000, // 20ns between ACTIVATE and READ/WRITE
                TCL_PAUSE_WAIT      = 3; // three clock cycles since using CAS latency of 3

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
            o_addr[9] = 1'b1; // Burst read and single write
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
            o_cs_n = 1'b0;
            o_ras_n = 1'b1;
            o_cas_n = 1'b0;
            o_we_n = 1'b1;
        end
    endtask
    
    task SetWrite;
        begin
            
        end
    endtask
    
    reg [3:0] CurrentState, NextState;
    
    // Multiplexed addresses requested by user on the i_addr
    assign BankAddrReq =  i_addr[AddressWidth-1 : AddressWidth-BankAddrLen];
    assign RowAddrReq = i_addr[AddressWidth-BankAddrLen-1 : AddressWidth-BankAddrLen-RowAddrLen];
    assign ColAddrReq = i_addr[AddressWidth-BankAddrLen-RowAddrLen-1 : AddressWidth-BankAddrLen-RowAddrLen-ColAddrLen];
    
    reg [ColAddrLen-1:0] ColAddrSaved;
    reg [1:0] Switch_OperationReq; // 0 for write, 1 for read
    reg [$clog2(ReadBurstLength)-1:0] Counter_BurstWordsLeft;
    reg [WordLength-1:0] Register_o_data;
    reg Register_o_valid;
    
    assign o_busy = (CurrentState != IDLE);
    assign o_data = Register_o_data;
    assign o_valid = Register_o_valid;
    
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            CurrentState <= INIT_PAUSE;
            Counter_WaitClocks <= INIT_PAUSE_WAIT; // 200ns for the initial pause
            Counter_BurstWordsLeft <= 0;
            Register_o_data <= 0;
            Register_o_valid <= 1'b0;
        end else begin
            Counter_WaitClocks <= Counter_WaitClocks - 1;
            if (Counter_WaitClocks == 0) begin
                Counter_WaitClocks <= Counter_NextWaitClocks;
            end
            CurrentState <= NextState;
            Register_o_valid <= 1'b0;
            if (NextState == READ_CMD) begin
                Counter_BurstWordsLeft <= ReadBurstLength;
            end else if (CurrentState == READ_WORD) begin
                Counter_BurstWordsLeft <= Counter_BurstWordsLeft - 1;
                Register_o_data <= io_data; // need to revise this latching
                Register_o_valid <= 1'b1;
            end
        end
    end
     
    always @(*) begin
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
                    Counter_NextWaitClocks = REFRESH_WAIT;
                end else begin
                    NextState = SET_MODE;
                end
            end
            REFRESH : begin
                SetRefresh();
                if (Counter_WaitClocks == 0) begin
                    NextState = IDLE;
                    Counter_NextWaitClocks = 0; // do nothing until a read/write command comes
                end else begin
                    NextState = REFRESH;
                end
            end
            IDLE : begin
                SetNOP();
                o_clk_en = 1'b1;
                o_dqm = 2'b11;
                if (i_enable) begin
                    Switch_OperationReq = i_rw;
                    NextState = ACTIVATE;
                    Counter_NextWaitClocks = 1; // just launch ACTIVATE
                end else begin
                    NextState = IDLE;
                end
            end
            ACTIVATE : begin
                SetActivate();
                o_bank = BankAddrReq;
                o_addr = RowAddrReq;
                ColAddrSaved = ColAddrReq; // saving for Read/Write
                if (Counter_WaitClocks == 0) begin
                    NextState = TRCD_PAUSE;
                    Counter_NextWaitClocks = TRCD_PAUSE_WAIT; // Activated, now waiting for 
                end else begin
                    NextState = ACTIVATE;
                end
            end
            TRCD_PAUSE : begin
                SetNOP();
                if (Counter_WaitClocks == 0) begin
                    NextState = (Switch_OperationReq) ? READ_CMD : WRITE_WORD;
                    Counter_NextWaitClocks = 1; // Just launch READ_BURST
                end else begin
                    NextState = TRCD_PAUSE;
                end
            end
            READ_CMD : begin
                SetRead();
                o_addr[ColAddrLen-1:0] = ColAddrSaved;
                o_addr[10] = 1; // reading with auto-precharge
                NextState = TCL_PAUSE;
                Counter_NextWaitClocks = TCL_PAUSE_WAIT;
            end
            TCL_PAUSE : begin
                SetNOP();
                if (Counter_WaitClocks == 0) begin
                    NextState = READ_WORD;
                    Counter_NextWaitClocks = 1; // Just launch READ_WORD
                end else begin
                    NextState = TCL_PAUSE;
                end
            end
            READ_WORD : begin
                if (Counter_BurstWordsLeft == 1) begin
                    NextState = IDLE;
                    Counter_NextWaitClocks = 0;
                end else begin
                    NextState = READ_WORD;
                end
            end
            WRITE_WORD : begin
                
            end
            default : begin
            end
        endcase
    end
    
endmodule

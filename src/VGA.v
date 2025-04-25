`timescale 1ns / 1ps

// ----------
// A VGA hardware management module, outputs the Y+U/V pixel pair, MSB first. 
// ----------
module VGA #(
    parameter ClockFrequency = 50_000_000,
    parameter ClockFrequencyPCLK = 6_144_000,
    parameter ClockFrequencySCCB = 200_000,
    parameter PixelBitWidth = 16,
    parameter FrameWidth = 640,
    parameter FrameHeight = 480,
    parameter ActiveFrameWidth = 512,
    parameter ActiveFrameHeight = 384
)(
    input wire CLK, p_clk, RST,
    input wire h_sync,
    input [7:0] i_data,
    inout o_sio_d,
    output wire o_sio_c,
    output wire [PixelBitWidth-1:0] o_data,
    output wire o_ready
);
    
    localparam TransferNumberSCCB = 11; 

    reg Switch_FirstByteRead;
    reg Switch_PixelReady;
    reg [PixelBitWidth-1:0] Pixel;
    
    reg [7:0] SCCB_i_data;
    reg [7:0] SCCB_i_addr;
    reg SCCB_i_ready;
    wire SCCB_o_busy;
    
    reg Switch_SetupSCCB;
    reg Register1_Switch_SetupSCCB;
    reg Register2_Switch_SetupSCCB;
    
    reg [7:0] SetupAddrSCCB;
    reg [7:0] SetupDataSCCB;
    
    reg [$clog2(TransferNumberSCCB)-1:0] Counter_CurrTransferSCCB;
    
    (* keep = "true" *) reg [31:0] Counter_PCLK;
    (* keep = "true" *) reg [31:0] Counter_HSYNC;
    
    always @(posedge p_clk) begin
        if (!RST) begin
            Switch_FirstByteRead <= 1'b0;
            Pixel <= 0;
            Switch_PixelReady <= 1'b0;
            Counter_PCLK <= 0;
        end else begin
            Register1_Switch_SetupSCCB <= Switch_SetupSCCB;
            Register2_Switch_SetupSCCB <= Register1_Switch_SetupSCCB;
            if (!Register2_Switch_SetupSCCB) begin
                if (Switch_FirstByteRead == 1'b0) begin
                  Pixel[15:8] <= i_data;
                  Switch_PixelReady <= 1'b0;
                  Switch_FirstByteRead <= 1'b1;
                end else begin
                  Pixel[7:0] <= i_data;
                  Switch_PixelReady <= 1'b1;
                  Switch_FirstByteRead <= 1'b0;
                end
            end else begin
              Switch_PixelReady <= 1'b0;
            end 
        end
    end
    
    reg Register_Switch_PixelReady;
    reg Register2_Switch_PixelReady;
    
    reg Register_SCCB_o_busy;
    reg Register2_SCCB_o_busy;
    reg [PixelBitWidth-1:0] Register_Pixel;
    
    assign o_ready = (Register2_Switch_PixelReady == 1'b0 && Register_Switch_PixelReady == 1'b1) ? 1'b1 : 1'b0;
    assign o_data = Register_Pixel;
    
    always @(posedge CLK) begin
        if (!RST) begin
            SCCB_i_ready <= 1'b0;
            Switch_SetupSCCB <= 1'b1;
            Counter_HSYNC <= 0;
            Register_Switch_PixelReady <= 1'b0;
            Counter_CurrTransferSCCB <= 1'b0;
        end else begin
            Register_Switch_PixelReady <= Switch_PixelReady;
            Register2_Switch_PixelReady <= Register_Switch_PixelReady;
            Register_SCCB_o_busy <= SCCB_o_busy;
            Register2_SCCB_o_busy <= Register_SCCB_o_busy;
            Register_Pixel <= Pixel;
            if (Switch_SetupSCCB) begin
                if (Register2_SCCB_o_busy && SCCB_i_ready) begin // SCCB module took the input
                    SCCB_i_ready <= 1'b0;
                    Counter_CurrTransferSCCB <= Counter_CurrTransferSCCB + 1;
                end else if (!SCCB_o_busy) begin
                    if (Counter_CurrTransferSCCB == TransferNumberSCCB) begin
                        Switch_SetupSCCB <= 1'b0;
                    end else begin
                        SCCB_i_addr <= SetupAddrSCCB;
                        SCCB_i_data <= SetupDataSCCB;
                        SCCB_i_ready <= 1'b1;
                    end
                end
            end
        end
    end
        
    always @(*) begin // ugly, but the best way to declare the byte array in Verilog
        case (Counter_CurrTransferSCCB)
            0: begin SetupAddrSCCB = 8'h12; SetupDataSCCB = 8'h80; end
            1: begin SetupAddrSCCB = 8'hFF; SetupDataSCCB = 8'hFF; end
            2: begin SetupAddrSCCB = 8'h11; SetupDataSCCB = 8'h01; end
            3: begin SetupAddrSCCB = 8'h12; SetupDataSCCB = 8'h00; end
            4: begin SetupAddrSCCB = 8'h15; SetupDataSCCB = 8'h02; end
            5: begin SetupAddrSCCB = 8'h6B; SetupDataSCCB = 8'h0A; end
            6: begin SetupAddrSCCB = 8'h92; SetupDataSCCB = 8'hFF; end
            7: begin SetupAddrSCCB = 8'h93; SetupDataSCCB = 8'h01; end
            8: begin SetupAddrSCCB = 8'h0C; SetupDataSCCB = 8'h00; end
            9: begin SetupAddrSCCB = 8'h3E; SetupDataSCCB = 8'h0E; end
            10: begin SetupAddrSCCB = 8'h3A; SetupDataSCCB = 8'h04; end
            default: begin SetupAddrSCCB = 8'h00; SetupDataSCCB = 8'h00; end
        endcase
    end
    
    SCCB #(ClockFrequency, ClockFrequencySCCB) sccb(
        .CLK(CLK),
        .RST(RST),
        .i_data(SCCB_i_data),
        .i_addr(SCCB_i_addr),
        .i_ready(SCCB_i_ready),
        .o_sio_d(o_sio_d),
        .o_sio_c(o_sio_c),
        .o_busy(SCCB_o_busy)
    );
endmodule

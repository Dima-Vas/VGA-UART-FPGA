`timescale 1ns/1ps

module UART_tb;
  parameter ClockFrequency = 50_000_000;
  parameter BaudRate = 2_340_000;
  parameter BufferSize = 32768;
  
  localparam TicksPerBit = ClockFrequency / BaudRate;
  localparam FrameWidth = 10;
  
  reg CLK;
  reg RST;
  reg i_ready;
  reg [7:0] i_frame;
  wire o_data;
  wire o_ready;
  
  UART #(ClockFrequency,
         BaudRate,
         BufferSize) uut (
    .CLK(CLK),
    .RST(RST),
    .i_ready(i_ready),
    .i_frame(i_frame),
    .o_data(o_data),
    .o_ready(o_ready)
  );
  
  initial begin
    CLK = 0;
    forever #10 CLK = ~CLK;
  end
  
  initial begin
    RST = 0;
    #100;
    RST = 1;
  end
  
  initial begin
    i_ready = 0;
    i_frame = 8'h55;
    
    @(posedge RST);
    #50;
        
    // 10 bits are being transmitted
    #(TicksPerBit * FrameWidth * 20);
    
    i_frame = 8'h55;
    i_ready = 1;
    #20;
    i_ready = 0;
    
    #(TicksPerBit * FrameWidth * 20);
    
    i_frame = 8'h55;
    i_ready = 1;
    #20;
    i_ready = 0;
    
    #1000000;
    $finish;
  end
  
  initial begin
    $monitor("Time=%0t | o_data=%b", $time, o_data);
  end
  
endmodule
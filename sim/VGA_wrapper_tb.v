`timescale 1ns / 1ps

module VGA_wrapper_tb;

  reg CLK;
  reg RST;
  reg p_clk;
  reg h_sync;
  reg v_sync;
  reg [7:0] i_data;
  wire [15:0] io_data;


  wire x_clk;
  wire o_sio_c;
  wire o_sio_d;
  wire o_clk_en;
  wire o_cs_n;
  wire o_ras_n;
  wire o_cas_n;
  wire o_we_n;
  wire [12:0] o_addr;
  wire [1:0] o_bank;
  wire [1:0] o_dqm;
  wire o_data;

  parameter CLK_PERIOD = 20;
  parameter PCLK_PERIOD = 40;

  initial begin
    CLK = 0;
    forever #(CLK_PERIOD/2) CLK = ~CLK;
  end

  initial begin
    p_clk = 0;
    forever #(PCLK_PERIOD/2) p_clk = ~p_clk;
  end

  initial begin
    RST = 0;
    #100;
    RST = 1;
  end

  initial begin
    h_sync = 0;
    v_sync = 0;
    i_data = 8'h00;

    #200000000;
    $finish;
  end
  

  initial begin
  end

  VGA_wrapper #(
      .ClockFrequency(50_000_000),
      .ClockFrequencyXCLK(12_500_000),
      .ClockFrequencyPCLK(25_000_000),
      .ClockFrequencySCCB(200_000),
      .FrameWidth(640),
      .FrameHeight(480),
      .ActiveFrameWidth(512),
      .ActiveFrameHeight(384),
      .PixelBitWidth(16),
      .BaudRateUART(2_343_750),
      .BufferSizeUART(16384),
      .WordLengthSDRAM(16),
      .BurstLengthSDRAM(8),
      .BankAddrLengthSDRAM(2),
      .RowAddrLengthSDRAM(13),
      .ColAddrLengthSDRAM(9),
      .AddressWidthSDRAM(24)
  ) dut (
      .CLK(CLK),
      .RST(RST),
      .p_clk(p_clk),
      .h_sync(h_sync),
      .v_sync(v_sync),
      .i_data(i_data),
      .io_data(io_data),
      .x_clk(x_clk),
      .o_sio_c(o_sio_c),
      .o_sio_d(o_sio_d),
      .o_clk_en(o_clk_en),
      .o_cs_n(o_cs_n),
      .o_ras_n(o_ras_n),
      .o_cas_n(o_cas_n),
      .o_we_n(o_we_n),
      .o_addr(o_addr),
      .o_bank(o_bank),
      .o_dqm(o_dqm),
      .o_data(o_data)
  );
  
  
  reg [7:0] CurrData = 8'd0;
  
  always @(posedge p_clk) begin
    if (RST && ~dut.vga.Switch_SetupSCCB) begin
        i_data <= CurrData;
        CurrData <= (CurrData + 1) % 256;
    end
  end
  
parameter CAS_LATENCY = 3;

reg [15:0] SDRAM_DATA [0:1][0:8191][0:511]; 

reg [12:0] active_row [0:1];
reg        row_open   [0:1];

reg [8:0]  burst_col;
reg [2:0]  burst_cnt;
reg       in_burst;
reg       do_read;

assign io_data = (io_data_oe) ? io_data_drv : 16'bz;
wire [15:0] io_data_in = io_data;

reg [15:0] io_data_drv;
reg        io_data_oe;

reg [15:0] read_pipeline [0:CAS_LATENCY-1];
reg [$clog2(CAS_LATENCY):0] pipe_idx;
reg                         pipe_valid;

always @(posedge CLK) begin
  io_data_oe <= 0;

  if (!o_cs_n) begin
    if (!o_ras_n && o_cas_n && o_we_n) begin
      // ACTIVATE
      active_row[o_bank] <= o_addr;
      row_open[o_bank] <= 1;
    end else if (o_ras_n && !o_cas_n && row_open[o_bank]) begin
      burst_col <= o_addr;
      burst_cnt <= 0;
      in_burst <= 1;

      if (!o_we_n) begin
        // WRITE
        SDRAM_DATA[o_bank][active_row[o_bank]][o_addr[8:0]] <= io_data_in;
        do_read <= 0;
      end else begin
        // READ
        read_pipeline[0] <= SDRAM_DATA[o_bank][active_row[o_bank]][o_addr[8:0]];
        pipe_idx <= 1;
        pipe_valid <= 1;
        do_read <= 1;
      end
    end else if (!o_ras_n && o_cas_n && !o_we_n) begin
      // PRECHARGE
      row_open[o_bank] <= 0;
    end
  end

  // CAS latency respect
  if (pipe_valid) begin
    if (pipe_idx < CAS_LATENCY) begin
      read_pipeline[pipe_idx] <= SDRAM_DATA[o_bank][active_row[o_bank]][burst_col + pipe_idx];
      pipe_idx <= pipe_idx + 1;
    end else begin
      io_data_drv <= read_pipeline[CAS_LATENCY - 1];
      io_data_oe <= 1;
      pipe_valid <= 0;
    end
  end

  // Bursts for writes
  if (in_burst && !do_read) begin
    burst_cnt <= burst_cnt + 1;
    if (burst_cnt < 8) begin
      burst_col <= burst_col + 1;
      SDRAM_DATA[o_bank][active_row[o_bank]][burst_col + 1] <= io_data_in;
    end else begin
      in_burst <= 0;
    end
  end else if (in_burst && !pipe_valid && do_read) begin
    burst_cnt <= burst_cnt + 1;
    if (burst_cnt < 8) begin
      burst_col <= burst_col + 1;
      read_pipeline[0] <= SDRAM_DATA[o_bank][active_row[o_bank]][burst_col + 1];
      pipe_idx <= 1;
      pipe_valid <= 1;
    end else begin
      in_burst <= 0;
    end
  end
end


endmodule
`timescale 1ns / 1ps


module XCLK #(
    parameter ClockFrequency = 50_000_000,
    parameter OutputClockFrequency = 12_500_000
) (
    input wire i_clk,
    output wire o_clk
    );
    
    localparam ClockPeriod = 1_000_000_000 / ClockFrequency;
    localparam Divider = ClockFrequency / OutputClockFrequency;
    
    wire clkfb;
    
    PLL_ADV #(
        .CLKIN1_PERIOD(ClockPeriod),
        .CLKFBOUT_MULT(1),
        .CLKOUT0_DIVIDE(Divider)
    ) pll (
        .CLKFBOUT(clkfb),
        .CLKFBIN(clkfb),
        .CLKIN1(i_clk),
        .CLKOUT0(o_clk)
    );
endmodule

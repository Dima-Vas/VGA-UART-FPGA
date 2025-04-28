`timescale 1ns / 1ps

module SCCB_tb;

    parameter ClockFrequency = 50_000_000;
    parameter ClockFrequencySCCB = 400_000;
    parameter CLK_PERIOD = (1_000_000_000 / ClockFrequency);

    reg  CLK;
    reg  RST;
    reg  [7:0] tb_i_data;
    reg  [7:0] tb_i_addr;
    reg  tb_i_ready;

    wire o_sio_c;
    wire o_busy;
    wire o_sio_d;
    wire sio_d_bus;

    reg  simulate_ack;
    reg  [3:0] sccb_bit_count;
    reg  [1:0] sccb_phase_count;
    reg  sccb_transfer_active;

    // For edge detection
    reg  o_sio_c_prev;
    reg  sio_d_bus_prev;
    wire sio_c_falling_edge;
    wire sio_d_falling_edge;
    wire sio_d_rising_edge;

    SCCB #(
        .ClockFrequency(ClockFrequency),
        .ClockFrequencySCCB(ClockFrequencySCCB)
    ) dut (
        .CLK(CLK),
        .RST(RST),
        .i_data(tb_i_data),
        .i_addr(tb_i_addr),
        .i_ready(tb_i_ready),
        .o_sio_d(o_sio_d),
        .o_sio_c(o_sio_c),
        .o_busy(o_busy)
    );

    initial begin
        CLK = 1'b0;
        forever #(CLK_PERIOD / 2.0) CLK = ~CLK;
    end

    initial begin
        RST = 1'b0;
        o_sio_c_prev = 1'b1;
        sio_d_bus_prev = 1'b1;
        #(CLK_PERIOD * 10);
        RST = 1'b1;
    end

    assign sio_d_bus = (o_sio_d !== 1'bz) ? o_sio_d : // If DUT gives 0 or 1, use this value
                       (simulate_ack)        ? 1'b0        : // If Don't-Care, set low
                                               1'b1;         // No ACKers here, bus is 1

    always @(posedge CLK) begin
        o_sio_c_prev   <= o_sio_c;
        sio_d_bus_prev <= sio_d_bus;
    end

    assign sio_c_falling_edge = (o_sio_c_prev == 1'b1 && o_sio_c == 1'b0);
    assign sio_d_falling_edge = (sio_d_bus_prev == 1'b1 && sio_d_bus == 1'b0);
    assign sio_d_rising_edge  = (sio_d_bus_prev == 1'b0 && sio_d_bus == 1'b1);

    // START = SIO_C 1, SIO_D 1->0, not active already
    // STOP = SIO_C 1 SIO_D 0->1, active already
    assign sccb_start_detected = o_sio_c && sio_d_falling_edge && !sccb_transfer_active;
    assign sccb_stop_detected = o_sio_c && sio_d_rising_edge && sccb_transfer_active;


    always @(posedge CLK) begin
        if (!RST) begin
            sccb_transfer_active <= 1'b0;
            sccb_bit_count       <= 4'd0;
            sccb_phase_count     <= 2'd0;
            simulate_ack         <= 1'b0;
        end else begin
            if (sccb_start_detected) begin
                sccb_transfer_active <= 1'b1;
                sccb_bit_count       <= 4'd0;
                sccb_phase_count     <= 2'd0;
            end else if (sccb_stop_detected) begin
                sccb_transfer_active <= 1'b0;
                sccb_bit_count       <= 4'd0;
                sccb_phase_count     <= 2'd0;
            end

            simulate_ack <= 1'b0;

            if (sccb_transfer_active && sio_c_falling_edge) begin
                  $display("[%0t] SCCB Clock Fell, Bit Count = %d -> %d, Phase = %d", $time, sccb_bit_count, (sccb_bit_count==8)?0:sccb_bit_count+1, sccb_phase_count);
                if (sccb_bit_count == 8) begin // Don't care is here
                    sccb_bit_count <= 4'd0;
                    if (sccb_phase_count == 2) begin
                    end else begin
                        sccb_phase_count <= sccb_phase_count + 1;
                    end
                end else begin
                    sccb_bit_count <= sccb_bit_count + 1; // Count data bits 0 through 7, then ACK bit (as 8)
                end
            end

        end
    end

    initial begin
        tb_i_data = 8'h00;
        tb_i_addr = 8'h00;
        tb_i_ready = 1'b0;

        wait (RST === 1'b1);

        $display("[%0t] Transaction 1 (Addr: 0x%0h, Data: 0x%0h)", $time, 8'h11, 8'h80);
        wait (o_busy === 1'b0);
        @(posedge CLK);
        tb_i_addr = 8'h11;
        tb_i_data = 8'h80;
        tb_i_ready = 1'b1;
        @(posedge CLK);
        tb_i_ready = 1'b0;
        wait (sccb_transfer_active === 1'b1);
        $display("[%0t] Transaction 1 Active", $time);
        wait (sccb_transfer_active === 1'b0);
        $display("[%0t] Transaction 1 completed (STOP detected)", $time);
        #(CLK_PERIOD * 20);

        $display("[%0t] Transaction 2 (Addr: 0x%0h, Data: 0x%0h)", $time, 8'h12, 8'h06);
        wait (o_busy === 1'b0);
        @(posedge CLK);
        tb_i_addr = 8'h11;
        tb_i_data = 8'h80;
        tb_i_ready = 1'b1;
        @(posedge CLK);
        tb_i_ready = 1'b0;
        wait (sccb_transfer_active === 1'b1);
        $display("[%0t] Transaction 2 Active", $time);
        wait (sccb_transfer_active === 1'b0);
        $display("[%0t] Transaction 2 completed (STOP detected)", $time);
        #(CLK_PERIOD * 50);

        $finish;
    end

    initial begin
         $monitor("[%0t] i_rdy=%b i_addr=%h i_data=%h busy=%b SIO_C=%b SIO_D=%b (o_sio_d:%b) ack_sim=%b bit_cnt=%d phase=%d active=%b",
                 $time, tb_i_ready, tb_i_addr, tb_i_data, o_busy, o_sio_c, sio_d_bus, o_sio_d, simulate_ack, sccb_bit_count, sccb_phase_count, sccb_transfer_active);
    end

endmodule
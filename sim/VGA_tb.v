`timescale 1ns / 1ps

module VGA_tb;
    parameter PixelBitWidth = 16;
    
    reg CLK, RST;
    reg h_sync, p_clk;
    reg [7:0] i_data;
    wire [PixelBitWidth-1:0] o_data;
    wire o_ready;
    
    VGA #(PixelBitWidth) dut (
        .CLK(CLK),
        .RST(RST),
        .h_sync(h_sync),
        .p_clk(p_clk),
        .i_data(i_data),
        .o_data(o_data),
        .o_ready(o_ready)
    );

    always #20 CLK = ~CLK;
    always #10 p_clk = ~p_clk;

    integer row, col;
    initial begin
        CLK = 0;
        p_clk = 0;
        RST = 1;
        h_sync = 0;
        i_data = 8'd255;

        RST = 0;
        #100
        RST = 1;
        
        repeat (2) begin  

            for (row = 0; row < 480; row = row + 1) begin
                h_sync = 1;
                #10;
                
                for (col = 0; col < 640; col = col + 1) begin
                    i_data = 8'd255;
                    #10;
                end
                
                h_sync = 0;
                #30;
            end
        end
        $finish;
    end
    

    function integer count_ones(input [PixelBitWidth-1:0] data);
        integer i, count;
        begin
            count = 0;
            for (i = 0; i < PixelBitWidth; i = i + 1) begin
                if (data[i])
                    count = count + 1;
            end
            count_ones = count;
        end
    endfunction
    
    always @(posedge CLK) begin
        if (o_ready) begin
            $display("Row data ready at time %t with number of HIGH bits : %d", $time, count_ones(o_data));
        end else if (o_data == 0) begin
            $display("o_data is zero at time %t", $time);
        end
    end

endmodule

`timescale 1ns / 1ps

// ----------
// A VGA hardware management module, outputs the Y+U/V pixel pair, MSB first. 
// ----------
module VGA #(
    parameter PixelBitWidth = 16
)(
    input wire p_clk, RST,
    input wire h_sync,
    input [7:0] i_data,
    output reg [PixelBitWidth-1:0] o_data,
    output reg o_ready
);

    reg [$clog2(PixelBitWidth)-1:0] Counter_BitsRead;

    always @(posedge p_clk) begin
        if (!RST) begin
            Counter_BitsRead <= 0;
            o_data <= 0;
            o_ready <= 1'b0;
        end else if (h_sync) begin
            o_data[Counter_BitsRead + 7 -: 8] <= i_data; // YU or YV
            Counter_BitsRead <= Counter_BitsRead + 8;
            if (Counter_BitsRead + 8 >= PixelBitWidth) begin // row is read
                o_ready <= 1'b1;
                Counter_BitsRead <= 0;
            end else begin
                o_ready <= 1'b0;
            end 
        end else begin
            o_ready <= 1'b0; // in case h_sync is low but o_ready is not nullified
        end
    end
endmodule

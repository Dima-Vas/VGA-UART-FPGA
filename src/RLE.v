`timescale 1ns / 1ps


// ----------
// A simple value-counting module that outputs the VALUE-AMOUNT pair with a limit of
// 8 bits for the AMOUNT. 
// ----------
module RLE #(
    parameter Thres = 5
)(
    input wire CLK, RST,
    input wire i_ready,
    input [7:0] i_val,
    output reg [7:0] o_val,
    output reg [7:0] o_count,
    output reg o_ready
);

    reg Switch_NewVal;
    
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            o_val <= 0;
            o_count <= 0;
            o_ready <= 1'b0;
            Switch_NewVal <= 1'b1;
        end else if (i_ready) begin
                if (Switch_NewVal) begin // last val was read, clear and start new count
                    o_count <= 1;
                    o_ready <= 1'b0;
                    o_val <= i_val;
                    Switch_NewVal <= 1'b0;
                end else if (o_count == 255 || // should think about what happens when I skip the new i_val here
                            ($signed(i_val) - $signed(o_val) > Thres) ||
                            ($signed(o_val) - $signed(i_val) > Thres)) begin // different val arrived
                    o_ready <= 1'b1;
                    Switch_NewVal <= 1'b1; // give time to read the output
                end else begin
                    o_count <= o_count + 1;
                end
            end
        end
endmodule

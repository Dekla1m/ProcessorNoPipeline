`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.09.2026 09:31:18
// Design Name: 
// Module Name: BRAM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sdp #(
    RAM_W = 7, // Размер слова
    RAM_D = 4 // Размер памяти
)(
    input clk,
    input [$clog2(RAM_D) - 1 : 0] addra, addrb,
    input [RAM_W - 1 : 0] dina,
    input wea,
    input enb,
    output logic [RAM_W - 1 : 0] doutb
    );
    
    (* ram_style = "block" *)
    logic [RAM_W - 1 : 0] BRAM [0 : RAM_D - 1];
    logic [RAM_W - 1 : 0] ram_data;
    
    always_ff@(posedge clk) begin
        if (wea) BRAM[addra] <= dina;
        if (enb) ram_data <= BRAM[addrb]; 
    end
    
    always_comb doutb = ram_data;
endmodule

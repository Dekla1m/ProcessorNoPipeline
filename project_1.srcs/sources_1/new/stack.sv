`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.09.2026 09:42:11
// Design Name: 
// Module Name: stack
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


module stack #(
    RAM_W = 7, // Размер слова
    RAM_D = 4 // Размер памяти
)(
    input clk, rst, push, pop,
    input [RAM_W - 1 : 0] push_data,
    output logic [RAM_W - 1 : 0] pop_data,
    output logic valid, full, empty
    );
    
    localparam ADDR_WIDTH = $clog2 (RAM_D);
    
    (* ram_style = "block" *);
    logic [RAM_W - 1 : 0] mem [0 : RAM_D - 1];
    logic [ADDR_WIDTH : 0] sp; // Указатель на запись
    logic wr_en, rd_en;
    logic [ADDR_WIDTH-1:0] rd_addr;
    
    assign wr_en = !rst && push && !full;
    assign rd_en = !rst && pop  && !empty;
    assign rd_addr = rd_en ? sp[ADDR_WIDTH-1:0] - 1'b1: '0;
     
    always_ff @(posedge clk) 
       if (wr_en) 
        mem[sp[ADDR_WIDTH - 1 : 0]] <= push_data;    
    
    always_ff @(posedge clk) 
        if (rst) 
            pop_data <= '0;
        else if 
            (rd_en) pop_data <= mem[rd_addr];
       
    always_ff @(posedge clk) 
        if (rst) 
            valid <= '0;
        else 
            valid <= '1;
    
    always_comb begin
        full <= sp == RAM_D;
        empty <= (sp == '0);
    end
    
    always_ff @(posedge clk) 
        if (rst) 
            sp <= '0;
        else
            case ({wr_en, rd_en})
                2'b10: sp <= sp + 1;
                2'b01: sp <= sp - 1;
            endcase
endmodule

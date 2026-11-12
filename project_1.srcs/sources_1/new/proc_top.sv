`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.09.2026 10:10:47
// Design Name: 
// Module Name: proc_top
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


module proc_top(
input clk, rst,
input [9:0] prog_addr,
input [67:0] prog_data,
input prog_we,
output need
    );
    
    localparam WORD_SIZE = 16,
               RF_SIZE = 16, RF_ADDR_SIZE = $clog2(RF_SIZE),
               MEM_SIZE = 128, MEM_ADDR_SIZE = $clog2(MEM_SIZE),
               PROG_MEM_SIZE = 1024, PROG_MEM_ADDR_SIZE = $clog2(PROG_MEM_SIZE),
               CMD_SIZE = 68,
               COP_SIZE = 4;
    
    typedef enum logic [COP_SIZE - 1 : 0] {
        LTR, LTM, JMPH, JMPeq, JMP, ADD, RTM, MTR, SliMtoR, RtoSliM //PUSH, POP // Убрать пуш и поп
    } COP_type;
    
    logic [PROG_MEM_ADDR_SIZE - 1 : 0] pc;
    logic [PROG_MEM_ADDR_SIZE - 1 : 0] new_pc;
    logic [WORD_SIZE - 1 : 0] reg_a, new_reg_a, reg_b, new_reg_b, reg_c, new_reg_c;
    logic [CMD_SIZE - 1 : 0] RG_COM;
    logic [WORD_SIZE - 1 : 0] RF [0 : RF_SIZE - 1];
    
    logic [RF_ADDR_SIZE - 1 : 0] r1;
    logic [RF_ADDR_SIZE - 1 : 0] r2;
    logic [RF_ADDR_SIZE - 1 : 0] r3;
    logic [MEM_ADDR_SIZE - 1 : 0] m1;
    logic [WORD_SIZE - 1 : 0] lit;
    logic [PROG_MEM_ADDR_SIZE - 1 : 0] addr_to_jump;
    COP_type cop;
    assign need = pc[1]; // Вынужденный рандон=мный сигнал для синтеза, т.к. Вивадо не будет синтезировать то, у чего нет выхода
    
    always_comb begin
        cop = COP_type'(RG_COM[CMD_SIZE - 1                              -: COP_SIZE]);
        r1  =           RG_COM[CMD_SIZE - 1 - COP_SIZE                   -: RF_ADDR_SIZE];
        r2  =           RG_COM[CMD_SIZE - 1 - COP_SIZE - RF_ADDR_SIZE    -: RF_ADDR_SIZE];
        r3  =           RG_COM[CMD_SIZE - 1 - COP_SIZE - 2*RF_ADDR_SIZE  -: RF_ADDR_SIZE];
        lit =           RG_COM[WORD_SIZE - 1                             : 0];
        m1  =           RG_COM[CMD_SIZE - 1 - COP_SIZE                   -: MEM_ADDR_SIZE];
        addr_to_jump =  RG_COM[PROG_MEM_ADDR_SIZE - 1                     : 0];
    end
    
    logic [1:0] stage_counter;
    always_ff@(posedge clk)
        if (rst || stage_counter == 2)
            stage_counter <= '0;
        else
            stage_counter <= stage_counter + 1;
    
    sdp# (
        .RAM_W(CMD_SIZE),
        .RAM_D(PROG_MEM_SIZE)
    ) PROG (
        .clk,
        .addra(prog_addr),
        .addrb(pc),
        .dina(prog_data),
        .wea(prog_we),
        .enb(stage_counter == 0),
        .doutb(RG_COM)
    );
    
    logic [MEM_ADDR_SIZE - 1 : 0] mem_addr_w;
    logic [MEM_ADDR_SIZE - 1 : 0] mem_addr_r;
    assign mem_addr_r = new_reg_a[MEM_ADDR_SIZE-1:0];
    logic [WORD_SIZE - 1 : 0] mem_data_r;
    
    logic [WORD_SIZE - 1 : 0] mem_data_w;
    
    always_comb // Логика mem_data_w (данных для записи)
        if (stage_counter == 2)
            case (cop)
                LTM : mem_data_w = reg_b;
                RTM : mem_data_w = reg_a;
                RtoSliM:
                    case (reg_c)
                        0: mem_data_w = {reg_b[7:0], mem_data_r[7:0]};
                        1: mem_data_w = {mem_data_r[15:8], reg_b[3:0], mem_data_r[3:0]};
                        2: mem_data_w = {mem_data_r[15:4], reg_b[3:0]};
                        default: mem_data_w = mem_data_r;
                    endcase
                default mem_data_w = '0;
            endcase
        else
            mem_data_w = '0;
    
    always_comb // Логика mem_addr_w (адреса записи)
        case (cop)
            RTM: mem_addr_w = reg_b;
            LTM: mem_addr_w = m1;
            RtoSliM: mem_addr_w = reg_a;
            default: mem_addr_w = '0;
        endcase
   
    logic mem_data_re, mem_data_we;
    assign mem_data_re = stage_counter == 1 && !rst && (cop == MTR || cop == SliMtoR || cop == RtoSliM);
    assign mem_data_we = stage_counter == 2 && !rst && (cop == LTM || cop == RTM || (cop == RtoSliM && reg_c <= 2));
    sdp# (
        .RAM_W(WORD_SIZE),
        .RAM_D(MEM_SIZE)
    ) MEM (
        .clk,
        .addra(mem_addr_w),
        .addrb(mem_addr_r),
        .dina(mem_data_w),
        .wea(mem_data_we),
        .enb(mem_data_re),
        .doutb(mem_data_r)
    );
    
    
//    logic push = (stage_counter == 1 && cop == PUSH); // Не мой
//    logic pop = (stage_counter == 1 && cop == POP);; // Не мой
//    logic [WORD_SIZE - 1 : 0] push_data = new_reg_a;
//    logic [WORD_SIZE - 1 : 0] pop_data = new_reg_b;
//    logic valid;
//    logic full;
//    logic empty;
    
//    stack #(
//        .RAM_W(), // Размер слова
//        .RAM_D(1024) // Размер памяти
//    )(
//        .clk, .rst, 
//        .push, 
//        .pop,
//        .push_data,
//        .pop_data,
//        .valid, 
//        .full, 
//        .empty
//        );
    
    always_ff@(posedge clk) // Комб логика для комб new_reg_a и синхр reg_a
        if (rst)
            reg_a <= '0;
        else
            reg_a <= new_reg_a; 
    
    always_comb // Комбинационная логика reg_a 
        if (stage_counter == 1)
            case(cop)
            JMPH, JMPeq, RTM, SliMtoR, ADD: new_reg_a = RF[r1];
            RtoSliM: new_reg_a = RF[r2];
            MTR: new_reg_a = RF[r1];
            default: new_reg_a = '0;
        endcase
        else
            new_reg_a = '0;
    
    always_ff@(posedge clk) // Комб логика для комб new_reg_b и синхр reg_b
        if (rst)
            reg_b <= '0;
        else
            reg_b <= new_reg_b; 
    
    always_comb // Комбинационная логика reg_b 
        if (stage_counter == 1)
            case(cop)
            LTR, LTM: new_reg_b = lit;
            JMPH, JMPeq, SliMtoR, RTM, ADD: new_reg_b = RF[r2];
            RtoSliM: new_reg_b = RF[r1];
            default: new_reg_b = reg_b;
        endcase
        else
            new_reg_b = '0;
    
    always_ff@(posedge clk) // Комб логика для комб new_reg_c и синхр reg_c
        if (rst)
            reg_c <= '0;
        else
            reg_c <= new_reg_c; 
           
    always_comb // Комбинационная логика reg_c 
        if (stage_counter == 1)
            case(cop)
            RtoSliM, SliMtoR: new_reg_c = lit;
            default: new_reg_c = reg_c;
        endcase
        else
            new_reg_c = '0;

    always_ff@(posedge clk)
        if (rst)
            pc <= '0;
        else
            pc <= new_pc;
    
    always_comb // Работа с счетчиком команд. Я верю, что реализован
        if (stage_counter == 2)
            case (cop)
                JMPH:   if(reg_a > reg_b)
                            new_pc = addr_to_jump;
                        else
                            new_pc = pc + 1;
                
                JMPeq:   if(reg_a == reg_b)
                            new_pc = addr_to_jump;
                        else
                            new_pc = pc + 1;
                
                JMP: new_pc = addr_to_jump;
                default new_pc = pc + 1;
            endcase
        else
            new_pc = pc;
        
    always @(posedge clk) // Работа с регистрами. Часть не реализвоана
        if (rst)
            for (int i = 0; i < RF_SIZE; i = i + 1)
                RF[i] <= '0;
        else
            if (stage_counter == 2)
                case (cop)
                    LTR: RF[r1] <= reg_b;
                    ADD: RF[r3] <= reg_a + reg_b;
                    MTR: RF[r2] <= mem_data_r;
                    SliMtoR:
                        case (reg_c)
                            0: RF[r2] <= {8'b0, mem_data_r[15:8]};
                            1: RF[r2] <= (mem_data_r[7:4] == 4'hF) ? 16'hFFFF : {12'b0, mem_data_r[7:4]};
                            2: RF[r2] <= (mem_data_r[3:0] == 4'hF) ? 16'hFFFF : {12'b0, mem_data_r[3:0]};
                            default: ;
                        endcase
                endcase
             
        
endmodule

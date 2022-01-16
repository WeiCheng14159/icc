`timescale 1ns/10ps

module SAO ( clk, reset, in_en, din, sao_type, sao_band_pos, sao_eo_class, sao_offset, lcu_x, lcu_y, lcu_size, busy, finish);
input   clk;
input   reset;
input   in_en;
input   [7:0]  din;
input   [1:0]  sao_type;
input   [4:0]  sao_band_pos;
input          sao_eo_class;
input   [15:0] sao_offset;
input   [2:0]  lcu_x;
input   [2:0]  lcu_y;
input   [1:0]  lcu_size;
output  busy;
output  finish;

  sram_16384x8 golden_sram(.Q( ), .CLK( ), .CEN( ), .WEN( ), .A( ), .D( )); 
     
endmodule


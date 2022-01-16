`timescale 1ns/10ps
module SME ( clk, reset, case_insensitive, pattern_no, match_addr, valid, finish, T_data, T_addr, P_data, P_addr);
input         clk;
input         reset;
input         case_insensitive;
output [3:0]  pattern_no;
output [11:0] match_addr;
output        valid;
output        finish;
input  [7:0]  T_data;
output [11:0] T_addr;
input  [7:0]  P_data;
output [6:0]  P_addr;

endmodule

module DPA (clk,reset,IM_A, IM_Q,IM_D,IM_WEN,CR_A,CR_Q);
input clk;
input reset;
output [19:0] IM_A;
input [23:0] IM_Q;
output [23:0] IM_D;
output IM_WEN;
output [8:0] CR_A;
input [12:0] CR_Q;


endmodule

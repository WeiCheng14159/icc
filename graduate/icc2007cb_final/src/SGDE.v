module SGDE ( ready, done, clk, reset, sprite, start, type, X, Y, SR_CEN, SR_A, SR_Q, FB_CEN, FB_WEN, FB_A, FB_D, FB_Q);

input clk, reset, sprite, start;
input [1:0] type;
input [5:0] X, Y;
input [12:0] SR_Q;
input [11:0] FB_Q;

output ready, done;
output SR_CEN, FB_CEN, FB_WEN;
output [8:0] SR_A;
output [11:0] FB_A, FB_D;

endmodule

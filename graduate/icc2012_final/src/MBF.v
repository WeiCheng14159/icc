`timescale 1ns/10ps
module MBF(clk, reset, y_valid, z_valid, y, z);
input   clk;
input   reset;
output  y_valid;
output  z_valid;
output  [7:0]  y;
output  [7:0]  z;
endmodule

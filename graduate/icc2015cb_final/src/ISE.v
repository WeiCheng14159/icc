`timescale 1ns/10ps
`include "def.v"

module ISE( clk, reset, image_in_index, pixel_in, busy, out_valid, color_index, image_out_index);
input               clk;
input               reset;
input         [4:0] image_in_index;
input        [23:0] pixel_in;
output              busy;
output              out_valid;
output        [1:0] color_index;
output        [4:0] image_out_index;


wire    [`CMD_FLAG_W-1:0] fb_flags;
wire    [`CMD_FLAG_W-1:0] cmd_flags;
wire    [`INT_FLAG_W-1:0] int_flags;

assign                    fb_flags = int_flags & cmd_flags;

wire                      dp_cnt_rst;

ctrl ul_ctrl(
  .clk(clk),
  .reset(reset),
  .dp_cnt_rst(dp_cnt_rst),
  .fb_flags(fb_flags),
  .cmd_flags(cmd_flags),
  .busy(busy)
);


dp ul_dp(
  .clk(clk),
  .reset(reset),
  .cnt_rst(dp_cnt_rst),
  .cmd_flags(cmd_flags),
  .int_flags(int_flags),
  .out_valid(out_valid),
  .image_in_index(image_in_index),
  .pixel_in(pixel_in),
  .color_index(color_index),
  .image_out_index(image_out_index)
);

endmodule

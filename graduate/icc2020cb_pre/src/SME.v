`include "def.v"
module SME(
  input                                 clk,
  input                                 reset,
  input                           [7:0] chardata,
  input                                 isstring,
  input                                 ispattern,
  output                                match,
  output                          [4:0] match_index,
  output                                valid
);

  wire                [`STATE_W-1:0] fb_flags;
  wire                [`STATE_W-1:0] state;
  wire                [`STATE_W-1:0] int_flags;

  assign                             fb_flags = int_flags & state;
  wire                               dp_cnt_rst;

  ctrl ul_ctrl(
    .clk(clk),
    .reset(reset),
    .dp_cnt_rst(dp_cnt_rst),
    .fb_flags(fb_flags),
    .curr_state(state),
    .isstring(isstring),
    .ispattern(ispattern)
  );
  
  dp ul_dp(
    .clk(clk),
    .reset(reset),
    .cnt_rst(dp_cnt_rst),
    .state(state),
    .int_flags(int_flags),
    .chardata(chardata),
    .isstring(isstring),
    .ispattern(ispattern),
    .match(match),
    .match_index(match_index),
    .valid(valid)
  );
endmodule

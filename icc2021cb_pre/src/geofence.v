`include "def.v"

module geofence ( clk,reset,X,Y,R,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
input [10:0] R;
output valid;
output is_inside;
//reg valid;
//reg is_inside;

  wire    [`CMD_FLAG_W-1:0] fb_flags;
  wire    [`CMD_FLAG_W-1:0] cmd_flags;
  wire    [`INT_FLAG_W-1:0] int_flags;
  
  assign                    fb_flags = int_flags & cmd_flags;
  wire                      dp_cnt_rst;
 
  wire     [`GLB_CNT_W-1:0] glb_cnt;
  wire task_done;

  ctrl ul_ctrl(
    .clk(clk),
    .reset(reset),
    .dp_cnt_rst(dp_cnt_rst),
    .fb_flags(fb_flags),
    .cmd_flags(cmd_flags),
    .task_done(task_done)
  );
  
  dp ul_dp(
    .clk(clk),
    .reset(reset),
    .cnt_rst(dp_cnt_rst),
    .cmd_flags(cmd_flags),
    .int_flags(int_flags),
    .X(X),
    .Y(Y),
    .R(R),
    .is_inside(is_inside),
    .valid(valid),
    .task_done(task_done)
  );

endmodule


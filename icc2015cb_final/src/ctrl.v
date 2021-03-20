`include "def.v"

module ctrl(
  input                        clk,
  input                        reset,
  output                   reg dp_cnt_rst,
  input      [`INT_FLAG_W-1:0] fb_flags,
  output reg [`CMD_FLAG_W-1:0] cmd_flags,
  output                   reg busy
);

  reg           [`STATE_W-1:0] curr_state, next_state;
  reg         [`GLB_CNT_W-1:0] glb_cnt;

  // Global counter
  wire        [`GLB_CNT_W-2:0] glb_cnt_half = glb_cnt[`GLB_CNT_W-1:1];
  always @(posedge clk, posedge reset) begin
    if(reset)
      glb_cnt <= {`GLB_CNT_W{1'b0}};
    else if (cmd_flags[`CMD_COMP]) begin
      glb_cnt <= glb_cnt + 1'b1;
    end
  end
  
  // Wait for interrupt signal
  wire                      init_done = fb_flags[`INT_INIT];
  wire                      read_done = fb_flags[`INT_READ];
  wire                       avg_done = fb_flags[`INT_AVG];
  wire                      comp_done = fb_flags[`INT_COMP] && (glb_cnt_half == 31);
  wire                      comp_nyet = fb_flags[`INT_COMP];
  wire                      sort_done = fb_flags[`INT_SORT];
  wire                       out_done = fb_flags[`INT_OUT];

  // State Register (S)
  always @(posedge clk, posedge reset) begin
     if(reset)
       curr_state <= {`S_ZVEC | {{(`STATE_W-1){1'b0}}, 1'b1}};
     else
       curr_state <= next_state;
  end // State Register

  // Next State Logic (C)
  always @(*) begin
     next_state = `S_ZVEC;

     case (1'b1) // synopsys parallel_case

       // INIT state
       curr_state[`S_INIT]: begin
          if(init_done)
            next_state[`S_READ] = 1'b1;
          else
            next_state[`S_INIT] = 1'b1;
       end

       // READ state
       curr_state[`S_READ]: begin
          if(read_done)
            next_state[`S_AVG] = 1'b1;
          else
            next_state[`S_READ] = 1'b1;
       end

       // AVG state
       curr_state[`S_AVG]: begin
          if(avg_done)
            next_state[`S_COMP] = 1'b1;
          else
            next_state[`S_AVG] = 1'b1;
       end
       
       // COMP state
       curr_state[`S_COMP]: begin
          if(comp_done)
            next_state[`S_SORT] = 1'b1;
          else if(comp_nyet)
            next_state[`S_READ] = 1'b1;
          else
            next_state[`S_COMP] = 1'b1;
       end

       // SORT state
       curr_state[`S_SORT]: begin
          if(sort_done)
            next_state[`S_OUT] = 1'b1;
          else
            next_state[`S_SORT] = 1'b1;
       end
       
       // OUT state
       curr_state[`S_OUT]: begin
          if(out_done)
            next_state[`S_END] = 1'b1;
          else
            next_state[`S_OUT] = 1'b1;
       end

       // End state
       curr_state[`S_END]: begin
          next_state[`S_END] = 1'b1;
       end

       // default
       default: begin
         next_state[`S_INIT] = 1'b1;
       end
     endcase

      // Reset condition
       if(reset) begin
         next_state[`S_INIT] = 1'b1;
       end

  end // Next State Logic (C)

  // Output Logic (C)
  always @(*) begin
    cmd_flags = {`CMD_FLAG_W{1'b0}}; 
    busy = 1'b1;
    dp_cnt_rst = 1'b0;

    case (1'b1) // synopsys parallel_case

      // INIT state
      curr_state[`S_INIT]: begin
        cmd_flags[`CMD_INIT] = 1'b1;
      end

      // READ state
      curr_state[`S_READ]: begin
        cmd_flags[`CMD_READ] = 1'b1;
        busy = 0; // start reading
      end

      // AVG state
      curr_state[`S_AVG]: begin
        cmd_flags[`CMD_AVG] = 1'b1;
      end

      // COMP state
      curr_state[`S_COMP]: begin
        cmd_flags[`CMD_COMP] = 1'b1;
        if(comp_nyet)
          dp_cnt_rst = 1;
      end

      // SORT state
      curr_state[`S_SORT]: begin
        cmd_flags[`CMD_SORT] = 1'b1;
        if(sort_done)
          dp_cnt_rst = 1;
      end

      // OUT state
      curr_state[`S_OUT]: begin
        cmd_flags[`CMD_OUT] = 1'b1;
      end

      // End state

      //default
      default: cmd_flags = {`CMD_FLAG_W{1'b0}};
    endcase

  end // Next State Logic (C)

endmodule

`include "def.v"

module ctrl(
  input                        clk,
  input                        reset,
  output                   reg dp_cnt_rst,
  input      [`INT_FLAG_W-1:0] fb_flags,
  output reg [`CMD_FLAG_W-1:0] cmd_flags,
  input                        task_done
);

  reg           [`STATE_W-1:0] curr_state, next_state;
  reg         [`GLB_CNT_W-1:0] glb_cnt;

  // Global counter
  always @(posedge clk, posedge reset) begin
    if(reset)
      glb_cnt <= {`GLB_CNT_W{1'b0}};
    else if (cmd_flags[`CMD_COMP]) begin
      glb_cnt <= glb_cnt + 1'b1;
    end
  end

  // Wait for interrupt signal
  wire                      read_done = fb_flags[`INT_READ];
  wire                      vect_done = fb_flags[`INT_VECT];
  wire                      cros_done = fb_flags[`INT_CROS];
  wire                      sort_done = fb_flags[`INT_SORT];
  wire                      edge_done = fb_flags[`INT_EDGE];
  wire                      area_done = fb_flags[`INT_AREA];
  wire                     area1_done = fb_flags[`INT_SUM_AREA];
  wire                      comp_done = task_done;

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

       // READ state
       curr_state[`S_READ]: begin
          if(read_done)
            next_state[`S_VECT] = 1'b1;
          else
            next_state[`S_READ] = 1'b1;
       end

       // VECT state
       curr_state[`S_VECT]: begin
          if(vect_done)
            next_state[`S_CROS] = 1'b1;
          else
            next_state[`S_VECT] = 1'b1;
       end
       
       // CROS state
       curr_state[`S_CROS]: begin
          if(cros_done)
            next_state[`S_SORT] = 1'b1;
          else
            next_state[`S_CROS] = 1'b1;
       end
      
       // SORT state
       curr_state[`S_SORT]: begin
          if(sort_done)
            next_state[`S_EDGE] = 1'b1;
          else
            next_state[`S_SORT] = 1'b1;
       end

       // SORT state
       curr_state[`S_EDGE]: begin
          if(edge_done)
            next_state[`S_AREA] = 1'b1;
          else
            next_state[`S_EDGE] = 1'b1;
       end
       
       // AREA state
       curr_state[`S_AREA]: begin
          if(area_done)
            next_state[`S_SUM_AREA] = 1'b1;
          else
            next_state[`S_AREA] = 1'b1;
       end

       // SUM_AREA state
       curr_state[`S_SUM_AREA]: begin
          if(area1_done)
            next_state[`S_COMP] = 1'b1;
          else
            next_state[`S_SUM_AREA] = 1'b1;
       end

       // COMP state
       curr_state[`S_COMP]: begin
          if(comp_done)
            next_state[`S_READ] = 1'b1;
          else 
            next_state[`S_COMP] = 1'b1;
       end
       
       // End state
       curr_state[`S_END]: begin
          next_state[`S_END] = 1'b1;
       end

       // default
       default: begin
         next_state[`S_READ] = 1'b1;
       end
     endcase

      // Reset condition
       if(reset) begin
         next_state[`S_READ] = 1'b1;
       end

  end // Next State Logic (C)

  // Output Logic (C)
  always @(*) begin
    cmd_flags = {`CMD_FLAG_W{1'b0}}; 
    dp_cnt_rst = 1'b0;

    case (1'b1) // synopsys parallel_case

      // READ state
      curr_state[`S_READ]: begin
        cmd_flags[`CMD_READ] = 1'b1;
        if(read_done) begin
          dp_cnt_rst = 1;
        end
      end

      // VECT state
      curr_state[`S_VECT]: begin
        cmd_flags[`CMD_VECT] = 1'b1;
        if(vect_done) begin
          dp_cnt_rst = 1;
        end
      end

      // CROS state
      curr_state[`S_CROS]: begin
        cmd_flags[`CMD_CROS] = 1'b1;
        if(cros_done) begin
          dp_cnt_rst = 1;
        end
      end

      // SORT state
      curr_state[`S_SORT]: begin
        cmd_flags[`CMD_SORT] = 1'b1;
        if(sort_done) begin
          dp_cnt_rst = 1;
        end
      end

      // EDGE state
      curr_state[`S_EDGE]: begin
        cmd_flags[`CMD_EDGE] = 1'b1;
        if(edge_done) begin
          dp_cnt_rst = 1;
        end
      end

      // AREA state
      curr_state[`S_AREA]: begin
        cmd_flags[`CMD_AREA] = 1'b1;
        if(area_done) begin
          dp_cnt_rst = 1;
        end
      end
     
      // SUM_AREA state
      curr_state[`S_SUM_AREA]: begin
        cmd_flags[`CMD_SUM_AREA] = 1'b1;
        if(area1_done) begin
          dp_cnt_rst = 1;
        end
      end

      // COMP state
      curr_state[`S_COMP]: begin
        cmd_flags[`CMD_COMP] = 1'b1;
        if(comp_done)
          dp_cnt_rst = 1;
      end

      // End state

      //default
      default: cmd_flags = {`CMD_FLAG_W{1'b0}};
    endcase

  end // Next State Logic (C)

endmodule

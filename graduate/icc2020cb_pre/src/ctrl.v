`include "def.v"

module ctrl(
  input                                 clk,
  input                                 reset,
  output reg                            dp_cnt_rst,
  input                  [`STATE_W-1:0] fb_flags,
  output reg             [`STATE_W-1:0] curr_state,
  input                                 isstring,
  input                                 ispattern
);

  reg                    [`STATE_W-1:0] next_state;
  reg                      [`CNT_W-1:0] cnt;
  
  wire                      read_done = fb_flags[`S_READ];
  wire                      proc_done = fb_flags[`S_PROC];

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

    case (1'b1)
      // READ state
      curr_state[`S_READ]: begin
        if(read_done)
          next_state[`S_PROC] = 1'b1;
        else
          next_state[`S_READ] = 1'b1;
      end

      // PROC state
      curr_state[`S_PROC]: begin
        if(proc_done) begin
          next_state[`S_OUT] = 1'b1;
        end else begin
          next_state[`S_PROC] = 1'b1;
        end
      end

      // OUT state
      curr_state[`S_OUT]: begin
        next_state[`S_READ] = 1'b1;
      end

      // default
      default: begin
        next_state[`S_READ] = 1'b1;
      end
    endcase

  end // Next State Logic (C)

  // Output Logic (C)
  always @(*) begin
    dp_cnt_rst = 1'b0;

    case (1'b1)
      // READ state
      curr_state[`S_READ]: begin
        if(read_done) begin
          dp_cnt_rst = 1'b1;
        end
      end

      // PROC state
      curr_state[`S_PROC]: begin
        if(proc_done) begin
          dp_cnt_rst = 1'b1;
        end
      end

      // OUT state
      curr_state[`S_OUT]: begin
        dp_cnt_rst = 1'b1;
      end

      //default
      default: ;
    endcase

  end // Next State Logic (C)

endmodule

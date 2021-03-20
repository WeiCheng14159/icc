
`include "def.v"

module dp(
  input                           clk,
  input                           reset,
  input                           cnt_rst,
  input         [`CMD_FLAG_W-1:0] cmd_flags,
  output reg    [`INT_FLAG_W-1:0] int_flags,

  output                      reg out_valid,
  input                     [4:0] image_in_index,
  input                    [23:0] pixel_in,

  output reg                [1:0] color_index,
  output reg                [4:0] image_out_index
);

  // Input shifter
  reg                 [4:0] image_index_buf [0:4];
  wire                [4:0] in_idx = image_index_buf[4]; // Delay 4 cycle
  integer in_buf_idx;
  always @(posedge clk, posedge reset) begin
    if(reset) begin
      for(in_buf_idx=0; in_buf_idx <=4; in_buf_idx =in_buf_idx+1) begin: in_mage_index_buf_rst
        image_index_buf[in_buf_idx] <= 5'h0;
      end
    end else begin
      image_index_buf[0] <= image_in_index;
      for(in_buf_idx=0; in_buf_idx < 4; in_buf_idx=in_buf_idx+1) begin: in_mage_index_buf_shift
        image_index_buf[in_buf_idx + 1] <= image_index_buf[in_buf_idx];
      end
    end
  end

  // S_READ
  wire                [7:0] r = pixel_in [23:16];
  wire                [7:0] g = pixel_in [15:8];
  wire                [7:0] b = pixel_in [7:0];
  reg         [`PSUM_W-1:0] r_psum, g_psum, b_psum;
  reg                [14:0] r_cnt, g_cnt, b_cnt;
  // S_AVG
  reg          [`AVG_W-1:0] r_avg, g_avg, b_avg;
  // S_COMP
  reg         [`DATA_W-1:0] img_rank [31:0];
  reg          [`CNT_W-1:0] cnt;
  wire         [`CNT_W-1:0] cnt_zero = {`CNT_W{1'b0}};
  // S_SORT
  wire                [5:0] itr_idx = (cnt % 34); // range 0 - 33
  wire                [4:0] imr_idx = itr_idx[4:0];
  reg                 [4:0] curr_min_idx;
  reg         [`DATA_W-1:0] curr_min;
  wire        [`DATA_W-1:0] curr_rank;
  reg                 [4:0] sorted_ptr;
  reg                 [6:0] sorted_rank [31:0];
  reg                [31:0] picked; // picked by sorting algo
  wire                      all_picked = (picked == 32'hFFFFFFFF); // all picked ?
  // S_OUT
  wire                [4:0] out_idx = cnt[4:0];

  // Shared counter
  always @(posedge clk, posedge reset) begin
    if(reset)
      cnt <= cnt_zero;
    else if (cnt_rst)
      cnt <= cnt_zero;
    else if (cmd_flags[`CMD_READ] | cmd_flags[`CMD_SORT] | 
             cmd_flags[`CMD_OUT])
      cnt <= cnt + 1;
  end

  // S_OUT
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_OUT] <= 1'b0;
    end else if (cmd_flags[`CMD_OUT]) begin
      if(cnt >= 32)
        int_flags[`INT_OUT] <= 1'b1;
      else
        int_flags[`INT_OUT] <= 1'b0;
    end else
        int_flags[`INT_OUT] <= 1'b0;
  end

    // Output result
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        color_index <= 2'b00;
        image_out_index <= 5'b00000;
        out_valid <= 1'b0;
      end else if (cmd_flags[`CMD_OUT]) begin
        if(cnt >= 0 && cnt <= 31) begin
          // out_valid
          out_valid <= 1'b1;
          // color_index
          color_index <= sorted_rank[out_idx][6:5];
          // image_out_index
          image_out_index <= sorted_rank[out_idx][4:0]; 
        end
      end else begin
        out_valid <= 1'b0;
      end
    end

  // S_SORT
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_SORT] <= 1'b0;
    end else if (cmd_flags[`CMD_SORT]) begin
      if(all_picked)
        int_flags[`INT_SORT] <= 1'b1;
      else
        int_flags[`INT_SORT] <= 1'b0;
    end else
        int_flags[`INT_SORT] <= 1'b0;
  end

    // curr_min_idx
    always @(posedge clk, posedge reset) begin
      if(reset) begin 
        curr_min_idx <= 5'h0;
      end else if (cmd_flags[`CMD_SORT]) begin 
        if(itr_idx >= 0 && itr_idx <= 31) begin
          // Update curr_min
          if (img_rank[imr_idx] < curr_min && picked[imr_idx] == 1'b0) begin
            curr_min_idx <= imr_idx;
          end
        end else if(itr_idx == 32) begin
          curr_min_idx <= curr_min_idx;
        end else begin // (itr_idx == 33) Reset counter
          curr_min_idx <= 5'h0;
        end
      end
    end

    // curr_min
    assign curr_rank = img_rank[imr_idx];
    always @(posedge clk, posedge reset) begin
      if(reset) begin 
        curr_min <= {`DATA_W{1'b1}};
      end else if (cmd_flags[`CMD_SORT]) begin 
        if(itr_idx >= 0 && itr_idx <= 31) begin
          // Update curr_min
          if (curr_rank < curr_min && picked[imr_idx] == 1'b0) begin
            curr_min <= curr_rank;
          end
        end else if(itr_idx == 32) begin
          curr_min <= curr_min;
        end else begin // (itr_idx == 33) Reset counter
          curr_min <= {`DATA_W{1'b1}};
        end 
      end
    end

    // picked, sorted_ptr
    always @(posedge clk, posedge reset) begin
      if(reset) begin 
        picked <= 32'h0;
        sorted_ptr <= 5'h0;
      end else if (cmd_flags[`CMD_SORT]) begin 
        if(itr_idx == 32) begin
          sorted_ptr <= sorted_ptr + 1'b1;
          picked[curr_min_idx] <= 1'b1;
        end
      end
    end

    // sorted_rank
    integer k, m, n;
    always @(posedge clk, posedge reset) begin
      if(reset) begin 
        for(k=0; k<=31; k=k+1) begin: sorted_rank_rst
          sorted_rank[k] <= 7'h0;
        end
      end else if (cmd_flags[`CMD_SORT]) begin 
        if(itr_idx == 32) begin
          // Put into sorted array
          sorted_rank[sorted_ptr] <= {curr_min[`DATA_W-1:`DATA_W-2], curr_min_idx};
        end else begin
          for(m=0; m<=31; m=m+1) begin: sorted_rank_hold_1
            sorted_rank[m] <= sorted_rank[m];
          end
        end 
      end
    end


  // S_AVG
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_AVG] <= 1'b0;
    end else if (cmd_flags[`CMD_AVG]) begin
      int_flags[`INT_AVG] <= 1'b1;
  end else
      int_flags[`INT_AVG] <= 1'b0;
  end

    // Calculate average
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        r_avg <= {`AVG_W{1'b0}};
        g_avg <= {`AVG_W{1'b0}};
        b_avg <= {`AVG_W{1'b0}};
      end else if (cmd_flags[`CMD_AVG]) begin
        r_avg <= (r_cnt == 15'h0000) ? {`AVG_W{1'b0}} : ({r_psum, 2'b00} / r_cnt);
        g_avg <= (g_cnt == 15'h0000) ? {`AVG_W{1'b0}} : ({g_psum, 2'b00} / g_cnt);
        b_avg <= (b_cnt == 15'h0000) ? {`AVG_W{1'b0}} : ({b_psum, 2'b00} / b_cnt);
      end
    end

  // S_COMP
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_COMP] <= 1'b0;
    end else if (cmd_flags[`CMD_COMP]) begin
      int_flags[`INT_COMP] <= 1'b1;
    end else
      int_flags[`INT_COMP] <= 1'b0;
  end

    // Compute img_rank
    integer i, j, p;
    always @(posedge clk, posedge reset) begin
      if(reset) begin 
        for(i=0; i<=31; i=i+1) begin: img_rank_rst
          img_rank[i] <= {`DATA_W{1'b0}}; 
        end
      end else if (cmd_flags[`CMD_COMP]) begin
        if (r_cnt >= g_cnt && r_cnt >= b_cnt) begin // R
          img_rank[in_idx] <= {`R, r_avg};
        end else if (g_cnt >= b_cnt && g_cnt > r_cnt) begin // G
          img_rank[in_idx] <= {`G, g_avg};
        end else if (b_cnt > r_cnt && b_cnt > g_cnt) begin // B
          img_rank[in_idx] <= {`B, b_avg};
        end else begin
          for(p=0; p<=31; p=p+1) begin: img_rank_hold_1
            img_rank[p] <= 0;
          end
        end
      end
    end

  // S_READ
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_READ] <= 1'b0;
    end else if (cmd_flags[`CMD_READ]) begin
      if(cnt < `BUF_SIZE)
        int_flags[`INT_READ] <= 1'b0;
      else
        int_flags[`INT_READ] <= 1'b1;
    end else
        int_flags[`INT_READ] <= 1'b0;
  end

    // Pixel accumulation
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        r_cnt <= 15'h0000; g_cnt <= 15'h0000; b_cnt <= 15'h0000;
        r_psum <= {`PSUM_W{1'b0}}; g_psum <= {`PSUM_W{1'b0}}; b_psum <= {`PSUM_W{1'b0}};
      end else begin
        case({cnt_rst, cmd_flags[`CMD_READ]})
          // CMD_READ
          2'b01: begin
            if(cnt >= 1 && cnt < `BUF_SIZE + 2) begin
              if (r >= g && r >= b) begin 
                r_cnt <= r_cnt + 1;
                r_psum <= r_psum + r;
              end else if (g >= b && g > r) begin
                g_cnt <= g_cnt + 1;
                g_psum <= g_psum + g;
              end else if (b > r && b > g) begin
                b_cnt <= b_cnt + 1;
                b_psum <= b_psum + b;
              end
            end
          end
          // cnt_rst
          2'b10: begin
            r_cnt <= 15'h0000; g_cnt <= 15'h0000; b_cnt <= 15'h0000;
            r_psum <= {`PSUM_W{1'b0}}; g_psum <= {`PSUM_W{1'b0}}; b_psum <= {`PSUM_W{1'b0}};
          end
          // Both: reset counter
          2'b11: begin
            r_cnt <= 15'h0000; g_cnt <= 15'h0000; b_cnt <= 15'h0000;
            r_psum <= {`PSUM_W{1'b0}}; g_psum <= {`PSUM_W{1'b0}}; b_psum <= {`PSUM_W{1'b0}};
          end
          // Maintain value
          default: begin
            r_cnt <= r_cnt; g_cnt <= g_cnt; b_cnt <= b_cnt;
            r_psum <= r_psum; g_psum <= g_psum; b_psum <= b_psum;
          end
        endcase
      end
    end

  // S_INIT 
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_INIT] <= 1'b0;
    end else if (cmd_flags[`CMD_INIT]) begin
      int_flags[`INT_INIT] <= 1'b1;
    end else
      int_flags[`INT_INIT] <= 1'b0;
  end

endmodule

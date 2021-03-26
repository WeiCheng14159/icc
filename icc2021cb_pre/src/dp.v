
`include "def.v"

module dp(
  input                           clk,
  input                           reset,
  input                           cnt_rst,
  input         [`CMD_FLAG_W-1:0] cmd_flags,
  output reg    [`INT_FLAG_W-1:0] int_flags,
  input             [`DATA_W-1:0] X,
  input             [`DATA_W-1:0] Y,
  input             [`LENG_W-1:0] R,
  output                      reg is_inside,
  output                      reg valid,
  output                      reg task_done
);
  // S_SUM_AREA
  reg signed [2*`DATA_W+2:0] area_sum;
  // S_AREA
  reg         [`DATA_W-1:0] a;
  reg         [`DATA_W-1:0] b;
  reg         [`DATA_W-1:0] c;
  reg      [2*`DATA_W-1: 0] area [0:5];
  reg                 [2:0] sorted_idx_p;
  reg       [2*`DATA_W-1:0] sqrt_in0_tri, sqrt_in1_tri;
  
  // S_EDGE
  reg         [`DATA_W-1:0] edges [0:5];
  wire                [2:0] sorted_idx;
  wire                [2:0] curr_pt; 
  reg                 [2:0] curr_pt_p;
  reg       [2*`DATA_W-1:0] sqrt_in0_edge;
  wire        [`DATA_W-1:0] sqrt_out0, sqrt_out1;
  wire      [2*`DATA_W-1:0] euclid_dist;
  
  // S_SORT
  reg                 [2:0] sorted [0:4];
  reg                 [2:0] sorted_ptr;
  wire                [2:0] sort_idx; 
  reg                 [2:0] curr_max_idx;
  reg                 [4:0] curr_max;
  reg                 [4:0] picked; // picked by sorting algo
  wire                      all_picked; // all picked ?

  // S_CROS
  reg                 [0:4] tab [0:4];
  wire                [2:0] v_a_idx, v_b_idx;
  wire                      a_x_b;
  wire signed [2*`DATA_W+1:0] left, right;
  
  // S_VECT
  reg    signed [`DATA_W:0] vec_x [0:5];
  reg    signed [`DATA_W:0] vec_y [0:5];

  // S_READ
  reg    signed [`DATA_W:0] x [0:5];
  reg    signed [`DATA_W:0] y [0:5];
  reg           [`LENG_W:0] r [0:5];
  wire                [2:0] in_idx;
  reg          [`CNT_W-1:0] cnt;
  wire         [`CNT_W-1:0] cnt_zero = {`CNT_W{1'b0}};

  // Square root module
  reg       [2*`DATA_W-1:0] sqrt_in0_pin, sqrt_in1_pin;
  always @(*) begin
    sqrt_in1_pin = sqrt_in1_tri;
    if(cmd_flags[`CMD_EDGE])
      sqrt_in0_pin = sqrt_in0_edge;
    else
      sqrt_in0_pin = sqrt_in0_tri;
  end

  DW_sqrt #(20, 0) S0(.a(sqrt_in0_pin), .root(sqrt_out0));
  DW_sqrt #(20, 0) S1(.a(sqrt_in1_pin), .root(sqrt_out1));

  // Shared counter
  wire do_cnt = (cmd_flags[`CMD_READ] | cmd_flags[`CMD_VECT] |
                 cmd_flags[`CMD_CROS] | cmd_flags[`CMD_SORT] |
                 cmd_flags[`CMD_EDGE] | cmd_flags[`CMD_AREA] |
                 cmd_flags[`CMD_SUM_AREA] |cmd_flags[`CMD_COMP]);
  always @(posedge clk, posedge reset) begin
    if(reset) begin
      cnt <= cnt_zero;
    end else if(cnt_rst) begin
      cnt <= cnt_zero;
    end else if(do_cnt) begin 
      cnt <= cnt + 1;
    end
  end

  // S_READ
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_READ] <= 1'b0;
    end else if (cmd_flags[`CMD_READ]) begin
      if(cnt <= 5)
        int_flags[`INT_READ] <= 1'b0;
      else
        int_flags[`INT_READ] <= 1'b1;
    end else
        int_flags[`INT_READ] <= 1'b0;
  end

    // Read input
    assign in_idx = cnt[2:0];
    integer k;
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        for(k=0; k<=5; k=k+1) begin: in_arr_rst
          x[k] <= 0;
          y[k] <= 0;
          r[k] <= 0;
        end
      end else if(cmd_flags[`CMD_READ]) begin
        if(cnt <= 5) begin
          x[in_idx] <= X;
          y[in_idx] <= Y;
          r[in_idx] <= R;
        end
      end
    end

  // S_VECT
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_VECT] <= 1'b0;
    end else if (cmd_flags[`CMD_VECT]) begin
      if(cnt <= 5)
        int_flags[`INT_VECT] <= 1'b0;
      else
        int_flags[`INT_VECT] <= 1'b1;
    end else
        int_flags[`INT_VECT] <= 1'b0;
  end

    // Compute vector
    integer v;
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        for(v=0; v<=5; v=v+1) begin: vec_x_rst
          vec_x[v] <= 0;
          vec_y[v] <= 0;
        end
      end else if(cmd_flags[`CMD_VECT]) begin
        if(cnt >= 1 && cnt <= 5) begin
          vec_x[in_idx-1] <= x[in_idx] - x[0];
          vec_y[in_idx-1] <= y[in_idx] - y[0];
        end
      end
    end

  // S_CROS
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_CROS] <= 1'b0;
    end else if (cmd_flags[`CMD_CROS]) begin
      if(cnt <= 24)
        int_flags[`INT_CROS] <= 1'b0;
      else
        int_flags[`INT_CROS] <= 1'b1;
    end else
        int_flags[`INT_CROS] <= 1'b0;
  end

    // Fill a 5x5 table
    // An entry is 1'b1 if cross product is positive
    // is 1'b0 if cross product is negative
    assign v_a_idx = cnt / 5;
    assign v_b_idx = cnt % 5;
    assign left  = (vec_x[v_a_idx] * vec_y[v_b_idx]);
    assign right = (vec_y[v_a_idx] * vec_x[v_b_idx]);
    assign a_x_b = left > right;
    integer t;
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        for(t=0; t<=4; t=t+1) begin: tab_rst
          tab[t] <= 0;
        end
      end else if(cmd_flags[`CMD_CROS]) begin
        if(cnt <= 24) begin
          if(v_b_idx != v_a_idx) begin // No diagonal 
            // v_x \cross v_y
            if(a_x_b) begin // cross pos
              tab[v_a_idx][v_b_idx] <= 1'b1;
            end else begin // cross neg
              tab[v_a_idx][v_b_idx] <= 1'b0;
            end
          end
        end
      end
    end

  // S_SORT 
  assign all_picked = (picked == 5'b11111);
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

    wire [2:0] entry_sum = tab[sort_idx][0] +
                           tab[sort_idx][1] +
                           tab[sort_idx][2] +
                           tab[sort_idx][3] +
                           tab[sort_idx][4];
    assign sort_idx = (cnt % 6); // range 0 - 5
    integer ra;
    // Sort tab array
    always @(posedge clk, posedge reset) begin
      if(reset) begin 
        picked <= 0;
        sorted_ptr <= 0;
        curr_max_idx <= 0;
        curr_max <= 0;
        for(ra=0; ra<=4; ra=ra+1) begin: sorted_rst
          sorted[ra] <= 0;
        end
      end else if (cmd_flags[`CMD_SORT]) begin 
        if(sort_idx <= 4) begin
          // Update max 
          if (entry_sum >= curr_max && picked[sort_idx] == 1'b0) begin
            curr_max_idx <= sort_idx;
            curr_max <= entry_sum;
          end
        end else if(sort_idx == 5) begin
          curr_max <= 0;
          // Put into sorted array
          sorted[sorted_ptr] <= curr_max_idx;
          sorted_ptr <= (sorted_ptr + 1) % 5;
          picked[curr_max_idx] <= 1'b1;
        end
      end else if(cmd_flags[`CMD_EDGE]) begin
        picked <= 0;
      end
    end

  // S_EDGE 
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_EDGE] <= 1'b0;
    end else if (cmd_flags[`CMD_EDGE]) begin
      if(cnt <= 6)
        int_flags[`INT_EDGE] <= 1'b0;
      else
        int_flags[`INT_EDGE] <= 1'b1;
    end else
        int_flags[`INT_EDGE] <= 1'b0;
  end

    // Compute edge length accoroding to lendth
    assign sorted_idx = cnt[2:0] % 5; // 0-4
    assign curr_pt = (sorted[sorted_idx] + 1); // 0-5
    assign euclid_dist = (x[curr_pt] - x[curr_pt_p]) * (x[curr_pt] - x[curr_pt_p]) +
                         (y[curr_pt] - y[curr_pt_p]) * (y[curr_pt] - y[curr_pt_p]);
    integer e;
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        for(e=0; e<=5; e=e+1) begin: edges_rst
          edges[e] <= 0;
        end
        sqrt_in0_edge <= 0;
      end else if(cmd_flags[`CMD_EDGE]) begin
        // Calculate euclidean distance between two pts
        if(cnt == 0) begin
          sqrt_in0_edge <= (x[0] - x[curr_pt]) * (x[0] - x[curr_pt]) + (y[0] - y[curr_pt]) * (y[0] - y[curr_pt]);
        end else if(cnt >= 1 && cnt <= 4) begin
          edges[cnt-1] <= sqrt_out0;
          sqrt_in0_edge <= euclid_dist;
        end else if(cnt == 5)begin
          sqrt_in0_edge <= (x[curr_pt_p] - x[0]) * (x[curr_pt_p] - x[0]) + (y[curr_pt_p] - y[0]) * (y[curr_pt_p] - y[0]);
          edges[4] <= sqrt_out0;
        end else if(cnt == 6) begin
          edges[5] <= sqrt_out0;
        end
      end
    end

  // S_AREA 
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_AREA] <= 1'b0;
    end else if (cmd_flags[`CMD_AREA]) begin
      if(cnt <= 6)
        int_flags[`INT_AREA] <= 1'b0;
      else
        int_flags[`INT_AREA] <= 1'b1;
    end else
        int_flags[`INT_AREA] <= 1'b0;
  end
    
    // Compute 6 triangle area
    wire        [`DATA_W :0] sum_0    = r[0] + r[sorted[0]+1] + edges[0]; 
    wire        [`DATA_W :0] sum_head = sum_0[`DATA_W:1];
    wire        [`DATA_W :0] sum_5    = r[0] + r[sorted[4]+1] + edges[5]; 
    wire        [`DATA_W :0] sum_tail = sum_5[`DATA_W:1];
    wire        [`DATA_W :0] sum      = r[curr_pt_p] + r[curr_pt] + edges[sorted_idx] ; 
    wire        [`DATA_W :0] s        = sum[`DATA_W:1];
    
    integer itr_a;
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        for(itr_a=0; itr_a <= 5; itr_a=itr_a+1) begin
          area[itr_a] <= 0;
        end
        sqrt_in0_tri <= 0;
        sqrt_in1_tri <= 0;
      end else if(cmd_flags[`CMD_AREA]) begin
        if(cnt == 0) begin
          sqrt_in0_tri <= sum_head * (sum_head- r[0]);
          sqrt_in1_tri <= (sum_head - r[sorted[0]+1]) * (sum_head - edges[0]);
        end else if(cnt >= 1 && cnt <= 4) begin
          area[curr_pt_p] <= sqrt_out0 * sqrt_out1;
          sqrt_in0_tri <= s * (s - r[curr_pt_p]);
          sqrt_in1_tri <= (s - r[curr_pt]) * (s - edges[sorted_idx]);
        end else if(cnt == 5) begin
          area[curr_pt_p] <= sqrt_out0 * sqrt_out1;
          sqrt_in0_tri <= sum_tail * (sum_tail - r[0] );
          sqrt_in1_tri <= (sum_tail - r[sorted[4] + 1]) * (sum_tail - edges[5]);
        end else if(cnt == 6) begin
          area[0] <= sqrt_out0 * sqrt_out1;
        end
      end
    end

  // S_SUM_AREA
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_SUM_AREA] <= 1'b0;
    end else if (cmd_flags[`CMD_SUM_AREA]) begin
      if(cnt <= 6)
        int_flags[`INT_SUM_AREA] <= 1'b0;
      else
        int_flags[`INT_SUM_AREA] <= 1'b1;
    end else
        int_flags[`INT_SUM_AREA] <= 1'b0;
  end

    // Sum the area fenced by six points
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        sorted_idx_p <= 0;
        area_sum <= 0;
      end else if(cmd_flags[`CMD_SUM_AREA]) begin
        sorted_idx_p <= sorted_idx;
        if(cnt == 0) begin
          area_sum <= area_sum + x[0] * y [curr_pt] - x[curr_pt] * y[0];
        end else if(cnt >= 1 && cnt <= 4) begin
          area_sum <= area_sum + x[curr_pt_p] * y [curr_pt] - x[curr_pt] * y[curr_pt_p];
        end else if(cnt == 5) begin
          area_sum <= area_sum + x[curr_pt_p] * y [0] - x[0] * y[curr_pt_p];
        end else if(cnt == 6) begin
          area_sum <= area_sum[2*`DATA_W+1:1] ;
        end
      end else if(cmd_flags[`CMD_READ]) begin
        area_sum <= 0;
      end
    end

  // S_COMP
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_COMP] <= 1'b0;
    end else if (cmd_flags[`CMD_COMP]) begin
      if(cnt <= 7)
        int_flags[`INT_COMP] <= 1'b0;
      else
        int_flags[`INT_COMP] <= 1'b1;
    end else
        int_flags[`INT_COMP] <= 1'b0;
  end

    integer tt;
    wire [2:0] com_idx = cnt[2:0];
    reg signed [2*`DATA_W+2:0] accu;
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        is_inside <= 0;
        valid <= 0;
        accu <= 0;
        task_done <= 0;
      end else if(cmd_flags[`CMD_COMP]) begin
        if(cnt <= 5) begin
          accu <= accu + area[com_idx];
        end else if(cnt == 6) begin
          accu <= 0;
          valid <= 1;
          task_done <= 1;
          if(accu >= area_sum) 
            is_inside <= 0;
          else
            is_inside <= 1;
        end else begin
          task_done <= 0;
          valid <= 0;
          is_inside <= 0;
        end
      end
    end

  // curr_pt_p 
  always @(posedge clk, posedge reset) begin
    if(reset)
      curr_pt_p <= 0;
    else begin
      curr_pt_p <= curr_pt;
    end
  end

endmodule

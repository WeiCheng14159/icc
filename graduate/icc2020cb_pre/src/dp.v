`include "def.v"

`define send_interrupt(flag_i, thres_i)\
  always @(posedge clk) begin          \
    if(reset) begin                    \
      int_flags[flag_i] <= 1'b0;       \
    end else begin                     \
      if(state[flag_i])                \
        int_flags[flag_i] <= (cnt <= thres_i) ? 1'b0 : 1'b1; \
      else                             \
        int_flags[flag_i] <= 1'b0;     \
    end                                \
  end                                  \

module dp(
  input                                 clk,
  input                                 reset,
  input                                 cnt_rst,
  input                  [`STATE_W-1:0] state,
  output                 [`STATE_W-1:0] int_flags,
  input                           [7:0] chardata,
  input                                 isstring,
  input                                 ispattern,
  output reg                            match,
  output reg                      [4:0] match_index,
  output reg                            valid
);

  reg                      [`CNT_W-1:0] cnt;
  wire                     [`CNT_W-1:0] cnt_zero = {`CNT_W{1'b0}};

  // Memory
  reg [`DATA_W-1:0] str [0:`STR_SIZE-1];
  reg [`DATA_W-1:0] pat [0:`PAT_SIZE-1];

  reg [5:0] str_len; 
  reg [3:0] pat_len;
  reg [`ITR_W-1:0] pat_itr;
  reg [0:`PAT_SIZE-1] is_dot, is_star;
  reg signed [`ITR_W-1:0] str_itr, str_itr_h, str_itr_t, head_match_idx;
  reg m_head_match, m_tail_match;
  reg [0:`PAT_SIZE-1] m_all_match;
  reg p_is_head, p_all_dots, p_is_star;
  
  // str, pat, str_len, pat_len
  integer i;
  always @(posedge clk) begin
    if(reset) begin
      for(i=0 ; i<`STR_SIZE ; i=i+1) begin
        str[i] <= 0;
      end
      for(i=0 ; i<`PAT_SIZE ; i=i+1) begin
        pat[i] <= `DOT;
      end
      str_len <= 0;
      pat_len <= 0;
    end else if(state[`S_OUT]) begin
      // Reset pattern array
      pat_len <= 0;
      for(i=0 ; i<`PAT_SIZE ; i=i+1) begin
        pat[i] <= `DOT;
      end
    end else if(state[`S_READ])begin
      // Fill string array
      str[0] <= `DOLLAR;
      if(isstring) begin
        str[1] <= chardata;
        if(~|cnt) begin
          for(i=2 ; i<`STR_SIZE ; i=i+1) begin
            str[i] <= `HEAD;
          end
          str_len <= 3;
        end else begin
          for(i=2 ; i<`STR_SIZE ; i=i+1) begin
            str[i] <= str[i-1];
          end
          str_len <= str_len + 1;
        end
      end
      // Fill pattern array
      if(ispattern) begin
        pat[0] <= chardata;
        for(i=1 ; i<`PAT_SIZE ; i=i+1) begin
          pat[i] <= pat[i-1];
        end
        pat_len <= pat_len + 1;
      end
    end
  end

  // S_READ
  assign int_flags[`S_READ] = (~isstring & ~ispattern);
  
  // m_all_match
  integer str_idx;
  always @(*) begin
    if(reset) begin
      m_all_match = 0;
    end else begin
      for(i=0 ; i<`PAT_SIZE ; i=i+1) begin
        str_idx = str_itr + i;
        if(str_idx >= str_len) m_all_match[i] = `True;
        else if( (str_idx==str_len-1) & (str[str_len-1]==`HEAD) & (pat[i]==`DOT) )
          m_all_match[i] = `True;
        else if(pat[i] == `DOT) m_all_match[i] = `True;
        else if(pat[i] == `HEAD & str[str_idx] == `SPACE) m_all_match[i] = `True;
        else if(pat[i] == `DOLLAR & str[str_idx] == `SPACE) m_all_match[i] = `True;
        else m_all_match[i] = (pat[i] == str[str_idx]) ? `True : `False;
      end
    end
  end

  // m_state, pat_itr, str_itr, str_itr_h, str_itr_t, head_match_idx
  // m_head_match, m_tail_match
  reg [2:0] m_state;
  localparam M_INIT = 0, M_MATCHING = 1, M_HEAD_MATCHING = 2,
             M_TAIL_MATCHING = 3, M_NO_MATCH = 4, M_MATCH = 5;
  
  always @(posedge clk) begin
    if(reset | state[`S_READ]) begin 
      m_state <= M_INIT;
      pat_itr <= 0;
      str_itr <= 0;
      str_itr_h <= 0;
      str_itr_t <= 0;
      head_match_idx <= 0;
      m_head_match <= `False;
      m_tail_match <= `False;
    end else if(state[`S_PROC]) begin
      case(m_state)
        M_INIT: begin // Init variables
          if(p_is_star) begin
            m_state <= M_HEAD_MATCHING;
            pat_itr <= pat_len - 1;
            str_itr_h <= str_len - 1;
          end else begin
            m_state <= M_MATCHING; 
            str_itr <= str_len - pat_len;
          end
        end
        M_MATCHING: begin
          if(str_itr >= 0 & str_itr <= (str_len - pat_len) ) begin
            if(&m_all_match) m_state <= M_MATCH;
            else str_itr <= str_itr - 1;
          end else
            m_state <= M_NO_MATCH;
        end
        M_HEAD_MATCHING: begin
          if(str_itr_h >= 0 & str_itr_h <= str_len-1) begin
            if(pat[pat_itr] == `STAR) begin
              m_state <= M_TAIL_MATCHING; m_head_match <= `True;
              head_match_idx <= str_itr_h + pat_len - 1 - pat_itr;
              pat_itr <= 0;
            end else if(pat[pat_itr] == str[str_itr_h] | 
                        pat[pat_itr] == `DOT | 
                        pat[pat_itr] == `HEAD & str[str_itr_h] == `SPACE |
                        pat[pat_itr] == `DOLLAR & str[str_itr_h] == `SPACE ) begin
              str_itr_h <= str_itr_h - 1; pat_itr <= pat_itr - 1;
            end else begin
              str_itr_h <= (is_dot[pat_len-1]) ? str_itr_h : str_itr_h - 1; 
              pat_itr <= pat_len - 1;
            end
          end else begin
            m_state <= M_TAIL_MATCHING;
            pat_itr <= 0;
          end
        end
        M_TAIL_MATCHING: begin
          if(str_itr_t >= 0 & str_itr_t <= str_len-1) begin
            if(pat[pat_itr] == `STAR) begin
              if( (str_itr_h - str_itr_t) < -1) begin 
                // * symbol match nothing
                m_state <= M_NO_MATCH; m_tail_match <= `False;
              end else begin // * symbol match zero or more char
                m_state <= M_MATCH; m_tail_match <= `True;
              end
            end else if(pat[pat_itr] == str[str_itr_t] | 
                        pat[pat_itr] == `DOT | 
                        pat[pat_itr] == `HEAD & str[str_itr_t] == `SPACE |
                        pat[pat_itr] == `DOLLAR & str[str_itr_t] == `SPACE ) begin
              str_itr_t <= str_itr_t + 1; pat_itr <= pat_itr + 1;
            end else begin
              pat_itr <= 0;
              if(pat_itr >= 1)
                str_itr_t <= (str[str_itr_t] == pat[pat_itr-1]) ? str_itr_t : (str_itr_t + 1);
              else
                str_itr_t <= str_itr_t + 1;
            end
          end else begin
            m_state <= M_NO_MATCH;
          end
        end
        M_MATCH: m_state <= M_MATCH; 
        M_NO_MATCH: m_state <= M_NO_MATCH;
        default: ;
      endcase
    end
  end

  // is_dot, is_star
  always @(*) begin
    if(reset) begin
      for(i=0 ; i<`PAT_SIZE ; i=i+1) begin
        is_dot[i] = `False;
        is_star[i] = `False;
      end
    end else begin
      for(i=0 ; i<`PAT_SIZE ; i=i+1) begin
        is_dot[i] = (pat[i] == `DOT) ? `True : `False;
        is_star[i] = (pat[i] == `STAR) ? `True : `False;
      end
    end
  end

  // Special cases
  always @(posedge clk) begin
    if(reset) begin
      p_is_head <= `False;
      p_all_dots <= `False;
      p_is_star <= `False;
    end else if(state[`S_READ]) begin
      p_is_star <= (|is_star) ? `True : `False;
    end else if(state[`S_PROC]) begin
      p_is_head <= (pat[pat_len-1] == `HEAD ) ? `True : `False;
      p_all_dots <= (&is_dot) ? `True : `False;
    end
  end

  // match, match_index, valid
  always @(posedge clk) begin           
    if(reset) begin                     
      match <= `False;
      match_index <= 5'b0;
      valid <= `False;
    end else if(state[`S_OUT]) begin   
      valid <= (m_state == M_MATCH | m_state == M_NO_MATCH) ? `True : `False;
      if(m_state == M_MATCH) begin
        if(p_all_dots) begin
          match_index <= 0; match <= `True;
        end else if(p_is_star & m_head_match & m_tail_match) begin
          match_index <= str_len - 2 - head_match_idx; match <= `True;
        end else if(p_is_star & (~m_head_match | ~m_tail_match) ) begin
          match_index <= 0; match <= `False;
        end else begin
          match_index <= (str_len - str_itr - pat_len - 1 + p_is_head);
          match <= `True;
        end
      end else begin
        match_index <= 5'b0; match <= `False;
      end
    end else begin
      match <= `False;
      match_index <= 5'b0;
      valid <= `False;
    end
  end

  // S_PROC
  assign int_flags[`S_PROC] = (m_state == M_MATCH || m_state == M_NO_MATCH);

  // cnt
  always @(posedge clk, posedge reset) begin
    if(reset)
      cnt <= cnt_zero;
    else if(cnt_rst)
      cnt <= cnt_zero;
    else if (|state)
      cnt <= cnt + 1;
  end
endmodule

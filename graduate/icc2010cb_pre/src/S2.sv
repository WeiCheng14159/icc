module S2(clk,
	  rst,
	  updown,
	  S2_done,
	  RB2_RW,
	  RB2_A,
	  RB2_D,
	  RB2_Q,
	  sen,
	  sd);

  input clk,rst,updown;
  output S2_done,RB2_RW;
  output [2:0] RB2_A;
  output [17:0] RB2_D;
  input [17:0] RB2_Q;
  inout sen,sd;
        

logic [4:0]read_cnt[2];
logic [3:0]output_cnt;//(addr:5,data:8)
logic [20:0]recv_data;
logic final_recv;

//mem_ctl
assign RB1_D=recv_data[17:0];
always_comb begin
	if(updown) RB1_A=recv_data[20:18];
	else RB1_A=output_cnt-1;
end
always_ff(@posedge clk,posedge rst) begin
	if(rst) begin
		read_cnt<={3'd7,3'd7};
		final_recv<=0;
		RB1_RW<=1;
	end
	else begin
		if(updown) begin //receive
			if(sen) begin
				RB1_RW<=0;
				final_recv<=!RB1_A;
			end
			else RB1_RW<=1;
		end
		else begin//transmit
			RB1_RW<=1;
			if(!output_cnt) begin
				if(!read_cnt[0]) begin
					read_cnt<='{{read_cnt[0]-1},{read_cnt[0]-1}};
				end
			end
			else begin
				read_cnt[1]<=read_cnt[1]<<1;
			end
		end
	end
end

//transmit ctl

always_comb begin
	if(updown) begin
		sd=1'bz;
		sen=1'bz;
	end
	else begin
		sd=(output_cnt<10)? RB1_Q[read_cnt[0]]:read_cnt[1][2];
		sen=(!output_cnt);
	end
end

always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		output_cnt<=4'd14;
	end
	else begin
		if(updown) begin//receive
			if(!sen) recv_data<={recv_data[19:0],sd};
		end
		else begin//transmit
			if(!output_cnt) begin
				if(~read_cnt[0]) begin
					output_cnt<=4'd14;
				end
			end
			else output_cnt<=output_cnt-1;
		end
	end
end

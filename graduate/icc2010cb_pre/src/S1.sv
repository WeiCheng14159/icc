module S1(clk,
	rst,
	updown,
	S1_done,
	RB1_RW,
	RB1_A,
	RB1_D,
	RB1_Q,
	sen,
sd);

input clk,rst,updown;
output logic S1_done,RB1_RW;
output logic [4:0] RB1_A;
output logic [7:0] RB1_D;
input [7:0] RB1_Q;
inout sen,sd;

logic sen_delay;
logic [3:0]read_cnt[2],debug1,debug2;
assign debug1=read_cnt[0];
assign debug2=read_cnt[1];
logic [4:0]output_cnt;//(addr:3,data:18)
logic [12:0]recv_data;
logic final_recv;

//mem_ctl
always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		read_cnt<={4'hf,4'hf};
		S1_done<=0;
		final_recv<=0;
		RB1_RW<=1;
		RB1_A<=0;
		//RB1_D<=0;
		sen_delay<=1;
	end
	else begin
		S1_done<=final_recv;
		if(updown) begin //receive
			sen_delay<=sen;
			if(sen&&!sen_delay) begin
				RB1_RW<=0;
				final_recv<=(recv_data[12:8]==17);
				RB1_D<=recv_data[7:0];
			end
			else RB1_RW<=1;
			RB1_A<=recv_data[12:8];
		end
		else begin//transmit
			RB1_RW<=1;
			RB1_A<=output_cnt-2;
			if(!output_cnt) begin
				read_cnt<='{{read_cnt[0]+1},{read_cnt[0]+1}};
			end
			else begin
				if(output_cnt inside {[18:20]}) read_cnt[1]<=read_cnt[1]<<1;
			end
		end
	end
end

//transmit ctl

logic sen_data,sd_data;
assign sd=(updown)? 1'bz:sd_data;
assign sen=(updown)? 1'bz:sen_data;

always_ff@(negedge clk,posedge rst) begin
	if(rst) begin
		output_cnt<=5'd0;
		sen_data<=1;
	end
	else begin
		sd_data<=(output_cnt<19)? RB1_Q[7-read_cnt[0]]:read_cnt[1][2];
		sen_data<=(!output_cnt);
		if(updown) begin//receive
			if(!sen) recv_data<={recv_data[11:0],sd};
		end
		else begin//transmit
			if(!output_cnt) begin
				if(read_cnt[0]<8) begin
					output_cnt<=5'd21;
				end
			end
			else output_cnt<=output_cnt-1;
		end
	end
end
endmodule

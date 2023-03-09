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

logic [2:0]read_cnt[2];
logic [4:0]output_cnt;//(addr:3,data:18)
logic [12:0]recv_data;
logic final_recv;

//mem_ctl
assign RB1_D=recv_data[7:0];
always_comb begin
	if(updown) RB1_A=recv_data[12:8];
	else RB1_A=output_cnt-2;
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
		sd=(output_cnt<20)? RB1_Q[read_cnt[0]]:read_cnt[1][2];
		sen=(!output_cnt);
	end
end

always_ff@(negedge clk,posedge rst) begin
	if(rst) begin
		output_cnt<=5'd22;
	end
	else begin
		if(updown) begin//receive
			if(!sen) recv_data<={recv_data[11:0],sd};
		end
		else begin//transmit
			if(!output_cnt) begin
				if(~read_cnt[0]) begin
					output_cnt<=5'd22;
				end
			end
			else output_cnt<=output_cnt-1;
		end
	end
end

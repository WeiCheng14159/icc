`define P(a,b) sti_tmp[b][tmp_cnt+a]

module DT(
	input 			clk, 
	input			reset,
	output	logic	done ,
	output	logic	sti_rd ,
	output	logic 	[9:0]	sti_addr ,
	input			[15:0]	sti_di,
	output	logic	res_wr ,
	output	logic	res_rd ,
	output	logic 	[13:0]	res_addr ,
	output	logic 	[7:0]	res_do,
	input		[7:0]	res_di
);
function [7:0] minimum;
	input [7:0]in[4];
	int i;
	begin
		minimum=in[0];
		for(i=1;i<4;++i) begin
			if(in[i]<minimum) minimum=in[i];
		end
	end
endfunction

//logic [13:0]core_cnt;
logic [3:0] tmp_cnt;
logic [2:0] sti_cnt;
logic [6:0] row_cnt;
logic req_cnt;
logic [1:0]req_cnt2;
logic [7:0]sti_tmp[2][18],tmp;
enum {GET_STI_DATA,JOIN_UP,JOIN_BOTTOM,GET_RES_DATA,END} status;
int i;
logic [1:0]loop_cnt;
/*
core(2*3):
|0,0|1,0|2,0|
|0,1|1,1|2,1|

UP:
|m|m|m|
|m|o| |

BOTTOM:
| |o|m|
|m|m|m|
*/

always_ff @(posedge clk,negedge reset) begin
	if(!reset) begin
		done<=0;
		tmp_cnt<=1;
		sti_cnt<=0;
		row_cnt<=0;
		sti_rd<=0;
		req_cnt<=1;
		req_cnt2<=0;
		res_addr<=0;
		res_wr<=0;
		res_rd<=0;
		res_do<=0;
		sti_tmp<='{default:'0};
		status<=GET_STI_DATA;
	end
	else begin
		case(status)
			GET_STI_DATA:begin
				if(sti_rd) begin
					for(i=2;i<18;++i) sti_tmp[req_cnt][i]<={6'd0,sti_di[17-i]};
					if(req_cnt) status<=JOIN_UP;
				end
				{sti_rd,req_cnt}<={sti_rd,req_cnt}+1;
				sti_addr<={row_cnt+(!req_cnt),sti_cnt};
			end
			JOIN_UP:begin
				res_wr<=`P(1,1);
				res_addr<={row_cnt+7'd1,sti_cnt,tmp_cnt}-1;
				res_do<=minimum({`P(0,0),`P(1,0),`P(2,0),`P(0,1)})+1;
				if(tmp_cnt==4'b1111) begin
					if(sti_cnt==3'b111) begin
						if(row_cnt==7'b1111101) begin
							for(loop_cnt=0;loop_cnt<3;++loop_cnt) begin
								sti_tmp[0][loop_cnt]<=sti_tmp[0][15+loop_cnt];
								sti_tmp[1][loop_cnt]<=sti_tmp[1][15+loop_cnt];
							end
							status<=JOIN_BOTTOM;
						end
						else begin
							{row_cnt,sti_cnt,tmp_cnt}<={row_cnt,sti_cnt,tmp_cnt}+3;
							for(loop_cnt=0;loop_cnt<4;++loop_cnt) sti_tmp[loop_cnt[1]][loop_cnt[0]]<=0;
							req_cnt<=1;
							status<=GET_STI_DATA;
						end
					end
					else begin
						{sti_cnt,tmp_cnt}<={sti_cnt,tmp_cnt}+1;
						for(loop_cnt=0;loop_cnt<4;++loop_cnt) sti_tmp[loop_cnt[1]][loop_cnt[0]]<=sti_tmp[loop_cnt[1]][16+loop_cnt[0]];
						req_cnt<=1;
						status<=GET_STI_DATA;
					end
				end
				else tmp_cnt<=tmp_cnt+1;
			end
			JOIN_BOTTOM:begin
				res_rd<=0;
				res_wr<=(sti_tmp[1][0]!=0);
				res_addr<={row_cnt,sti_cnt,tmp_cnt}-1;
				tmp=minimum({sti_tmp[0][1],sti_tmp[1][1],sti_tmp[2][1],sti_tmp[2][0]})+1;
				res_do<=tmp<sti_tmp[1][0]? tmp:sti_tmp[1][0];
				status<=GET_RES_DATA;
				//prepare next data
				for(loop_cnt=0;loop_cnt<4;++loop_cnt) sti_tmp[loop_cnt[1]][loop_cnt[0]]<=sti_tmp[loop_cnt[1]][1+loop_cnt[0]];
				//{row_cnt,sti_cnt,tmp_cnt}<={row_cnt,sti_cnt,tmp_cnt}-(({sti_cnt,tmp_cnt}==7'b0000001)? 3:1);
				{res_rd,req_cnt}<=2'b01;
				req_cnt2<=({sti_cnt,tmp_cnt}==7'b0000001)? 3:1;
			end
			GET_RES_DATA:begin
				if(res_rd) begin
					sti_tmp[0][req_cnt]<=res_di;
					if(req_cnt) begin 
						if(req_cnt2) begin
							if({row_cnt,sti_cnt,tmp_cnt}==14'b1111111) done<=1;
							else {row_cnt,sti_cnt,tmp_cnt}<={row_cnt,sti_cnt,tmp_cnt}-1;
						end
						else status<=JOIN_BOTTOM;
						req_cnt2<=req_cnt2-1;
					end
				end
				res_rd<=1;
				req_cnt<=!req_cnt;
				res_addr<={row_cnt+(!req_cnt),sti_cnt,tmp_cnt}-3;
			end
		endcase
	end
end
endmodule

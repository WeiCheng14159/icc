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
logic [3:0]req_cnt2;
logic [7:0]cache[2][3],tmp;
enum {GET_DATA_UP,JOIN_UP,JOIN_BOTTOM,GET_DATA_BOTTOM,END} status;
int i;
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
		tmp_cnt<=0;
		sti_cnt<=0;
		row_cnt<=0;
		sti_rd<=0;
		req_cnt<=1;
		req_cnt2<=0;
		res_addr<=0;
		res_wr<=0;
		res_rd<=0;
		res_do<=0;
		cache<='{default:'0};
		status<=GET_DATA_UP;
	end
	else begin
		case(status)
			GET_DATA_UP:begin
				res_wr<=0;
				res_rd<=1;
				sti_rd<=1;
				res_addr<={row_cnt,sti_cnt,tmp_cnt}+2;
				sti_addr<={row_cnt+1,sti_cnt}+((tmp_cnt==4'b1111)? 1:0);

				// move reuse data
				cache[0][0]<=cache[0][1];
				cache[1][0]<=cache[1][1];
				cache[0][1]<=((res_rd)? res_di:cache[0][2]);
				cache[1][1]<=cache[1][2];
				
				// new line
				if({sti_cnt,tmp_cnt}==7'b1111111) begin
					status<=GET_DATA_UP;
					{row_cnt,sti_cnt,tmp_cnt}<={row_cnt,sti_cnt,tmp_cnt}+1;
				end
				else status<=JOIN_UP;
			end
			JOIN_UP:begin
				res_rd<=0;
				sti_rd<=0;
				res_wr<=sti_di[4'd14-tmp_cnt];
				res_addr<={row_cnt+7'd1,sti_cnt,tmp_cnt}+1;
				tmp=minimum({cache[0][0],cache[0][1],res_di,cache[1][0]})+1;
				res_do<=tmp;
				cache[0][2]<=res_di;
				if(sti_di[4'd14-tmp_cnt]) cache[1][1]<=tmp;
				{row_cnt,sti_cnt,tmp_cnt}<={row_cnt,sti_cnt,tmp_cnt}+(({sti_cnt,tmp_cnt}==7'b1111101)? 2:1);
				status<=({row_cnt,sti_cnt,tmp_cnt}==14'b11111101111101)? JOIN_BOTTOM:GET_DATA_UP;
			end
			JOIN_BOTTOM:begin
				res_rd<=0;
				res_wr<=(cache[0][1]!=0);
				res_addr<={row_cnt,sti_cnt,tmp_cnt}-1;
				tmp=minimum({cache[1][0],cache[1][1],cache[1][2],cache[0][2]})+1;
				tmp=tmp<cache[0][1]? tmp:cache[0][1];
				res_do<=tmp;
				cache[0][1]<=(cache[0][1])? tmp:0;
				status<=GET_DATA_BOTTOM;
				//prepare next data
				cache[0][0]<=0;
				cache[1][0]<=0;
				cache[0][1]<=cache[0][0];
				cache[1][1]<=cache[1][0];
				cache[0][2]<=cache[0][1];
				cache[1][2]<=cache[1][1];
				{res_rd,req_cnt}<=2'b01;
				req_cnt2<=({sti_cnt,tmp_cnt}==7'd2)? 2:0;
			end
			GET_DATA_BOTTOM:begin
				res_wr<=0;
				if(res_rd) begin
					cache[req_cnt][0]<=res_di;
					if(req_cnt) begin 
						if(req_cnt2) begin
							cache[0][1]<=cache[0][0];
							cache[0][2]<=cache[0][1];
							cache[1][1]<=res_di;
							cache[1][2]<=cache[1][1];
						end
						else status<=JOIN_BOTTOM;
						req_cnt2<=req_cnt2-1;
					end
					else begin
						if({row_cnt,sti_cnt,tmp_cnt}==14'b1111111) done<=1;
						else {row_cnt,sti_cnt,tmp_cnt}<={row_cnt,sti_cnt,tmp_cnt}-1;
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

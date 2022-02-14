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
	input [7:0]in[5];
	int i;
	begin
		minimum=in[4];
		for(i=0;i<4;++i) begin
			if(in[i]<minimum) minimum=in[i];
		end
	end
endfunction

//logic [13:0]core_cnt;
logic [3:0] tmp_cnt;
logic [2:0] sti_cnt;
logic [6:0] row_cnt;
logic req_cnt;
logic [7:0]sti_tmp[2][18];
enum {INIT,JOIN_UP,JOIN_BOTTOM,CTRL,END} status;
int i;
logic [7:0]tmp;

logic last_row;
assign last_row=(row_cnt==7'b1111110);

//assign res_addr={core_cnt[13:7]+(status!=JOIN_UP) ,core_cnt[6:0]}+1;

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
		sti_addr<=10'd8;
		sti_rd<=0;
		tmp_cnt<=0;
		sti_cnt<=0;
		row_cnt<=0;
		req_cnt<=0;
		res_addr<=0;
		res_wr<=0;
		res_rd<=0;
		res_do<=0;
		sti_tmp<='{default:'0};
		status<=INIT;
	end
	else begin
		case(status)
			INIT:begin
				if(sti_rd) begin
					for(i=2;i<18;++i) sti_tmp[1][i]<=sti_di[17-i];
					sti_rd<=0;
					tmp_cnt<=1;
					status<=JOIN_UP;
				end
				else sti_rd<=1;
			end
			JOIN_UP:begin
				if
			end
		endcase
		/*
		case(status)
			INIT:begin
				if(sti_rd) begin
					for(i=2;i<18;++i) sti_tmp[1][i]<=sti_di[17-i];
					sti_rd<=0;
					status<=JOIN_UP;
				end
				else sti_rd<=1;
			end
			JOIN_UP:begin
				tmp=minimum('{`P(0,1),`P(0,0),`P(1,0),`P(2,0),8'hff})+1;
				res_wr<=`P(1,1);
				`P(1,1)<=`P(1,1)? tmp:0;
				res_addr<={row_cnt+1,sti_cnt,tmp_cnt}-1;
				res_do<=tmp;
				res_rd<=0;
				status<=CTRL;
			end
			CTRL:begin
				res_wr<=0;
				if(~tmp_cnt) begin
					res_wr<=0;
					tmp_cnt<=tmp_cnt+1;
					status<=JOIN_BOTTOM;
				end
				else begin //end col of sti_tmp
					if(last_row && sti_cnt==3'b111) status<=END;
					else begin
						if(sti_rd) begin
							if(res_rd) begin
								res_rd<=0;
								for(i=0;i<18;++i) sti_tmp[0][i]<=(last_row)? 0:sti_tmp[1][i];
								sti_tmp[1][0]<=res_di;
								for(i=2;i<18;++i) sti_tmp[1][i]<=sti_di[17-i];
								sti_addr<=sti_cnt? {row_cnt+2,sti_cnt}-1:0;
							end
							else begin
								sti_tmp[1][1]<=sti_di[0];
								//finish request data
								sti_rd<=0;
								tmp_cnt<=0;
								row_cnt<=(last_row)? 0:row_cnt+1;
								sti_cnt<=sti_cnt+last_row;
								status<=JOIN_BOTTOM;
							end
						end
						else begin //start request data
							sti_rd<=1;
							sti_addr<=last_row? {7'd1,sti_cnt}+1:{row_cnt+2,sti_cnt};
							res_rd<=1;
							res_addr<=last_row? {7'd1,sti_cnt,4'he}:sti_cnt? {row_cnt+7'd2,sti_cnt-3'd1,4'he}:0;
						end
					end
				end
			end
			JOIN_BOTTOM:begin
				tmp=minimum('{`P(2,1)+1,`P(0,1)+1,`P(1,1)+1,`P(2,1)+1,`P(1,0)});
				res_wr<=`P(1,0);
				`P(1,0)<=`P(1,0)? tmp:0;
				res_addr<={row_cnt,sti_cnt,tmp_cnt}-1;
				res_do<=tmp;
				res_rd<=0;
				status<=CTRL;
			end
			END: done<=1;
		endcase
		*/
	end
end
endmodule

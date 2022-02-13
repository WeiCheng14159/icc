`define P(a,b) (sti_tmp[b][cnt+a])

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
logic [3:0] cnt;
logic [2:0] sti_cnt;
logic [6:0] row_cnt;
logic index;
logic [17:0]sti_tmp[2];
enum {JOIN_UP,JOIN_BOTTOM,CTRL} status;
logic [7:0]tmp1,tmp2;

assign sti_addr={core_cnt[13:9]+index ,core_cnt[8:4]}+1;
assign res_addr={core_cnt[13:7]+(status!=JOIN_UP) ,core_cnt[6:0]}+1;

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
		sti_rd<=0;
		cnt<=0;
		sti_cnt<=0;
		row_cnt<=1;
		index<=1;
		res_wr<=0;
		res_rd<=0;
		res_do<=0;
		sti_tmp<='{default:'0};
		status<=CTRL;
	end
	else begin
		case(status)
			JOIN_UP:begin
				res_wr<=(`P(1,1));
				res_do<=minimum('{`P(0,1),`P(0,0),`P(1,0),`P(2,0),8'hff});
				res_rd<=0;
				status<=CTRL;
			end
			CTRL:begin
				res_wr<=0;
				if(~cnt) begin
					res_rd<=1;
					core_cnt<=core_cnt+1;
					status<=JOIN_BOTTOM;
				end
				else begin //end col of sti_tmp
					if(~row_cnt) cnt<=cnt+1;
					else begin
						if(~sti_cnt) begin
							sti_tmp[0]<=sti_tmp[1];
							sti_tmp[1]<=sti_
						end
						else done<=1;
					end
				end
			end
			JOIN_BOTTOM:begin
				res_wr<=`P(1,0);//(sti_tmp[core_cnt[3:0]+1][0]);
				res_do<=minimum('{`P(2,1),`P(0,1),`P(1,1),`P(2,1),res_di})+1;
				res_rd<=0;
				status<=JOIN_UP;
			end
		endcase
	end
end
endmodule

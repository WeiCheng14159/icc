`define MIN_2(a,b) (a<b? a:b)
`define MIN_4(a,b,c,d) `MIN(`MIN_2(a,b),`MIN_2(c,d))
`define `P(a,b) sti_tmp[core_cnt[3:0]+a][b]
module DT(
	input 			clk, 
	input			reset,
	output	reg		done ,
	output	reg		sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input		[15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input		[7:0]	res_di
);
logic [13:0]core_cnt;
logic [1:0]cnt;
logic [17:0][1:0]sti_tmp;
enum {JOIN_UP,JOIN_BOTTOM,CTRL} status;

assign sti_addr={core_cnt[13:9]+cnt[0] ,core_cnt[8:4]};
assign res_addr={core_cnt[13:7]-(status!=JOIN_UP) ,core_cnt[6:0]};

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
		core_cnt<=14'd128;
		cnt<=2'b01;
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
				res_do<=`MIN_4(`P(0,1),`P(0,0),`P(1,0),`P(2,0));
				res_rd<=0;
				status<=CTRL;
			end
			CTRL:begin
				res_wr<=0;
				if(core_cnt[6:0]==7'b1111110) begin //end col
					if(core_cnt[13:7]==7'b1111111) done<=1;
					else begin //get data
						if(cnt==2'b11) begin
							res_rd<=1;
							status<=JOIN_BOTTOM;
							core_cnt<={core_cnt[13:7]+1,7'd1};
							sti_rd<=0;
							cnt<=2'b01;
						end
						else begin
							sti_rd<=1;
							cnt<=cnt+1;
						end
						if(cnt[1]) sti_tmp[cnt[0]]<={sti_tmp[1:0],sti_di};
					end
				end
				else core_cnt<=core_cnt+1;
			end
			JOIN_BOTTOM:begin
				res_wr<=(sti_tmp[core_cnt[3:0]+1][0]);
				res_do<=`MIN_2(res_di,`MIN_4(`P(2,1),`P(0,1),`P(1,1),`P(2,1)))+1;
				res_rd<=0;
				status<=JOIN_UP;
			end
		endcase
	end
end
endmodule

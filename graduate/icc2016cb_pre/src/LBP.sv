
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output logic  [13:0] 	gray_addr;
output logic         	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output logic  [13:0] 	lbp_addr;
output logic  	lbp_valid;
output logic  [7:0] 	lbp_data;
output logic  	finish;
//====================================================================

enum {GET_DATA,CALC,FINISH} status;
logic [7:0]cache[3][3];
/* 
cache:
(2,0)(1,0)(0,0)
(2,1)(1,1)(0,1)
(2,2)(1,2)(0,2)
POS:
0,1,2
3, ,4
5,6,7
*/
localparam struct{
	x;
	y;
} POS={'{2,0},'{1,0},'{0,0},'{2,1},'{0,1},'{2,2},'{1,2},'{0,2}};
logic [13:0]core_cnt;
logic [1:0]req_x,req_y, next_x,next_y;
logic [4:0]i;

always_ff @(posedge clk,posedge reset) begin
	if(reset) begin
		gray_req<=0;
		lbp_data<=0;
		lbp_addr<=0;
		lbp_valid<=0;
		cache<='{default:'0};
		core_cnt<=0;
		req_x<=0;
		req_y<=0;
	end
	else begin
		case(status)
			GET_DATA:begin
				lbp_valid<=0;
				if(gray_ready) begin
					gray_req<=1;
					if(gray_req) begin
						// get data
						cache[req_x][req_y]<=gray_data;
						// next request
						if(req_y) next_y=req_y-1;
						else begin
							if(next_x) begin
								next_x=req_x-1;
								next_y=3;
							end
							else status<=CALC;
						end
						req_x<=next_x;
						req_y<=next_y;
						gray_addr<={core_cnt[13:7]+next_y,core_cnt[6:0]+7'd2-next_x};
					end
					else begin // control to get data
						req_x<=(core_cnt[6:0])? 3:0;
						req_y<=3;
						// shift left
						if(!core_cnt[6:0]) begin
							for(i=0;i<3;++i) begin
								cache[2][i]<=cache[1][i];
								cache[1][i]<=cache[0][i];
							end
						end
					end
				end
			end
			CALC:begin
				gray_req<=0;
				lbp_valid<=1;
				lbp_addr<={core_cnt[13:7]+7'd1,core_cnt[6:0]+7'd1};
				for(i=0;i<8;++i) begin
					lbp_data[i]<=(cache[POS[i].x][POS[i].y]>=cache[1][1]);
				end
				status<=(core_cnt==14'b11111011111101)? FINISH:GET_DATA;
				core_cnt<=core_cnt+(core_cnt[6:0]==7'b1111101)? 3:1;
			end
			FINISH:begin
				lbp_valid<=0;
				gray_req<=0;
				finish<=1;
			end
		endcase
	end
end

//====================================================================
endmodule

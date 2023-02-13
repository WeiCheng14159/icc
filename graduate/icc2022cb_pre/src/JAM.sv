`define SWAP(a,b) \
	temp=a;\
	a=b;\
	b=temp;

module JAM (
	input CLK,
	input RST,
	output logic [2:0] W,
	output logic [2:0] J,
	input [6:0] Cost,
	output logic [3:0] MatchCount,
	output logic [9:0] MinCost,
output logic Valid );

logic [6:0]cost[8][8];
logic [2:0]order[2][8],tmp_order[8];
enum {INIT,GET,CALC,DONE}status_e;

logic [3:0]temp; // for macro

logic [2:0]swap_index[2],larger_index[2];
logic [2:0]pw,pj,cnt,swap_number[2],larger_number[2];
logic [3:0]i,j;
logic [9:0]cur_sum;

//'{order[0],order[1]....,order[7]}
//find swap point and min point
always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		swap_index<='{3'd6,3'd0};
		swap_number<='{3'd6,3'd0};
		larger_index<='{3'd7,3'd0};
		larger_number<='{3'd7,3'd0};
	end
	else begin
		if(cnt) begin
			if(order[0][cnt]>order[0][cnt-1]) begin
				swap_index[0]<=cnt-1;
				swap_number[0]<=order[0][cnt-1];
				larger_index[0]<=cnt;
				larger_number[0]<=order[0][cnt];
			end
			else if(order[0][cnt] inside {[swap_number[0]:larger_number[0]]}) begin
				larger_index[0]<=cnt;
				larger_number[0]<=order[0][cnt];
			end
		end
		else begin
			if(status_e==CALC) swap_index[0]<=3'd7;
			swap_index[1]<=swap_index[0];
			swap_number[1]<=swap_number[0];
			larger_index[1]<=larger_index[0];
			larger_number[1]<=larger_number[0];
		end
	end
end
//sum & check
always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		cur_sum<={10{1'b1}};
		MatchCount<=4'd0;
		MinCost<={10{1'b1}};
	end
	else begin
		if(cnt==0&&status_e==CALC) begin
			if(cur_sum<MinCost) begin
				MinCost<=cur_sum;
				MatchCount<=1;
			end
			else if(cur_sum==MinCost) MatchCount<=MatchCount+1;
			cur_sum<=cost[0][order[1][0]];
		end
		else cur_sum<=cur_sum+cost[cnt][order[0][cnt]];
	end
end

always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		order[0]<='{3'd0,3'd1,3'd2,3'd3,3'd4,3'd5,3'd6,3'd7};
		order[1]<='{3'd4,3'd0,3'd1,3'd2,3'd3,3'd5,3'd6,3'd7};
		cost<='{default: '0};
		W<=3'd7;
		J<=3'd7;
		pw<=3'd7;
		pj<=3'd7;
		Valid<=1'b0;
		status_e<=INIT;
		cnt<=3'd0;
	end
	else begin
		case(status_e)
			INIT: begin
				if(W) W<=W-3'd1;
				else begin
					J<=J-3'd1;
					W<=3'd7;
				end
				pw<=W;
				pj<=J;
				if(!(pw|pj)) status_e<=CALC;
				cost[pw][pj]<=Cost;
			end
			CALC: begin
				cnt<=cnt+3'd1;
				// wonder how to deal with data confusion while writing?
				//swap points
				if(cnt==0) begin
					if(swap_index[0]==3'd7) status_e<=DONE;
					tmp_order=order[0];
					order[0]<=order[1];
					tmp_order[swap_index[0]]=larger_number[0];
					tmp_order[larger_index[0]]=swap_number[0];
					order[1]<=tmp_order;
				end
				else begin
					if(cnt inside {[swap_index[1]+1:3+((swap_index[1]+1)>>1)]}) begin
						order[1][cnt]<=order[1][4'd8-cnt+swap_index[1]];
						order[1][4'd8-cnt+swap_index[1]]<=order[1][cnt];
					end
				end
			end
			DONE: begin
				Valid<=1;
			end
		endcase
	end
end


endmodule

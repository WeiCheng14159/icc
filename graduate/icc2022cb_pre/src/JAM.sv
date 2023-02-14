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
logic [2:0]order[8],tmp_order[8];
enum {INIT,GET,CALC,DONE}status_e;

logic [3:0]temp; // for macro

logic [2:0]swap_index,larger_index;
logic [2:0]pw,pj,cnt,swap_number,larger_number;
logic [3:0]i,j;
logic [9:0]cur_sum;

//'{order[0],order[1]....,order[7]}
//find swap point and min point
always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		swap_index<=3'd0;
		swap_number<=3'd0;
		larger_index<=3'd0;
		larger_number<=3'd0;
	end
	else begin
		if(cnt==7) swap_index<=3'd7;
		else if(order[cnt+1]>order[cnt]) begin
			swap_index<=cnt;
			swap_number<=order[cnt];
		end
		if(order[cnt] inside {[swap_number:larger_number]}) begin
			larger_index<=cnt;
			larger_number<=order[cnt];
		end
	end
end
//sum & check
//logic [9:0]adder_sum;
//assign adder_sum=cur_sum+cost[cnt][order[cnt]];
always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		cur_sum<={10{1'b1}};
		MatchCount<=4'd0;
		MinCost<={10{1'b1}};
	end
	else begin
		if(cnt==7) begin
			if(cur_sum+cost[7][order[7]]<MinCost) begin
				MinCost<=cur_sum+cost[7][order[7]];
				MatchCount<=1;
			end
			else if(cur_sum==MinCost) MatchCount<=MatchCount+1;
			cur_sum<=0;
		end
		else cur_sum<=cur_sum+cost[cnt][order[cnt]];
	end
end

//reorder order
always_comb begin
	tmp_order=order;
	tmp_order[swap_index]=larger_number;
	tmp_order[larger_index]=swap_number;
	unique case(swap_index)
		3'd0: tmp_order<='{tmp_order[0],tmp_order[7],tmp_order[6],tmp_order[5],tmp_order[4],tmp_order[3],tmp_order[2],tmp_order[1]};
		3'd1: tmp_order<='{tmp_order[0],tmp_order[1],tmp_order[7],tmp_order[6],tmp_order[5],tmp_order[4],tmp_order[3],tmp_order[2]};
		3'd2: tmp_order<='{tmp_order[0],tmp_order[1],tmp_order[2],tmp_order[7],tmp_order[6],tmp_order[5],tmp_order[4],tmp_order[3]};
		3'd3: tmp_order<='{tmp_order[0],tmp_order[1],tmp_order[2],tmp_order[3],tmp_order[7],tmp_order[6],tmp_order[5],tmp_order[4]};
		3'd4: tmp_order<='{tmp_order[0],tmp_order[1],tmp_order[2],tmp_order[3],tmp_order[4],tmp_order[7],tmp_order[6],tmp_order[5]};
		3'd5: tmp_order<='{tmp_order[0],tmp_order[1],tmp_order[2],tmp_order[3],tmp_order[4],tmp_order[5],tmp_order[7],tmp_order[6]};
		3'd6: tmp_order<='{tmp_order[0],tmp_order[1],tmp_order[2],tmp_order[3],tmp_order[4],tmp_order[5],tmp_order[6],tmp_order[7]};
	endcase
end

always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		order<='{3'd0,3'd1,3'd2,3'd3,3'd4,3'd5,3'd6,3'd7};
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
				if(cnt==7) begin
					if(swap_index==3'd7) status_e<=DONE;
					order<=tmp_order;
				end
			end
			DONE: begin
				Valid<=1;
			end
		endcase
	end
end


endmodule

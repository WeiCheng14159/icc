module JAM (
	input CLK,
	input RST,
	output logic [2:0] W,
	output logic [2:0] J,
	input [6:0] Cost,
	output logic [3:0] MatchCount,
	output logic [9:0] MinCost,
output logic Valid );

logic [2:0]order[8],tmp_order[8],rotate[8];
enum {CALC,CHECK,DONE,NONE}status_e[3];

logic [2:0]swap_index,larger_index;
logic [2:0]cnt,swap_number,larger_number;
logic [9:0]cur_sum;
logic init_skip;

//find swap point and min point
always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		swap_index<=3'd6;
		swap_number<=3'd6;
		larger_index<=3'd6;
		larger_number<=3'd6;
	end
	else begin
		case(status_e[0])
			CALC: begin
				if(cnt!=3'd7 && order[1]>order[0]) begin
					swap_index<=cnt;
					swap_number<=order[0];
					larger_index<=cnt;
					larger_number<=order[1];
				end
				else if(order[0] inside {[swap_number:larger_number]}) begin
					larger_index<=cnt;
					larger_number<=order[0];
				end
			end
			CHECK: swap_index<=3'd7;
		endcase
	end
end

//sum & check
always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		cur_sum<=0;
		W<=0;
		J<=0;
		MatchCount<=4'd0;
		MinCost<={10{1'b1}};
		init_skip<=1;
	end
	else begin
		if(status_e[0]==CALC) begin
			W<=cnt;
			J<=order[0];
		end
		case (status_e[2])
			CALC: cur_sum<=cur_sum+Cost;
			CHECK: begin
				if(cur_sum<MinCost) begin
					MinCost<=cur_sum;
					MatchCount<=1;
				end
				else if(cur_sum==MinCost) MatchCount<=MatchCount+1;
				cur_sum<=0;
			end
		endcase
	end
end

assign rotate='{order[1],order[2],order[3],order[4],order[5],order[6],order[7],order[0]};

always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		order<='{3'd0,3'd1,3'd2,3'd3,3'd4,3'd5,3'd6,3'd7};
		Valid<=1'b0;
		status_e<='{CALC,NONE,NONE};
		cnt<=3'd0;
	end
	else begin
		for(int i=1;i<3;++i) status_e[i]<=status_e[i-1];
		unique case(status_e[0])
			CALC: begin
				cnt<=cnt+3'd1;
				if(cnt==3'd7) status_e[0]<=CHECK;
				order<=rotate;

			end
			CHECK: begin
				//reorder order
				tmp_order=order;
				tmp_order[swap_index]=larger_number;
				tmp_order[larger_index]=swap_number;
				case(swap_index)
					3'd0: tmp_order='{tmp_order[0],tmp_order[7],tmp_order[6],tmp_order[5],tmp_order[4],tmp_order[3],tmp_order[2],tmp_order[1]};
					3'd1: tmp_order='{tmp_order[0],tmp_order[1],tmp_order[7],tmp_order[6],tmp_order[5],tmp_order[4],tmp_order[3],tmp_order[2]};
					3'd2: tmp_order='{tmp_order[0],tmp_order[1],tmp_order[2],tmp_order[7],tmp_order[6],tmp_order[5],tmp_order[4],tmp_order[3]};
					3'd3: tmp_order='{tmp_order[0],tmp_order[1],tmp_order[2],tmp_order[3],tmp_order[7],tmp_order[6],tmp_order[5],tmp_order[4]};
					3'd4: tmp_order='{tmp_order[0],tmp_order[1],tmp_order[2],tmp_order[3],tmp_order[4],tmp_order[7],tmp_order[6],tmp_order[5]};
					3'd5: tmp_order='{tmp_order[0],tmp_order[1],tmp_order[2],tmp_order[3],tmp_order[4],tmp_order[5],tmp_order[7],tmp_order[6]};
					3'd6: tmp_order='{tmp_order[0],tmp_order[1],tmp_order[2],tmp_order[3],tmp_order[4],tmp_order[5],tmp_order[6],tmp_order[7]};
				endcase
				order<=tmp_order;

				if(swap_index==3'd7) status_e[0]<=DONE;
				else status_e[0]<=CALC;
			end
			DONE: begin
				if(status_e[2]==DONE) Valid<=1;
			end
		endcase
	end
end


endmodule

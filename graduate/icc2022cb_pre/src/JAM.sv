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
	output logic Valid
);

logic [6:0]cost[8][8],cur_cost[8];
logic [6:0]swap_point,larger_point;
logic [2:0]order[8],sp_number,lp_number;
logic [2:0]new_order[8];
enum {INIT,CALC,DONE}status;

logic [3:0]temp; // for macro

logic [2:0]min_point,pw,pj;

always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		for(i=0;i<8;++i) order[i]<=i;
		cost<='{default: 0};
		W<=3'd7;
		J<=3'd7;
		pw<=3'd7;
		pj<=3'd7;
		cmp<=8'd0;
		MatchCount<=4'd0;
		MinCost<={10{1'b1}};
		Valid<=1'b0;
	end
	else begin
		unique case(status)
			INIT: begin
				if(!W) begin
					if(J) J<=J-3'd1;
					W<=3'd7;
				end
				else W<=W-3'd1;
				pw<=W;
				pj<=J;
				if(!{pw,pj}) status<=CALC;
				cost[pw][pj]<=Cost;
			end
			CALC: begin
				//find swap point
				swap_point=0;
				for(i=7;i;--i) begin
					if(order[i]>order[i-1]) begin
						swap_point=i;
						break;
					end
				end
				j=swap_point;
				for(i=1;i<8;++i) begin
					if(i>=swap_point&&(order[i] inside {[order[swap_point-1]:order[j]]})) j=i;
				end
				`SWAP(new_order[j],new_order[swap_point-1]);
				for(i=swap_point,j=7;i<j;++i,--j) begin
					`SWAP(new_order[i],new_order[j])
				end
				for(i=0;i<8;++i) order[i]<=new_order[i];
				if(!swap_point) status<=DONE;
				//calc
				tmp_cost=0;
				for(i=0;i<8;++i) tmp_cost=tmp_cost+cost[i][order[i]];
				if(tmp_cost<MinCost) begin
					MinCost<=tmp_cost;
					MatchCount<=4'd1;
				end
				else if(tmp_cost==MinCost) MatchCount<=MatchCount+1;
			end
			DONE: begin
				Valid<=1;
			end
		endcase
	end
end


endmodule



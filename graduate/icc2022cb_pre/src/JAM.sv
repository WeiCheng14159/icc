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
logic [2:0]order[8];
logic [2:0]new_order[8];
enum {INIT,CALC,DONE}status;

logic [3:0]temp; // for macro

logic [2:0]swap_point,min_point,pw,pj;
logic [3:0]i,j;
logic [9:0]tmp_cost;

always_ff@(posedge CLK,posedge RST) begin
	if(RST) begin
		for(i=0;i<8;++i) order[i]<=i;
		cost<='{default: '0};
		W<=3'd7;
		J<=3'd7;
		pw<=3'd7;
		pj<=3'd7;
		MatchCount<=4'd0;
		MinCost<={10{1'b1}};
		Valid<=1'b0;
	end
	else begin
		case(status)
			INIT: begin
				if(!W) begin
					if(!J) status<=CALC;
					else J<=J-3'd1;
					W<=3'd7;
				end
				else W<=W-3'd1;
				pw<=W;
				pj<=J;
				cost[pw][pj]<=Cost;
			end
			CALC: begin
				//swap
				for(i=0;i<8;++i) new_order[i]=order[i];
				swap_point=0;
				for(i=7;i;--i) begin
					if(order[i]>order[i-1]) begin
						swap_point=i;
						break;
					end
				end
				for(i=swap_point+1,j=swap_point;i<8;++i) begin
					if(order[j]>order[i]&&order[i]>order[swap_point-1]) j=i;
				end
				`SWAP(new_order[j],new_order[swap_point-1]);
				unique case(swap_point)
					3'd1: order<='{new_order[0],new_order[1],new_order[2],new_order[3],new_order[4],new_order[5],new_order[6],new_order[7]};
					3'd2: order<='{new_order[1],new_order[0],new_order[2],new_order[3],new_order[4],new_order[5],new_order[6],new_order[7]};
					3'd3: order<='{new_order[2],new_order[1],new_order[0],new_order[3],new_order[4],new_order[5],new_order[6],new_order[7]};
					3'd4: order<='{new_order[3],new_order[2],new_order[1],new_order[0],new_order[4],new_order[5],new_order[6],new_order[7]};
					3'd5: order<='{new_order[4],new_order[3],new_order[2],new_order[1],new_order[0],new_order[5],new_order[6],new_order[7]};
					3'd6: order<='{new_order[5],new_order[4],new_order[3],new_order[2],new_order[1],new_order[0],new_order[6],new_order[7]};
					3'd7: order<='{new_order[6],new_order[5],new_order[4],new_order[3],new_order[2],new_order[1],new_order[0],new_order[7]};
				endcase
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

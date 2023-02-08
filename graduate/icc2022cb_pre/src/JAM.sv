`define SWAP(a,b) \
	temp=a;\
	a=b;\
	b=temp;

module add #(parameter WIDTH=32,SIZE=2)(
	input [WIDTH-1:0] data[SIZE],
	output [WIDTH+$clog2(SIZE+1)-1:0]sum
);
generate
case SIZE
	1:assign result=data[0];
	2:assign result=data[0]+data[1];
	default: begin
		min #(.WIDTH (WIDTH),.SIZE(SIZE/2))
			right(.data(data[SIZE/2-1:0]),.result(r1));

		min #(.WIDTH (WIDTH),.SIZE(SIZE-SIZE/2))
			left(.data(data[SIZE-1:SIZE/2]),.result(r2));

		assign result=r1+r2;
	end
endcase
endgenerate
endmodule

module extract #(parameter WIDTH=3,SIZE=8)(
	input [SIZE-1:0]hot_index,
	input [WIDTH-1:0]array[SIZE],
	output logic [WIDTH-1:0]element
);
logic [WIDTH-1:0]filtered[SIZE];
always_comb begin
	for(int i=0;i<SIZE;++i) filtered[i]=hot_index[i]? array[i]:0;
	element=filtered.or();
end
endmodule



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
				for(i=0;i<7;++i) swap_point[i]=(order[i+1]<order[i]);
				if(!swap_point) status<=DONE;
				swap_point=swap_point&(-swap_point);//rightest set bit=swap_point
				extract spe(.hot_index('{swap_point,1'b0}),.array(order),.element(sp_number));
				//find min number > swap point number on right side of swap point
				lp_number=3'b111;
				larger_point=0;
				for(i=0;i<7;++i) begin
					if(((7'b1000000>>>i)&swap_point)&&(order[6-i]>sp_number)&&(order[6-i]<lp_number)) begin
						larger_point=1<<(6-i);
						lp_number=order[i];
					end
				end
				//swap
				for(int i=0;i<8;++i) begin
					if('{swap_point,1'b0}[i]|'{1'b0,larger_point}[i]) new_order[i]=('{swap_point,1'b0}[i])? sp_number:lp_number;
					else new_order[i]=order[i];
				end
				//reverse right side of swap point
				unique case(1'b1)
					generate
					for(int i=0;i<7;++i) begin
						swap_point[i]: {>>3{order}}<='{new_order[7:i+1],{<<3{new_order[i:0]}}};
					end
					endgenerate
				endcase
				//calc job
				for(int i=0;i<8;++i) cur_cost[i]=cost[i][order[i]];
				add #(.WIDTH(7),.SIZE(8)) cost_adder (.data(cur_cost),.result(cur_sum));
				if(cur_sum<MinCost) begin
					MinCost=cur_sum;
					MatchCount<=0;
				end
				else if(cur_sum==MinCost) MatchCount<=MatchCount+1;

				////swap_point=0;
				////for(i=7;i;--i) begin
				////	if(order[i]>order[i-1]) begin
				////		swap_point=i;
				////		break;
				////	end
				////end
				////j=swap_point;
				////for(i=1;i<8;++i) begin
				////	if(i>=swap_point&&(order[i] inside {[order[swap_point-1]:order[j]]})) j=i;
				////end
				////`SWAP(new_order[j],new_order[swap_point-1]);
				////for(i=swap_point,j=7;i<j;++i,--j) begin
				////	`SWAP(new_order[i],new_order[j])
				////end
				////for(i=0;i<8;++i) order[i]<=new_order[i];
				////if(!swap_point) status<=DONE;
				//calc
				////tmp_cost=0;
				////for(i=0;i<8;++i) tmp_cost=tmp_cost+cost[i][order[i]];
				////if(tmp_cost<MinCost) begin
				////	MinCost<=tmp_cost;
				////	MatchCount<=4'd1;
				////end
				////else if(tmp_cost==MinCost) MatchCount<=MatchCount+1;
			end
			DONE: begin
				Valid<=1;
			end
		endcase
	end
end


endmodule



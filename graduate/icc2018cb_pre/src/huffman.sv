module huffman(clk, reset, gray_valid, CNT_valid, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
    code_valid, HC1, HC2, HC3, HC4, HC5, HC6);

input clk;
input reset;
input gray_valid;
input [7:0] gray_data;
output CNT_valid;
output [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
output code_valid;
output [7:0] HC1, HC2, HC3, HC4, HC5, HC6;
output [7:0] M1, M2, M3, M4, M5, M6;
  
logic [7:0]HC[6];
logic [7:0]M[6];
assign HC1 <=HC[0] ;
assign HC2 <=HC[1] ;
assign HC3 <=HC[2] ;
assign HC4 <=HC[3] ;
assign HC5 <=HC[4] ;
assign HC6 <=HC[5] ;
assign M1  <=M[0]  ;
assign M2  <=M[1]  ;
assign M3  <=M[2]  ;
assign M4  <=M[3]  ;
assign M5  <=M[4]  ;
assign M6  <=M[5]  ;

struct packed{
	logic [3:0] right,left,parrent;
	logic [7:0] cnt;
} tree[11];
logic [3:0]uncoded[6],min_1,min_2;

assign CNT1<=tree[0].cnt;
assign CNT2<=tree[1].cnt;
assign CNT3<=tree[2].cnt;
assign CNT4<=tree[3].cnt;
assign CNT5<=tree[4].cnt;
assign CNT6<=tree[5].cnt;

enum {INPUT,GENERATE_TREE,GENERATE_CODE} status;
logic [2:0]cnt;
logic [2:0]i,ended;

always_ff @(posedge clk,posedge reset) begin
	if(reset) begin
		CNT_valid<=0;
		code_valid<=0;
		status<=INPUT;
		cnt<=0;
		CNT<='{default: '0};
		HC <='{default: '0};
		M  <='{default: '0};
		for(i=0;i<11;++i) tree[i]<='{i,4'hf,4'hf,0};
		uncoded<='{default: '1};
	end
	else begin
		case(status)
			INPUT: begin
				if(gray_valid) begin //input
					cnt<=6;
					tree[gray_data-1].cnt<=tree[gray_data-1].cnt+1;
				end
				else if(cnt) begin //already inputted & stop input
					for(i=0;i<6 ;++i) uncoded[i]<=i;
					status<=GENERATE_TREE;
				end
				code_valid<=0;
			end
			GENERATE_TREE: begin
				// fond min & second min
				min_1=4'hf;
				min_2=4'hf;
				for(i=0;i<6;++i) begin
					if(!~uncoded[i]) begin
						if(tree[uncoded[i]].cnt<tree[uncoded[min_2]].cnt) begin
							if(tree[uncoded[i]].cnt<tree[uncoded[min_1]].cnt) min_1=i;
							else min_2=i;
						end
					end
				end
				// combine & create tree
				tree[cnt]<='{uncoded[min_1],uncoded[min_2],4'hf,tree[min_1].cnt+tree[min_2].cnt};
				tree[uncoded[min_1]].parrent<=cnt;
				tree[uncoded[min_2]].parrent<=cnt;
				uncoded[min_1]<=cnt;
				uncoded[min_2]<=4'hf;
				
				// final & +1
				if(cnt==11) status<=GENERATE_CODE;
				cnt<=cnt+1;
			end
			GENERATE_CODE: begin
				ended=1;
				for(i=0;i<6;++i) begin
					if(!~tree[i].parrent) begin
						ended=0;
						HC<={HC[6:0],(tree[tree[i].parrent].left==tree[i].right)};
						M<={M[6:0],1'b1};
						tree[i].right<=tree[i].parrent;
						tree[i].parrent<=tree[tree[i].parrent].parrent;
					end
				end
				if(ended) begin
					for(i=0;i<6;++i) tree[i]<='{i,4'hf,4'hf,0};
					cnt<=0;
					code_valid<=1;
					status<=INPUT;
				end
			end
		endcase
	end
end

endmodule


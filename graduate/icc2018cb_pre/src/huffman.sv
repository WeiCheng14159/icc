module huffman(clk, reset, gray_valid, gray_data, CNT_valid, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
    code_valid, HC1, HC2, HC3, HC4, HC5, HC6, M1, M2, M3, M4, M5, M6,cnt,cnt2,cnt3);

input clk;
input reset;
input gray_valid;
input [7:0] gray_data;
output logic CNT_valid;
output logic [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
output logic code_valid;
output logic [7:0] HC1, HC2, HC3, HC4, HC5, HC6;
output logic [7:0] M1, M2, M3, M4, M5, M6;
  
logic [7:0]HC[6];
logic [7:0]M[6];
assign HC1 =HC[0] ;
assign HC2 =HC[1] ;
assign HC3 =HC[2] ;
assign HC4 =HC[3] ;
assign HC5 =HC[4] ;
assign HC6 =HC[5] ;
assign M1  =M[0]  ;
assign M2  =M[1]  ;
assign M3  =M[2]  ;
assign M4  =M[3]  ;
assign M5  =M[4]  ;
assign M6  =M[5]  ;

struct packed{
	logic [3:0] left,right,parrent;
	logic is_left;
	logic [7:0] cnt;
} tree[11];
logic [3:0]uncoded[6],min_1,min_2;//6

assign CNT1=tree[0].cnt;
assign CNT2=tree[1].cnt;
assign CNT3=tree[2].cnt;
assign CNT4=tree[3].cnt;
assign CNT5=tree[4].cnt;
assign CNT6=tree[5].cnt;

enum {INPUT,FIND_MIN,GENERATE_TREE,GENERATE_CODE} status;
output logic [3:0]cnt,cnt2,cnt3;
logic [3:0]i;
logic ended;

always_ff @(posedge clk,posedge reset) begin
	if(reset) begin
		CNT_valid<=0;
		code_valid<=0;
		status<=INPUT;
		cnt<=0;
		cnt2<=0;
		cnt3<=0;
		HC <='{default: '0};
		M  <='{default: '0};
		for(i=0;i<11;++i) tree[i]<='{i,4'hf,4'hf,0,0};
		uncoded<='{default: '1};
		min_1<=4'hf;
		min_2<=4'hf;
	end
	else begin
		case(status)
			INPUT: begin
				code_valid<=0;
				// input
				if(gray_valid) begin
					cnt<=6;
					tree[gray_data-1].cnt<=tree[gray_data-1].cnt+1;
				end
				else if(cnt) begin //already inputted & stop input
					for(i=0;i<6 ;++i) uncoded[i]<=i;
					CNT_valid<=1;
					status<=FIND_MIN;
					min_1<=4'hf;
					min_2<=4'hf;
				end
			end
			FIND_MIN: begin
				CNT_valid<=0;
				// fond min & second min
				if(~uncoded[cnt2]) begin
					if((min_2==4'hf)||tree[uncoded[cnt2]].cnt<=tree[uncoded[min_2]].cnt) begin
						if((min_1==4'hf)||tree[uncoded[cnt2]].cnt<=tree[uncoded[min_1]].cnt) begin
							if(tree[uncoded[cnt2]].cnt==tree[uncoded[min_1]].cnt && uncoded[cnt2]<uncoded[min_1]) begin
								min_2<=cnt2;
							end
							else begin
								min_2<=min_1;
								min_1<=cnt2;
							end
						end
						else min_2<=cnt2;
					end
				end
				if(cnt2==5) begin
					status<=GENERATE_TREE;
					cnt2<=0;
				end
				else cnt2<=cnt2+1;
			end
			GENERATE_TREE: begin
				// combine & create tree
				tree[cnt]<='{uncoded[min_1],uncoded[min_2],4'hf,0,tree[uncoded[min_1]].cnt+tree[uncoded[min_2]].cnt};
				tree[uncoded[min_1]].is_left<=1;
				tree[uncoded[min_1]].parrent<=cnt;
				tree[uncoded[min_2]].parrent<=cnt;
				uncoded[min_1]<=cnt;
				uncoded[min_2]<=4'hf;

				// final & +1
				if(cnt==10) status<=GENERATE_CODE;
				else begin
					min_1<=4'hf;
					min_2<=4'hf;
					status<=FIND_MIN;
					cnt<=cnt+1;
				end
			end
			GENERATE_CODE: begin
				// generate huffman code from tree
				ended=1;
				for(i=0;i<6;++i) begin
					HC[i][cnt3]<=tree[i].is_left;
					if(~tree[i].parrent) begin
						ended=0;
						M[i]<={M[i][6:0],1'b1};
						tree[i]<=tree[tree[i].parrent];
					end
				end
				// end
				if(ended) code_valid<=1;
				else cnt3<=cnt3+1;
			end
		endcase
	end
end

endmodule


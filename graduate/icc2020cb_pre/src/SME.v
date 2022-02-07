`include "def.v"
`define space 8'h20
`define NEXT_PATTERN_START \
	if(star_pattern&&str_star<=str_max) begin// restart from prev * \
		str_star<=str_star+1; \
		pattern_cur<=pattern_star; \
		str_cur<=str_star; \
	end \
	else begin// restart \
		pattern_cur<=0; \
		str_cur<=start+1; \
		start<=start+1; \
	end
module SME(
	input                                 clk,
	input                                 reset,
	input                           [7:0] chardata,
	input                                 isstring,
	input                                 ispattern,
	output reg                            match,
	output reg                      [4:0] match_index,
	output reg                            valid
);
reg [5:0]start,str_max,str_star,str_cur;
reg [3:0]pattern_max,pattern_star,pattern_cur;
reg [7:0]str[0:33];
reg [7:0]pattern[0:7];
reg busy,star_pattern;

integer i;
always @(posedge clk,posedge reset) begin
	if(reset)begin
		match<=0;
		match_index<=0;
		valid<=0;
		str_cur<=0;
		str_max<=1;
		str_star<=0;
		pattern_cur<=0;
		pattern_max<=0;
		pattern_star<=0;
		busy<=0;
		star_pattern<=0;
		for(i=0;i<34;i=i+1) str[i]<=`space;
		for(i=0;i<8;i=i+1) pattern[i]<=0;
	end
	else begin
		case(1'b1)
			isstring:begin
				if(busy) begin
					busy<=0;
					valid<=0;
					pattern_max<=0;
					str_max<=2;
					str[1]<=chardata;
				end
				else begin
					str_max<=str_max+1;
					str[str_max]<=chardata;
				end
			end
			ispattern:begin
				str_cur<=0;
				pattern_cur<=0;
				star_pattern<=0;
				start<=0; 
				if(busy) begin
					busy<=0;
					valid<=0;
					pattern_max<=1;
					pattern[0]<=chardata;
				end
				else begin
					pattern_max<=pattern_max+1;
					pattern[pattern_max]<=chardata;
				end
			end
			busy:begin
				str[str_max]<=`space;// set last to space
				if(pattern_cur==pattern_max) begin // match
					match_index<=start-1;
					match<=1;
					valid<=1;
				end
				else if(str_cur==str_max+2) begin // not match
					match<=0;
					valid<=1;
				end
				else begin
					case(pattern[pattern_cur])
						str[str_cur]:begin
							pattern_cur<=pattern_cur+1;
							str_cur<=str_cur+1;
						end
						8'h5E:begin //^
							if(str[str_cur-1]==`space) pattern_cur<=pattern_cur+1;
							else begin
								str_cur<=start+1;
								start<=start+1;
							end
						end
						8'h24:begin //$
							if(str[str_cur]==`space) pattern_cur<=pattern_cur+1;
							else begin
								`NEXT_PATTERN_START
							end
						end
						8'h2E:begin //.
							pattern_cur<=pattern_cur+1;
							if(str_cur)	str_cur<=str_cur+1;// skip padding space
							else begin
								str_cur<=str_cur+2;
								start<=1;
							end
						end
						8'h2A:begin //*
							star_pattern<=1;
							pattern_star<=pattern_cur+1;
							pattern_cur<=pattern_cur+1;
							str_star<=str_cur;
						end
						default:begin // not match
							`NEXT_PATTERN_START
						end
					endcase
				end
			end
			default:begin
				if(str_max&&pattern_max&&!busy) busy<=1;
			end
		endcase
	end
end
endmodule

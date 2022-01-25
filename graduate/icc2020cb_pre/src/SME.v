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




endmodule

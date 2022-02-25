`define abs(a,b) ((a>b)? a-b:b-a)
`define is_in_circle(c) \
	({1'b0,square[`abs(x,cx[c])]}+{1'b0,square[`abs(y,cy[c])]}<=square[cr[c]])

module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate;

reg [6:0]square[0:8];
reg [3:0]cx[0:2];
reg [3:0]cy[0:2];
reg [3:0]cr[0:2];

reg [3:0]x,y;
reg [1:0]tmp;
integer i;
always @(posedge clk,posedge rst) begin
	if(rst) begin
		busy<=1'b0;
		valid<=1'b0;
		x<=4'd0;
		y<=4'd0;
		candidate<=8'b0;
		// generate square number
		// read test data,range 0~8
		// 9(max center point)-1(min selected point)=8
		for(i=0;i<=8;i=i+1) begin
			square[i]<=i*i;
		end
		for(i=0;i<3;i=i+1) begin
			cx[i]<=0;
			cy[i]<=0;
			cr[i]<=0;
		end
	end
	else begin
		// get data
		if(en) begin
			x<=4'd1;
			y<=4'd1;
			busy<=1'b1;
			valid<=1'b0;
			candidate<=8'b0;
			for(i=0;i<3;i=i+1) begin
				cx[i]<=central[23-i*8 -: 4];
				cy[i]<=central[19-i*8 -: 4];
				cr[i]<=radius[11-i*4 -: 4];
			end
		end
		// calculate
		if(busy) begin
			if(valid) busy<=1'b0;
			case(mode)
				2'b00:begin
					if(`is_in_circle(0)) candidate<=candidate+8'd1;
				end
				2'b01:begin
					if(`is_in_circle(0)&&`is_in_circle(1)) candidate<=candidate+8'd1;
				end
				2'b10:begin
					if(`is_in_circle(0)^`is_in_circle(1)) candidate<=candidate+8'd1;
				end
				2'b11:begin
					tmp=0;
					for(i=0;i<3;i=i+1) begin
						if(`is_in_circle(i)) tmp=tmp+1;
					end
					if(tmp==2) candidate<=candidate+8'd1;
				end
			endcase
			// loop every point
			if(x==4'd8) begin
				x<=1;
				if(y==4'd8) begin //last point
					y<=4'd1;
					valid<=1'b1;
				end
				else y<=y+4'd1;
			end
			else x<=x+4'd1;
		end
		else valid<=0;
	end
end
endmodule

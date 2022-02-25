`include "def.v"

`define VECTOR(a,xy) $signed({11'd0,point[a].xy}-point[0].xy)
`define CROSS_PRODUCT(i,j) (`VECTOR(i,x)*`VECTOR(j,y)<`VECTOR(j,x)*`VECTOR(i,y))
`define DET(a,b) ({11'd0,a.x}*b.y-{11'd0,b.x}*a.y)
`define ABS(a,b) ((a>b)? (a-b):(b-a))
`define RELU(a,b) ((a>b)? (a-b):0)
`define SQUARE(a) ({10'd0,a}*{a})
`define DISTANCE(a,b) ({1'd0,`SQUARE(`ABS(point[a].x,point[b].x))}+`SQUARE(`ABS(point[a].y,point[b].y)))
`define DIV2(a) ((a+a[0])>>1)

`define THRESHHOLD 50

module geofence ( clk,reset,X,Y,R,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
input [10:0] R;
output logic valid;
output logic is_inside;
//reg valid;
//reg is_inside;
enum {GET_DATA,SORT_NODE,CALC_FENCE_AREA,CALC_EDGE,CALC_POINT_AREA_1,CALC_POINT_AREA_2,ANSWER} status;

struct packed{
	reg[9:0] x,y;
	reg[10:0] r;
} point[6];
logic [2:0] cnt,cnt2,i;
logic [22:0] fence_area,point_area;
logic [10:0] fence_edge;
logic [11:0]S,S_a,S_b,S_c;

logic [22:0] sqrt_in;
logic [11:0] sqrt_out,tmp,tmp2;
DW_sqrt #(.width(23)) sqrt(sqrt_in,sqrt_out);


always_ff @(posedge clk,posedge reset) begin
	if(reset) begin
		status<=GET_DATA;
		for(i=0;i<6;++i) point[i]<='{10'd0,10'd0,11'd0};
		cnt<=3'd0;
		cnt2<=3'd0;
		fence_area<=23'd0;
		point_area<=23'd0;
		fence_edge<=11'd0;
		tmp<=12'd0;
		tmp2<=12'd0;
		valid<=0;
		is_inside<=0;
	end
	else begin
		case(status)
			GET_DATA:begin
				valid<=0;
				if(cnt<3'd6) begin
					point[cnt]<='{X,Y,R};
					cnt<=cnt+1;
				end
				else begin
					status<=SORT_NODE;
					cnt<=3'd1;
					cnt2<=3'd2;
				end
			end
			SORT_NODE:begin
				if(`CROSS_PRODUCT(cnt,cnt2)) begin
					point[cnt]<=point[cnt2];
					point[cnt2]<=point[cnt];
				end
				if(cnt2==3'd5) begin
					cnt2<=cnt+2;
					if(cnt==3'd4) begin
						cnt<=3'd0;
						status<=CALC_FENCE_AREA;
					end
					else cnt<=cnt+1;
				end
				else cnt2<=cnt2+1;
				fence_area<=23'd0;
			end
			CALC_FENCE_AREA:begin 
				if(cnt==3'd5) begin
					status<=CALC_EDGE;
					fence_area<=(fence_area+`DET(point[5],point[0]));
					cnt<=3'd0;
				end
				else begin
					fence_area<=(fence_area+`DET(point[cnt],point[cnt+1]));
					cnt<=cnt+1;
				end
				point_area<=23'd0;
			end

			CALC_EDGE:begin //sqrt(x^2-y^2)=c
				point_area<=((tmp*tmp2)>>1);
				status<=CALC_POINT_AREA_1;
				fence_edge<=sqrt_out;
			end
			CALC_POINT_AREA_1:begin //sqrt(S*(S-a))
				if(cnt) fence_area<=`RELU(fence_area,point_area);
				if(cnt==6) status<=ANSWER;
				else status<=CALC_POINT_AREA_2;
				tmp<=sqrt_out;
			end
			CALC_POINT_AREA_2:begin //sqrt((S-b)*(S-c))
				status<=CALC_EDGE;
				tmp2<=sqrt_out;
				cnt<=cnt+1;
				valid<=0;
			end
			ANSWER:begin
				valid<=!valid;
				is_inside<=(fence_area)? 1:0;
				cnt<=0;
				if(valid) status<=GET_DATA;
			end
		endcase
	end
end
// control sqrt module
always_comb begin
	// S=a+b+c;
	// S_a=-a+b+c;
	// S_b=a-b+c;
	// S_c=a+b-c;
	if(cnt==3'd5) begin
		S={1'b0,fence_edge}+point[5].r+point[0].r;
		S_a=`RELU({1'b0,fence_edge}+point[0].r,point[5].r);
		S_b=`RELU({1'b0,fence_edge}+point[5].r,point[0].r);
		S_c=`RELU({2'd0,point[5].r}+point[0].r,fence_edge);
	end
	else begin
		S={1'b0,fence_edge}+point[cnt].r+point[cnt+1].r;
		S_a=`RELU({1'b0,fence_edge}+point[cnt+1].r,point[cnt].r);
		S_b=`RELU({1'b0,fence_edge}+point[cnt].r,point[cnt+1].r);
		S_c=`RELU({2'd0,point[cnt].r}+point[cnt+1].r,fence_edge);
	end
	case(status)
		CALC_EDGE:begin //sqrt(x^2-y^2)=c
			if(cnt==3'd5) sqrt_in={2'd0,`DISTANCE(5,0)};
			else sqrt_in={2'd0,`DISTANCE(cnt,cnt+1)};
		end
		CALC_POINT_AREA_1:begin //sqrt(S*(S-2a)) 
			sqrt_in={12'd0,S}*S_a;
		end
		CALC_POINT_AREA_2:begin //sqrt((S-2b)*(S-2c))
			sqrt_in={12'd0,S_b}*S_c;
		end
		default:sqrt_in=23'd0;
	endcase
end
endmodule

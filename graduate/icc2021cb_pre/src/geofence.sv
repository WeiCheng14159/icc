`include "def.v"
`include "DW_sqrt.v"

`define DIRECTION(a,b) ((a.x>b.y)^(b.x>a.y))
`define DET(a,b) ({11'd0,a.x}*b.y-{11'd0,b.x}*a.y)
`define ABS(a,b) ((a>b)? (a-b):(b-a))
`define RELU(a,b) ((a>b)? (a-b):0)
`define SQUARE(a) ({10'd0,a}*a)
`define DISTANCE(a,b) (`SQUARE(`ABS(point[a].x,point[b].x))+`SQUARE(`ABS(point[a].y,point[b].y)));

`define THRESHHOLD 25

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
enum {GET_DATA,SORT_NODE,CALC_FENCE_AREA,CALC_EDGE,CALC_POINT_AREA_1,CALC_POINT_AREA_2} status;

struct {
	reg[10:0] x,y;
	reg[10:0] r;
} point[6],tmp_point;
logic [2:0] cnt,i,j;
logic [21:0] tmp_area
logic [15:0] fence_area,tmp,point_area;
logic [10:0] fence_edge;
logic [12:0]S,S_a,S_b,S_c;

logic [20:0] sqrt_in;
logic [10:0] sqrt_out;
module DW_sqrt #(.width(21)) sqrt(sqrt_in,sqrt_out);

assign is_inside=`ABS(fence_area,point_area)<`THRESHHOLD;

always_ff @(posedge clk,posedge reset) begin
	if(reset) begin
		status<=GET_DATA;
		for(i=0;i<6;++i) tmp_point[i]<=0;
		cnt<=0;
		valid<=0;
		fence_area<=0;
		tmp<=0;
		point_area<=0;
		fence_edge<=0;
	end
	else begin
		case(status)
			GET_DATA:begin
				if(cnt<6) begin
					point[cnt]<=(cnt==0)? `{X,Y,R}:`{X-point[0].x,Y-point[0].y,R};
					cnt<=cnt+1;
				end
				else begin
					point[0].x=0;
					point[0].y=0;
					status<=SORT_NODE;
				end
			end
			SORT_NODE:begin
				for(i=1;i<6;++i) begin
					for(j=i+1;j<6;++j) begin
						if(`DIRECTION(point[i],point[j])) begin
							tmp_point=point[i];
							point[i]=point[j];
							point[j]=tmp_point;
						end
					end
				end
				cnt<=0;
				status<=CALC_FENCE;
			end
			CALC_FENCE_AREA:begin // not devided by 2 yet
				tmp_point=`{0,0,0};
				tmp_area=0;
				for(i=0;i<6;++i) begin
					case(i)
						5:tmp_area+=`DET(point[5],point[0]);
						default:tmp_area+=`DET(point[i],point[i+1]);
					endcase
					fence_area<={tmp_area[14:0],1'b0};
				end
				status<=CALC_EDGE;
				cnt<=0;
			end

			CALC_EDGE:begin //sqrt(x^2-y^2)
				status<=CALC_POINT_AREA_1;
				fence_edge<=sqrt_out;
			end
			CALC_POINT_AREA_1:begin //sqrt(S*(S-2a))
				status<=CALC_POINT_AREA_2;
				tmp<=sqrt_out;
			end
			CALC_POINT_AREA_2:begin //sqrt((S-2b)*(S-2c))
				status<=CALC_EDGE;
				point_area<=point_area+tmp*sqrt_out;
				cnt<=cnt+1;
				if(cnt==5) begin
					status<=GET_DATA;
					cnt<=0;
				end
			end
		endcase
	end
end
// control sqrt_in
always_comb begin
	// S=a+b+c (will devide 2 after calc area)
	// S_a=-a+b+c;
	// S_b=a-b+c;
	// S_c=a+b-c;
	if(cnt==5) begin
		S={2'd0,point[5].r}+point[0].r+fence_edge;
		S_a=`RELU({2'd0,point[0].r}+fence_edge,point[5].r);
		S_b=`RELU({2'd0,point[5].r}+fence_edge,point[0].r);
		S_c=`RELU({2'd0,point[5].r}+point[0].r,fence_edge);
	end
	else begin
		S={2'd0,point[cnt].r}+point[cnt+1].r+fence_edge;
		S_a=`RELU({2'd0,point[cnt+1].r}+fence_edge,point[cnt].r);
		S_b=`RELU({2'd0,point[cnt].r}+fence_edge,point[cnt+1].r);
		S_c=`RELU({2'd0,point[cnt].r}+point[cnt+1].r,fence_edge);
	end

	case(status)
		CALC_EDGE: //sqrt(x^2-y^2)
		if(cnt==5) sqrt_in=`DISTANCE(5,0);
		else sqrt_in=`DISTANCE(cnt,cnt+1);
	end
	CALC_POINT_AREA_1:begin //sqrt(S*(S-2a)) 
		sqrt_in=S*S_a;
	end
	CALC_POINT_AREA_2:begin //sqrt((S-2b)*(S-2c))
		sqrt_in=S_b*S_c;
	end
	default:sqrt_in=0;
endcase
end
endmodule

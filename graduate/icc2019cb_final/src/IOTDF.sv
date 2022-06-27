`timescale 1ns/10ps
`define EXTRACT_LOW 128'h6FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
`define EXTRACT_HIGH 128'hAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
`define EXCLUDE_LOW 128'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
`define EXCLUDE_HIGH 128'hBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output         busy;
output logic        valid;
output logic[127:0] iot_out;

typedef enum {Max=1,Min,Avg,Extract,Exclude,PeakMax,PeakMin} fn;

logic [127:0]in,out_tmp;
logic [127:0]max,min;
logic [130:0]sum;
logic [6:0]counter;

logic [5:0]i,j;
logic init,diff;
assign busy=0;
always_comb begin
	case(fn'(fn_sel)) // synopsys full_case
		Max: iot_out<=max;
		Min: iot_out<=min;
		Avg: iot_out<=sum[130:3];
		Extract: iot_out<=out_tmp;
		Exclude: iot_out<=out_tmp;
		PeakMax: iot_out<=max;
		PeakMin: iot_out<=min;
	endcase
end
always_ff @(posedge clk,posedge rst) begin
	if(rst) begin
		counter<=0;
		init<=1;
		in<=128'd0;
		max<=128'd0;
		min<=~128'd0;
		sum<=131'd0;
		valid<=0;
	end
	else begin
		if(in_en) begin
			counter<=counter+1;
			in[7:0]<=iot_in;
			for(i=1;i<16;++i) in[8*i +:8]<=in[8*(i-1) +:8];
			init<=0;
			if(!counter[3:0]&&!init) begin
				case(fn'(fn_sel)) // synopsys full_case
					Max: begin
						max<=(max<in)? in:max;
						if(counter[6:4]==0) valid<=1;
					end
					Min: begin
						min<=(min>in)? in:min;
						if(counter[6:4]==0)	valid<=1;
					end
					Avg: begin
						sum<=sum+in;
						if(counter[6:4]==0) valid<=1;
					end
					Extract: begin
						if(in>`EXTRACT_LOW && in<`EXTRACT_HIGH) begin
							valid<=1;
							out_tmp<=in;
						end
					end
					Exclude: begin
						if(in<`EXCLUDE_LOW || in>`EXCLUDE_HIGH) begin
							valid<=1;
							out_tmp<=in;
						end
					end
					PeakMax: begin
						if(max<in) begin
							max<=in;
							diff<=1;
						end
						if(counter[6:0]==0&&diff) begin
							valid<=1;
							diff<=0;
						end
					end
					PeakMin: begin
						if(min>in) begin
							min<=in;
							diff<=1;
						end
						if(counter[6:0]==0&&diff) begin
							valid<=1;
							diff<=0;
						end
					end
				endcase
			end
			else begin
				if(valid) begin
					case(fn'(fn_sel))
						Max: max<=128'd0;
						Min: min<=~128'd0;
						Avg: sum<=131'd0;
					endcase
				end
				valid<=0;
			end
		end
	end
end
endmodule

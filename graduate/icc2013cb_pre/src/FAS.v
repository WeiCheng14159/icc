module multi_adder #(parameter WIDTH=32,SIZE=2)(
	input [WIDTH*SIZE-1:0] data,
	output [WIDTH-1:0] add_sum
);
generate
case(SIZE)
	1:assign add_sum=data[WIDTH-1:0];
	2:assign add_sum=data[WIDTH+:7]+data[0+:7];
	default: begin
		logic [WIDTH-1:0]r1;
		multi_adder #(.WIDTH (WIDTH),.SIZE(SIZE/2))
		right(.data(data[WIDTH*(SIZE/2)-1:0]),.add_sum(r1));

		logic [WIDTH-1:0]r2;
		multi_adder #(.WIDTH (WIDTH),.SIZE(SIZE-SIZE/2))
		left(.data(data[WIDTH*SIZE-1:WIDTH*(SIZE/2)]),.add_sum(r2));

		assign add_sum=r1+r2;
	end
endcase
endgenerate
endmodule

typedef struct{
	logic [16:0] real_value,imag_value;
} ComplexNumber_s;

module fft_calculator(
	input ComplexNumber_s x,
	input ComplexNumber_s y,
	output ComplexNumber_s fft_a,
	output ComplexNumber_s fft_b
);
assign fft_a='{real_value: }
endmodule

module  FAS (data_valid, data, clk, rst, fir_d, fir_valid, fft_valid, done, freq,
 fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8,
 fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0);
input clk, rst;
input data_valid;
input [15:0] data; 

output logic fir_valid, fft_valid;
output logic [15:0] fir_d;
output logic [31:0] fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8;
output logic [31:0] fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0;
output logic done;
output logic [3:0] freq;
//FIR filter

//fir_c:4+16
//data,fir_d:1+7+8
//adder_in:8+13
localparam signed [19:0] logic fir_c [32]={FIR_C00,FIR_C01,FIR_C02,FIR_C03,FIR_C04,FIR_C05,FIR_C06,FIR_C07,FIR_C08,FIR_C09,FIR_C10,FIR_C11,FIR_C12,FIR_C13,FIR_C14,FIR_C15,FIR_C16,FIR_C17,FIR_C18,FIR_C19,FIR_C20,FIR_C21,FIR_C22,FIR_C23,FIR_C24,FIR_C25,FIR_C26,FIR_C27,FIR_C28,FIR_C29,FIR_C30,FIR_C31};
logic signed [15:0]fir_pipe[31],
logic signed [35:0]fir_mul[32];//TODO: optimize?
logic [21*32-1:0] adder_in;
logic [20:0] adder_out;
logic [4:0]fir_cnt;
always_ff@(posedge clk) begin
	fir_pipe[0]<=data;
	for(int i=0;i<31;++i) fir_pipe[i+1]<=fir_pipe[i];
end
always_comb begin
	fir_mul[0]=data*fir_c[0];
	for(int i=1;i<32;++i) fir_mul[i]=fir_pipe[i-1]*fir_c[i];
	for(int i=0;i<32;++i) adder_in[21*i+:21]=fir_mul[i][12+:21];
end
multi_adder #(.WIDTH(21),.SIZE(32)) fir_adder(.data(adder_in),.add_sum(adder_out));
always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		fir_d<=0;
		fir_valid<=0;
		fir_cnt<=0;
	end
	else begin
		if(data_valid) begin
			fir_d<=adder_out[20:5];
			if(fir_cnt== ~5'd0) fir_valid<=1;
			else fir_cnt<=fir_cnt+1;
		end
	end
end

//FFT
logic [3:0] fft_cnt;
logic [15:0] fft_in[16];
ComplexNumber_s fft_cache[16];

always_comb begin// TODO:wrong value,it sould be reversed bit 
	fft_d0={>>{fft_cache[0]};
	fft_d1={>>{fft_cache[1]};
	fft_d2={>>{fft_cache[2]};
	fft_d3={>>{fft_cache[3]};
	fft_d4={>>{fft_cache[4]};
	fft_d5={>>{fft_cache[5]};
	fft_d6={>>{fft_cache[6]};
	fft_d7={>>{fft_cache[7]};
	fft_d8={>>{fft_cache[8]};
	fft_d9={>>{fft_cache[9]};
	fft_d10={>>{fft_cache[10]};
	fft_d11={>>{fft_cache[11]};
	fft_d12={>>{fft_cache[12]};
	fft_d13={>>{fft_cache[13]};
	fft_d14={>>{fft_cache[14]};
	fft_d15={>>{fft_cache[15]};
end

always_ff@(posedge clk) begin
	if(fir_valid) begin
		fft_in[0]<=fir_d;
		for(int i=1;i<16;++i) fft_in[i]<=fft_in[i-1];
	end
	if(fft_cnt==4'd15) begin
		//new data in
		fft_cache[0]<='{real_value:fir_d,imag_value:0};
		for(int i=1;i<16;++i) fft_cache[i]<='{real_value:fft_in[i],imag_value:16'd0};
		//old data out
		fft_valid<=1;		
	end
	else fft_valid<=0;
end


always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		fft_cnt<=0;
	end
	else begin
		if(fir_valid) fft_cnt<=fft_cnt+1;
		unique case(fft_cnt[3:2])
			2'd0:begin
				fft_cache[]
			end
			2'd1:begin
			end
			2'd2:begin
			end
			2'd3:begin
			end
		endcase
	end
end



endmodule



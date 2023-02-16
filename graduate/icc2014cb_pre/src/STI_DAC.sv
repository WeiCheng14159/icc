module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       oem_finish, oem_dataout, oem_addr,
	       odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr);

input		clk, reset;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output logic		so_data, so_valid;

output logic  oem_finish, odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr;
output logic [4:0] oem_addr;
output logic [7:0] oem_dataout;

logic [4:0] so_out_cnt;
logic [3:0] split_index;
logic [15:0] pi_data_cache,tmp;
logic zero_lead;
enum {IN,OUT} status_e;

//STI
assign so_valid<=(status_e==OUT);

always_ff@(posedge clk,posedge reset) begin
	if(reset) begin
		so_out_cnt<=0;
		split_index<=0;
		pi_data_cache<=0;
		zero_lead<=0;
		status_e<=IN;
	end
	else begin
		case(status_e)
			IN: begin
				if(load) begin
					zero_lead<=(pi_length[1])? pi_msb^pi_fill:1;
					//count output bits
					so_out_cnt<={pi_length,3'b111};

					//reorder input data
					tmp=(pi_msb)? {<<{pi_data}}:pi_data;
					if(pi_length==2'b00) pi_data_cache<=(pi_low^pi_msb)? tmp:tmp>>8;
					else pi_data_cache<=tmp;

					//border of add-on zero and data
					split_index<=((pi_length==2'b10) && ~(pi_msb^pi_fill)) 4'd8:4'd16;
					status_e<=OUT;
				end
			end
			OUT:begin
				if(zero_lead^(so_out_cnt<split_index)) so_data<=0;
				else begin
					so_data<=pi_data_cache[0];
					pi_data_cache<={pi_data_cache[0]:pi_data_cache[15:1]};
				end

				so_out_cnt<=so_out_cnt-1;
				if(!so_out_cnt) status_e<=IN;
			end
		endcase
	end
end

//DAC
logic [7:0]address,dac_cache,mem_selector;
logic [2:0]byte_cnt;
logic so_valid_delay;
assign {even4_wr,odd4_wr,even3_wr,odd3_wr,even2_wr,odd2_wr,even1_wr,odd1_wr}=mem_selector;
assign oem_addr=address[5:1];
//assign mem_selector=8'd1<<{{address[7:6],address[0]}};
always_ff@(posedge clk,posedge reset) begin
	if(reset) begin
		address<=0;
		byte_cnt<=0;
	end
	else begin
		if(so_valid) begin
			byte_cnt<=byte_cnt+1;
			oem_dataout<={oem_dataout[6:0],so_data};
		end
		so_valid_delay<=so_valid;
		if(byte_cnt==0&&so_valid_delay) begin
			mem_selector<=8'd1<<{{address[7:6],address[0]}}
			address<=address+1;
		end
		else mem_selector<=8'd0;
	end
end
//==============================================================================







endmodule

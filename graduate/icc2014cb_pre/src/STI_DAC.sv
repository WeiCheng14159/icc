module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
               so_data, so_valid,
               oem_finish, oem_dataout, oem_addr,
               odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr);

input           clk, reset;
input           load, pi_msb, pi_low, pi_end; 
input   [15:0]  pi_data;
input   [1:0]   pi_length;
input           pi_fill;
output logic            so_data, so_valid;

output logic  oem_finish, odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr;
output logic [4:0] oem_addr;
output logic [7:0] oem_dataout;

logic [4:0] so_out_cnt,split_index;
logic [15:0] pi_data_cache,tmp;
logic zero_lead;
enum {IN,OUT} status_e;

//STI
//assign so_valid=(status_e==OUT);

always_ff@(posedge clk,posedge reset) begin
        if(reset) begin
                so_out_cnt<=0;
                split_index<=0;
                pi_data_cache<=0;
                zero_lead<=0;
                status_e<=IN;
                so_valid<=0;
                so_data<=0;
        end
        else begin
                case(status_e)
                        IN: begin
                                if(load) begin
                                        zero_lead<=(pi_length[1])? pi_msb^pi_fill:1;
                                        //count output bits
                                        so_out_cnt<={pi_length,3'b111};

                                        //reorder input data
                                        if(pi_msb) tmp={<<{pi_data}};
                                        else tmp=pi_data;
                                        //tmp=(pi_msb)? {<<{pi_data}}:pi_data;
                                        if(pi_length==2'b00) pi_data_cache<=(pi_low^pi_msb)? tmp>>8:tmp;
                                        else pi_data_cache<=tmp;

                                        //border of add-on zero and data
                                        split_index<=((pi_length==2'b10) && ~(pi_msb^pi_fill))? 5'd8:5'd16;
                                        status_e<=OUT;
                                end
                                so_valid<=0;
                        end
                        OUT:begin
                                if(!load) begin
                                        if(zero_lead^(so_out_cnt<split_index)) so_data<=0;
                                        else begin
                                                so_data<=pi_data_cache[0];
                                                pi_data_cache<={pi_data_cache[0],pi_data_cache[15:1]};
                                        end

                                        so_valid<=1;
                                        so_out_cnt<=so_out_cnt-1;
                                        if(!so_out_cnt) status_e<=IN;
                                end
                        end
                endcase
        end
end

//DAC
logic [7:0]address,dac_cache,mem_selector[3];
logic [2:0]byte_cnt;
logic end_zero,oem_finish_buffer;
logic [7:0]oem_dataout_buffer;
logic [4:0]oem_addr_buffer;
assign {even4_wr,odd4_wr,even3_wr,odd3_wr,even2_wr,odd2_wr,even1_wr,odd1_wr}=mem_selector[0];
assign oem_finish=(address[7:6]==0&&oem_addr==0&&pi_end);
//assign {odd4_wr,even4_wr,odd3_wr,even3_wr,odd2_wr,even2_wr,odd1_wr,even1_wr}=mem_selector;
always_ff@(posedge clk,posedge reset) begin
        if(reset) begin
                oem_dataout<=0;
                oem_dataout_buffer<=0;
                address<=0;
                byte_cnt<=0;
                oem_addr<=0;
                oem_addr_buffer<=0;
                end_zero<=0;
                mem_selector<='{default:0};
        end
        else begin
                if(so_valid) begin
                        byte_cnt<=byte_cnt+1;
                        oem_dataout_buffer<={oem_dataout_buffer[6:0],so_data};
                end
                else if(status_e==IN && pi_end) begin
                        end_zero<=~end_zero;
                        oem_dataout_buffer<=0;
                end

                if(mem_selector[2]) oem_dataout<=oem_dataout_buffer;
                oem_addr<=oem_addr_buffer;
                if(byte_cnt==7||end_zero) begin
                        oem_addr_buffer<=address[5:1];
                        address<=address+1;
                        mem_selector[2]<=8'd1<<({address[7:6],(address[3]^address[0])});
                end
                else mem_selector[2]<=8'd0;
                for(int i=0;i<2;++i) mem_selector[i]<=mem_selector[i+1];
        end
end
//==============================================================================
endmodule

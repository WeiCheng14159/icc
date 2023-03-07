module S1(clk,
	rst,
	updown,
	S1_done,
	RB1_RW,
	RB1_A,
	RB1_D,
	RB1_Q,
	sen,
	sd);

input clk,rst,updown;
output logic S1_done,RB1_RW;
output logic [4:0] RB1_A;
output logic [7:0] RB1_D;
input [7:0] RB1_Q;
inout sen,sd;

logic [4:0]read_addr,write_addr;
logic [3:0]read_cnt;

//transmit ctl

assign sen=(transmiting)? 1'b0:1'bz;
assign sd=(transmiting)? RB1_Q[read_cnt]:1'bz;////
assign RB1_A=(addr_read)? write_addr:read_addr;

always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		transmiting<=0;
		read_addr<=17;
		write_addr<=~5'd0;
		addr_read<=0;
	end
	else begin
		priority case(1'b0)
			sen: begin //receive
				RB1_RW<=1;
				transmiting<=0;
				RB1_D<={RB1_D[1:7],sd};//////
				addr_read<=0;
			end
			transmiting: begin // not transmitting 
				if(addr_read&&read_cnt<8) begin
					transmiting<=1;
					read_cnt<=read_cnt+1;
					read_addr<=17;
				end
				RB1_RW<=addr_read;
				addr_read<=1;
			end
			default: begin //transmiting
				{transmiting,read_addr}<={transmiting,read_addr}-1;
			end
		endcase
	end
end
endmodule

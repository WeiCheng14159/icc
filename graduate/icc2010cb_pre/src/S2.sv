module S2(clk,
	  rst,
	  updown,
	  S2_done,
	  RB2_RW,
	  RB2_A,
	  RB2_D,
	  RB2_Q,
	  sen,
	  sd);

  input clk,rst,updown;
  output S2_done,RB2_RW;
  output [2:0] RB2_A;
  output [17:0] RB2_D;
  input [17:0] RB2_Q;
  inout sen,sd;
        

logic [3:0]read_addr,write_addr;
logic [4:0]read_cnt;

//transmit ctl

assign sen=(transmiting)? 1'b0:1'bz;
assign sd=(transmiting)? RB2_Q[read_cnt]:1'bz;////
assign RB2_A=(addr_read)? write_addr:read_addr;

always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		transmiting<=0;
		read_addr<=7;
		write_addr<=~5'd0;
		addr_read<=0;
	end
	else begin
		priority case(1'b0)
			sen: begin //receive
				RB2_RW<=1;
				transmiting<=0;
				RB2_D<={RB2_D[1:7],sd};//////
				addr_read<=0;
			end
			transmiting: begin // not transmitting 
				if(addr_read&&read_cnt<18) begin
					transmiting<=1;
					read_cnt<=read_cnt+1;
					read_addr<=7;
				end
				RB2_RW<=addr_read;
				addr_read<=1;
			end
			default: begin //transmiting
				{transmiting,read_addr}<={transmiting,read_addr}-1;
			end
		endcase
	end
end
endmodule

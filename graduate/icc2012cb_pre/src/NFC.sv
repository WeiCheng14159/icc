`timescale 1ns/100ps
module NFC(clk, rst, done, F_IO_A, F_CLE_A, F_ALE_A, F_REN_A, F_WEN_A, F_RB_A, F_IO_B, F_CLE_B, F_ALE_B, F_REN_B, F_WEN_B, F_RB_B);

input clk;
input rst;
output logic done;
inout [7:0] F_IO_A;
output logic F_CLE_A;
output logic F_ALE_A;
output logic F_REN_A;
output logic F_WEN_A;
input  F_RB_A;
inout [7:0] F_IO_B;
output logic F_CLE_B;
output logic F_ALE_B;
output logic F_REN_B;
output logic F_WEN_B;
input  F_RB_B;

logic [8:0]page_cnt;
enum {WAIT,ADDR,W_R} read_status,write_status;
enum {CMD,COL,ROW1,ROW2} addr_status_index;
logic [3:0] r_addr_status,w_addr_status;
logic [8:0]col_cnt,row_cnt;
logic [7:0]io_cache[2];
logic [7:0]io_a_out,io_a_in,io_b_out;
logic stop;

assign F_IO_A=(read_status==W_R)? 'bz:io_a_out;
assign io_a_in=F_IO_A;
assign F_IO_B=io_b_out;

//a output
assign F_CLE_A=(read_status==ADDR && r_addr_status[CMD]);
assign F_ALE_A=(read_status==ADDR && (r_addr_status[ROW2:COL]));
always_comb begin
	case(read_status)
		ADDR:begin
			unique case(1'b1)
				r_addr_status[CMD ]:io_a_out={7'd0,col_cnt[8]};
				r_addr_status[COL ]:io_a_out=col_cnt[7:0];
				r_addr_status[ROW1]:io_a_out=row_cnt[7:0];
				r_addr_status[ROW2]:io_a_out={7'd0,row_cnt[8]};
			endcase
		end
		default: io_a_out='bz;
	endcase
end

//b output
logic write_end;
assign F_CLE_B=(write_status==ADDR && (w_addr_status[CMD])) || (write_end);
assign F_ALE_B=(write_status==ADDR && (w_addr_status[ROW2:COL]));

always_comb begin
	case(write_status)
		WAIT: io_b_out=(write_end)? 8'h10:8'hxx;
		ADDR: begin
			unique case(1'b1)
				w_addr_status[CMD ]:io_b_out=8'h80;
				w_addr_status[COL ]:io_b_out=col_cnt[7:0];
				w_addr_status[ROW1]:io_b_out=row_cnt[7:0];
				w_addr_status[ROW2]:io_b_out={7'd0,row_cnt[8]};
			endcase
		end
		W_R: io_b_out=(write_end)? 8'h10:io_cache[1];
	endcase
end

logic r_idle,w_idle,r_ing,w_ing,unwake;
assign r_idle=(read_status==WAIT);
assign w_idle=(write_status==WAIT && !write_end &&(unwake||F_RB_B));
assign r_valid=(read_status==W_R);
assign w_valid=(write_status==W_R);
//cache
always_ff@(posedge F_REN_A) io_cache[0]<=io_a_in;
always_ff@(posedge clk) io_cache[1]<=io_cache[0];
//counter
assign done=(stop && F_RB_B);
always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		col_cnt<=0;
		row_cnt<=0;
		stop<=0;
	end
	else begin
		if(col_cnt==~9'd0) begin
			if(w_idle) begin
				col_cnt<=0;
				if(~row_cnt) row_cnt<=row_cnt+1;
				else stop<=1;
			end
		end
		else col_cnt<=col_cnt+(r_valid);
	end
end
//a status
assign F_REN_A=(read_status==W_R)? !clk:1;
assign F_WEN_A=(r_addr_status)? !clk:1;
always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		read_status<=WAIT;
		r_addr_status<=1<<CMD;
	end
	else begin
		unique case(read_status)
			WAIT: begin
				if(w_idle && !stop) begin
					read_status<=ADDR;
					r_addr_status<=1<<CMD;
				end
			end
			ADDR: begin
				if(!r_addr_status) begin
					if(F_RB_A) read_status<=W_R;
				end
				r_addr_status<=r_addr_status<<1;
			end
			W_R: begin
				if(col_cnt==~9'd0) read_status<=WAIT;
			end
		endcase
	end
end
//b status
assign F_REN_B=1;
assign F_WEN_B=((write_status==ADDR)||(write_status==W_R))? !clk:1;
always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		write_status<=WAIT;
		w_addr_status<=1<<CMD;
		write_end<=0;
		unwake<=1;
	end
	else begin
		unique case(write_status)
			WAIT: begin
				w_addr_status<=1<<CMD;
				if(r_addr_status[COL] && !stop) begin
					write_status<=ADDR;
				end
				write_end<=0;
			end
			ADDR: begin
				unwake<=0;
				w_addr_status<=w_addr_status<<1;
				if(w_addr_status[ROW2]) write_status<=W_R;
			end
			W_R: begin
				if(read_status==WAIT) begin
					write_end<=1;
				end
				if(write_end) write_status<=WAIT;
			end
		endcase
	end
end

endmodule

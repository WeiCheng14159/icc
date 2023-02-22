`timescale 1ns/100ps
module NFC(clk, rst, done, F_IO_A, F_CLE_A, F_ALE_A, F_REN_A, F_WEN_A, F_RB_A, F_IO_B, F_CLE_B, F_ALE_B, F_REN_B, F_WEN_B, F_RB_B);

input clk;
input rst;
output done;
inout [7:0] F_IO_A;
output F_CLE_A;
output F_ALE_A;
output F_REN_A;
output F_WEN_A;
input  F_RB_A;
inout [7:0] F_IO_B;
output F_CLE_B;
output F_ALE_B;
output F_REN_B;
output F_WEN_B;
input  F_RB_B;

logic [8:0]page_cnt;
enum {WAIT,ADDR,W_R} read_status,write_status;
enum {CMD1=5'b00001,CMD2=5'b00010,COL=5'b00100,ROW1=5'b01000,ROW2=5'b10000} r_addr_status,w_addr_status;
logic [8:0]col_cnt,row_cnt;
localparam cache_size=6;
logic [7:0]io_cache[cache_size];
logic [$clog2(cache_size)-1:0] col_diff;
logic [7:0]io_a_out;

assign F_IO_A=(read_status==W_R)? io_a_out:'bz;

//a output
always_comb begin
	case(read_status)
		ADDR:begin
			unique case(r_addr_status)
				CMD2 :io_a_out={7'd0,col_cnt[8]};
				COL :io_a_out=col_cnt[7:0];
				ROW1:io_a_out=row_cnt[7:0];
				ROW2:io_a_out={7'd0,row_cnt[8]};
			endcase
		end
		default: io_a_out='bz;
	endcase
	F_CLE_A=(read_status==ADDR && r_addr_status==CMD2);
	F_ALE_A=(read_status==ADDR && (r_addr_status&(COL|ROW1|ROW2));
end

//b output
always_comb begin
	case(write_status)
		WAIT: F_IO_B=8'hxx;
		ADDR: begin
			unique case(w_addr_status)
				CMD2 :F_IO_B={7'd0,col_cnt[8]};
				CMD2 :F_IO_B=8'h80;
				COL :F_IO_B=col_cnt[7:0]+col_diff;
				ROW1:F_IO_B=row_cnt[7:0];
				ROW2:F_IO_B={7'd0,row_cnt[8]};
			endcase
		end
		W_R: F_IO_B=io_cache[col_diff-1];
	endcase
	F_CLE_B=(write_status==ADDR && (w_addr_status&(CMD1|CMD2)));
	F_ALE_B=(write_status==ADDR && (w_addr_status&(COL|ROW1|ROW2)));
end

logic r_idle,w_idle,r_ing,w_ing;
assign r_idle=(read_status==WAIT && F_RB_A);
assign w_idle=(write_status==WAIT && F_RB_B && col_diff==0);
assign r_valid=(read_status==W_R && F_REN_A);
assign w_valid=(write_status==W_R && F_WEN_B);
//cache
always_ff@(posedge clk) begin
	if(F_REN_A) begin
		io_cache[0]<=F_IO_A;
		for(int i=1;i<cache_size;++i) io_cache[i]<=io_cache[i-1];
	end
end
//counter
always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		col_cnt<=0;
		row_cnt<=0;
		col_diff<=0;
		done<=0;
	end
	else begin
		if(w_idle && r_idle) begin
			if(col_cnt==~9'd0) begin
				col_cnt<=0;
				if(~row_cnt) row_cnt<=row_cnt+1;
				else done<=1;
			end
		end
		else col_cnt<=col_cnt+(r_valid);
		col_diff<=col_diff+(r_valid)-(w_valid);
	end
end
//a status
always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		read_status<=WAIT;
		r_addr_status<=CMD2;
		F_REN_A<=1;
		F_WEN_A<=1;
	end
	else begin
		unique case(read_status)
			WAIT: begin
				F_REN_A<=1;
				F_WEN_A<=1;
				r_addr_status<=CMD2;
				if(F_RB_A && w_idle) read_status<=ADDR;
			end
			ADDR: begin
				F_WEN_A<=~F_WEN_A;
				if(F_WEN_A) begin
					if(r_addr_status==ROW2) begin
						if(F_RB_A) read_status<=W_R;
					end
					else r_addr_status<<=1;
				end
			end
			W_R: begin
				F_REN_A<=~F_REN_A;
				if(col_cnt==~9'd0 || (!F_RB_A) || ((!F_RB_B)&&col_diff==cache_size)) read_status=WAIT;
			end
		endcase
	end
end
//b status
always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		write_status<=WAIT;
		w_addr_status<=CMD1;
		F_REN_B<=1;
		F_WEN_B<=1;
	end
	else begin
		unique case(write_status)
			WAIT: begin
				F_REN_B<=1;
				F_WEN_B<=1;
				w_addr_status<=CMD1;
				if(col_diff && F_RB_B) write_status<=ADDR;
			end
			ADDR: begin
				F_WEN_B<=~F_WEN_B;
				if(F_WEN_B) begin
					w_addr_status<<=1;
					if(w_addr_status==ROW2) write_status<=W_R;
				end
			end
			W_R: begin
				F_WEN_B<=~F_WEN_B;
				if((!F_RB_B) || (!col_diff)) write_status<=WAIT;
			end
		endcase
	end
end

endmodule

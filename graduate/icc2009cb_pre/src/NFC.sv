`timescale 1ns/100ps
`define CMD_RW 32
`define CMD_FLASH_ADDR 31:14
`define CMD_FLASH_BLOCK_ADDR 31:25
`define CMD_MEM_ADDR 13:7
`define CMD_RW_LEN 6:0

module NFC(clk, rst, cmd, done, M_RW, M_A, M_D, F_IO, F_CLE, F_ALE, F_REN, F_WEN, F_RB);

input clk;
input rst;
input [32:0] cmd;
output logic done;
output logic M_RW;
output logic [6:0] M_A;
inout  [7:0] M_D;
inout  [7:0] F_IO;
output logic F_CLE;
output logic F_ALE;
output logic F_REN;
output logic F_WEN;
input  F_RB;

//state ctrl
logic [17:0] flash_addr;
logic valid_cmd[3];
enum {READ=0,ERASE=1,WRITE=2} state_index;
enum {INIT_READ=2,INIT_ERASE=0,INIT_WRITE=1} prev_state_index;// for init state
logic [2:0] state,next_state;
enum {FLASH_CMD,FLASH_ADDR,FLASH_EXEC,FLASH_DONE} flash_status_index;
logic [3:0] flash_state,next_flash_state;
logic flash_read,flash_write;
logic [1:0] flash_addr_cnt;
logic [6:0] rw_cnt;
logic flash_addr_read_wait;

logic [6:0]block_addr;
logic dirty,hit,target_addr;
assign hit=(block_addr==cmd[`CMD_FLASH_BLOCK_ADDR]&&(!dirty));
assign target_addr=(flash_addr>=cmd[`CMD_FLASH_ADDR])
logic cache_rotate;

logic im_read,im_write;
always_comb begin
	next_state={state[2:1],state[0]};
	next_flash_state={next_flash_state[2:1],next_flash_state[0]};
end

always_ff@(posedge clk) valid_cmd<='{done,valid_cmd[0],!valid_cmd[1]};
always_ff@(posedge clk,posedge rst) begin
	if(rst) begin
		state<='0;
		flash_state<='0;
		done<='0;
		dirty<='1;
		rw_cnt<='0;
		flash_addr<='0;
		M_A<=0;
		flash_addr_read_wait<='0;
	end
	else begin
		if(valid_cmd[1]) begin//recv cmd
			rw_cnt<=cmd[`CMD_RW_LEN];
			M_A<=cmd[`CMD_MEM_ADDR];
			//set init state
			unique case({cmd[`CMD_RW],hit})
				2'b00: begin//write & no hit:read,erase,write
					state<=3'd1<<INIT_READ;
					flash_addr<={cmd[`CMD_FLASH_BLOCK_ADDR],11'd0};//block start

					block_addr<=cmd[`CMD_FLASH_BLOCK_ADDR];
					dirty<='0;
				end
				2'b01: begin//write & hit:erase,write
					state<=3'd1<<INIT_ERASE;
					flash_addr<={cmd[`CMD_FLASH_BLOCK_ADDR],11'd0};//block start
				end
				2'b10: begin//read & no hit:flash to im
					state<=3'd1<<INIT_READ;
					flash_addr<=cmd[`CMD_FLASH_ADDR];
				end
				2'b11: begin//read & hit:cache to im
					state<=3'd1<<INIT_READ;
					flash_addr<={cmd[31:21],8'd0};//page start(for cache)
					flash_state<='0;
				end
			endcase
		end
		else begin
			//ctl
			unique case(1'b1)
				//flash access state
				flash_state[FLASH_CMD]: begin
					flash_state<=next_flash_state;
				end
				flash_state[FLASH_ADDR]: begin
					if(!flash_addr_cnt) begin
						if(state[READ]) begin
							if(flash_addr_read_wait) begin //read flash need wait data transfer(1 cycle)
								flash_state<=next_flash_state;
								if(target_addr) M_A<=M_A+1;
							end
							flash_addr_read_wait<=!flash_addr_read_wait
						end
						else flash_state<=next_flash_state;
					end
					flash_addr_cnt<=flash_addr_cnt-1;
				end
				flash_state[FLASH_EXEC]: begin
					if(&flash_addr[8:0] || !rw_cnt) flash_state<=next_flash_state;
					unique case(1'b1)
						state[READ]: begin
							if(cmd[`CMD_RW]) flash_addr<=flash_addr+1;
							else flash_addr[8:0]<=flash_addr[8:0]+1;
							if(target_addr) rw_cnt<=rw_cnt-1;
						end
						state[WRITE]: begin
							flash_addr<=flash_addr+1;
						end
					endcase

					if(state[READ] && target_addr && rw_cnt) M_A<=M_A+1;
				end
				flash_state[FLASH_DONE]: begin
					if(F_RB) begin
						if(!rw_cnt && (cmd[`CMD_RW] || state[WRITE])) done<=!done;
						else flash_state<=next_flash_state;
					end
					if(cmd[`CMD_RW]) flash_addr_cnt<=2'd2;
					else begin
						//rotate ro flash_state[FLASH_DONE]&state[READ] to stop input to FLASH
						if(rw_cnt || !state[READ]) state<=next_state;
						unique case(1'b1)
							next_state[READ]: flash_addr_cnt<=2'd2;
							next_state[ERASE]:flash_addr_cnt<=2'd1;
							next_state[WRITE]:flash_addr_cnt<=2'd2;
						endcase
					end
				end
				//no flash access => init or read cache
				default: begin
					if(rw_cnt||(~flash_addr[7:0])) begin
						if(target_addr && rw_cnt) rw_cnt<=rw_cnt-1;
						flash_addr<=flash_addr+1;
					end
					else flash_state<=4'd1<<FLASH_DONE;
				end
			endcase
		end
	end
end

//block mem cache
logic [7:0]cache[8][256],cache_head;
assign cache_head=cache[flash_addr[10:8]][0];

always_comb begin//when to rotate cache
	if(cmd[`CMD_RW]) rotate=(!flash_state && (~flash_addr));
	else rotate=(state[READ]||state[WRITE])&&flash_state[FLASH_EXEC];
end
//use rotate to reduce mux
//must rotate 255
always_ff@(posedge clk) begin
	if(cache_rotate) begin
		for(logic[3:0] i='0;i<4'b1000;++i) begin
			if(flash_addr[10:8]==i[2:0]) begin
				unique case({flash_read,im_read})
					2'b00:cache[i[2:0]][0]<=cache[flash_addr[10:8]][255];
					2'b10:cache[i[2:0]][0]<=F_IO;
					2'b11:cache[i[2:0]][0]<=M_D;
				endcase
			end
			else cache[i[2:0]][0]<=cache[i[2:0]][255];
			for(int j=1;j<256;++j) begin
				cache[i[2:0]][j]<=cache[i[2:0]][j-1];
			end
		end
	end
end


//flash ctrl
assign F_REN=(flash_read)? !clk:'1;
assign F_WEN=(flash_write)? !clk:'1;

always_comb begin
	unique case(1'b1)
		flash_state[FLASH_CMD]: begin
			unique case(1'b1)
				state[READ]: F_IO={7'd0,flash_addr[8]}
				state[ERASE]:F_IO=8'h60;
				state[WRITE]:F_IO=8'h80;
			endcase
			{F_CLE,F_ALE,flash_read,flash_write}=4'b1001;
		end
		flash_state[FLASH_ADDR]: begin
			unique case(flash_addr_cnt)
				2'd2:F_IO=flash_addr[7:0];
				2'd1:F_IO=flash_addr[16:9];
				2'd0:F_IO={6'd0,flash_addr[17]};
			endcase
			{F_CLE,F_ALE,flash_read,flash_write}={1'b0,F_RB,1'b0,F_RB};
		end
		flash_state[FLASH_EXEC]: begin
			unique case(1'b1)
				state[READ]: F_IO='z;
				state[ERASE]:F_IO=8'hd0;
				state[WRITE]:F_IO=cache_head;
			endcase
			{F_CLE,F_ALE,flash_read,flash_write}={2'b00,state[READ],state[WRITE]};
		end
		flash_state[FLASH_DONE]: begin
			unique case(1'b1)
				state[READ]: F_IO='z;
				state[ERASE]:F_IO=8'h10;
				state[WRITE]:F_IO=8'h70;
			endcase
			{F_CLE,F_ALE,flash_read,flash_write}={(!state[READ]),2'b00,(!state[READ])};
		end
		default: begin//reset
			if(dirty) begin//never write
				F_IO=8'hff;
				{F_CLE,F_ALE,flash_read,flash_write}=4'b1001;
			end
			else begin
				state[READ]: F_IO='z;
				{F_CLE,F_ALE,flash_read,flash_write}=4'b0000;
			end
		end
	endcase
end

// IM control
assign M_RW<=!im_write;
//im_read:valid read(address cycle not include)
//im_write:valid write
always_comb begin
	case({cmd[`CMD_RW],hit})
		2'b10: begin//write(im) and no hit
			M_D=F_IO;
			im_read=0;
			im_write=(flash_state[FLASH_EXEC] && rw_cnt);
		end
		2'b11: begin//write(im) and hit
			M_D=cache_head;
			im_read=0;
			im_write=(target_addr && rw_cnt);
		end
		default: begin
			M_D='z;
			im_read=(target_addr && rw_cnt && state[READ]&&flash_state[FLASH_EXEC]);
			im_write='0;
		end
	endcase
end

endmodule

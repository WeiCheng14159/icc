`timescale 1ns/1ns
`define CACHE_INDEX(addr) cache[addr.y][addr.x]
`define SWAP_N(a,b) {a,b}<={b,a}
`define ADDR_SETUP 0.19
`define ADDR_HOLD 0.05
`define DATA_SETUP 0.11

module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
input clk;
input reset;
input [7:0] IROM_Q;
input [2:0] cmd;
input cmd_valid;
output logic IROM_EN;
output logic [5:0] IROM_A;
output logic IRB_RW;
output logic [7:0] IRB_D;
output logic [5:0] IRB_A;
output logic busy;
output logic done;

logic [7:0] cache[8][8];
typedef struct packed{
	logic [2:0] y,x;
} coordinate_s;
logic editing;
//cmd
enum {WRITE=0,UP=1,DOWN=2,LEFT=3,RIGHT=4,AVG=5,MX=6,MY=7} cmd_index_e;
logic [7:0] cmd_cache;
logic cmd_valid_c;
logic after_load;
logic pause_cmd;
assign busy=(pause_cmd || editing);

always_ff@(posedge clk,posedge reset) begin
	if(reset) begin
		cmd_valid_c<=1;
		cmd_cache<=1<<WRITE;
		after_load<=0;
		pause_cmd<=1;
	end
	else begin
		if(!busy && cmd_valid) begin
			cmd_cache<=1<<cmd;
			after_load<=1;
			pause_cmd<=(cmd inside {WRITE,AVG,MX,MY});
		end
		else pause_cmd<=0;
		cmd_valid_c<=(cmd_valid && !busy);
end
end
//addr ctl
coordinate_s op,rw_addr;//op=0~6(move -1,-1 from origin)
assign IROM_A=op;
assign IRB_A=op;
logic [2:0]step_cnt;

localparam logic [1:0] mx_step[6]={0,2,0,1,3,1};
localparam logic [1:0] my_step[6]={0,1,0,2,3,2};
localparam logic [1:0] avg_step[8]={0,1,2,3,0,1,2,3};
//always_comb begin
//      case(1'b1)
//              cmd_cache[AVG]: rw_addr='{op.y+avg_step[step_cnt][1],op.x+avg_step[step_cnt][0]};
//              cmd_cache[MX]: rw_addr='{op.y+mx_step[step_cnt][1],op.x+mx_step[step_cnt][0]};
//              cmd_cache[MY]: rw_addr='{op.y+my_step[step_cnt][1],op.x+my_step[step_cnt][0]};
//              default: rw_addr=6'dx;
//      endcase
//end

always_ff@(posedge clk,posedge reset) begin
	if(reset) begin
		step_cnt<=1;
		editing<=1;
		op<='{default:'0};
		rw_addr<='{default:'0};
		done<=0;
	end
	else begin
		if(cmd_valid_c) begin
			unique case(1'b1) //unique0
			cmd_cache[WRITE]: begin
				op<=#`ADDR_SETUP 0;
				step_cnt[0]<=1;
				editing<=1;
			end
			cmd_cache[UP    ]: op.y<=#`ADDR_SETUP (op.y==0)? op.y:op.y-1;
			cmd_cache[DOWN  ]: op.y<=#`ADDR_SETUP (op.y==6)? op.y:op.y+1;
			cmd_cache[LEFT  ]: op.x<=#`ADDR_SETUP (op.x==0)? op.x:op.x-1;
			cmd_cache[RIGHT ]: op.x<=#`ADDR_SETUP (op.x==6)? op.x:op.x+1;
			cmd_cache[AVG]: begin
				editing<=1;
				step_cnt<=7;
				rw_addr<='{op.y+avg_step[7][1],op.x+avg_step[7][0]};
			end
			cmd_cache[MX]: begin
				editing<=1;
				step_cnt<=5;
				rw_addr<='{op.y+mx_step[5][1],op.x+mx_step[5][0]};
			end
			cmd_cache[MY]: begin
				editing<=1;
				step_cnt<=5;
				rw_addr<='{op.y+my_step[5][1],op.x+my_step[5][0]};
			end
		endcase
	end
	else begin
		case(1'b1)
			cmd_cache[WRITE]: begin
				if(editing) {step_cnt[0],op}<=#`ADDR_SETUP ({step_cnt[0],op}+7'd1);
				else begin
					op<=#`ADDR_SETUP '{3'd3,3'd3};
					done<=after_load;
				end
				editing<=step_cnt[0];
			end
			cmd_cache[AVG]: begin
				if(editing) begin
					{editing,step_cnt}<={editing,step_cnt}-1;
					rw_addr<='{op.y+avg_step[step_cnt-1][1],op.x+avg_step[step_cnt-1][0]};
				end
			end
			cmd_cache[MX]: begin
				if(editing) begin
					{editing,step_cnt}<={editing,step_cnt}-1;
					rw_addr<='{op.y+mx_step[step_cnt-1][1],op.x+mx_step[step_cnt-1][0]};
				end
			end
			cmd_cache[MY]: begin
				if(editing) begin
					{editing,step_cnt}<={editing,step_cnt}-1;
					rw_addr<='{op.y+my_step[step_cnt-1][1],op.x+my_step[step_cnt-1][0]};
				end
			end
		endcase
	end
end
end
//en or output ctl
assign IRB_RW=!(cmd_cache[WRITE] && editing);
assign IROM_EN=!(cmd_cache[WRITE] && editing);

assign IRB_D=cache[0][0];


//read data & write value
logic [7:0] read_data;
assign read_data=`CACHE_INDEX(rw_addr);
logic [9:0] write;
always_ff@(posedge clk) begin
	case(1'b1)
		cmd_cache[AVG]: begin
			case(step_cnt) inside
				3'd7: write<=read_data;
				3'd6,3'd5,3'd4: write<=write+read_data;
			endcase
		end
		cmd_cache[MX],cmd_cache[MY]: begin
			write[9:2]<=read_data;
		end
	endcase
end

//cache ctl

logic [1:0] drop;
coordinate_s tmp1,tmp2;

always_ff@(posedge clk) begin
	if(editing) begin
		case(1'b1)
			cmd_cache[WRITE]: begin
				cache[7][7]<=#`DATA_SETUP IROM_Q;
				for(logic[5:0] i=6'd0;i<6'b111111;++i) begin
					tmp1=i;
					tmp2={i}+6'd1;
					`CACHE_INDEX(tmp1)<=#`DATA_SETUP `CACHE_INDEX(tmp2);
				end
			end
			cmd_cache[AVG],cmd_cache[MX],cmd_cache[MY]: begin
				`CACHE_INDEX(rw_addr)<=write[9:2];
			end
		endcase
	end
end

endmodule

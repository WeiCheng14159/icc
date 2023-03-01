`define CACHE_INDEX(addr) cache[addr.x][addr.y]
`define SWAP_N(a,b) {a,b}<={b,a}

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
//cmd
enum {WRITE=0,UP=1,DOWN=2,LEFT=3,RIGHT=4,AVG=5,MX=6,MY=7} cmd_cache;
logic load;
logic [1:0]op_act;
always_ff@(posedge clk,posedge reset) begin
	if(reset) begin
		load<=1;
		cmd_cache<=WRITE;
	end
	else begin
		if(!busy) begin
			if(cmd_valid) begin
				cmd_cache<=cmd;
				unique case(cmd)
					AVG	: op_act<=2'd3;
					MX	: op_act<=2'd1;
					MY	: op_act<=2'd1;
					default: op_act<=2'd0;
				endcase
			end
			load<=0;
		end
	end
end
//addr ctl
coordinate_s op;//op=0~6(move -1,-1 from origin)
assign IROM_EN=(!load);
assign IROM_A=op;

assign IRB_RW=(cmd_cache==WRITE);
assign IRB_A=op;
assign IRB_D=`CACHE_INDEX(op);
always_ff@(posedge clk,posedge reset) begin
	if(reset) begin
		op<='{3'd4,3'd4};
		busy<=1;
	end
	else begin
		if(busy||cmd_valid) begin
			unique case(cmd_cache) 
				WRITE: begin
					if({op}==~6'd0) begin
						op<='{3'd4,3'd4};
						busy<=0;
					end
					else {op}<={op}+1;
				end
				UP		: op.y<=(op.y==0)? op.y:op.y-1;
				DOWN	: op.y<=(op.y==6)? op.y:op.y+1;
				LEFT	: op.x<=(op.x==0)? op.x:op.x-1;
				RIGHT	: op.x<=(op.x==6)? op.x:op.x+1;
			endcase
		end
	end
end

//cache ctl
logic [7:0] avg;
coordinate_s square[4];
assign square[4]='{op,'{op.y,op.x+1},'{op.y+1,op.x},{op.y+1,op.x+1}};
always_ff@(posedge clk) begin
	if(busy) begin
		cache[7][7]<=IROM_Q;
		for(coordinate_s i='{default:'0};i!='{default:'1};++i) begin
			coordinate_s j={i}+6'd1;
			`CACHE_INDEX(i)<=`CACHE_INDEX(j);
		end
	end
	else begin
		case(cmd_cache) //unique0
			AVG: begin
				{avg,2'dx}=(`CACHE_INDEX(square[0])+`CACHE_INDEX(square[1]))+(`CACHE_INDEX(square[2])+`CACHE_INDEX(square[3]));
				for(int i=0;i<4;++i) `CACHE_INDEX(square[i])<=avg;
			end
			MX: begin
				`SWAP_N(`CACHE_INDEX(square[0]),`CACHE_INDEX(square[2]));
				`SWAP_N(`CACHE_INDEX(square[1]),`CACHE_INDEX(square[3]));
			end
			MY: begin
				`SWAP_N(`CACHE_INDEX(square[0]),`CACHE_INDEX(square[1]));
				`SWAP_N(`CACHE_INDEX(square[2]),`CACHE_INDEX(square[3]));
			end
		endcase
	end
end

endmodule


module avg(din, reset, clk, ready, dout);
input reset, clk;
input [15:0] din;
output reg ready; 
output reg [15:0] dout;

// ==========================================
//  Enter your design below
// ==========================================
reg [31:0] cnt;
reg [19:0] sum;
reg [15:0] avg;
reg [15:0] near;
reg [15:0] temp [11:0];
reg [3:0] i;
reg [15:0] dis [11:0];
reg [3:0] j;
always@(negedge clk or posedge reset)begin
  if(reset)begin
    i <= 4'd0 - 4'd1;
    cnt <= 32'd0;
    ready <= 1'b0;
  end
  else begin
    i <= i + 4'd1;
    cnt <= cnt + 32'd1;
    

    temp[0] <= temp[1];
    temp[1] <= temp[2];
    temp[2] <= temp[3];
    temp[3] <= temp[4];
    temp[4] <= temp[5];
    temp[5] <= temp[6];
    temp[6] <= temp[7];
    temp[7] <= temp[8];
    temp[8] <= temp[9];
    temp[9] <= temp[10];
    temp[10] <= temp[11];
    temp[11] <= din;
    if(i == 4'ha)
      ready <= 1'b1;
    else if(i == 4'hb)
      i <= 4'd0;
    else ;
  end
end

always@(*)begin
  if(reset)begin
    sum = 20'd0;
  end
  else if(cnt >= 4'hb)begin
      sum = temp[0] + temp[1] + temp[2] + temp[3] + temp[4] + temp[5] + temp[6] + temp[7] + temp[8] + temp[9] + temp[10] + temp[11];
  end
  else
  ;
end

function [15:0] sign_sub;
    input [15:0] data_1;
    input [15:0] data_2;
    begin
        if(data_1 < data_2)
            sign_sub = data_2 - data_1;
        else if(data_1 > data_2)
            sign_sub = data_1 - data_2;
        else 
            sign_sub = 16'd0;
    end
endfunction


/*
always@(*) begin
  near = 16'd0;
  for( i=0; i<12;i=i+1)begin
    avg = (temp[i]<<3) + (temp[i]<<2);
    if(avg <= sum & temp[i] > near)begin
        near = temp[i];
    end
    else
        ;
  end
dout = near;
end
*/

 
reg [3:0] k,k2;
reg [3:0] min;
always@(*)begin
  near = 16'd0;
  min = 4'd0;
  if (cnt >= 32'd12)begin
    avg = sum/12;
    for(j=0;j<12;j=j+1)begin
      dis[j] =sign_sub(temp[j],avg);
    end
    /*
    for(k=0;k<12;k=k+1)begin
      for(k2=0;k2<12;k2=k2+1)begin
        if(dis[k] > dis[k2])
          min = k2;
        else if(dis[k] == dis[k2])
          min = (temp[k] < avg)? k:(temp[k2] < avg)? k2:k2;
        else if(dis[k] < dis[k2])
          min = k ; 
      end
    end
    */
    for(k=0;k<12;k=k+1)begin
      for(k2=0;k2<12;k2=k2+1)begin
        if(dis[k2] < dis[min])
          min  = k2 ;
      end
    end
    


  end
  dout = temp[min];
end


endmodule

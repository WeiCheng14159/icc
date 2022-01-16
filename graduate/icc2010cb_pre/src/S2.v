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

  input clk,
        rst,
        updown;
  
  output S2_done,
         RB2_RW;
  
  output [2:0] RB2_A;
  
  output [17:0] RB2_D;
  
  input [17:0] RB2_Q;
  
  inout sen,
        sd;
        
endmodule

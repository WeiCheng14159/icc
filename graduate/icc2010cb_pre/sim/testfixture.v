`timescale 1ns/100ps

`define tb1
`ifdef tb1
  `define INFILE_RB1_in "tb1_RB1_in.dat"
  `define INFILE_RB1_out "tb1_RB1_goal.dat"
  `define INFILE_RB2 "tb1_RB2_goal.dat"
`endif
`ifdef tb2
  `define INFILE_RB1_in "tb2_RB1_in.dat"
  `define INFILE_RB1_out "tb2_RB1_goal.dat"
  `define INFILE_RB2 "tb2_RB2_goal.dat"
`endif
`ifdef tb3
  `define INFILE_RB1_in "tb3_RB1_in.dat"
  `define INFILE_RB1_out "tb3_RB1_goal.dat"
  `define INFILE_RB2 "tb3_RB2_goal.dat"
`endif

`define CYCLE 100
`define SDFFILE_1 "S1_syn.sdf"
`define SDFFILE_2 "S2_syn.sdf"

`include "RB1.v"
`include "RB2.v"

module testfixture();

  reg clk,
      rst;
  wire S1_done,
       S2_done;
      
  reg updown;
 
       
  wire rb1_rw,               //memory enable signal
       rb2_rw;
       
  wire [4:0] rb1_a;
  wire [2:0] rb2_a;
  
  wire [7:0] rb1_d,
             rb1_q;
             
  wire [17:0] rb2_d,
              rb2_q;
       
  wire sen,
       sd;
       
  reg [7:0] RB1_OUT [0:17];
  reg [17:0] RB2 [0:7];

  reg [20:0] s1_up;
  reg [12:0] s2_down;
  
  integer i,j,k,n,m,err_RB1,err_RB2,err_up,err_down,do_rb1,do_rb2,do_up,do_down;
  
  parameter duty = `CYCLE/2;     
       
 
  S1  s1(.clk(clk),
         .rst(rst),
         .updown(updown),
         .S1_done(S1_done),
         .RB1_RW(rb1_rw),
         .RB1_A(rb1_a),
         .RB1_D(rb1_d),
	       .RB1_Q(rb1_q),
	       .sen(sen),
         .sd(sd));
              
  S2  s2(.clk(clk),
         .rst(rst),
         .updown(updown),
         .S2_done(S2_done),
         .RB2_RW(rb2_rw),
         .RB2_A(rb2_a),
         .RB2_D(rb2_d),
         .RB2_Q(rb2_q),
         .sen(sen),
         .sd(sd));

  RB1 m1(.CLK(clk),
         .CEN(1'b0),
         .WEN(rb1_rw),
         .A(rb1_a),
         .D(rb1_d),
         .Q(rb1_q));
         
         
  RB2 m2(.CLK(clk),
         .CEN(1'b0),
         .WEN(rb2_rw),
         .A(rb2_a),
         .D(rb2_d),
         .Q(rb2_q));
  initial 
  begin
    `ifdef FSDB
      $fsdbDumpfile("SI.fsdb");
      $fsdbDumpvars;
    `endif

    `ifdef SDF
      $sdf_annotate(`SDFFILE_1,s1);
      $sdf_annotate(`SDFFILE_2,s2);
    `endif

    $readmemh (`INFILE_RB1_in,m1.mem);
    $readmemh (`INFILE_RB1_out,RB1_OUT);
    $readmemh (`INFILE_RB2,RB2);
  end

  initial
  begin
    clk = 1'b0;
    rst = 1'b0;
    updown = 1'b0;
    #45
      rst = 1'b1;
    #230
      rst = 1'b0;
    err_RB1 = 0;
    err_RB2 = 0;
    err_up = 0;
    err_down = 0;
    n = 0;
    m = 0;
    do_rb1 = 0;
    do_rb2 = 0;
    do_up = 0;
    do_down = 0;

  @(posedge S2_done)  // check RB2
    begin
      for(k=0;k<8;k=k+1)
      begin
        if(m2.mem[k] !== RB2[k])
        begin
          err_RB2 = err_RB2 + 1;
          $write("ERROR : RB2[%2h] = %h (expect = %h)\n", k,m2.mem[k],RB2[k]);
        end
        `ifdef tb2
          m2.mem[k] = ~m2.mem[k];
        `endif
      end
      do_rb2 = 1;
      #duty updown = 1'b1;
    end
  end

  always #duty clk = ~clk;
  
  always@(posedge clk)
  begin
    if(updown === 1'b0)  //check S1 to S2 frame
    begin
      if(n<8)
      begin
        if(sen === 1'b1)
          j = 0;
        else
        begin
          do_up = 1;
          s1_up[20-j] = sd;
          if(j === 20)
          begin
            if((RB2[n] !== s1_up[17:0]) || (n !== s1_up[20:18]))
            begin
              err_up = err_up + 1;
              $write("ERROR : The %3dth upload frame = %3b %b (expect = %3b %b)\n",n,s1_up[20:18],s1_up[17:0],n,RB2[n]);
            end
            n = n+1;
          end
          j=j+1;
        end  
      end
    end
  end
  
  always@(negedge clk)
  begin
    if(updown === 1'b1)
    begin
      if(m < 18)
      begin
        if(sen === 1'b1)
        begin
          j = 0;
        end
        else
        begin
          do_down = 1;
          s2_down [12-j] = sd;
          if(j === 12)
          begin
            if((RB1_OUT[m] !== s2_down[7:0]) || (m !== s2_down[12:8]))
            begin
              err_down = err_down + 1;
              $write("ERROR : The %3dth download frame = %b %b (expect = %5b %b)\n",m,s2_down[12:8],s2_down[7:0],m,RB1_OUT[m]);
            end
            m = m + 1;
          end
          j = j + 1;
        end
      end
    end
  end
  

  initial
  begin
    @(posedge S1_done)  //check RB1
    begin
      for(i=0;i<18;i=i+1)
      begin
        if(m1.mem[i] !== RB1_OUT[i]) 
        begin
          err_RB1 = err_RB1 + 1;
          $write("ERROR : RB1[%2h] = %h (expect = %h)\n", i,m1.mem[i],RB1_OUT[i]);
        end
      do_rb1 = 1;
      end
      
      if(err_RB1 === 0 && err_RB2 ===0 && err_up === 0 && err_down === 0 && do_rb1 === 1 && do_rb2 === 1 && do_up === 1 && do_down === 1)
      begin
        $display("\n");
        $display("\n");
        $display("        ****************************              ");
        $display("        **                        **        /|__/|");
        $display("        **  Congratulations !!    **      / O,O  |");
        $display("        **                        **    /_____   |");
        $display("        **  Simulation Complete!! **   /^ ^ ^ \\  |");
        $display("        **                        **  |^ ^ ^ ^ |w|");
        $display("        ****************************   \\m___m__|_|");
        $display("\n");
      end
      else if(err_RB2 ===0 && err_up === 0 && do_rb2 === 1 && do_up === 1)
      begin
        $write("------------------------------------------\n");
	$write("    Upload function  check successfully!\n");
        $write("------------------------------------------\n");
      end

      if(do_rb1 === 1 && err_RB1 === 0)
      begin
        $write("------------------------------------------\n");
        $write("      RB1 check successfully!\n");
        $write("------------------------------------------\n\n");
      end
      else
      begin
        $write("------------------------------------------\n");
        if(do_rb1 === 1)
        begin
          $write("There are %4d errors in RB1!\n",err_RB1);
          $write("      RB1 check fail!\n");
        end
        else
          $write("----------No Finish Write RB1-------------\n");  
        $write("------------------------------------------\n\n");
      end
      
      if(do_rb2 === 1 && err_RB2 === 0)
      begin
        $write("------------------------------------------\n");
        $write("      RB2 check successfully!\n");
        $write("------------------------------------------\n\n");
      end
      else
      begin
        $write("------------------------------------------\n");
        if(do_rb2 === 1)
        begin
          $write("There are %4d errors in RB2!\n",err_RB2);
          $write("      RB2 check fail!\n");
        end
        else
          $write("----------No Finish Write RB2-------------\n");  
        $write("------------------------------------------\n\n");
      end  
      
      if(do_up === 1 && err_up === 0)
      begin
        $write("------------------------------------------\n");
        $write("      upload frame check successfully!\n");
        $write("------------------------------------------\n\n");
      end
      else
      begin
        $write("------------------------------------------\n");
        if(do_up === 1)
        begin
          $write("There are %4d errors in during upload!\n",err_up);
          $write("Upload frame check fail!\n");
        end
        else
          $write("----------No Execting upload--------------\n");  
        $write("------------------------------------------\n\n");
      end
      
      if(do_down === 1 && err_down === 0)
      begin
        $write("------------------------------------------\n");
        $write("      download frame check successfully!\n");
        $write("------------------------------------------\n\n");
      end
      else
      begin
        $write("------------------------------------------\n");
        if(do_down === 1)
        begin
          $write("There are %4d errors in during download!\n",err_down);
          $write("Download frame check fail!\n");
        end
        else
          $write("----------No Execting download------------\n");  
        $write("------------------------------------------\n\n");
      end
      #55 $finish;
    end
  end
 
endmodule
                                                                                    

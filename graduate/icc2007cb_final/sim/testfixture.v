`timescale 100ps/1ps 
`define CYCLE    20                 // Modify your clock period here
`define SDFFILE  "./SGDE.sdf"       // Modify your sdf file name
`define INDATAFILE "./input1.dat"   // Input Patterns for X, Y, type
`define GOLDENDATA "./golden1.dat"  // Golden Pattern
`define OUTIMAGE "./image1.xpm"     // Output Image 

module test;
parameter PATTERN = `INDATAFILE;
parameter EXCEPT = `GOLDENDATA;
parameter n_sprite_max = 20;
parameter fb_size = 4096;
parameter CLOCK = `CYCLE*10;

reg         clk, reset, sprite, start;
reg [1:0]   type;
reg [5:0]   X, Y;
wire [12:0] SR_Q;
wire [11:0] FB_Q;

wire        ready, done;
wire        SR_CEN, FB_CEN, FB_WEN;
wire [8:0]  SR_A;
wire [11:0] FB_A, FB_D; 

reg [6:0]   xx, yy;
reg [13:0]  data [0:n_sprite_max];
reg [11:0]  frame_buffer [0:4095];
reg [13:0]  in_temp;
reg [11:0]  fb_temp;
reg         fb_ctrl, comp_flag, out_FB_CEN, out_FB_WEN, over, stop;
reg [11:0]  out_FB_A;
reg [11:0]  res_frame_buffer [0:4095];

wire        i_FB_CEN, i_FB_WEN;
wire [11:0] i_FB_A;
integer     i, j, err;
integer     a, b, k, h,xpmfile;
integer     adder;
integer	    n_sprite;

assign i_FB_CEN = (fb_ctrl)?out_FB_CEN:FB_CEN;
assign i_FB_WEN = (fb_ctrl)?out_FB_WEN:FB_WEN;
assign i_FB_A = (fb_ctrl)?out_FB_A:FB_A;

SGDE sgde1 (.ready(ready), .done(done), .clk(clk), .reset(reset), .sprite(sprite), .start(start), .type(type), .X(X), .Y(Y), .SR_CEN(SR_CEN), .SR_A(SR_A), .SR_Q(SR_Q), .FB_CEN(FB_CEN), .FB_WEN(FB_WEN), .FB_A(FB_A), .FB_D(FB_D), .FB_Q(FB_Q)); 

SR sr1 (.Q(SR_Q), .CLK(clk), .CEN(SR_CEN), .A(SR_A));

FB fb1 (.Q(FB_Q), .CLK(clk), .CEN(i_FB_CEN), .WEN(i_FB_WEN), .A(i_FB_A), .D(FB_D));

//initial $sdf_annotate(`SDFFILE, sgde1);

initial $readmemb (PATTERN, data);
initial $readmemb (EXCEPT, frame_buffer);

initial begin
   clk = 1'b0;
   reset = 1'b0;
   i = 0; j = 0; err = 0;
   fb_ctrl = 1'b0;
   comp_flag = 1'b0;
   start = 1'b0;
   sprite = 1'b0;
   over = 1'b0;
   stop = 1'b0;
   xx = 7'd0;
   yy = 7'd0;
   #CLOCK reset = 1'b1;
   #CLOCK reset = 1'b0;
end

always begin #(CLOCK/2) clk = ~clk; end

always @(posedge clk) begin
   if (reset == 1) begin
     n_sprite = data[0];
     i = 1;
     in_temp = 0;
   end
   else begin
     if (ready == 1) begin
       @(negedge clk)
       if (i <= n_sprite) begin
         sprite = 1'b1;
         in_temp = data[i];
         X = in_temp[13:8];
         Y = in_temp[7:2];
         type = in_temp[1:0];
         i = i+1;
       end
       else if (i == n_sprite+1) begin
         start = 1'b1;
         sprite = 1'b0;
         @(negedge clk) start = 1'b0;
         i = i+1;
       end
     end
     else 
       begin
       @(negedge clk)
       sprite = 1'b0;
       end
   end
end

initial begin
  $dumpfile("GE.vcd");
  $dumpvars;
  //$fsdbDumpfile("GE.fsdb");
  //$fsdbDumpvars;  
end

always @(posedge done) begin
   $display ("==================================================");
   $display ("=  Total Execution Time:%d ns  =", $time/10);
   $display ("==================================================\n");
   @(negedge clk) out_FB_CEN = 1'b0;
   fb_ctrl = 1'b1;
   out_FB_WEN = 1'b1;
   out_FB_A = 0;
   @(posedge clk) 
   comp_flag = 1'b1;
end

always @(posedge clk) begin
   if (fb_ctrl ==1) begin
     if (j < fb_size ) begin
       fb_temp = frame_buffer[j]; 
       if ((j%64) == 0)
         xx = 7'd0;
       else 
         xx = (j)%64;
       if (j <= 63)
         yy = yy;
       else if((j)%64 == 0)
         yy = yy+1;
     end
   end
end

always @(negedge clk) begin
   if (comp_flag ==1) begin
     res_frame_buffer[out_FB_A]=FB_Q;
     out_FB_A = out_FB_A+1;
     if (FB_Q !== fb_temp) begin
       $display("ERROR at corrdinate (%d,%d):	output %b !=	expect %b ", xx, yy, FB_Q, fb_temp);
       err = err + 1;
     end
     j = j+1;
     if (j >= fb_size) begin
       comp_flag = 0;
       over = 1'b1;
       @(negedge clk) stop = 1'b1;
     end  
   end
end

initial begin
   @(posedge stop) 
   if (over == 1)
   begin
      $display("---------------------------------------------\n");
      if (err == 0)  begin
         $display("All data have been generated successfully!\n");
         $display("-------------------PASS-------------------\n");
      end
      else
         $display("There are %d errors!\n", err);
      $display("---------------------------------------------\n");
   end
   else begin
     $display("---------------------------------------------\n");
     $display("Error!!! There is no any data output ...!\n");
     $display("-------------------FAIL-------------------\n");
     $display("---------------------------------------------\n");
   end
   xpm_write;
   $finish;
end

task xpm_write;
begin
/////////////////////////////////////////
//    write xpmfile                    //
/////////////////////////////////////////
      xpmfile= $fopen(`OUTIMAGE); 
      if(!xpmfile) $finish;
  
      $fdisplay(xpmfile, "/* XPM */");
      $fdisplay(xpmfile, "static char * image_xpm[] = {");
      $fdisplay(xpmfile, "\"640 640 72 2\",");
      $fdisplay(xpmfile, "\"..	c #000000\",");
      $fdisplay(xpmfile, "\"+.	c #006900\",");
      $fdisplay(xpmfile, "\"@.	c #008600\",");
      $fdisplay(xpmfile, "\"#.	c #0433D6\",");
      $fdisplay(xpmfile, "\"$.	c #090CE0\",");
      $fdisplay(xpmfile, "\"I.	c #0E560E\",");
      $fdisplay(xpmfile, "\"&.	c #137771\",");
      $fdisplay(xpmfile, "\"*.	c #1E865D\",");
      $fdisplay(xpmfile, "\"=.	c #36B33B\",");
      $fdisplay(xpmfile, "\"-.	c #379647\",");
      $fdisplay(xpmfile, "\";.	c #3DA63B\",");
      $fdisplay(xpmfile, "\">.	c #48686D\",");
      $fdisplay(xpmfile, "\",.	c #4B71AA\",");
      $fdisplay(xpmfile, "\"'.	c #4C7EC6\",");
      $fdisplay(xpmfile, "\").	c #504A41\",");
      $fdisplay(xpmfile, "\"!.	c #5C84A2\",");
      $fdisplay(xpmfile, "\"~.	c #602F90\",");
      $fdisplay(xpmfile, "\"{.	c #63A2FE\",");
      $fdisplay(xpmfile, "\"].	c #7297C4\",");
      $fdisplay(xpmfile, "\"^.	c #78A9C8\",");
      $fdisplay(xpmfile, "\"/.	c #7EC127\",");
      $fdisplay(xpmfile, "\"(.	c #89781F\",");
      $fdisplay(xpmfile, "\"_.	c #89CF89\",");
      $fdisplay(xpmfile, "\":.	c #92BDFD\",");
      $fdisplay(xpmfile, "\"<.	c #9C8926\",");
      $fdisplay(xpmfile, "\"[.	c #9DDBFC\",");
      $fdisplay(xpmfile, "\"}.	c #A7E6FE\",");
      $fdisplay(xpmfile, "\"|.	c #ABCCFF\",");
      $fdisplay(xpmfile, "\"1.	c #BFD8FE\",");
      $fdisplay(xpmfile, "\"  	c #CCFF00\",");
      $fdisplay(xpmfile, "\"3.	c #CEC939\",");
      $fdisplay(xpmfile, "\"4.	c #CEE70F\",");
      $fdisplay(xpmfile, "\"5.	c #CEECCE\",");
      $fdisplay(xpmfile, "\"6.	c #CF86A2\",");
      $fdisplay(xpmfile, "\"7.	c #D6F10A\",");
      $fdisplay(xpmfile, "\"8.	c #DE8463\",");
      $fdisplay(xpmfile, "\"9.	c #DECEBD\",");
      $fdisplay(xpmfile, "\"0.	c #DFB757\",");
      $fdisplay(xpmfile, "\"a.	c #E7BF57\",");
      $fdisplay(xpmfile, "\"b.	c #EAEC07\",");
      $fdisplay(xpmfile, "\"c.	c #ED1A2A\",");
      $fdisplay(xpmfile, "\"d.	c #F26912\",");
      $fdisplay(xpmfile, "\"e.	c #F2EC05\",");
      $fdisplay(xpmfile, "\"f.	c #F38309\",");
      $fdisplay(xpmfile, "\"g.	c #F54133\",");
      $fdisplay(xpmfile, "\"h.	c #F7C767\",");
      $fdisplay(xpmfile, "\"i.	c #F7D2B9\",");
      $fdisplay(xpmfile, "\"j.	c #F89F0B\",");
      $fdisplay(xpmfile, "\"k.	c #FADE76\",");
      $fdisplay(xpmfile, "\"l.	c #FC8E64\",");
      $fdisplay(xpmfile, "\"m.	c #FCCE06\",");
      $fdisplay(xpmfile, "\"n.	c #FE5600\",");
      $fdisplay(xpmfile, "\"o.	c #FE8425\",");
      $fdisplay(xpmfile, "\"p.	c #FEA11B\",");
      $fdisplay(xpmfile, "\"q.	c #FEAD35\",");
      $fdisplay(xpmfile, "\"r.	c #FEB672\",");
      $fdisplay(xpmfile, "\"s.	c #FEFF00\",");
      $fdisplay(xpmfile, "\"t.	c #FF0000\",");
      $fdisplay(xpmfile, "\"u.	c #FF7379\",");
      $fdisplay(xpmfile, "\"v.	c #FFAFAD\",");
      $fdisplay(xpmfile, "\"w.	c #FFC6B9\",");
      $fdisplay(xpmfile, "\"x.	c #FFDDD8\",");
      $fdisplay(xpmfile, "\"y.	c #FFE5E5\",");
      $fdisplay(xpmfile, "\"z.	c #FFE74A\",");
      $fdisplay(xpmfile, "\"A.	c #FFE752\",");
      $fdisplay(xpmfile, "\"B.	c #FFE76E\",");
      $fdisplay(xpmfile, "\"C.	c #FFEC94\",");
      $fdisplay(xpmfile, "\"D.	c #FFEF39\",");
      $fdisplay(xpmfile, "\"E.	c #FFF731\",");
      $fdisplay(xpmfile, "\"F.	c #FFF742\",");
      $fdisplay(xpmfile, "\"G.	c #FFF752\",");
      $fdisplay(xpmfile, "\"H.	c #FFFFFF\",");
  
      for (a=0;a<64;a=a+1)
      begin
        for (k=0;k<10;k=k+1)
        begin
          $fwrite(xpmfile, "\"");
          for (b=0;b<64;b=b+1)
          begin
            adder=a*64+b;
               case(res_frame_buffer[a*64+b])
                 12'b000000000000: $fwrite(xpmfile, "....................");
                 12'b000001100000: $fwrite(xpmfile, "+.+.+.+.+.+.+.+.+.+.");
                 12'b000010000000: $fwrite(xpmfile, "@.@.@.@.@.@.@.@.@.@.");
                 12'b000000111101: $fwrite(xpmfile, "#.#.#.#.#.#.#.#.#.#.");
                 12'b000000001110: $fwrite(xpmfile, "$.$.$.$.$.$.$.$.$.$.");
                 12'b000001010000: $fwrite(xpmfile, "I.I.I.I.I.I.I.I.I.I.");
                 12'b000101110111: $fwrite(xpmfile, "&.&.&.&.&.&.&.&.&.&.");
                 12'b000110000101: $fwrite(xpmfile, "*.*.*.*.*.*.*.*.*.*.");
                 12'b001110110011: $fwrite(xpmfile, "=.=.=.=.=.=.=.=.=.=.");
                 12'b001110010100: $fwrite(xpmfile, "-.-.-.-.-.-.-.-.-.-.");
                 12'b001110100011: $fwrite(xpmfile, ";.;.;.;.;.;.;.;.;.;.");
                 12'b010001100110: $fwrite(xpmfile, ">.>.>.>.>.>.>.>.>.>.");
                 12'b010001111010: $fwrite(xpmfile, ",.,.,.,.,.,.,.,.,.,.");
                 12'b010001111100: $fwrite(xpmfile, "'.'.'.'.'.'.'.'.'.'.");
                 12'b010101000100: $fwrite(xpmfile, ").).).).).).).).).).");
                 12'b010110001010: $fwrite(xpmfile, "!.!.!.!.!.!.!.!.!.!.");
                 12'b011000101001: $fwrite(xpmfile, "~.~.~.~.~.~.~.~.~.~.");
                 12'b011010101111: $fwrite(xpmfile, "{.{.{.{.{.{.{.{.{.{.");
                 12'b011110011100: $fwrite(xpmfile, "].].].].].].].].].].");
                 12'b011110101100: $fwrite(xpmfile, "^.^.^.^.^.^.^.^.^.^.");
                 12'b011111000010: $fwrite(xpmfile, "/./././././././././.");
                 12'b100001110001: $fwrite(xpmfile, "(.(.(.(.(.(.(.(.(.(.");
                 12'b100011001000: $fwrite(xpmfile, "_._._._._._._._._._.");
                 12'b100110111111: $fwrite(xpmfile, ":.:.:.:.:.:.:.:.:.:.");
                 12'b100110000010: $fwrite(xpmfile, "<.<.<.<.<.<.<.<.<.<.");
                 12'b100111011111: $fwrite(xpmfile, "[.[.[.[.[.[.[.[.[.[.");
                 12'b101011101111: $fwrite(xpmfile, "}.}.}.}.}.}.}.}.}.}.");
                 12'b101011001111: $fwrite(xpmfile, "|.|.|.|.|.|.|.|.|.|.");
                 12'b101111011111: $fwrite(xpmfile, "1.1.1.1.1.1.1.1.1.1.");
                 12'b110011110000: $fwrite(xpmfile, "                    ");
                 12'b110011000011: $fwrite(xpmfile, "3.3.3.3.3.3.3.3.3.3.");
                 12'b110011100000: $fwrite(xpmfile, "4.4.4.4.4.4.4.4.4.4.");
                 12'b110011101100: $fwrite(xpmfile, "5.5.5.5.5.5.5.5.5.5.");
                 12'b110010001010: $fwrite(xpmfile, "6.6.6.6.6.6.6.6.6.6.");
                 12'b110111110000: $fwrite(xpmfile, "7.7.7.7.7.7.7.7.7.7.");
                 12'b110110000110: $fwrite(xpmfile, "8.8.8.8.8.8.8.8.8.8.");
                 12'b110111001011: $fwrite(xpmfile, "9.9.9.9.9.9.9.9.9.9.");
                 12'b110110110101: $fwrite(xpmfile, "0.0.0.0.0.0.0.0.0.0.");
                 12'b111010110101: $fwrite(xpmfile, "a.a.a.a.a.a.a.a.a.a.");
                 12'b111011100000: $fwrite(xpmfile, "b.b.b.b.b.b.b.b.b.b.");
                 12'b111000010010: $fwrite(xpmfile, "c.c.c.c.c.c.c.c.c.c.");
                 12'b111101100001: $fwrite(xpmfile, "d.d.d.d.d.d.d.d.d.d.");
                 12'b111111100000: $fwrite(xpmfile, "e.e.e.e.e.e.e.e.e.e.");
                 12'b111110000000: $fwrite(xpmfile, "f.f.f.f.f.f.f.f.f.f.");
                 12'b111101000011: $fwrite(xpmfile, "g.g.g.g.g.g.g.g.g.g.");
                 12'b111111000110: $fwrite(xpmfile, "h.h.h.h.h.h.h.h.h.h.");
                 12'b111111011011: $fwrite(xpmfile, "i.i.i.i.i.i.i.i.i.i.");
                 12'b111110010000: $fwrite(xpmfile, "j.j.j.j.j.j.j.j.j.j.");
                 12'b111111010111: $fwrite(xpmfile, "k.k.k.k.k.k.k.k.k.k.");
                 12'b111110000110: $fwrite(xpmfile, "l.l.l.l.l.l.l.l.l.l.");
                 12'b111111000000: $fwrite(xpmfile, "m.m.m.m.m.m.m.m.m.m.");
                 12'b111101010000: $fwrite(xpmfile, "n.n.n.n.n.n.n.n.n.n.");
                 12'b111110000010: $fwrite(xpmfile, "o.o.o.o.o.o.o.o.o.o.");
                 12'b111110100001: $fwrite(xpmfile, "p.p.p.p.p.p.p.p.p.p.");
                 12'b111110100011: $fwrite(xpmfile, "q.q.q.q.q.q.q.q.q.q.");
                 12'b111110110111: $fwrite(xpmfile, "r.r.r.r.r.r.r.r.r.r.");
                 12'b111111110000: $fwrite(xpmfile, "s.s.s.s.s.s.s.s.s.s.");
                 12'b111100000000: $fwrite(xpmfile, "t.t.t.t.t.t.t.t.t.t.");
                 12'b111101110111: $fwrite(xpmfile, "u.u.u.u.u.u.u.u.u.u.");
                 12'b111110101010: $fwrite(xpmfile, "v.v.v.v.v.v.v.v.v.v.");
                 12'b111111001011: $fwrite(xpmfile, "w.w.w.w.w.w.w.w.w.w.");
                 12'b111111011101: $fwrite(xpmfile, "x.x.x.x.x.x.x.x.x.x.");
                 12'b111111101110: $fwrite(xpmfile, "y.y.y.y.y.y.y.y.y.y.");
                 12'b111111100100: $fwrite(xpmfile, "z.z.z.z.z.z.z.z.z.z.");
                 12'b111111100101: $fwrite(xpmfile, "A.A.A.A.A.A.A.A.A.A.");
                 12'b111111100110: $fwrite(xpmfile, "B.B.B.B.B.B.B.B.B.B.");
                 12'b111111101001: $fwrite(xpmfile, "C.C.C.C.C.C.C.C.C.C.");
                 12'b111111100011: $fwrite(xpmfile, "D.D.D.D.D.D.D.D.D.D.");
                 12'b111111110011: $fwrite(xpmfile, "E.E.E.E.E.E.E.E.E.E.");
                 12'b111111110100: $fwrite(xpmfile, "F.F.F.F.F.F.F.F.F.F.");
                 12'b111111110101: $fwrite(xpmfile, "G.G.G.G.G.G.G.G.G.G.");
                 12'b111111111111: $fwrite(xpmfile, "H.H.H.H.H.H.H.H.H.H.");
                 default: $fwrite(xpmfile,"H.H.H.H.H.H.H.H.H.H.");
               endcase
          end
          $fwrite(xpmfile, "\"");
          if(a==63 && k==9)
            $fwrite(xpmfile, "};\n");
          else
            $fwrite(xpmfile, ",\n");
        end
   end
   $fclose(xpmfile);
   $finish;
///////////////////////////
//    write xpmfile end  //
///////////////////////////
end
endtask

endmodule

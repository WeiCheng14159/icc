`timescale 1ns/10ps
`define CYCLE      10                 // Modify your clock period here
`define SDFFILE    "./MBF_syn.sdf"    // Modify your sdf file name
`define End_CYCLE  10000000          // Modify cycle times once your design need more cycle times!
`define EXP1       "./LPF_golden2.dat"     
`define EXP2       "./HPF_golden2.dat"     

module test;
parameter N_EXP   = 527;

reg   clk ;
reg   reset ;
wire  y_valid;
wire  z_valid;
wire  [7:0]   y, z;
reg   [7:0]   exp_mem1   [0:N_EXP-1];
reg   [7:0]   exp_mem2   [0:N_EXP-1];
reg   [7:0]   out_temp1;
reg   [7:0]   out_temp2;

integer       i, out_f, err1, err2, pass1, pass2, exp_num1, exp_num2;
reg           over1, over2;
wire  over =  over1 & over2;

   MBF  MBF(.clk(clk), .reset(reset), .y_valid(y_valid), .z_valid(z_valid), .y(y), .z(z));
   

`ifdef SDFFILE
initial $sdf_annotate(`SDFFILE, MBF);
`endif

initial	$readmemh (`EXP1, exp_mem1);
initial	$readmemh (`EXP2, exp_mem2);

initial begin
#0;
   clk         = 1'b1;
   reset       = 1'b0;
   exp_num1    = 0;
   exp_num2    = 0;
   err1        = 0;
   err2        = 0;
   pass1       = 0;
   pass2       = 0;
   over1       = 1'b0;   
   over2       = 1'b0;      
end

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
$dumpfile("MBF2.vcd");
$dumpvars;
//$fsdbDumpfile("MBF2.fsdb");
//$fsdbDumpvars;

   out_f = $fopen("out.dat");
   if (out_f == 0) begin
        $display("Output file open error !");
        $finish;
   end
end

initial begin
   #0              reset = 1'b1;
   #(`CYCLE*1);    reset = 1'b0;
end

always @(posedge clk)begin
   if(!over1)begin
      out_temp1 = exp_mem1[exp_num1];
      if(y_valid)begin
      $fdisplay(out_f,"%2h", y);      
         if((y !== out_temp1) || (y === 8'hx)) begin
            $display("ERROR at LPF %3d:output %2h !=expect %2h " ,exp_num1, y, out_temp1);
            err1 = err1 + 1 ;  
         end            
         else begin      
            pass1 = pass1 + 1 ;
         end      
         #1 exp_num1 = exp_num1 + 1;
      end     
      if(exp_num1 === N_EXP)  over1 = 1'b1;   
   end
end

always @(posedge clk)begin
   if(!over2)begin
      out_temp2 = exp_mem2[exp_num2];
      if(z_valid)begin
         $fdisplay(out_f,"%2h", z);      
         if((z !==out_temp2) || (z ===8'hx)) begin
            $display("ERROR at HPF %3d:output %2h !=expect %2h " ,exp_num2, z, out_temp2);
            err2 = err2 + 1 ;  
         end            
         else begin      
            pass2 = pass2 + 1 ;
         end      
         #1 exp_num2 = exp_num2 + 1;
      end     
      if(exp_num2 === N_EXP)  over2 = 1'b1;   
   end
end

initial  begin
 #(`CYCLE * `End_CYCLE);
   
 $display("-----------------------------------------------------\n");
 $display("Error!!! Somethings' wrong with your code ...!\n");
 $display("-------------------------FAIL------------------------\n");
 $display("-----------------------------------------------------\n");
 
 $finish;
end

initial begin
      @(posedge over)      
      if((over) && (exp_num1!='d0) && (exp_num2!='d0)) begin
         $display("-----------------------------------------------------\n");
         if ((err1 == 0) && (err2 == 0))  begin
            $display("Congratulations! All data have been generated successfully!\n");
            $display("-------------------------PASS------------------------\n");
         end
         else begin
            $display("There are %d errors for LPF!\n", err1);
            $display("There are %d errors for HPF!\n", err2);
            $display("-----------------------------------------------------\n");
         end
      end
      #(`CYCLE/2); $finish;
end
   
endmodule


`timescale 1ns/10ps
`define CYCLE       10           	   // Modify your clock period here
`define SDFFILE     "./SME_syn.sdf"	   // Modify your sdf file name
`define End_CYCLE   100000000              // Modify cycle times once your design need more cycle times!
`define EXP         "./golden3.dat"   
`define DEL         1
module test;
parameter E_NUM  = 43;

reg         clk;
reg         reset;
reg         case_insensitive;
wire [3:0]  pattern_no;
wire [11:0] match_addr;
wire        valid;
wire        finish;
wire [7:0]  T_data;
wire [11:0] T_addr;
wire [7:0]  P_data;
wire [6:0]  P_addr;

reg   [15:0]  exp_mem     [0:E_NUM-1];
reg   [15:0]  old_mem     [0:E_NUM-1];
reg           flag        [0:E_NUM-1];
reg   [15:0]  miss_tmp;
integer       i, j, k, out_f, err, pass, miss;
reg           hit, repeated, ok;
reg   [15:0]  a, b, c;


SME SME( .clk(clk),
         .reset(reset), 
         .case_insensitive(case_insensitive),
         .pattern_no(pattern_no),
         .match_addr(match_addr),
         .valid(valid),
         .finish(finish),
         .T_data(T_data),
         .T_addr(T_addr),
         .P_data(P_data),
         .P_addr(P_addr)
        );

rom_4096x8_t13 rom_4096x8_t13(
   .Q(T_data),
   .CLK(clk),
   .CEN(1'b0),
   .A(T_addr)
);


rom_128x8_t13 rom_128x8_t13(
   .Q(P_data),
   .CLK(clk),
   .CEN(1'b0),
   .A(P_addr)
);
 

`ifdef SDF
   initial $sdf_annotate(`SDFFILE, SME);
`endif

initial	$readmemh (`EXP, exp_mem);


initial begin
   clk               = 1'b0;
   reset             = 1'b0;
   case_insensitive  = 1'b1;
   err               = 0;
   pass              = 0;
   miss              = 0;
   hit               = 0;
   repeated          = 0;
   j                 = 0;
   ok                = 0;
   
   for(i=0; i<=E_NUM-1; i=i+1)begin
      flag[i]=0;
   end
   
end

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
//$dumpfile("SME.vcd");
//$dumpvars;
$fsdbDumpfile("SME.fsdb");
$fsdbDumpvars;
$fsdbDumpMDA;

   out_f = $fopen("out.dat");
   if (out_f == 0) begin
        $display("Output file open error !");
        $finish;
   end
end


initial begin
   @(posedge clk)  #`DEL  reset = 1'b1;
   #`CYCLE                reset = 1'b0;      
end

always @(posedge clk)begin
   if(valid==1)begin
      a= {pattern_no, match_addr};            
      
      for(i=0;i<=E_NUM-1;i=i+1)begin
         b=exp_mem[i];
         
         if(hit==0)begin
            if(a===b)begin
               if(j !== 0)begin
                  for(k=0; k<=j-1; k=k+1)begin
                     c= old_mem[k];
                     if(a===c)begin
                        repeated=1;
                     end
                  end
                  
                  if(repeated===0)begin
                     hit=1;
                     flag[i]=1;
                     pass=pass+1;
                     old_mem[j]=a;            
                     j=j+1;  
                  end                  
               end
               
               else begin //for first j=0 case
                  hit=1;  
                  flag[i]=1;
                  pass=pass+1;
                  old_mem[j]=a;            
                  j=j+1;                   
               end                 
            end
            else begin  //output a != expect value: b
               hit=0;               
            end
         end
            
      end
         
      if(hit===0)begin
         if(!repeated)begin   //repeated output is ok!
            err=err+1;
            $display("Error! output: pattern_no=%x  match_addr=%x \n", pattern_no, match_addr);
         end
      end  
         
      hit=0;
      repeated=0;
   end                                             
end


always @(posedge finish)begin
   if(finish)begin
      miss=E_NUM-pass;
      
      $display("*******      The Summary of String matching       ******\n");
      $display("--------------------------------------------------------\n");      
      $display("   pass  : %d\n", pass);
      $display("   error : %d\n", err);
      $display("   miss  : %d\n", miss);
      $display("--------------------------------------------------------\n");


      
      if(miss !==0)begin      
         $display("*******         The Miss Summary as below         ******\n");
         
         for(i=0; i<=E_NUM-1; i=i+1)begin
            if(flag[i] === 0)begin
               miss_tmp  = exp_mem[i];               
               $display("  Miss! pattern_no: %X  match_addr: %3X  \n", miss_tmp[15:12], miss_tmp[11:0]);
            end
         end      
      end
                  
   end                 
   ok=1;
end


initial  begin
 #(`CYCLE * `End_CYCLE);
   
 $display("-----------------------------------------------------\n");
 $display("Error!!! System has not received 'finish' signal for 'High'...!\n");
 $display("Please check the 'finish' signal again.              \n");
 $display("Another reason perhaps your End_CYCLE is too short!  \n");
 $display("So please check it and then run the simulation again!\n");
 $display("-------------------------FAIL------------------------\n");
 $display("-----------------------------------------------------\n");
 
 $finish;
end


initial begin
      @(posedge ok)      
      if((miss===0)  && (err === 0) && (pass===E_NUM)) begin
         $display("-----------------------------------------------------\n");
         $display("Congratulations! All data have been generated successfully!\n");
         $display("-------------------------PASS------------------------\n");
      end
      #(`CYCLE/2); $finish;
end

  
endmodule


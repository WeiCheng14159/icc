`timescale 1ns/100ps

`define tb1
`ifdef tb1
  `define CMD "p1_cmd.dat"
  `define MEM "p1_mem.dat"
  `define NUM 2
`endif
`ifdef tb2
  `undef tb1
  `define CMD "p2_cmd.dat"
  `define MEM "p2_mem.dat"
  `define NUM 4
`endif
`ifdef tb3
  `undef tb1
  `define CMD "p3_cmd.dat"
  `define MEM "p3_mem.dat"
  `define NUM 10
`endif
`ifdef tb4
  `undef tb1
  `define CMD "p4_cmd.dat"
  `define MEM "p4_mem.dat"
  `define NUM 10
`endif

`define CYCLE 10
`define SDFFILE  "NFC_syn.sdf"
`include "./t13rf128x8.v"
`include "./flash.v"
module test;

  reg  clk, rst;
  reg  [32:0] cmd;
  wire done;
  wire m_wen;
  wire [6:0] m_addr;
  wire [7:0] m_do, m_data;
  wire [7:0] f_io;
  wire f_cle, f_ale, f_ren, f_wen, f_rb;
  
  reg [32:0] pat_cmd [0:`NUM - 1];
  reg [7:0] pat_mem [0:(`NUM * 128) - 1];
  reg [32:0] pre_cmd;
  integer n, i, err;

  parameter duty = `CYCLE / 2;

  assign m_data = m_wen ? m_do : 8'hzz;

  NFC top(.clk(clk), 
          .rst(rst), 
          .cmd(cmd), 
          .done(done),
          .M_RW(m_wen), 
          .M_A(m_addr), 
          .M_D(m_data), 
          .F_IO(f_io), 
          .F_CLE(f_cle), 
          .F_ALE(f_ale), 
          .F_REN(f_ren), 
          .F_WEN(f_wen), 
          .F_RB(f_rb) );

  t13rf128x8 m1(.CLK(clk), 
                 .CEN(1'b0), 
                 .WEN(m_wen), 
                 .A(m_addr),
                 .D(m_data), 
                 .Q(m_do) );

  flash f1(.IO7(f_io[7]), 
           .IO6(f_io[6]), 
           .IO5(f_io[5]), 
           .IO4(f_io[4]), 
           .IO3(f_io[3]), 
           .IO2(f_io[2]), 
           .IO1(f_io[1]), 
           .IO0(f_io[0]), 
           .CLE(f_cle), 
           .ALE(f_ale), 
           .CENeg(1'b0), 
           .RENeg(f_ren), 
           .WENeg(f_wen), 
           .R(f_rb) );

  initial begin
    `ifdef FSDB
      $fsdbDumpfile("nfc.fsdb");
      $fsdbDumpvars;
    `endif

    `ifdef SDF
      $sdf_annotate(`SDFFILE, top);
    `endif

    $readmemb (`CMD, pat_cmd);
    $readmemb (`MEM, pat_mem);
  end

  initial begin
    clk = 1'b0;
    rst = 1'b0;
    n = 0;
    err = 0;
    #3
      rst = 1'b1;
    #15
      rst = 1'b0;
  end

  always #duty clk = ~clk;

  always @(posedge clk)
  begin
    if (done) 
    begin
      #duty cmd = pat_cmd[n];
      pre_cmd = pat_cmd[n-1];
      if (^(pat_cmd[n-1] & 33'h100000000)) //read - check memory
        for (i = 0; i < 128; i = i+1)
        begin
          if (pat_mem[(128 * (n-1)) + i] !== m1.mem[i])
          begin
            err = err + 1;
            $write("ERROR : mem[%2h] = %h (expect = %h) \n", i, m1.mem[i], pat_mem[(128 * (n-1)) + i]);
          end
        end
      if (~^(pat_cmd[n-1] & 33'h100000000)) //write - check flash
        for (i = 0; i < pre_cmd[6:0]; i = i+1)
        begin
          if (pat_mem[(128 * (n-1)) + i + pre_cmd[13:7]] !== f1.Mem[i + pre_cmd[31:14]])
          begin
            err = err + 1;
            $write("ERROR : flash[%5h] = %2h (expect = %h) \n", i + pre_cmd[31:14], f1.Mem[i + pre_cmd[31:14]], pat_mem[(128 * (n-1)) + i + pre_cmd[13:7]]);
          end
        end
      if (~^(pat_cmd[n] & 33'h100000000)) //write - update memory
        for (i = 0; i < 128; i = i+1)
          m1.mem[i] = pat_mem[(128 * n) + i];
      pre_cmd = pat_cmd[n];
      n = n + 1;
      if (n <= `NUM)
      begin
        $write("Command #%2d: ", n);
        if (~pre_cmd[32]) //write
          $write("Write, ");
        else //read
          $write("Read, ");
          $write("A_flash = %hH, A_memory = %hH, Length = %d.\n", pre_cmd[31:14], pre_cmd[13:7], pre_cmd[6:0]);
      end
    end

    if (n == `NUM + 1)
    begin
      if (err == 0)
      begin
        $write("------------------------------------------\n");
        $write("Internal Memory check successfully!\n");
        $write("-------------------PASS-------------------\n");
      end else begin
        $write("------------------------------------------\n");
        $write("There are %d errors!\n", err);
        $write("-------------------FAIL-------------------\n");
      end
      #2 $finish;
    end
  end

endmodule

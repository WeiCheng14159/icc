// This is generated automatically on 2021/03/26-23:39:53
// Check the # of bits for state registers !!!
// Check the # of bits for flag registers !!!

`ifndef __FLAG_DEF__
`define __FLAG_DEF__

// There're 9 interrupt flags in this design
`define INT_READ               	 0  
`define INT_VECT               	 1  
`define INT_CROS               	 2  
`define INT_SORT               	 3  
`define INT_EDGE               	 4  
`define INT_AREA               	 5  
`define INT_SUM_AREA           	 6  
`define INT_COMP               	 7  
`define INT_DONE               	 8  
`define INT_FLAG_W             	 9  

// There're 9 output flags in this design
`define CMD_READ               	 0  
`define CMD_VECT               	 1  
`define CMD_CROS               	 2  
`define CMD_SORT               	 3  
`define CMD_EDGE               	 4  
`define CMD_AREA               	 5  
`define CMD_SUM_AREA           	 6  
`define CMD_COMP               	 7  
`define CMD_DONE               	 8  
`define CMD_FLAG_W             	 9  

// There're 10 states in this design
`define S_READ                 	 0  
`define S_VECT                 	 1  
`define S_CROS                 	 2  
`define S_SORT                 	 3  
`define S_EDGE                 	 4  
`define S_AREA                 	 5  
`define S_SUM_AREA             	 6  
`define S_COMP                 	 7  
`define S_DONE                 	 8  
`define S_END                  	 9  
`define S_ZVEC                 	 10'b0
`define STATE_W                	 10 

// Macro from template
`define BUF_SIZE               	 5'd6
`define READ_MEM_DELAY         	 1  

// Self-defined macro
`define CNT_W                  	 16 
`define GLB_CNT_W              	 16 
`define LENG_W                 	 11 
`define DATA_W                 	 10 

`endif

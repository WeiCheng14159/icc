// This is generated automatically on 2021/03/20-22:22:12
// Check the # of bits for state registers !!!
// Check the # of bits for flag registers !!!

`ifndef __FLAG_DEF__
`define __FLAG_DEF__

// There're 6 interrupt flags in this design
`define INT_INIT               	 0  
`define INT_READ               	 1  
`define INT_AVG                	 2  
`define INT_COMP               	 3  
`define INT_SORT               	 4  
`define INT_OUT                	 5  
`define INT_FLAG_W             	 6  

// There're 6 output flags in this design
`define CMD_INIT               	 0  
`define CMD_READ               	 1  
`define CMD_AVG                	 2  
`define CMD_COMP               	 3  
`define CMD_SORT               	 4  
`define CMD_OUT                	 5  
`define CMD_FLAG_W             	 6  

// There're 7 states in this design
`define S_INIT                 	 0  
`define S_READ                 	 1  
`define S_AVG                  	 2  
`define S_COMP                 	 3  
`define S_SORT                 	 4  
`define S_OUT                  	 5  
`define S_END                  	 6  
`define S_ZVEC                 	 7'b0
`define STATE_W                	 7  

// Macro from template
`define BUF_SIZE               	 16'd16382
`define READ_MEM_DELAY         	 1  
`define EMPTY_ADDR             	 {5{1'b0}}
`define EMPTY_DATA             	 {24{1'b0}}

// Self-defined macro
`define CNT_W                  	 16 
`define GLB_CNT_W              	 16 
`define R                      	 2'b00
`define G                      	 2'b01
`define B                      	 2'b10
`define AVG_W                  	 11 
`define PSUM_W                 	 22 
`define DATA_W                 	 13 

`endif

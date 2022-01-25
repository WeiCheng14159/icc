// This is generated automatically on 2022/01/26-03:15:32
// Check the # of bits for state registers !!!
// Check the # of bits for flag registers !!!

`ifndef __FLAG_DEF__
`define __FLAG_DEF__

// There're 3 states in this design
`define S_READ                 	 0  
`define S_PROC                 	 1  
`define S_OUT                  	 2  
`define S_ZVEC                 	 3'b0
`define STATE_W                	 3  

// Macro from template
`define True                   	 1'b1
`define False                  	 1'b0
`define HEAD                   	 8'h5E
`define DOLLAR                 	 8'h24
`define DOT                    	 8'h2E
`define SPACE                  	 8'h20
`define STAR                   	 8'h2A
`define STR_SIZE               	 40 
`define PAT_SIZE               	 9  
`define EMPTY_ADDR             	 {16{1'b0}}
`define EMPTY_DATA             	 {16{1'b0}}
`define DATA_W                 	 8  

// Self-defined macro
`define CNT_W                  	 5  
`define ITR_W                  	 7  

`endif

#You may modified the clock constraints 
#or add more constraints for your design
####################################################
set cycle  10        
create_clock -period $cycle [get_ports clk]
...
...





####################################################



#The following are design spec. for synthesis
#You can NOT modify this seciton
#####################################################
set_clock_uncertainty  0.1  [all_clocks]
set_clock_latency      0.5  [all_clocks]
set_input_delay  1     -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 1     -clock clk [all_outputs] 
set_load         1     [all_outputs]
set_drive        1     [all_inputs]

set_operating_conditions -max_library slow -max slow
set_wire_load_model -name tsmc13_wl10 -library slow                        
#####################################################
                       

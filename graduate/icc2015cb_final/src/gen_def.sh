#!/bin/bash

timestamp=$(date +%Y/%m/%d-%H:%M:%S)
printf "// This is generated automatically on ${timestamp}\n"
printf "// Check the # of bits for state registers !!!\n"
printf "// Check the # of bits for flag registers !!!\n\n"

STATES=("S_INIT"             \
        "S_READ"             \
        "S_AVG"              \
        "S_COMP"             \
        "S_SORT"             \
        "S_OUT"              \
        "S_END"              \
)

OUT_FLAGS=("CMD_INIT"        \
           "CMD_READ"        \
           "CMD_AVG"         \
           "CMD_COMP"        \
           "CMD_SORT"        \
           "CMD_OUT"         \
)
INT_FLAGS=("INT_INIT"        \
           "INT_READ"        \
           "INT_AVG"         \
           "INT_COMP"        \
           "INT_SORT"        \
           "INT_OUT"         \
)

def_pattern="%-30s \t %-3s\n"
# Generate macro
printf "\`ifndef __FLAG_DEF__\n"
printf "\`define __FLAG_DEF__\n"

# Generate interrupt flags
len=${#INT_FLAGS[@]}
printf "\n// There're ${len} interrupt flags in this design\n"
for((idx=0; idx<${len}; idx++))
do
  printf "$def_pattern" "\`define ${INT_FLAGS[$idx]}" "${idx}"
done

# Generate interrupt flag width
printf "$def_pattern" "\`define INT_FLAG_W" "`expr ${idx}`"

# Generate output flags
len=${#OUT_FLAGS[@]}
printf "\n// There're ${len} output flags in this design\n"
for((idx=0; idx<${len}; idx++))
do
  printf "$def_pattern" "\`define ${OUT_FLAGS[$idx]}" "${idx}"
done

# Generate output flag width
printf "$def_pattern" "\`define CMD_FLAG_W" "`expr ${idx}`"


# Generate FSM states
len=${#STATES[@]}
printf "\n// There're ${len} states in this design\n"
for((idx=0; idx<${len}; idx++))
do
  printf "$def_pattern" "\`define ${STATES[$idx]}" "${idx}"
done

# Generate FSM init vector
printf "$def_pattern" "\`define S_ZVEC"     "${len}'b0"
printf "$def_pattern" "\`define STATE_W"    "${len}"

# Generate other macro
printf "\n// Macro from template\n"
printf "$def_pattern" "\`define BUF_SIZE"             "16'd16382"
printf "$def_pattern" "\`define READ_MEM_DELAY"       "1"

printf "$def_pattern" "\`define EMPTY_ADDR"           "{5{1'b0}}"
printf "$def_pattern" "\`define EMPTY_DATA"           "{24{1'b0}}"


printf "\n// Self-defined macro\n"
printf "$def_pattern" "\`define CNT_W"                "16"
printf "$def_pattern" "\`define GLB_CNT_W"            "16"

# Color encoding (2 bit)
printf "$def_pattern" "\`define R"                    "2'b00"
printf "$def_pattern" "\`define G"                    "2'b01"
printf "$def_pattern" "\`define B"                    "2'b10"

# Average width
printf "$def_pattern" "\`define AVG_W"                "11"
printf "$def_pattern" "\`define PSUM_W"               "22"

printf "$def_pattern" "\`define DATA_W"               "13" # AVG_W + 2

# Generate end macro
printf "\n\`endif\n"

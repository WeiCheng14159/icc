#!/bin/bash

timestamp=$(date +%Y/%m/%d-%H:%M:%S)
printf "// This is generated automatically on ${timestamp}\n"
printf "// Check the # of bits for state registers !!!\n"
printf "// Check the # of bits for flag registers !!!\n\n"

STATES=("S_READ"             \
        "S_VECT"             \
        "S_CROS"             \
        "S_SORT"             \
        "S_EDGE"             \
        "S_AREA"             \
        "S_SUM_AREA"             \
        "S_COMP"             \
        "S_DONE"             \
        "S_END"              \
)

OUT_FLAGS=("CMD_READ"        \
           "CMD_VECT"        \
           "CMD_CROS"        \
           "CMD_SORT"        \
           "CMD_EDGE"        \
           "CMD_AREA"        \
           "CMD_SUM_AREA"        \
           "CMD_COMP"        \
           "CMD_DONE"        \
)
INT_FLAGS=("INT_READ"        \
           "INT_VECT"        \
           "INT_CROS"        \
           "INT_SORT"        \
           "INT_EDGE"        \
           "INT_AREA"        \
           "INT_SUM_AREA"        \
           "INT_COMP"        \
           "INT_DONE"        \
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
printf "$def_pattern" "\`define BUF_SIZE"             "5'd6"
printf "$def_pattern" "\`define READ_MEM_DELAY"       "1"

#printf "$def_pattern" "\`define EMPTY_ADDR"           "{5{1'b0}}"
#printf "$def_pattern" "\`define EMPTY_DATA"           "{24{1'b0}}"


printf "\n// Self-defined macro\n"
printf "$def_pattern" "\`define CNT_W"                "16"
printf "$def_pattern" "\`define GLB_CNT_W"            "16"

# Length width
printf "$def_pattern" "\`define LENG_W"               "11"
# Coordiate width
printf "$def_pattern" "\`define DATA_W"               "10"

# Generate end macro
printf "\n\`endif\n"

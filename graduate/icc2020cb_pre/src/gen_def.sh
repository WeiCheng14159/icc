#!/bin/bash

timestamp=$(date +%Y/%m/%d-%H:%M:%S)
printf "// This is generated automatically on ${timestamp}\n"
printf "// Check the # of bits for state registers !!!\n"
printf "// Check the # of bits for flag registers !!!\n\n"

STATES=("S_READ"            \
        "S_PROC"            \
        "S_OUT"             \
)

def_pattern="%-30s \t %-3s\n"
# Generate macro
printf "\`ifndef __FLAG_DEF__\n"
printf "\`define __FLAG_DEF__\n"

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
printf "$def_pattern" "\`define True"                 "1'b1"
printf "$def_pattern" "\`define False"                "1'b0"
printf "$def_pattern" "\`define HEAD"                 "8'h5E"
printf "$def_pattern" "\`define DOLLAR"               "8'h24"
printf "$def_pattern" "\`define DOT"                  "8'h2E"
printf "$def_pattern" "\`define SPACE"                "8'h20"
printf "$def_pattern" "\`define STAR"                 "8'h2A"
printf "$def_pattern" "\`define STR_SIZE"             "40"
printf "$def_pattern" "\`define PAT_SIZE"             "9"

printf "$def_pattern" "\`define EMPTY_ADDR"           "{16{1'b0}}"
printf "$def_pattern" "\`define EMPTY_DATA"           "{16{1'b0}}"

printf "$def_pattern" "\`define DATA_W"               "8"

printf "\n// Self-defined macro\n"
printf "$def_pattern" "\`define CNT_W"                "5"
printf "$def_pattern" "\`define ITR_W"                "7"

# Generate end macro
printf "\n\`endif\n"

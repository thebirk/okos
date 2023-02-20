#!/bin/bash
objdump -D $1 -S -M intel --no-show-raw-insn --visualize-jumps=extended-color | less -R

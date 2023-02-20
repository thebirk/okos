#!/bin/bash
gdb kernel.bin -ex "target remote localhost:1234"
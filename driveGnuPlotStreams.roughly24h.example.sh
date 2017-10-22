#!/bin/bash
cat /dev/ttyS1 | awk '// {system("echo 0:"$1)}' | perl driveGnuPlotStreams.pl 1 1 \
 86400 \
 -40 40 \
 800x600+2+2 \
 temp \
 0

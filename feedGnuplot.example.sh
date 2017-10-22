#!/bin/bash
cat /dev/ttyS1 | awk '// {system("echo 1 "$1)}' | perl feedGnuplot.pl --dataindex --lines --points --y2 1 --stream

#!/bin/bash
stty -F /dev/ttyS1 300 
#cat /dev/ttyS1 | awk '// {print d,$1}' "d=$(date +%s)"
cat /dev/ttyS1 | awk '// {system("echo $(date +%s) "$1)}'

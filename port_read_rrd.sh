#!/bin/bash
renice 19 $$
stty -F /dev/ttyS0 300 
#cat /dev/ttyS0 | awk '// {print d,$1}' "d=$(date +%s)"
cat /dev/ttyS0 | awk '// {print $0 ; system("\
 rrdtool update ttyS0_0.rrd $(date +%s):"$1";\
 rrdtool update ttyS0_1.rrd $(date +%s):"$2";\
 rrdtool update ttyS0_2.rrd $(date +%s):"$3";\
 rrdtool update ttyS0_3.rrd $(date +%s):"$4";\
 rrdtool update ttyS0_4.rrd $(date +%s):"$5";\
 rrdtool update ttyS0_5.rrd $(date +%s):"$6";\
 rrdtool update ttyS0_6.rrd $(date +%s):"$7";\
 rrdtool update ttyS0_7.rrd $(date +%s):"$8";"\
 )}'

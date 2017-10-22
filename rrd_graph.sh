#!/bin/bash
rrdtool graph last_hour.png --start $[$(date +%s)-3600] --end $(date +%s) \
 DEF:temp=ttyS0_0.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w 600 -h 200 --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

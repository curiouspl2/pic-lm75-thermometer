#!/bin/bash
rrdtool graph last_24h.png --start now-86399 --end now \
 DEF:temp=ttyS1.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w 600 -h 200 --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

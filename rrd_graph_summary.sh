#!/bin/bash

WIDTH=1200
HEIGHT=200
#bonus height for weekly stats
HEIGHT_BONUS=100

#summary
rrdtool graph last_week_summary.png --start now-604800 --end now \
 DEF:0=ttyS0_0.rrd:temp:AVERAGE LINE1:0#000000:0.8m \
 DEF:1=ttyS0_1.rrd:temp:AVERAGE LINE1:1#0000FF:0.5m \
 DEF:2=ttyS0_2.rrd:temp:AVERAGE LINE1:2#00FF00:0.2m \
 DEF:3=ttyS0_3.rrd:temp:AVERAGE LINE1:3#00FFFF:0.1m \
 DEF:4=ttyS0_4.rrd:temp:AVERAGE LINE1:4#FF0000:0m \
 DEF:5=ttyS0_5.rrd:temp:AVERAGE LINE1:5#FF00FF:-0.01m \
 DEF:6=ttyS0_6.rrd:temp:AVERAGE LINE1:6#FF8F00:-0.20m \
 DEF:7=ttyS0_7.rrd:temp:AVERAGE LINE1:7#A0A0A0:-0.50m \
 -w $WIDTH -h $[$HEIGHT + $HEIGHT_BONUS]  --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced &

rrdtool graph last_24h_summary.png --start now-86399 --end now \
 DEF:0=ttyS0_0.rrd:temp:AVERAGE LINE1:0#000000:0.8m \
 DEF:1=ttyS0_1.rrd:temp:AVERAGE LINE1:1#0000FF:0.5m \
 DEF:2=ttyS0_2.rrd:temp:AVERAGE LINE1:2#00FF00:0.2m \
 DEF:3=ttyS0_3.rrd:temp:AVERAGE LINE1:3#00FFFF:0.1m \
 DEF:4=ttyS0_4.rrd:temp:AVERAGE LINE1:4#FF0000:0m \
 DEF:5=ttyS0_5.rrd:temp:AVERAGE LINE1:5#FF00FF:-0.01m \
 DEF:6=ttyS0_6.rrd:temp:AVERAGE LINE1:6#fF8F00:-0.20m \
 DEF:7=ttyS0_7.rrd:temp:AVERAGE LINE1:7#A0A0A0:-0.50m \
 -w $WIDTH -h $HEIGHT  --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced &

rrdtool graph last_hour_summary.png --start now-3600 --end now \
 DEF:0=ttyS0_0.rrd:temp:AVERAGE LINE1:0#000000:0.8m \
 DEF:1=ttyS0_1.rrd:temp:AVERAGE LINE1:1#0000FF:0.5m \
 DEF:2=ttyS0_2.rrd:temp:AVERAGE LINE1:2#00FF00:0.2m \
 DEF:3=ttyS0_3.rrd:temp:AVERAGE LINE1:3#00FFFF:0.1m \
 DEF:4=ttyS0_4.rrd:temp:AVERAGE LINE1:4#FF0000:0m \
 DEF:5=ttyS0_5.rrd:temp:AVERAGE LINE1:5#FF00FF:-0.01m \
 DEF:6=ttyS0_6.rrd:temp:AVERAGE LINE1:6#fF8F00:-0.20m \
 DEF:7=ttyS0_7.rrd:temp:AVERAGE LINE1:7#A0A0A0:-0.50m \
 -w $WIDTH -h $HEIGHT --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced &


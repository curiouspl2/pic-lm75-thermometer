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

#0
rrdtool graph last_week_0.png --start now-604800 --end now \
 DEF:temp=ttyS0_0.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_24h_0.png --start now-86399 --end now \
 DEF:temp=ttyS0_0.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_hour_0.png --start now-3600 --end now \
 DEF:temp=ttyS0_0.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

#1
rrdtool graph last_week_1.png --start now-604800 --end now \
 DEF:temp=ttyS0_1.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_24h_1.png --start now-86399 --end now \
 DEF:temp=ttyS0_1.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_hour_1.png --start now-3600 --end now \
 DEF:temp=ttyS0_1.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

#2
rrdtool graph last_week_2.png --start now-604800 --end now \
 DEF:temp=ttyS0_2.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_24h_2.png --start now-86399 --end now \
 DEF:temp=ttyS0_2.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_hour_2.png --start now-3600 --end now \
 DEF:temp=ttyS0_2.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

#3
rrdtool graph last_week_3.png --start now-604800 --end now \
 DEF:temp=ttyS0_3.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_24h_3.png --start now-86399 --end now \
 DEF:temp=ttyS0_3.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_hour_3.png --start now-3600 --end now \
 DEF:temp=ttyS0_3.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

#4
rrdtool graph last_week_4.png --start now-604800 --end now \
 DEF:temp=ttyS0_4.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_24h_4.png --start now-86399 --end now \
 DEF:temp=ttyS0_4.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_hour_4.png --start now-3600 --end now \
 DEF:temp=ttyS0_4.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

#5
rrdtool graph last_week_5.png --start now-604800 --end now \
 DEF:temp=ttyS0_5.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_24h_5.png --start now-86399 --end now \
 DEF:temp=ttyS0_5.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_hour_5.png --start now-3600 --end now \
 DEF:temp=ttyS0_5.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

#6
rrdtool graph last_week_6.png --start now-604800 --end now \
 DEF:temp=ttyS0_6.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_24h_6.png --start now-86399 --end now \
 DEF:temp=ttyS0_6.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_hour_6.png --start now-3600 --end now \
 DEF:temp=ttyS0_6.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

#7
rrdtool graph last_week_7.png --start now-604800 --end now \
 DEF:temp=ttyS0_7.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_24h_7.png --start now-86399 --end now \
 DEF:temp=ttyS0_7.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced

rrdtool graph last_hour_7.png --start now-3600 --end now \
 DEF:temp=ttyS0_7.rrd:temp:AVERAGE LINE2:temp#FF0000 \
 -w $WIDTH -h $HEIGHT --full-size-mode --alt-autoscale --no-gridfit \
  --alt-y-grid --slope-mode --interlaced


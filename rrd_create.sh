#!/bin/bash
rrdtool create ttyS0_0.rrd --step 1 DS:temp:GAUGE:5:-50:100 RRA:AVERAGE:0.1:10:60480
rrdtool create ttyS0_1.rrd --step 1 DS:temp:GAUGE:5:-50:100 RRA:AVERAGE:0.1:10:60480
rrdtool create ttyS0_2.rrd --step 1 DS:temp:GAUGE:5:-50:100 RRA:AVERAGE:0.1:10:60480
rrdtool create ttyS0_3.rrd --step 1 DS:temp:GAUGE:5:-50:100 RRA:AVERAGE:0.1:10:60480
rrdtool create ttyS0_4.rrd --step 1 DS:temp:GAUGE:5:-50:100 RRA:AVERAGE:0.1:10:60480
rrdtool create ttyS0_5.rrd --step 1 DS:temp:GAUGE:5:-50:100 RRA:AVERAGE:0.1:10:60480
rrdtool create ttyS0_6.rrd --step 1 DS:temp:GAUGE:5:-50:100 RRA:AVERAGE:0.1:10:60480
rrdtool create ttyS0_7.rrd --step 1 DS:temp:GAUGE:5:-50:100 RRA:AVERAGE:0.1:10:60480


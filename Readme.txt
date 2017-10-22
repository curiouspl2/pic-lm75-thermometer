.asm and .hex file for pic include gnuplot nessesities.
you can modify baudrate in the source, i've choosed 300bps
personally because it is easy to implement it for i.e. audio modem,
or optic link - faster baud rates would be problematic, and we need
such solutions because we want galvanic isolation to protect 
(expensive) PC from i.e. lightning strike induced currents.


shell script inserts date to stream from serial port. 
pic could theoretically insert own date, but it would 
1)drift 
2)make it impossible to enter sleep mode
3)increase power consumption
4)take more time to transmit over serial line

the resulting stream can be redirected to file , which can be later 
used by gnuplot to draw nie plot of temperature.

another , simpler approach would be to make pic emit also index number, 
which could be then used by gnuplot directly as X axis.
current approach is just appropriate for 'pc thermometer'.

scripts for RRD are added for convience - they are tested, and fully operational.

!!! power considerations !!!

with use of low-power lp2950 voltage regulator, and 4700uF and 2200uF capacitors 
and ad3232 (max232 equiv),
it was possible to transmit data out of 8 sensors powered from single serial port.

additional accuracy code (0.125C) for lm75A and adt75A was added, and it seems
that such amount of data is on very edge of power capacity of serial port.

addition of more capacitors is imho recommended to maintain stable supply, 
and if outdoor use is planned - perhaps small solar cell would also help.
(electronics require just 3.3V)





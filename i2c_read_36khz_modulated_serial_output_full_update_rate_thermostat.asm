;*******************************************************************
;
;	simple i2c thermometer
;
;	i2c thermometers in, 36khz modulated (IR compat) serial out, 
;	shift register based display with CLOCK and DATA. 
;	to interface to computer use TSOP infrared demodulator with it's output tied to RX pin (ttl)
;	TSOP works optimally at 1200bps. 
; 	if you want to switch to normal bit-banged serial - you must hack the serial routines yourself
;	(i still did not got to it, but i've left plenty of commented-out code to make it simple)
;	
;	there are few fixmes, lot of spaghetti and bit of confusing assumptions, 
; 	 but code is tested and does it's job fine.
;
;	
;*******************************************************************

;-----------features 

#define infrared_serial_output
	;//fixme - not really ifdef'd propelry yet
	; 36khz modulated serial output 
#ifdef 	infrared_serial_output
;#define splash_message
	; greeting/splash message on init/reset
;#define calibration_phase 
	;uncomment to display OSCCAL values (and calibrate serial out)
#endif 	infrared_serial_output

;#define shutdown_mode 
	; shut down lm75 after operations
;#define  sleep_mode 
	; sleep for delay
;#define  shift_register_display
	; required to have any shift register routines at all 
;#define	cooling_mode
	;//fixme 
	; global cooling or heating mode of thermostat. should be selectable for each sensor independently,
	; and from EEPROM... 
	; requires re-make of shutdown routines which mess with config register as a whole. 
	; right now setting affects ALL sensors. not defining means sensor will try to heat to set temp (active high)
#define	pseudo_analog_keyboard
	; pseudo analog keyboard. it sets KEY_[n] low, measures time taking it to get high again,
	; then sets it high and measures time taking it to get low. 
	; this is stored in two variables allowing to implement few types of keyboards. 

#ifdef	pseudo_analog_keyboard
#define	simple_two_key_keyboard
	; this is simplest two keys implementation. 
	; it requires 100nF cap and two buttons with 100ohm resistors (one to Vss , one to Vdd)
	; pros - not dependent on temperature, quality of capacitor etc. 
;#define analog_ladder_keyboard
	; using 100nF cap and set of resistors to change discharge and charge times in series with each switch. 
	;//fixme - currently not implemented
#ifdef	infrared_serial_output
#define	pseudo_analog_keyboard_infrared_serial_debug 
	;debug detected 0to1 and 1to0 transition times of keyboard
	;usefull to tune up resistor ladder keyboard resistors
#endif  infrared_serial_output

#endif 	pseudo_analog_keyboard

;------formatting
;//fixme 
; it would be nice to create new formatting theme for tv terminals displays
; idea would be to clear screen and then nicely format all sensors output so they appear in columns
; along with their additional settings like thermostats and some text descriptions 
; like :
;no  actual/setpoint/hyst
;1	22 / 24 / 22 - living room - heat pump
;2	10 / 99 / 99 - outside
;3	10 / 4 	/ 3  - garage heated with ground heat pump
;4 	-4 / -5 / -4 - fridge
;5 	 8 / 10 / 8  - fridge out to garage heat buffer
;6 	40 / 98 / 85 - solar collector critical - dump heat to garage buffer
;7	40 / 35 / 30 - solar collector low power pump
;8	25 / 25 / 30 - hybrid solar cell cooling

;#define  shift_register_display_0to7
	; use shift register display , order 0 to 7
;#define  shift_register_display_7to0
	; use shift register display, order 7 to 0 
;define	cr_only_for_gnuplot
	; uncomment to send only cr without lf - gnuplot scripts require such formatting
#define padded_output 
	; pad output to make it look pretty on serial terminals 

#define	thermostat_display
	; display thermostat settings for each sensor?
;-----
	; extra delay for i2c routines , insert nops here for longer cables
i2c_delay	macro
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	endm

;--define which thermometers are enabled - only ones defined there will be initalised, woken up, read and their themostats 
updated

#define		lm75_0
#define		lm75_1
;#define	lm75_2
;#define	lm75_3
;#define	lm75_4
;#define	lm75_5
;#define	lm75_6
;#define	lm75_7

;*******************************************************************
;
;	I/O configuration
;

#ifdef	infrared_serial_output
#define S_out		GPIO,GP5	; 1200 baud , 36khz modulated serial out
#define S_out_TRIS	TRISIO,GP5	; serial port TRIS
#define S_out_WPU	WPU,GP5
#endif 	infrared_serial_output 

#define	SCL		GPIO,GP1	; GP1 - SCL
#define	SCL_tris	TRISIO,GP1	; GP1 - tris
#define SCL_WPU		WPU,GP1

#define SDA		GPIO,GP2 	; GP2 - SDA
#define SDA_tris	TRISIO,GP2 	; GP2 - tris 
#define SDA_WPU		WPU,GP2

#ifdef shift_register_display
#define DISPLAY_CLOCK	GPIO,GP4 	; GP4 - shift register CLOCK
#define DISPLAY_CLOCK_TRIS TRISIO,GP4	; GP4 - tris
#define	DISPLAY_CLOCK_WPU WPU,GP4

#define DISPLAY_DATA	GPIO,GP0	; GP5 - shift register DATA
#define DISPLAY_DATA_TRIS TRISIO,GP0	; GP5 - tris
#define	DISPLAY_DATA_WPU WPU,GP0
#endif

#ifdef	pseudo_analog_keyboard
; this keyboard implementation uses just one pin to sense few buttons.
; it requires capacitor and buttons to pull it up or down .  
#define	KEY_1		GPIO,GP4
#define KEY_1_tris	TRISIO,GP4
#define KEY_1_WPU	WPU,GP4
#endif	pseudo_analog_keyboard

;#define minus_on_last_dot 1 		; if this is defined, minus is displayed as last dot,
					; instead of 'character' - on 7 segment.
					; last dot is useless anyway, 
					; and you can re-route i's line to 'real' minus LED 
					; i.e. horizontal oriented flat blue LED, 
					; or snowflake masked LED , or whatever. 					
			;comment it out for regular displayed on first segment. obviously it will not fit on
			; 2 character displays.
#define chars_per_display	4	
 ; how many chars single display fits? used for padding, and choice to display 100's and below 1's.


;*******************************************************************
;
;	lm75 configuration
;

;#define	lm75_classic	;uncomment this to compile simplified 0.5C precission code

;*******************************************************************
;
;	CPU configuration
;

	MESSG		"Processor = 12F629"
	#define 	RAMStart	0x20
	processor	12f629
	include		<p12f629.inc>
;	__config	_INTRC_OSC_CLKOUT & _PWRTE_ON & _WDT_OFF & _CP_OFF & _BODEN_ON  & _MCLRE_OFF
	__config	_INTRC_OSC_NOCLKOUT & _PWRTE_ON & _WDT_ON & _CP_OFF & _BODEN_ON  & _MCLRE_OFF
;	__config	_HS_OSC & _PWRTE_ON & _WDT_OFF & _CP_OFF & _BODEN_ON  & _MCLRE_OFF



;----------------------------------------end of defines
;--------------------------------------------------------------end of defines
; ------------------------------------------------------------------------------end of defines


; 	code base was 16f628 frequency counter. 
; 	designed for 4mhz crystal resonator (serial IO routines)

;o-----o-----o-----o-----o-----o-----o-----o-----o-----o-----o-----o
;*******************************************************************
;
;	Some frequently used code fragments
;	Use macros to make mistreaks consistently.
;
;-------------------------------------------------------------------
;	Select Register Bank 0

bank0	macro
	errorlevel	+302		; Re-enable bank warning
	bcf		STATUS,RP0	; Select Bank 0
	endm

;-------------------------------------------------------------------
;	Select Register Bank 1

bank1	macro
	bsf		STATUS,RP0	; Select Bank 1
	errorlevel	-302		; disable warning
	endm

;-------------------------------------------------------------------
;	Copy a 32 bit thing from one place to another

copy	macro	from,to

	movf	from+0,W
	movwf	to+0

	movf	from+1,W
	movwf	to+1

	movf	from+2,W
	movwf	to+2

	movf	from+3,W
	movwf	to+3

	endm





#define	beq	bz		; Motorola syntax branches
#define	BEQ	bz
#define	BNE	bnz
#define	bne	bnz

#define	BCC	bnc
#define	bcc	bnc
#define	BCS	bc
#define	bcs	bc

#define	BRA	goto
#define	bra	goto

;*******************************************************************
;
;	file register declarations: uses only registers in bank0
;	bank 0 file registers begin at 0x20 in the 16F628
;
;*******************************************************************

	cblock	RAMStart


	bcd:8			; BCD, MSD first 

	COUNT			; Bin to BCD convert (bit count)
	cnt			;                    (BCD BYTES)


	CHR
	TEMP			; DATS/Putchr temporary
	pmsg_t			; Used by PMSG

	FLAGS

	LM75_0:2		; LM75_0 temperature

	R_sign			; + and - 	

	LM75_adress		; adress of currently read themometer

	I2C_buffer:1		; I2C buffer variable (loops, etc)
	I2C_count:1		; I2c count variable (for loop)
	

	AccA:4			; Binary, MSByte first

	D_hex			; used by hex output routine	
				; used by serial out routines
	S_Wtemp			
	S_count
	S_mask			; used by IR routine

	d1
	d2
	baud_delay

	TXD
	TEMP1
	TEMP2
	set_temp
	set_hyst
	chars_left
	KEY_1_0to1_time
	KEY_1_1to0_time
	endc


;**********************************************************

#ifdef	calibration_phase
DISPLAY_CALIBRATION	macro

        clrf    AccA
        clrf    AccA+1
	clrf	AccA+2
	bank1
	movfw	OSCCAL
	bank0	
        movwf   AccA+3
;       Format as BCD string
;        iorwf   FPE,f           ; W may hold Error (0xff)
        call    B2_BCD          ; format as BCD
				; extract and send to display
;        call    Swap3
;       call    Move3
	SWAPF	bcd+6,W		;
	CALL	PutNyb
	MOVF	bcd+6,W		;
	CALL	PutNyb
	SWAPF	bcd+7,W		;
	CALL	PutNyb
	MOVF	bcd+7,W		;
	CALL	PutNyb
	endm
#endif
;-------------------------macros

;
;	Begin Executable Stuff(tm)
;

	org	0

GO	clrwdt			; 0 << Reset
	clrf	INTCON		; 1 No interrupts
	goto	START		; 2 << Interrupt.
	org	4
	goto 	INTERRUPT

INTERRUPT

	retfie


;**********************************************************
;
;	Part of string printer
;

pmsub	movwf	PCL		; Goto W
	nop			; Just in case
pm_end	return

;**********************************************************
;
;	Text Strings (stored in RETLWs)
;


C_and_half dt	".5 ",0  ; so we do not add it. 

#ifdef padded_output
C_full		dt	".0   ",0	; for gnuplot, we do not need the "C" suffix
C_point_125	dt	".125 ",0
C_point_25	dt	".25  ",0
C_point_375	dt	".375 ",0
C_point_5	dt	".5   ",0
C_point_625	dt	".625 ",0
C_point_75	dt	".75  ",0
C_point_875	dt	".875 ",0
#else
C_full	dt	".0 ",0	; for gnuplot, we do not need the "C" suffix
C_point_125	dt	".125 ",0
C_point_25	dt	".25 ",0
C_point_375	dt	".375 ",0
C_point_5	dt	".5 ",0
C_point_625	dt	".625 ",0
C_point_75	dt	".75 ",0
C_point_875	dt	".875 ",0
#endif
			; we need space though , to separate fields for gAWK
adv1	dt	"thermometer ",0


;**********************************************************
;
;	Main Program
;

START	
	movlw	0x07		; 2 Comparator off
	movwf	CMCON		; 3
	call	Init		; INITIALISE 
	CLRF	GPIO
	bsf	S_out		; Serial output to idle
#ifdef	splash_message
	MOVLW	adv1		; Sign on
	call	pmsg
#endif 	splash_message

;---------------------wake up all sensors
#ifdef  lm75_0
;	movlw	H'90'
	movlw	b'10010000'	;0 
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif

#ifdef 	lm75_1
;	movlw	H'92'
	movlw	b'10010010'	;1
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif

#ifdef	lm75_2
	movlw	b'10010100'	;2
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif

#ifdef	lm75_3
	movlw	b'10010110'	;3
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif

#ifdef	lm75_4
	movlw	b'10011000'	;4
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif

#ifdef	lm75_5
	movlw	b'10011010'	;5
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif

#ifdef	lm75_6
	movlw	b'10011100'	;6
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif

#ifdef	lm75_7
	movlw	b'10011110'	;7
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif
	call 	Delay_100ms

;--------------------


	call 	set_thermostats
;-------------------- init cr 
	call 	send_crlf 
			; initial cr. no data to not confuse scripts 
	clrwdt


mainloop	


#ifdef	shutdown_mode
;-------------------------------if we do use shutdown mode, we have to wake up all sensors
#ifdef	lm75_0
	movlw	b'10010000'	;0 
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif 	lm75_0

#ifdef	lm75_1
	movlw	b'10010010'	;1
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif	lm75_1

#ifdef	lm75_2
	movlw	b'10010100'	;2
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif	lm75_2

#ifdef	lm75_3
	movlw	b'10010110'	;3
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif	lm75_3

#ifdef	lm75_4
	movlw	b'10011000'	;4
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif	lm75_4

#ifdef	lm75_5
	movlw	b'10011010'	;5
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif	lm75_5

#ifdef	lm75_6
	movlw	b'10011100'	;6
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif	lm75_6

#ifdef	lm75_7
	movlw	b'10011110'	;7
	movwf	LM75_adress
	call	LM75_WAKEUP
#endif	lm75_7

	call	Delay_100ms
	clrwdt 			; wdt must start from 0 , otherwise will overflow..

	bank1
	bcf	OPTION_REG,PS2
	sleep 			;take a nap while lm75 is waking up
	bsf	OPTION_REG,PS2
	bank0

#endif	shutdown_mode


	clrwdt


#ifdef	shift_register_display_0to7
;--------if we do use shift register display, display the temperature, in the order we defined (0 to 7)
; sensor 0-7 order
#ifdef	lm75_0
	movlw	H'90'		;0 
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_0
#ifdef	lm75_1
	movlw	H'92'		;1
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_1
#ifdef	lm75_2
	movlw	b'10010100'	;2
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_2
#ifdef	lm75_3
	movlw	b'10010110'	;3
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_3
#ifdef	lm75_4
	movlw	b'10011000'	;4
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_4
#ifdef	lm75_5
	movlw	b'10011010'	;5
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_5
#ifdef	lm75_6
	movlw	b'10011100'	;6
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_6
#ifdef	lm75_7
	movlw	b'10011110'	;7
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_7
#endif	shift_register_display_0to7
;--==============================================

#ifdef	shift_register_display_7to0
;--------if we do use shift register display, display the temperature, in the order we defined (7 to 0)
; sensor 7-0 order 
#ifdef	lm75_7
	movlw	b'10011110'	;7
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_7
#ifdef	lm75_6
	movlw	b'10011100'	;6
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_6
#ifdef	lm75_5
	movlw	b'10011010'	;5
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_5
#ifdef	lm75_4
	movlw	b'10011000'	;4
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_4
#ifdef	lm75_3
	movlw	b'10010110'	;3
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_3
#ifdef	lm75_2
	movlw	b'10010100'	;2
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_2
#ifdef	lm75_1
	movlw	H'92'		;1
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_1
#ifdef	lm75_0
	movlw	H'90'		;0 
	movwf	LM75_adress
	call 	GET_TEMPERATURE
	call	DISPLAY_TEMPERATURE_7SEGMENT	
#endif	lm75_0
#endif	shift_register_display_7to0



#ifdef	lm75_0
	movlw	H'90'		;0 
	movwf	LM75_adress
	call 	GET_TEMPERATURE
#ifdef	shutdown_mode
	movlw	H'90'
	movwf	LM75_adress
	call	LM75_SHUTDOWN	; put lm75 to zzz. 
#endif	shutdown_mode
	call	DISPLAY_TEMPERATURE	
	clrwdt 
#ifdef	thermostat_display
	movlw	d'00'
	call	EE_R
	movwf	set_temp
	call	DISPLAY_THERMOSTAT
	movlw	d'09'
	call	EE_R
	movwf	set_hyst
	call	DISPLAY_HYSTERESIS
#endif	thermostat_display

#endif	lm75_0

#ifdef	lm75_1
	movlw	H'92'		;1
	movwf	LM75_adress
	call 	GET_TEMPERATURE
#ifdef	shutdown_mode
	movlw	H'92'
	movwf	LM75_adress
	call	LM75_SHUTDOWN	; put lm75 to zzz. 
#endif	shutdown_mode
	call	DISPLAY_TEMPERATURE
	clrwdt 
#ifdef	thermostat_display
	movlw	d'01'
	call	EE_R
	movwf	set_temp
	call	DISPLAY_THERMOSTAT
	movlw	d'10'
	call	EE_R
	movwf	set_hyst
	call	DISPLAY_HYSTERESIS
#endif	thermostat_display

#endif	lm75_1

#ifdef	lm75_2
	movlw	b'10010100'	;2
	movwf	LM75_adress
	call 	GET_TEMPERATURE
#ifdef	shutdown_mode
	movlw	b'10010100'	;2
	movwf	LM75_adress
	call	LM75_SHUTDOWN	; put lm75 to zzz. 
#endif	shutdown_mode
	call	DISPLAY_TEMPERATURE
	clrwdt 
#ifdef	thermostat_display
	movlw	d'02'
	call	EE_R
	movwf	set_temp
	call	DISPLAY_THERMOSTAT
	movlw	d'11'
	call	EE_R
	movwf	set_hyst
	call	DISPLAY_HYSTERESIS
#endif	thermostat_display

#endif	lm75_2

#ifdef	lm75_3
	movlw	b'10010110'	;3
	movwf	LM75_adress
	call 	GET_TEMPERATURE
#ifdef	shutdown_mode
	movlw	b'10010110'	;3
	movwf	LM75_adress
	call	LM75_SHUTDOWN	; put lm75 to zzz. 
#endif	shutdown_mode	
	call	DISPLAY_TEMPERATURE
	clrwdt
#ifdef	thermostat_display
	movlw	d'03'
	call	EE_R
	movwf	set_temp
	call	DISPLAY_THERMOSTAT
	movlw	d'12'
	call	EE_R
	movwf	set_hyst
	call	DISPLAY_HYSTERESIS
#endif	thermostat_display

#endif	lm75_3

#ifdef	lm75_4
	movlw	b'10011000'	;4
	movwf	LM75_adress
	call 	GET_TEMPERATURE
#ifdef	shutdown_mode
	movlw	b'10011000'	;4
	movwf	LM75_adress
	call	LM75_SHUTDOWN	; put lm75 to zzz. 
#endif	shutdown_mode
	call	DISPLAY_TEMPERATURE
	clrwdt 
#ifdef	thermostat_display
	movlw	d'04'
	call	EE_R
	movwf	set_temp
	call	DISPLAY_THERMOSTAT
	movlw	d'13'
	call	EE_R
	movwf	set_hyst
	call	DISPLAY_HYSTERESIS
#endif	thermostat_display

#endif	lm75_4

#ifdef	lm75_5
	movlw	b'10011010'	;5
	movwf	LM75_adress
	call 	GET_TEMPERATURE
#ifdef	shutdown_mode
	movlw	b'10011010'	;5
	movwf	LM75_adress
	call	LM75_SHUTDOWN	; put lm75 to zzz. 
#endif	shutdown_mode
	call	DISPLAY_TEMPERATURE
	clrwdt
#ifdef	thermostat_display
	movlw	d'05'
	call	EE_R
	movwf	set_temp
	call	DISPLAY_THERMOSTAT
	movlw	d'14'
	call	EE_R
	movwf	set_hyst
	call	DISPLAY_HYSTERESIS
#endif	thermostat_display

#endif	lm75_5

#ifdef	lm75_6
	movlw	b'10011100'	;6
	movwf	LM75_adress
	call 	GET_TEMPERATURE
#ifdef	shutdown_mode
	movlw	b'10011100'	;6
	movwf	LM75_adress
	call	LM75_SHUTDOWN	; put lm75 to zzz. 
#endif	shutdown_mode
	call	DISPLAY_TEMPERATURE
	clrwdt
#ifdef	thermostat_display
	movlw	d'06'
	call	EE_R
	movwf	set_temp
	call	DISPLAY_THERMOSTAT
	movlw	d'15'
	call	EE_R
	movwf	set_hyst
	call	DISPLAY_HYSTERESIS
#endif	thermostat_display

#endif	lm75_6

#ifdef	lm75_7
	movlw	b'10011110'	;7
	movwf	LM75_adress
	call 	GET_TEMPERATURE
#ifdef	shutdown_mode
	movlw	b'10011110'	;7
	movwf	LM75_adress
	call	LM75_SHUTDOWN	; put lm75 to zzz. 
#endif	shutdown_mode
	call	DISPLAY_TEMPERATURE
	clrwdt
#ifdef	thermostat_display
	movlw	d'07'
	call	EE_R
	movwf	set_temp
	call	DISPLAY_THERMOSTAT
	movlw	d'16'
	call	EE_R
	movwf	set_hyst
	call	DISPLAY_HYSTERESIS
#endif	thermostat_display

#endif	lm75_7

;-----if you want to calibrate pic, uncomment code below.

#ifdef calibration_phase
	; calibration is simple - it decreases OSCCAL value , sets it and tries to send it over serial. 
	; obviously only 'valid' OSCCAL values will get recieved. 
	; it will not work with autobaud recievers. 
	; pick some OSCCAL from the 'middle' for steady reception and be happy with it. 

	DISPLAY_CALIBRATION
	bank1
	decf	OSCCAL
	bank0
#endif

#ifdef	pseudo_analog_keyboard
	call	scankey_pseudo_analog
#ifdef	pseudo_analog_keyboard_infrared_serial_debug
	movlw	"A"
	call	putchr
	movfw	KEY_1_0to1_time
	call 	DISPLAY_W
	movlw	"B"
	call	putchr
	movfw	KEY_1_1to0_time
	call	DISPLAY_W
#endif	pseudo_analog_keyboard_infrared_serial_debug

#ifdef 	simple_two_key_keyboard
	movf	KEY_1_0to1_time,f
	btfss	STATUS,Z
	call	KEY_1_1_pressed

	movf	KEY_1_1to0_time,f
	btfss	STATUS,Z
	call	KEY_1_0_pressed

#endif 	simple_two_key_keyboard 

#endif	pseudo_analog_keyboard

;-----------------------------------------------------------

#ifdef	cr_only_for_gnuplot
	call	send_cr
#else
	call 	send_crlf
#endif 	cr_only_for_gnuplot 

#ifdef	sleep_mode
	sleep 			; we go to sleep. 
#endif	sleep_mode
	goto 	mainloop	


; -- below delay for longer sleep. 
	movlw	d'200'
	movwf	baud_delay
delay_1s
	call 	delay_3333
	decfsz	baud_delay
	goto	delay_1s

	goto	mainloop	; Start next measurement

;-------------------------------------------------------------------------------
;------------------------------end of mainloop----------------------------------
;-------------------------------------------------------------------------------

set_thermostats:

;--------------------------set all thermostats to values stored in EEPROM
#ifdef	lm75_0
	movlw	d'00'
	call	EE_R
	movwf	set_temp
	movlw	d'09'
	call	EE_R
	movwf	set_hyst

	movlw	b'10010000'	;0 
	movwf	LM75_adress
	call	SET_THERMOSTAT
#endif

#ifdef	lm75_1
	movlw	d'01'
	call	EE_R
	movwf	set_temp
	movlw	d'10'
	call	EE_R
	movwf	set_hyst

	movlw	b'10010010'	;1
	movwf	LM75_adress
	call	SET_THERMOSTAT
#endif

#ifdef	lm75_2
	movlw	d'02'
	call	EE_R
	movwf	set_temp
	movlw	d'11'
	call	EE_R
	movwf	set_hyst

	movlw	b'10010100'	;2
	movwf	LM75_adress
	call	SET_THERMOSTAT
#endif

#ifdef	lm75_3
	movlw	d'03'
	call	EE_R
	movwf	set_temp
	movlw	d'12'
	call	EE_R
	movwf	set_hyst

	movlw	b'10010110'	;3
	movwf	LM75_adress
	call	SET_THERMOSTAT
#endif 

#ifdef	lm75_4
	movlw	d'04'
	call	EE_R
	movwf	set_temp
	movlw	d'13'
	call	EE_R
	movwf	set_hyst

	movlw	b'10011000'	;4
	movwf	LM75_adress
	call	SET_THERMOSTAT
#endif

#ifdef	lm75_5
	movlw	d'05'
	call	EE_R
	movwf	set_temp
	movlw	d'14'
	call	EE_R
	movwf	set_hyst

	movlw	b'10011010'	;5
	movwf	LM75_adress
	call	SET_THERMOSTAT
#endif

#ifdef	lm75_6
	movlw	d'06'
	call	EE_R
	movwf	set_temp
	movlw	d'15'
	call	EE_R
	movwf	set_hyst

	movlw	b'10011100'	;6
	movwf	LM75_adress
	call	SET_THERMOSTAT
#endif

#ifdef	lm75_7
	movlw	d'07'
	call	EE_R
	movwf	set_temp
	movlw	d'16'
	call	EE_R
	movwf	set_hyst

	movlw	b'10011110'	;7
	movwf	LM75_adress
	call	SET_THERMOSTAT
#endif

	return 


#ifdef pseudo_analog_keyboard

#ifdef	simple_two_key_keyboard
;//fixme - just simple implementation allowing changing temp of sensor 0 
KEY_1_0_pressed:
#ifdef	pseudo_analog_keyboard_infrared_serial_debug
	movlw	"A"
	call	putchr
#endif	pseudo_analog_keyboard_infrared_serial_debug

	movlw	d'00'
	call	EE_R
	movwf	set_temp
	btfsc	set_temp,7	; test minus sign
	goto	KEY_1_0_negative
;positive. decrease
	decf	set_temp
	goto	KEY_1_0_pressed_write	; store

KEY_1_0_negative: ;//fixme - is this really nessesary? lol.
	xorlw	b'11111111' ;invert W
	movwf	set_temp
	incf	set_temp ; add 1 (convert from 2's complement)

	incf	set_temp	; decrease negative temperature
	movfw	set_temp ; move to W
	xorlw	b'11111111' ;invert W
	movwf	set_temp ; move to data register
	incf	set_temp	; add 1(convert from 2's complement)

KEY_1_0_pressed_write:
	movlw	d'00' ; set_temp
	bank1
	movwf	EEADR	; mem location
	bank0
	movfw	set_temp	; data
	call	EE_W
	movlw	d'09'	; hysteresis
	bank1
	movwf	EEADR 	; mem location
	bank0
	movfw	set_temp	; data
	call	EE_W
	
	call 	set_thermostats
	return

KEY_1_1_pressed:
#ifdef	pseudo_analog_keyboard_infrared_serial_debug
	movlw	"B"
	call	putchr
#endif	pseudo_analog_keyboard_infrared_serial_debug

	movlw	d'00'
	call	EE_R
	movwf	set_temp
	incf	set_temp
	goto	KEY_1_0_pressed_write	; same as for key 0

	return
#endif 	simple_two_key_keyboard

;scankeyboard
scankey_pseudo_analog:
	bank1
	bcf	KEY_1_tris
	bank0
	bcf	KEY_1
	call	Delay_100ms
	; set key sense to 0
	bank1
	bsf	KEY_1_tris 	; set to input
	bank0
	call	KEY_1_test_1

	bank1
	bcf	KEY_1_tris
	bank0
	bsf	KEY_1
	call	Delay_100ms
	; set key sense to 1
	bank1
	bsf	KEY_1_tris 	; set to input
	bank0
	call	KEY_1_test_0
	return

;	movf	KEY_1_0to1_time,f
;	btfss	STATUS,Z
;	goto	KEY_1_1_pressed

;	movf	KEY_1_1to0_time,f
;	btfss	STATUS,Z
;	goto	KEY_1_0_pressed

;-----test1
KEY_1_test_1:
	clrf	KEY_1_0to1_time

KEY_1_test_1_loop:
	incfsz	KEY_1_0to1_time
	goto	KEY_1_0to1_incf
	goto	KEY_1_0to1_time_overflow
		; key 1 held to 0 or no key pressed 
KEY_1_0to1_incf:
	btfss	KEY_1
	goto	KEY_1_test_1_loop
			; 1-255 value found
KEY_1_0to1_time_overflow:
			; KEY_1_0to1_time set to 0 
	return

;----test0
KEY_1_test_0:
	clrf	KEY_1_1to0_time

KEY_1_test_0_loop:
	incfsz	KEY_1_1to0_time
	goto	KEY_1_1to0_incf
	goto	KEY_1_1to0_time_overflow
		; key 1 held to 1 or no key pressed
KEY_1_1to0_incf:
	btfsc	KEY_1
	goto	KEY_1_test_0_loop
			; 1-255 value found
KEY_1_1to0_time_overflow:
			; KEY_1_1to0_time set to 0 
	return


DISPLAY_W:

        clrf    AccA
        clrf    AccA+1
	clrf	AccA+2
;	bank1
;	movfw	OSCCAL
;	bank0

        movwf   AccA+3	; mov W to AccA+3 - display 8 bit value

;       Format as BCD string
;        iorwf   FPE,f           ; W may hold Error (0xff)
        call    B2_BCD          ; format as BCD
				; extract and send to display
;        call    Swap3
;       call    Move3
	SWAPF	bcd+6,W		; 1000
;	CALL	PutNyb		; W is 256max so no need for 1000's
	MOVF	bcd+6,W		; 100
	CALL	PutNyb
	SWAPF	bcd+7,W		; 10
	CALL	PutNyb
	MOVF	bcd+7,W		; 1
	CALL	PutNyb
	return


#endif pseudo_analog_keyboard

; 100ms delay

Delay_100ms
			;99993 cycles
	movlw	0x1E
	movwf	d1
	movlw	0x4F
	movwf	d2
Delay_100ms_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_100ms_0
			;3 cycles
	goto	$+1
	nop
			;4 cycles (including call)
	return

;**********************************************************
;
;	Print String addressed by W
;	Note: Strings are in program space
;

pmsg	movwf	pmsg_t		; Temp for pointer

pm1	movf	pmsg_t,W	; Get current pointer
	call	pmsub
	andlw	0xff		; Test returned value
	beq	pm_end		; NULL = All done
	call	DATS
	incf	pmsg_t,F
	goto	pm1



;
;	Put a BCD nybble to display
;

PutNyb	ANDLW	0x0F		; MASK OFF OTHER PACKED BCD DIGIT
	ADDLW	0x30		; Convert BIN to ASCII

;**********************************************************
;
;	Put a data byte to display
;

DATS	movwf	TEMP		; Save character for LCD
	call	putchr

	RETLW	0

;------------------

#ifdef	shift_register_display
PUSH_7SEG:
	movwf	TEMP		; save data into F - we will roll it using rlf which cannot operate on W.
	movlw	0x08		; 8 bit to roll
	movwf	COUNT		; to bit counter

PUSH_7SEG_LOOP
	bsf	DISPLAY_DATA	; clearing DATA preemptively (0 means 'lit', so invert)
	rlf	TEMP,f 		; we roll left
	btfsc	STATUS,C	; if C is clear, no need to change DATA
	bcf	DISPLAY_DATA	; if C is set, DATA must be set too (0 means 'lit' , so invert)
				; 200ns
	
	
	bsf	DISPLAY_CLOCK	; rlf in external shift registers :)
	nop			; ensure shift register caught up
				; it is HC cmos , so 200ns should be fair enough. 
		; add more for slow chips or comment out for fast ones


	bcf	DISPLAY_CLOCK	; end of pulse then.

	decfsz	COUNT		; decrement counter, if not 0
	goto 	PUSH_7SEG_LOOP	; loop...

	bsf	DISPLAY_DATA
	nop
	bcf	DISPLAY_DATA
	nop
	bsf	DISPLAY_DATA
	nop
	bcf	DISPLAY_DATA

	return 
	
#endif	shift_register_display

;******************************************************************
;
;	Convert 32-bit binary number at <AccA:4> into a bcd number
;	at <bcd:5>. Uses Mike Keitz's procedure for handling bcd 
;	adjust. Microchip AN526
;

B2_BCD

b2bcd	movlw	.32		; 32-bits
	movwf	COUNT		; make cycle counter

	clrf	bcd+0		; clear result area
	clrf	bcd+1
	clrf	bcd+2
	clrf	bcd+3
	clrf	bcd+4
	clrf	bcd+5
	clrf	bcd+6
	clrf	bcd+7

	
b2bcd2  movlw	bcd		; make pointer
	movwf	FSR
	movlw	.8		; Number of BCD bytes?
	movwf	cnt		; 2 BCD digits per byte

; Mike's routine:

b2bcd3	movlw	0x33    
        addwf	INDF,f		; add to both nybbles
        btfsc	INDF,3		; test if low result > 7
        andlw	0xf0		; low result >7 so take the 3 out
        btfsc	INDF,7		; test if high result > 7
        andlw	0x0f		; high result > 7 so ok
        subwf	INDF,f		; any results <= 7, subtract back
        incf	FSR,f		; point to next
        decfsz	cnt,f
        goto	b2bcd3
        
        rlf	AccA+3,f	; get another bit
        rlf	AccA+2,f
        rlf	AccA+1,f
        rlf	AccA+0,f

	rlf	bcd+7,f
	rlf	bcd+6,f
	rlf	bcd+5,f
        rlf	bcd+4,f		; put it into bcd
        rlf	bcd+3,f
        rlf	bcd+2,f
        rlf	bcd+1,f
        rlf	bcd+0,f

        decfsz	COUNT,f		; all done?
        goto	b2bcd2		; no, loop
        return			; yes



;********************************************************************
;       Initialise Input & Output devices
;********************************************************************

Init	bank1

	movlw	b'00000000'		; Option register
	movwf	OPTION_REG	; weak pull-up enabled
				; INTDEG Don't care
				; Count RA4/T0CKI
				; Count on falling edge
				; Prescale Timer/counter
				; divide Timer/counter by 256
	bsf	OPTION_REG,PS1
	nop
	bsf	OPTION_REG,PS2
	nop
	bsf	OPTION_REG,PS0
	nop
	bsf	OPTION_REG,PSA
	call	3ffh
	movwf	OSCCAL

#ifdef	infrared_serial_output
	bcf	S_out_TRIS	; set serial output as output.
				; as we do not want to introduce 
				; extra noise on (simple) serial line)
				; this will remain like that 
				; so set each time , and never never back.
	nop
	bcf	S_out_WPU	; disable weak pullup on serial output's pin
	nop
#endif 	infrared_serial_output
#ifdef	pseudo_analog_keyboard
	bcf	KEY_1_WPU
#endif	pseudo_analog_keyboard

#ifdef	shift_register_display
	nop
	bcf	DISPLAY_CLOCK_TRIS ; display clock is output
	nop
	bcf	DISPLAY_DATA_TRIS ; display data is output
	nop
	bcf	DISPLAY_CLOCK_WPU
	nop
	bcf	DISPLAY_DATA_WPU
	nop
#endif	shift_register_display
	bank0

	return



;***********************************************************************
;
;    Print CRLF to serial
;

send_crlf
	movlw	0x0d		; CRLF
	call	putchr
	movlw	0x0a		; for gnuplot - only LF. 
	goto	putchr		; 

send_cr
	movlw	0x0d		; CRLF
	goto	putchr


	
;***********************************************************************
;
;    Print W as 2 Hex digits
;

hex_2	movwf	D_hex
	swapf	D_hex,w		; Get big bit
	call	hex_3

	movf	D_hex,w		; Get little bit

hex_3	andlw	0x0f		; keep bottom 4 bits
	addlw	0xF6
	bcc	hex_4
	addlw	0x07		; binary A -> ASCII A
hex_4	addlw	0x3A		; binary 0 -> ASCII 0
;	goto	putchr

;********************************************************
;
;    software serial Output Routines for PIC16Fx
;    and infrared 36khz modulated serial output routines. 

;    Clock is 4.0 MHz.
;    ie. 1.0 us per cycle = 4/Fosc.
;
;    9600 Baud  = 104.17 us
;               = 104.17   CPU cycles
;
;
;	4800 baud = 208 us
; 	1200 baud = 832 us
;
;	300 baud = 3333.333 us
;		- 3333.333 CPU cycles

;
;********************************************************
;
;	Output the character in W. Assumes Mac is ready.
;
;	Uses W
;
;	currently code below is result of some brainstorming and experiments.
;	infrared tsop4136 reciever cannot handle data rates below 1200 and above 2400, 
; 	so 300 baud output which was initial idea had to be abandoned. 
; 	1200 baud works perfectly - according to experiments, so this code is left so far.
; 	in future, ifdef'ing the code is needed - this way user can select proper baud rate, 
; 	ir modulation or not, and ir modulation period and duty cycle. 
; 	right now one have to either to adjust stuff by hand, or use as-is. 



;delay_3333
;
;			;3328 cycles
;	movlw	0x99
;	movwf	d1
;	movlw	0x03
;	movwf	d2
;Delay_0
;	decfsz	d1, f
;	goto	$+2
;	decfsz	d2, f
;	goto	Delay_0
;
;			;1 cycle
;	nop
;
;			;4 cycles (including call)
;	return

delay_3333		; ~832us, 1200 baud

			;828 cycles
	movlw	0xa5
	movwf	d1
	movlw	0x01
	movwf	d2
Delay_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_0

			;4 cycles (including call)
	return





IR_out_3333

;	movlw	d'123'		; 123 * 27us = ~3333us
	movlw	d'31'		; 30*27us = 810us  - plus 1
	movwf	d1		; plus 2 = 812
IR_out_1
	bsf	S_out		; 1us
	nop			; 2
	nop			; 3
	nop			; 4
	nop			; 5
	nop			; 6
	nop			; 7
	nop			; 8
	nop			; 9 
	nop			; 10 
	nop			; 11
	nop			; 12
	bcf	S_out		; 13
	nop			; 14
	nop			; 15
	nop			; 16
	nop			; 17
	nop			; 18
	nop			; 19
	nop			; 20
	nop			; 21
	nop			; 22
	nop			; 23
	nop			; 24
	decfsz	d1,f		; 25
	goto	IR_out_1	; 26 and 27

			; 810 
	bsf	S_out   ; 811, 1
	nop	; 812, 2
	nop	; 813, 3
	nop	; 814, 4
	nop	; 815, 5
	nop	; 816, 6
	nop	; 817, 7
	nop	; 818, 8
	nop	; 819, 9 
	nop	; 820, 10
	nop	; 821, 11
	nop	; 822, 12
	bcf	S_out ; 823, 13
	nop	; 824, 14
	nop	; 825, 15
	nop	; 826, 16
	nop	; 827, 17
	nop	; 828, 18
			; +4 (incl. call = 832)
	return





putchr	movwf	S_Wtemp		; Character being output



;	goto SENDsub 		; user 4800 baud routine 
				; or send over 300baud.
				; actually it could send on both 300 baud and 4800 baud, 
				; over different i/o pins or whatever your imagination suggests.

;------------------------------------------
;------TODO-----fix300baud routine...

	movlw	0x08		; Bit count
	movwf	S_count

;	bcf	S_out		; Send a 0 - Start bit
	bcf	S_mask,0		; send 0 . chooses if we send modulated out or no.
;	nop
;	nop
;	nop
;	nop

put_clp

				; baud delay
	btfsc	S_mask,0		; if S_mask is 1
	call 	delay_3333	; just idle delay...

	btfss	S_mask,0		; if S_mask is 0
	call	IR_out_3333	; modulate light with 36khz for 3333uS

	rrf	S_Wtemp,f	; Transmit a bit
	bcs	t_0

;	bcf	S_out		; Send a 0
	bcf	S_mask,0

	bra	tx_1

;t_0	bsf	S_out		; Send a 1
t_0	bsf	S_mask,0

tx_1	decfsz	S_count,f	; Done all bits?
	goto	put_clp

;	call 	delay_3333

	btfsc	S_mask,0		; if S_mask is 1
	call 	delay_3333	; just idle delay...

	btfss	S_mask,0		; if S_mask is 0
	call	IR_out_3333	; modulate light with 36khz for 3333uS


;	bsf	S_out		; Transmit two stop bit
	; 1 is just idle delay with infrared TX. so just idle 2 bits.
	call 	delay_3333
	call	delay_3333
				; delay one bit as i2c reads are fast.

	return




SENDsub	movwf	TXD		; store in data register
	bcf	S_out		; start bit
	movlw	0x08
	movwf	TEMP1		; number of bits to send, 9600-8-N-1
	call	T_Wait
_SENDa	btfsc	TXD,0x00	; send LSB first !
	bsf	S_out
	btfss	TXD,0x00
	bcf	S_out
	rrf	TXD,f
	call	T_Wait
	decfsz	TEMP1,f
	goto	_SENDa
	bsf	S_out		; stop bit
	call	T_Wait
	call	T_Wait		; due to re-synchronization
	RETURN

T_Wait	movlw	0x41		; FOR TRANSMISSION & RECEPTION
	movwf	TEMP2		; total wait cycle until next
	goto	X_Wait		; bit: 4800 baud ==> 208 us

;*** When entering this subroutine, ISR context restore has already consumed some cycles ***
SB_Wait	movlw	0x18		; FOR RECEPTION of start bit
	movwf	TEMP2		; total wait cycle : 104 us
	goto	X_Wait		; (=> sampling in the center of each bit)

X_Wait	decfsz	TEMP2,1		; LOOP
	goto	X_Wait
	RETURN

DISPLAY_HYSTERESIS:
	movlw	"H"
	call	putchr

        clrf    AccA
        clrf    AccA+1
	clrf	AccA+2
        movf    set_hyst,W        ; high byte
        movwf   AccA+3
        bcf     AccA+3,7        ; remove sign data from numerical display
        btfss   set_hyst,7        ; test sign
        goto    LM75_thermostat_PLUS
	goto	LM75_thermostat_MINUS
DISPLAY_THERMOSTAT:
	movlw	"T"
	call	putchr

        clrf    AccA
        clrf    AccA+1
	clrf	AccA+2
        movf    set_temp,W        ; high byte
        movwf   AccA+3
        bcf     AccA+3,7        ; remove sign data from numerical display
        btfss   set_temp,7        ; test sign
        goto    LM75_thermostat_PLUS
LM75_thermostat_MINUS:
	movfw	AccA+3	; store actual value in W
	clrf	AccA+3	; clear register
	decf	AccA+3	; decrement - it holds 1111 1111 now
	subwf	AccA+3,f	; subtract 1111 1111 - value, store in register
	movfw	AccA+3	; store in W
	andlw	b'01111111'	; leave just 7 bits
	movwf	AccA+3	; store in register. 

        movlw   0x2d            ; display minus
	movwf	R_sign	
	call 	DATS		; display it. 
        goto    LM75_thermostat_DISPLAY
LM75_thermostat_PLUS:
        movlw   0x20            ; plus
        movwf   R_sign          ; save for later display

LM75_thermostat_DISPLAY:

;       Format as BCD string
;        iorwf   FPE,f           ; W may hold Error (0xff)
        call    B2_BCD          ; format as BCD

				; extract and send to display
;        movf    R_sign,w        ; Sign
;       call    DATS		 - late display, old method.

	movf	bcd+6,W		; 100's 
	andlw	0x0f		; mask higher bcd digit
	btfsc	STATUS,Z	; did it flip to 0?
	goto	thermostat_blank100	; yes, blank 100's
	movf	bcd+6,W		; no, display 100's
	CALL	PutNyb		; display 10's. 
	goto	thermostat_noblank10	; we _have_ to display 10's, even if it's 0!
thermostat_blank100:

	SWAPF	bcd+7,W		; 10's 
	andlw	0x0f		; mask higher bcd digit
	btfsc	STATUS,Z	; did it flip to 0?
	goto	thermostat_blank10		; yes, blank 10's
thermostat_noblank10:
	swapf	bcd+7,W		; no, display 10's
	CALL	PutNyb		; display 10's. 
thermostat_blank10:
	MOVF	bcd+7,W		; 1's
	CALL	PutNyb		; display 1's

	movlw	0x20
	call	putchr
	return

;--------------

DISPLAY_TEMPERATURE:
        clrf    AccA
        clrf    AccA+1
	clrf	AccA+2
        movf    LM75_0,W        ; high byte
        movwf   AccA+3
        bcf     AccA+3,7        ; remove sign data from numerical display
        btfss   LM75_0,7        ; test sign
        goto    LM75_0_PLUS

LM75_0_MINUS:

	movfw	AccA+3	; store actual value in W
	clrf	AccA+3	; clear register
	decf	AccA+3	; decrement - it holds 1111 1111 now
	subwf	AccA+3,f	; subtract 1111 1111 - value, store in register
	movfw	AccA+3	; store in W
	andlw	b'01111111'	; leave just 7 bits
	movwf	AccA+3	; store in register. 

        movlw   0x2d            ; display minus
	movwf	R_sign	
	call 	DATS		; display it. 
        goto    LM75_0_DISPLAY
LM75_0_PLUS:
        movlw   0x20            ; plus
#ifdef	padded_display
	call	DATS
#endif	padded_display
;        movwf   R_sign          ; save for later display

LM75_0_DISPLAY:

;       Format as BCD string
;        iorwf   FPE,f           ; W may hold Error (0xff)
        call    B2_BCD          ; format as BCD

				; extract and send to display
;        movf    R_sign,w        ; Sign
;       call    DATS		 - late display, old method.

	movf	bcd+6,W		; 100's 
	andlw	0x0f		; mask higher bcd digit
	btfsc	STATUS,Z	; did it flip to 0?
	goto	blank100	; yes, blank 100's
	movf	bcd+6,W		; no, display 100's
	CALL	PutNyb		; display 10's. 
	goto	noblank10	; we _have_ to display 10's, even if it's 0!
blank100:

	SWAPF	bcd+7,W		; 10's 
	andlw	0x0f		; mask higher bcd digit
	btfsc	STATUS,Z	; did it flip to 0?
	goto	blank10		; yes, blank 10's
noblank10:
	swapf	bcd+7,W		; no, display 10's
	CALL	PutNyb		; display 10's. 
blank10:
	MOVF	bcd+7,W		; 1's
	CALL	PutNyb		; display 1's

#ifdef	lm75_classic
;---------------this is for real lm75
        movlw   C_full    ; C
        btfsc   LM75_0+1,7
        movlw   C_and_half
        goto    pmsg            ; includes RETURN
#else
;---------------below is for lm75A

	bcf	STATUS,C
	rrf	LM75_0+1,f
	rrf	LM75_0+1,f
	rrf	LM75_0+1,f
	rrf	LM75_0+1,f
	rrf	LM75_0+1,f

	movfw	LM75_0+1

        btfss   LM75_0,7        ; test sign
        goto    no_two_complement
				; do two's complement
	movfw	LM75_0+1	; store actual value in W
	clrf	LM75_0+1	; clear register
	decf	LM75_0+1	; decrement - it holds 1111 1111 now
	subwf	LM75_0+1,f	; subtract 1111 1111 - value, store in register
	movfw	LM75_0+1	; store in W
	andlw	b'00000111'	; leave just three bits
	movwf	LM75_0+1	; store in register.

no_two_complement

	movlw	d'07'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_875

	movlw	d'06'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_75

	movlw	d'05'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_625

	movlw	d'04'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_5

	movlw	d'03'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_375

	movlw	d'02'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_25

	movlw	d'01'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_125

        movlw   C_full    ; C
	goto 	pmsg

point_125
	movlw	C_point_125
	goto	pmsg
point_25
	movlw	C_point_25
	goto	pmsg
point_375
	movlw	C_point_375
	goto	pmsg
point_5
	movlw	C_point_5
	goto	pmsg
point_625
	movlw	C_point_625
	goto	pmsg
point_75
	movlw	C_point_75
	goto	pmsg
point_875
	movlw	C_point_875
	goto	pmsg
#endif 	;end code for lm75a and other high precission clones

;------------------------------------------------------------------------------

#ifdef	shift_register_display
DISPLAY_TEMPERATURE_7SEGMENT:
	clrf	R_sign		; sign is positive by default
        clrf    AccA
        clrf    AccA+1
	clrf	AccA+2
        movf    LM75_0,W        ; high byte
        movwf   AccA+3
        bcf     AccA+3,7        ; remove sign data from numerical display
        btfss   LM75_0,7        ; test sign
        goto    LM75_0_PLUS_7SEGMENT
LM75_0_MINUS_7SEGMENT:

	movfw	AccA+3	; store actual value in W
	clrf	AccA+3	; clear register
	decf	AccA+3	; decrement - it holds 1111 1111 now
	subwf	AccA+3,f	; subtract 1111 1111 - value, store in register
	movfw	AccA+3	; store in W
	andlw	b'01111111'	; leave just 7 bits
	movwf	AccA+3	; store in register. 

        movlw   0x1            ; store minus sign
	movwf	R_sign	
#ifdef	minus_on_last_dot
 ;do nothing
#else
	movlw	b'01000000'	; minus 
	call 	PUSH_7SEG		; display it...  
#endif

        goto    LM75_0_DISPLAY_7SEGMENT
LM75_0_PLUS_7SEGMENT:
        movlw   0x00            ; plus - nothing
        movwf   R_sign          ; save for later display

LM75_0_DISPLAY_7SEGMENT:

;       Format as BCD string
;        iorwf   FPE,f           ; W may hold Error (0xff)
        call    B2_BCD          ; format as BCD
				; extract and send to display
;        movf    R_sign,w        ; Sign
;       call    DATS		 - late display, old method.


	movf	bcd+6,W		; 100's 
	andlw	0x0f		; mask higher bcd digit
	btfsc	STATUS,Z	; did it flip to 0?
	goto	blank100_7SEGMENT	; yes, blank 100's
;	movf	bcd+6,W		; no, display 100's
	call	Bcd27seg	; convert number to 7 segment
	call	PUSH_7SEG	; display 100's 
;	CALL	PutNyb		; display 100's. 
	goto	noblank10_7SEGMENT	; we _have_ to display 10's, even if it's 0!

blank100_7SEGMENT:

#ifdef	minus_on_last_dot
	; minus is displayed on last dot. 100's place is available. and needs to be blanked
#else
	btfsc	R_sign,0	; check if it is negative number
	goto	skip_100_7SEGMENT ; it is. minus was displayed on 100's place, so we have to skip it.
#endif	
	movlw	0x00		; it is not. we have to display void to not break 'formatting', and shift away old result.
	call	PUSH_7SEG 	

skip_100_7SEGMENT
	SWAPF	bcd+7,W		; 10's 
	andlw	0x0f		; mask higher bcd digit
	btfsc	STATUS,Z	; did it flip to 0?
	goto	blank10_7SEGMENT		; yes, blank 10's
noblank10_7SEGMENT:
	swapf	bcd+7,W		; no, display 10's
	andlw	0x0f
	call	Bcd27seg	; convert number to 7 segment
	call	PUSH_7SEG	; display 10's
;	CALL	PutNyb		; display 10's.
	goto	skip_10_7SEGMENT ; we already displayed what should be displayed. skip blanking void display. 
blank10_7SEGMENT:

;	btfsc	R_sign,0	; check if it is negative number
;	goto	skip_100_7SEGMENT ; it is. minus was displayed on 10's place, so we have to skip it.
	movlw	0x00		; it is not. we have to display void to not break 'formatting', and shift away old result.
	call	PUSH_7SEG 	

skip_10_7SEGMENT:
	MOVF	bcd+7,W		; 1's
	andlw	0x0f		; mask higher bcd digit
	call 	Bcd27seg	; convert number to 7 segment
; only for 2 digit displays!
;	btfsc	R_sign,0		; check if number is negative, if it is, illuminate last dot which is re-wired to 'minus' 
; !!!
	iorlw	b'10000000'	; illuminate the decimal point dot - this is x. 
	call	PUSH_7SEG  	; display 1's point. 
;	CALL	PutNyb		; display 1's

;	return 			; FIXME  - higher precission display...

	; actually above routine is very 'example. blanking of digits for example
	; is not really good idea by simply not displaying them, especially if 'minus' sign 
	; is just decimal point of i.e. last digit - then one simply cares to copy minus sign to DP field 
	; of last digit displayed... 
	; if there are only 2 digits on 7 segment, one cannot display 100's either,  
	; and instead of inserting DP like above, one have to replace it in 1's by minus sign... 
	; so feel free to modify 
	; to suit your needs, ideally this would yield in niceely IFDEF'd code for 2 digits, 4 digits, 6 digits, and so on...

; fixme - even higher precission is possible - see below... 

#ifdef	lm75_classic
;---------------this is for real lm75

	movlw	0x00
	btfsc	LM75_0+1,7
	movlw	0x05	;5
	goto	LAST_DIGIT

;	call	Bcd27seg	; convert it to 7 segment
;#ifdef	minus_on_last_dot
;	btfsc	R_sign,0		; check if number is negative, zero - positive
;	iorlw	b'10000000'	; illuminate last decimal dot - which is re-wired to 'minus' sign only if value is negative...
;#endif
;	call	PUSH_7SEG
;	return 

#else
;---------------below is for lm75A

	bcf	STATUS,C
	rrf	LM75_0+1,f
	rrf	LM75_0+1,f
	rrf	LM75_0+1,f
	rrf	LM75_0+1,f
	rrf	LM75_0+1,f

	movfw	LM75_0+1

        btfss   LM75_0,7        ; test sign
        goto    no_two_complement_7segment
				; do two's complement	
	movfw	LM75_0+1	; store actual value in W
	clrf	LM75_0+1	; clear register
	decf	LM75_0+1	; decrement - it holds 1111 1111 now
	subwf	LM75_0+1,f	; subtract 1111 1111 - value, store in register
	movfw	LM75_0+1	; store in W
	andlw	b'00000111'	; leave just three bits
	movwf	LM75_0+1	; store in register. 

no_two_complement_7segment

	movlw	d'07'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_875_7segment

	movlw	d'06'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_75_7segment

	movlw	d'05'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_625_7segment

	movlw	d'04'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_5_7segment

	movlw	d'03'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_375_7segment

	movlw	d'02'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_25_7segment

	movlw	d'01'
	subwf	LM75_0+1,W
	btfsc	STATUS,Z
	goto	point_125_7segment

	movlw	0x00	;.0
	goto	LAST_DIGIT

point_125_7segment
	movlw	0x01	;.0
	goto	LAST_DIGIT
point_25_7segment
	movlw	0x03	;.0
	goto	LAST_DIGIT
point_375_7segment
	movlw	0x04	;.0
	goto	LAST_DIGIT
point_5_7segment
	movlw	0x05	;.0
	goto	LAST_DIGIT
point_625_7segment
	movlw	0x07	;.0
	goto	LAST_DIGIT
point_75_7segment
	movlw	0x08	;.0
	goto	LAST_DIGIT
point_875_7segment
	movlw	0x09	;.0
	goto	LAST_DIGIT
#endif 	;end code for lm75a and other high precission clones

LAST_DIGIT:
	call	Bcd27seg	; convert it to 7 segment
#ifdef	minus_on_last_dot
	btfsc	R_sign,0		; check if number is negative, zero - positive
	iorlw	b'10000000'	; illuminate last decimal dot - which is re-wired to 'minus' sign only if value is negative...
#endif
	goto	PUSH_7SEG

; BCD to 7 seg 
; 

Bcd27seg
	movwf	TEMP

;	movlw	d'09'
;	subwf	TEMP,W
;	btfsc	STATUS,Z
;	goto	BCD_09
;	movlw	d'08'
;	subwf	TEMP,W
;	btfsc	STATUS,Z
;	goto	BCD_08
;	movlw	d'07'
;	subwf	TEMP,W
;	btfsc	STATUS,Z
;	goto	BCD_07
;	movlw	d'06'
;	subwf	TEMP,W
;	btfsc	STATUS,Z
;	goto	BCD_06
;	movlw	d'05'
;	subwf	TEMP,W
;	btfsc	STATUS,Z
;	goto	BCD_05
;	movlw	d'04'
;	subwf	TEMP,W
;	btfsc	STATUS,Z
;	goto	BCD_04
;	movlw	d'03'
;	subwf	TEMP,W
;	btfsc	STATUS,Z
;	goto	BCD_03
;	movlw	d'02'
;	subwf	TEMP,W
;	btfsc	STATUS,Z
;	goto	BCD_02
;	movlw	d'01'
;	subwf	TEMP,W
;	btfsc	STATUS,Z
;	goto	BCD_01

;bit shorter routine...
	movlw	0x01
	subwf	TEMP,f
	btfsc	STATUS,Z
	goto 	BCD_01
	subwf	TEMP,f
	btfsc	STATUS,Z
	goto 	BCD_02
	subwf	TEMP,f
	btfsc	STATUS,Z
	goto 	BCD_03
	subwf	TEMP,f
	btfsc	STATUS,Z
	goto 	BCD_04
	subwf	TEMP,f
	btfsc	STATUS,Z
	goto 	BCD_05
	subwf	TEMP,f
	btfsc	STATUS,Z
	goto 	BCD_06
	subwf	TEMP,f
	btfsc	STATUS,Z
	goto 	BCD_07
	subwf	TEMP,f
	btfsc	STATUS,Z
	goto 	BCD_08
	subwf	TEMP,f
	btfsc	STATUS,Z
	goto 	BCD_09
	retlw	0x3f

BCD_01
	retlw	0x06
BCD_02
	retlw	0x5b
BCD_03
	retlw	0x4f
BCD_04
	retlw	0x66
BCD_05
	retlw	0x6d
BCD_06
	retlw	0x7d
BCD_07
	retlw	0x07
BCD_08
	retlw	0x7f
BCD_09
	retlw	0x6f


;	return
;	addwf	PCL,f
;	dt	0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0xff
;	IF ((HIGH ($)) != (HIGH (Bcd27seg+1)))             
;	ERROR "Bcd27seg CROSSES PAGE BOUNDARY!"         
;	ENDIF
;	nop
;	return
; for some reason this code doesn't work 

#endif	shift_register_display



GET_TEMPERATURE:
	call	i2c_reset
	nop 
	nop

;lm75 wake up
;        call    i2c_on
;        movlw   H'90'
;	movfw	LM75_adress
;       call    i2c_tx
;        movlw   b'00000001'           ; config register
;        call    i2c_tx
;        call    i2c_off
;	call    i2c_on
;        movlw   b'00000000'           ; wake up, OS 1 active. 
;        call    i2c_tx
;        call    i2c_off

; lm75 read temp
        call    i2c_on          ; activate bus
;        movlw   H'90'
	movfw	LM75_adress
        call    i2c_tx          ; adress LM75
        movlw   0
        call    i2c_tx          ; Temperature register
        call    i2c_off         ; release bus
        call    i2c_on          ; activate bus
;        movlw   H'91'           ; 1001 0001
	movfw	LM75_adress
	iorlw	0x01
        call    i2c_tx          ; adress LM75 for reading
        call    i2c_rxack
        movwf   LM75_0
        call    i2c_rx
        movwf   LM75_0+1
        call    i2c_off         ; release bus

	return

; lm75 shutdown

LM75_SHUTDOWN
;	call  	i2c_reset

        call    i2c_on
;        movlw   H'90'
	movfw	LM75_adress
        call    i2c_tx
        movlw   H'01'           ; config register
        call    i2c_tx
;        call    i2c_off
;        call    i2c_on
;        movlw   b'00000101'           ; shutdown, OS 1 active. 
         movlw   b'00000001'           ; shutdown, OS 0 active. 
        call    i2c_tx
	nop
	nop
	nop
	nop
        call    i2c_off

       return

LM75_WAKEUP
;	call  	i2c_reset

        call    i2c_on
	movfw	LM75_adress
        call    i2c_tx
        movlw   H'01'           ; config register
        call    i2c_tx

#ifdef	cooling_mode
        movlw    b'00000000'           ; wakeup , but OS 0 active (shutdown = 0) . 
#else
	movlw	 b'00000100'		;heating
#endif  cooling_mode

        call    i2c_tx
	nop
	nop
	nop
	nop
        call    i2c_off

       return

SET_THERMOSTAT:

	call 	i2c_reset
	nop
	nop
	call 	i2c_on
	movfw	LM75_adress	; choose address of lm75
	call	i2c_tx
	movlw	b'00000011'	; Tos register
	call 	i2c_tx
;	call	i2c_off
;	call	i2c_on
;	movlw	d'127'		
	movfw	set_temp
				; value 
				; to conserve power let thermostat out pin to float
				; remember thermostat is NOT active during sleep!
	call 	i2c_tx

;	call	i2c_off
;	call	i2c_on

	movlw	d'0'
	call	i2c_tx

	call 	i2c_off

	call 	i2c_on

	movfw	LM75_adress	; choose address of lm75
	call	i2c_tx
	movlw	b'00000010'	; Tos register
	call 	i2c_tx
;	call	i2c_off
;	call	i2c_on
;	movlw	d'127'		
	movfw	set_hyst
				; hysteresis
	call 	i2c_tx

;	call	i2c_off
;	call	i2c_on

	movlw	d'0'
	call	i2c_tx
	call 	i2c_off

	return





; ----------------------i2c routines --------------------------------

; I2c period is 2.5 us
; PIC cycle is 4/10Mhz = 0,4us
; so cycle hav to last 3 PIC cycles for High
; and 3 cycles for Low
; plus 1 cycle of reserve

; send byte from W to the I2c
; Most Significant Nibble first
; 78 cycles

delay_i2c:
	i2c_delay
	return



WrI2cW
        ; clock line low, data line is low
        ; byte of data in W
        movwf   I2C_buffer
        movlw   8
        movwf   I2C_count       ; 8 bits
        bank1
        bcf     SDA_tris
        call	delay_i2c
        bcf     SCL_tris
        bank0
WrI2cW1
        ; set data line
        bcf     SDA
        rlf     I2C_buffer,f
        btfsc   STATUS,C        ; 0?
        bsf     SDA             ; nein, 1
        call	delay_i2c
        bsf     SCL             ; clock high
	call	delay_i2c
        bcf     SCL
        decfsz  I2C_count,f     ; 8 bit raus?
        goto    WrI2cW1         ; nein
        return                  ; ja

;read byte from I2C to W
        ; clock is low
        ; data is low

RdI2cW
        clrf    I2C_buffer
        movlw   8
        movwf   I2C_count
;       bsf     SDA             ; failsafe
        bank1
        bsf     SDA_tris
        bank0
RdI2cW1
        call	delay_i2c
        bcf     STATUS,C
        btfsc   SDA
        bsf     STATUS,C
        rlf     I2C_buffer,f
        bsf     SCL             ; clock high
	call	delay_i2c
        bcf     SCL             ; clock low
        decfsz  I2C_count,f
        goto    RdI2cW1
        movfw   I2C_buffer
        bank1
        bcf     SDA_tris
        bank0
        return

i2c_rx
        ; recieve W over i2c
        ; clock is low
        ; data is low
        call    RdI2cW  ; 8 bit from I2C to W
        ; clock is low
        ; no ACK
        bank1
        bcf     SDA_tris
        bank0
        bsf     SDA
        call	delay_i2c
        bsf     SCL
        bank1
        bsf     SCL_tris
        bank0
i2c_rx1
        btfss   SCL
        goto    i2c_rx1
        bank1
        bcf     SCL_tris
        bank0
        bcf     SCL
	call	delay_i2c
        bcf     SDA
        return

i2c_off
        ; SCL is low and SDA is low
        bank1
        bcf     SDA_tris
        call	delay_i2c
        bcf     SCL_tris
        bank0
        bsf     SCL
        call	delay_i2c
        bsf     SDA
        return

i2c_tx
        ; send W over i2c
        call    WrI2cW          ; 8 bits out to W via I2c
        ; we have to send ACK now
        ; clock is now low
        bsf     SDA             ; free up data line
	call	delay_i2c
        bsf     SCL             ; ACK cycle high
        bank1
        bsf     SCL_tris
        bank0
i2c_tx2
        btfss   SCL
        goto    i2c_tx2
        bank1
        bcf     SCL_tris
        bank0
        bcf     SCL
        call	delay_i2c
        bcf     SDA
        return


i2c_txack
        ; send W over i2c
        call    WrI2cW          ; 8 bits out to W via I2c
        ; we have to send ACK now
        ; clock is now low
        bcf     SDA             ; free up data line
	call	delay_i2c
        bcf     SCL             ; ACK cycle high
	call	delay_i2c
	bcf	SDA
	call	delay_i2c
	bsf	SCL

        bank1
        bsf     SCL_tris
        bank0
i2c_txack2
        btfss   SCL
        goto    i2c_txack2
        bank1
        bcf     SCL_tris
        bank0
        bcf     SCL
        call	delay_i2c
        bcf     SDA
        return



i2c_rxack
        ; clock line is low
        ; data line is low
        call    RdI2cW          ; 8 bytes from I2C to W
        ; clock is low
        ; only ACK is to be sent
        bank1
        bcf     SDA_tris
        call	delay_i2c
        bcf     SCL_tris
        bank0
        bcf     SDA
	call	delay_i2c
        bsf     SCL
	call	delay_i2c

        bank1
        bsf     SCL_tris
        bank0
i2c_rxack1
        btfss   SCL
        goto    i2c_rxack1
        bank1
        bcf     SCL_tris
        bank0
        bcf     SCL
	call	delay_i2c
        bcf     SDA
        return

i2c_reset
        bank1
        bsf     SDA_tris ; SDA high and input (pullup)
	nop
        bcf     SCL_tris ; SCL as out
        bank0
        bsf     SCL     ; SCL high
        movlw   9
        movwf   I2C_buffer
i2c_reset1
        call	delay_i2c
        bcf     SCL     ;SCL 0
	call	delay_i2c
        bsf     SCL     ;SCL 1
        decfsz  I2C_buffer,f
        goto    i2c_reset1
        call	delay_i2c
        call    i2c_on
        call	delay_i2c
        bsf     SCL
        call	delay_i2c
        bcf     SCL
        call	delay_i2c
        call    i2c_off
        bank1
        bcf     SDA_tris
        nop
        bcf     SCL_tris
        bank0
        return

; bus take over!

i2c_on
        ; when SDA and SCL are high, then bring SDA low

        bank1
        bsf     SDA_tris        ; SDA high and input
        nop
        bsf     SCL_tris        ; SDL high and input
        bank0
        ; check if bus is free
        btfss   SCL
        goto    i2c_on          ; clock line free?
        btfss   SDA
        goto    i2c_on          ; date line free?

        bank1
        bcf     SDA_tris        ; SDA as output
        call	delay_i2c
        bcf     SCL_tris        ; SCL as output
        bank0
        bcf     SDA
        call	delay_i2c
        bcf     SCL
        return

; *******************************************************************

EE_R	bank1
	movwf	EEADR
	BSF	EECON1,RD	; EE Read
	MOVF	EEDATA,W	; W = EEDATA
	bank0
	RETURN
EE_W
	bank1
	MOVWF	EEDATA
	BSF	EECON1,WREN	; Enable Write
	MOVLW	0x55		;
	MOVWF	EECON2		; Write 0x55
	MOVLW	0xAA		;
	MOVWF	EECON2		; Write 0xAA
	BSF	EECON1,WR	; Set WR bit (begin write)

EE_W2	BTFSC	EECON1,WR	; Wait for write to finish
	GOTO	EE_W2
	bank0
	RETURN	


 
;********************************************************************
;	Tail End Charlie
;********************************************************************	
; initialize eeprom locations

DEEPROM        ORG 	0x2100
 
T_set 	de 	d'28',d'2',d'3',d'4',d'5',d'6',d'7',d'8',0xff
T_hyst 	de 	d'28',d'2',d'3',d'4',d'5',d'6',d'7',d'8',0xff


;calibration area - type your result 
	org	0x3ff
	retlw	d'75'	; here

 	END


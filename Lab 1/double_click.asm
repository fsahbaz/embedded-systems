;
; sahbaz_akman_lab1_double_click.asm
;
; Created: 17-Oct-18 2:38:06
; Author : FSAHBAZ16
;

.def butR = r16
.def ledR = r17
.def temp = r18 
.def temp2 = r19
.def dir = r23
.def cnt = r24

.org $0000
jmp RESET

.org $0006
jmp cState

rjmp RESET
RESET:
	ldi	r21, low(RAMEND)		
	out	spl, r21 				
	ldi	r21, high(RAMEND)		
	out	sph, r21 				
	ldi	r21, $FF		
	out	DDRC, r21
	ldi r21, $00
	out DDRB, r21
	ldi butR, $00
	ldi r21, 1<<INT2
	out GICR, r21
	ldi r21, 1<<ISC2
	out MCUSR, r21
	sei

C:
	cpi butR,$00
	brne sC
	ldi ledR, $00
	rjmp printLEDs
sC:
	cpi ledR, $00
	brne LED2
	ldi ledR, $01
	ldi dir, $FF
	rjmp printLEDs
LED2:
	cpi butR, $01
	brne LED5
revLED2:
	rcall delay05
	cpi dir, $00
	breq goRight
goLeft: 
	lsl ledR
	rcall ride
	rjmp printLEDs
goRight:
	lsr ledR
	rcall ride
	rjmp printLEDs
LED5:
	cpi butR, $02
	brne LED10
revLED5:
	rcall delay02
	cpi dir, $00
	breq goRight
	brne goLeft
LED10:
	rcall delay01
	cpi dir, $00
	breq goRight
	brne goLeft

printLEDs:
	out PORTC, ledR
	rjmp C
delay:
	ldi temp, $80
d1: dec temp
	brne d1
	ret

delay01: ser temp2
d01:	rcall delay
		dec temp2
		brne d01
		ret

delay02:
	rcall delay01
	rcall delay01
	ret

delay05:
	rcall delay01
	rcall delay01
	rcall delay01
	rcall delay01
	rcall delay01
	ret	
ride:
	cpi ledR, $80
	breq compl
	cpi ledR, $01
	breq compl
	ret
compl:
	com dir
	ret
cState:
	inc cnt
	cpi cnt,$02
	breq incB
	reti
incB:
	clr cnt
	cpi butR, $03
	breq resDeb
	inc butR
	rcall delay01
	reti
resDeb:
	ldi butR, $00
	rcall delay01
	reti

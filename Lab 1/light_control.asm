;
; sahbaz_akman_lab1_light_control.asm
;
; Created: 14-Oct-18 21:34:19
; Author : FSAHBAZ16
;



	.equ pattern = 0x00
	.def butR = r16
	.def ledR = r17
	.def temp = r18 
	.def temp2 = r19
	rjmp RESET
RESET:
	ldi temp, low(RAMEND)  
	out spl, temp     
	ldi temp, high(RAMEND)  
	out sph, temp     
	ldi temp, $FF  ; All ones makes
	out DDRB, temp  ; port B all outputs
	ldi butR, pattern
	ldi ledR, $01
	ldi r20, $00
LOOP:
	in butR, PIND
	cpi butR, $00
	breq L1
	mov r20, butR
L1:
	cpi r20,$01
	breq noLED
	cpi r20,$02
	breq LED2
	cpi r20, $04
	breq LED5
	cpi r20, $08
	breq LED10
	rjmp LOOP
noLED:
	ldi ledR, $00
	out PORTB, ledR
	rjmp LOOP
LED2:
	out PORTB, ledR
	lsl ledR
	rcall delay05
	cpi ledR, $80
	brne LED2
	cpi ledR, $80
	breq revLED2
	rjmp LOOP
revLED2:
	out PORTB, ledR
	lsr ledR
	rcall delay05
	out PORTB, ledR
	cpi ledR, $01
	brne revLED2
	rjmp LOOP
LED5:
	out PORTB, ledR
	lsl ledR
	rcall delay02
	cpi ledR, $80
	brne LED5
	cpi ledR, $80
	breq revLED5
	rjmp LOOP
revLED5:
	out PORTB, ledR
	lsr ledR
	rcall delay02
	out PORTB, ledR
	cpi ledR, $01
	brne revLED5
	rjmp LOOP
LED10:
	out PORTB, ledR
	lsl ledR
	rcall delay01
	cpi ledR, $80
	brne LED10
	cpi ledR, $80
	breq revLED10
	rjmp LOOP
revLED10:
	out PORTB, ledR
	lsr ledR
	rcall delay01
	out PORTB, ledR
	cpi ledR, $01
	brne revLED10
	rjmp LOOP

delay:
	ldi temp, $80
d1: dec temp
	brne d1
	ret

delay01:	ser temp2
d01:		rcall delay
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

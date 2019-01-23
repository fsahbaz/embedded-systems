;
; sahbaz-akman-lab4_task4.asm
;
; Created: 05-Dec-18 15:11:47
; Author : FSAHBAZ16
;


; Replace with your application code
;
; sahbaz-akman-lab4_task3.asm
;
; Created: 05-Dec-18 13:19:12
; Author : FSAHBAZ16
;
/*
 * Lab4_ADC.asm
 *
 *  
 */ 

; Basically, the user provides the input voltage from PB#, through the potentiometer.
; In order to assign the potentiometer voltage to PB3, the jumper is placed on the corresponding pin.
; As the input voltage is provided through PB3, the resulting voltage is converted to digital sequences,
; based on the ANA_COMP analog comparator subroutine logic.

; As the voltage the potentiometer changes, it can be observed from PORTD's LEDs, which display
; the result in binary, and PB3 LED.

; This part required us to generate a table, that can be found below. The similar logic now finds the
; corresponding results from the table below. Also, the logic behind displaying the stars is still the same, though 
; it now uses the table-drive value dispVal.

;***** Constants
.equ	preset=128		;in order to convert more accurately	
; define constants
.equ	BAUD_RATE	=9600
.equ	CPU_CLOCK	=4000000
.equ	BAUD_DIV	=(CPU_CLOCK/(16*BAUD_RATE))-1
;***** A/D converter Global Registers
.def	result=r16			;Result and intermediate data
.def	temp=r17			;Scratch register
.def	temp2=r20
.def	temp3=r21
.def	temp4=r22
.def	dispVal=r23
.def	cnt=r24
.def	SENTCHAR=r18

;***********************************************************
;*  	PROGRAM START - EXECUTION STARTS HERE
;***********************************************************
.cseg
.org $0000
jmp RESET      ;Reset handle
.org OVF0addr
jmp ANA_COMP   ;Timer0 overflow handle
.org ACIaddr
jmp ANA_COMP   ;Analog comparator handle

RESET:
	ldi 	temp, low(RAMEND)	; initialize stack pointer
	out		SPL, temp
	ldi 	temp, high(RAMEND)
	out 	SPH, temp
	rcall	convert_init		;Initialize A/D converter

	ldi		result, $ff		;set port D as output
	out		DDRD, result		;for LED’s

	ldi		TEMP, low(BAUD_DIV)		; set UART baud rate
	out		UBRRL, TEMP
	ldi		TEMP, high(BAUD_DIV)		; set UART baud rate
	out		UBRRH, TEMP
	sbi		UCSRB, TXEN			; enable serial transmitter
    sei					; enable interrupts
Delay:	
	clr	temp2			;Clear temp counter 1
	ldi	temp3,$f0		;Reset temp counter 2
loop1:	
	inc	temp2			;Count up temp counter 1
	brne	loop1			;Check if inner loop is finished
	inc 	temp3			;Count up temp counter 2
	brne 	loop1			;Check if delay is finished
	
	rcall	AD_convert		;Start conversion
Wait:
	brtc	Wait	
	cpi result, 0
	brsh ttable
	cpi result, 128
	brlo ttable
	rjmp Wait
ttable:
	ldi ZL, low(table*2)
	ldi ZH, high(table*2)
	mov r20, result
	clr temp4
	add ZL, r20
	adc ZH, temp4
	lpm dispVal, Z
	rcall transmit
	out	PORTD, dispVal		;Write result on port C
	rjmp	Delay			;Repeat conversion

convert_init:
	ldi     result,(1<<ACIE)|(1<<ACIS1)|(1<<ACIS0)  ;Initiate comparator
	out     ACSR,result 				; enable comparator interrupt
	ldi     result,(1<<TOIE0)      			;Enable timer interrupt
	out     TIMSK,result
	sbi     DDRB,PB1       			;Set converter charge/discharge pin
	cbi     DDRB,PB3			;AIN1	;Voltage input to the comparator
	ret					;Return from subroutine

AD_convert:
	ldi	result,preset		  	;Load offset value (192)
	out	TCNT0,result    		;to the counter
	clt					;Clear conversion complete flag (t)
	cbi	DDRB, PB2			;AIN0	;Disconnect discharging, input to comp.
	ldi	result,(1<<CS01)		;Start timer0 with prescaling f/8
	out	TCCR0,result

	sbi	PORTB,PB1				;Start charging of capacitor
	ret						;Return from subroutine

;Interrupt handler for A/D Comparator and overflow
ANA_COMP:       	
	in	result,TCNT0    	; Get timer value
	clr	temp    			; Stop timer0
	out	TCCR0,temp         
	subi	result,preset+1 	; Rescale A/D output 
								;(+1 for int. delay)

	cbi	PORTB,PB1       	;Start discharge
	sbi	DDRB, PB2		;AIN0	;Make discharging pin an output
					;it automatically becomes low
	set				;Set conversion complete flag (T flag)
	reti             		;Return from interrupt

transmit:
	mov cnt, dispVal
dectransmit:
	dec cnt
	cpi cnt, $00
	breq star
	ldi SENTCHAR, $20
	rcall putchar
	rjmp dectransmit
star:
	ldi SENTCHAR, $2A
	rcall putchar
	ldi SENTCHAR, $D
	rcall putchar
	ldi SENTCHAR, $0A
	rcall putchar
	ret

; subroutines
putchar:
    sbis    UCSRA, UDRE		; loop until USR:UDRE is 1
    rjmp    putchar
    out     UDR, SENTCHAR		; write SENTCHAR to transmitter buffer
    ret
table:
.db 1,3
.db 5,6
.db 8,10
.db 11,13
.db 14,16
.db 18,19
.db 21,22
.db 24,25
.db 27,28
.db 29,31
.db 32,34
.db 35,37
.db 38,39
.db 41,42
.db 43,45
.db 46,47
.db 48,50
.db 51,52
.db 53,55
.db 56,57
.db 58,59
.db 60,62
.db 63,64
.db 65,66
.db 67,68
.db 69,70
.db 71,72
.db 73,74 
.db 75,76
.db 77,78
.db 79,80
.db 81,82
.db 83,84
.db 85,86
.db 87,88
.db 89,90
.db 90,91
.db 92,93
.db 94,95
.db 95,96
.db 97,98
.db 99,99
.db 100,101
.db 102,103
.db 103,104
.db 105,105
.db 106,107
.db 108,108
.db 109,110
.db 110,111
.db 112,112
.db 113,114
.db 114,115
.db 116,116
.db 117,117
.db 118,119
.db 119,120
.db 120,121 
.db 122,122
.db 123,123
.db 124,124
.db 125,125
.db 126,126
.db 127,128
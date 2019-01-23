;
; sahbaz-akman-lab4_task2.asm
;
; Created: 03-Dec-18 0:56:40
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

; Right after displaying the result on PORTD, the transmit method is called, which basically assigns the current
; result to a counter variable that is later transferred to a subroutine that decrements it until it equals 0,
; then to the star subroutine that prints * and the remaining new line characters. These subroutines utilize
; the putchar subroutine.

;***** Constants
.equ	preset=192		;T/C0 Preset constant (256-64)	
; define constants
.equ	BAUD_RATE	=9600
.equ	CPU_CLOCK	=4000000
.equ	BAUD_DIV	=(CPU_CLOCK/(16*BAUD_RATE))-1

;***** A/D converter Global Registers
.def	result=r16			;Result and intermediate data
.def	temp=r17			;Scratch register
.def	temp2=r20
.def	temp3=r21
.def	cnt = r24
; define register aliases
.def	SENTCHAR	=r18		; sent character
; code segment
.cseg
.org $0000
jmp RESET      ;Reset handle
.org OVF0addr
jmp ANA_COMP   ;Timer0 overflow handle
.org ACIaddr
jmp ANA_COMP   ;Analog comparator handle
;***********************************************************
;*  	PROGRAM START - EXECUTION STARTS HERE
;***********************************************************


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
	brtc	Wait			;Wait until conversion is complete (T flag set)
	out		PORTD,result		;Write result on port C
	rcall	transmit
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
	
	set
	reti

transmit:
	mov cnt, result
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



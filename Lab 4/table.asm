;
; sahbaz-akman-lab4_task6.asm
;
; Created: 04-Dec-18 16:14:21
; Author : FSAHBAZ16
;

; Basically, the user provides the input voltage from PA6, through the potentiometer.
; In order to assign the potentiometer voltage to PA6, the jumper is placed on the corresponding pin.
; As the input voltage is provided through PA6, the resulting voltage is converted to digital sequences,
; based on the ANA_COMP analog comparator subroutine logic. This version initizalizes and uses the built-in
; ADC converter of the board, by assigning the required values to ADMUX and ADCSRA. (Explanation can be found
; in the report.)

; As the voltage the potentiometer changes, it can be observed from PORTD's LEDs, which display
; the result in binary, and PA6 LED.

; Right after displaying the dispVal on PORTD, the transmit method is called, which basically assigns the current
; dispVal to a counter variable that is later transferred to a subroutine that decrements it until it equals 0,
; then to the star subroutine that prints * and the remaining new line characters. These subroutines utilize
; the putchar subroutine.

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
.org ACIaddr
jmp ANA_COMP   ;Analog comparator handle
;***********************************************************
;*  	PROGRAM START - EXECUTION STARTS HERE
;***********************************************************
RESET:
	ldi		temp, low(RAMEND)  ; initialize stack pointer
	out		SPL, temp
	ldi		temp, high(RAMEND)
	out		SPH, temp
	rcall	convert_init    ;Initialize A/D converter

	cbi		DDRA,6
	ldi		result,$ff
	out		DDRD,result

	ldi		TEMP, low(BAUD_DIV)		; set UART baud rate
	out		UBRRL, TEMP
	ldi		TEMP, high(BAUD_DIV)		; set UART baud rate
	out		UBRRH, TEMP
	sbi		UCSRB, TXEN			; enable serial transmitter
	sbi		ADCSRA, 6
	sei     ;Enable global interrupt

Wait:  
	out  PORTD,result    ;Write result on port C
	rcall transmit
	rjmp  Wait      ;Repeat conversion

convert_init:
	ldi     result,(1<<ADLAR)|(1<<REFS0)|(1<<MUX2)|(1<<MUX1)      
	out     ADMUX,result       
	ldi     result,(1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)    
	out     ADCSRA,result
	ret       

;Interrupt handler for A/D Comparator and overflow
ANA_COMP:         
	cbi ADCSRA, 6
	in	result, ADCH   
	lsr result
	lsr result  
    sbi ADCSRA, 6
	reti                 ;Return from interrupt

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
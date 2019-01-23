;
; sahbaz-akman-lab2_task1.asm
;
; Created: 05-Nov-18 11:48:08
; Author : FSAHBAZ16
;


; Replace with your application code
; Setting the interrupt vectors.
.org $0000
jmp RESET
.org $0014 ; Every compare match event
jmp COUNT

.def temp = r16
.def Delay0 = r17
.def Delay1 = r18
.def butRead = r19
.def d0=r20
.def d1=r21
.def d2=r22
  
RESET:
	;; Initialize stack pointer
	ldi temp, LOW(RAMEND)    ;load the end of SRAM's low byte to "tmp"
	out SPL, temp      ;Initialize stack pointers low byte
	ldi temp, HIGH(RAMEND)    ;load the end of SRAM's high byte to "tmp"
	out SPH, temp      ;Initialize stack pointers high byte
	; Initializing part of PORTA as an output
	ldi temp, $07
	out DDRA, temp
	; Initializing part of PORTC as an output
	ldi temp, $FF
	out DDRC, temp
	ldi temp, $00
	out DDRD, temp ;port D input
	ldi d0, $00   
	ldi d1, $00 
	ldi d2, $00 
initBut:
	in butRead, PIND ;check input for  ing
	cpi butRead, $01
	brne initBut
	ldi temp, (1<<CS02)|(1<<CS00) 
	out TCCR0, temp
	ldi temp, 1<<TOV0 
	out TIFR, temp
	ldi temp, (1<<OCIE0)
	out TIMSK, temp
	ldi temp, 98
	out OCR0, temp
	sei 
Loop:
	;; Display No#0
	ldi temp, (1<<0)     ; Make bit#0 one, others zero
	out PORTA, temp
	mov temp, d0 ; Display 0 on seven segment display
	rcall disp
	out PORTC, temp
	rcall Delay
	;; Display No#1
	ldi temp, (1<<1)     ; Make bit#1 one, others zero
	out PORTA, temp
	mov temp, d1 ; Display 1 on seven segment display
	rcall disp
	out PORTC, temp
	rcall Delay
	;; Display No#2
	ldi temp, (1<<2)     ; Make bit#2 one, others zero
	out PORTA, temp
	mov temp, d2
	rcall disp
	out PORTC, temp
	rcall Delay
	in butRead,PIND
	cpi butRead, $02
	breq halt
	in butRead,PIND
	cpi butRead, $01
	breq initBut
	rjmp Loop
;; Delay subroutine
Delay:  
	ldi Delay0, $00
	ldi Delay1, $05
Wait:  
	subi Delay0, 1
	sbci Delay1, 0
	brcc Wait
	ret
COUNT:
	push temp
	in temp, SREG
	push temp ;Save processor status
	ldi temp, $00
	out TCNT0, temp ;Initialize T0 with r20
	inc d0 ;0.1s counting
	cpi d0, $0A
	brne not_yet
	ldi d0, 0
	inc d1 ;1s counting
	cpi d1, $0A
	brne not_yet
	ldi d1, 0
	inc d2 ;10s counting
	cpi d2, $0A
	brne not_yet
	ldi d2, 0
not_yet:
	pop temp
	out SREG, temp ;Recover processor status
	pop temp
	reti
halt:
	cli ; stop global interrupts
	ldi temp, (1<<0)    
	out PORTA, temp
	mov temp, d0
	rcall disp
	out PORTC, temp
	rcall Delay
	ldi temp, (1<<1)     ; Make bit#1 one, others zero
	out PORTA, temp
	mov temp, d1
	rcall disp
	out PORTC, temp
	rcall Delay
	ldi temp, (1<<2)     ; Make bit#2 one, others zero
	out PORTA, temp
	mov temp, d2
	rcall disp
	out PORTC, temp
	rcall Delay
	rjmp  Loop
disp:
	cpi temp,0
	breq load0
	cpi temp,1
	breq load1
	cpi temp,2
	breq load2
	cpi temp,3
	breq load3
	cpi temp,4
	breq load4
	cpi temp,5
	breq load5
	cpi temp,6
	breq load6
	cpi temp,7
	breq load7
	cpi temp,8
	breq load8
	cpi temp,9
	breq load9
	ret
load0:
	ldi temp,0b00111111
	ret
load1:
	ldi temp,0b10000110
	ret
load2:
	ldi temp,0b01011011
	ret
load3:
	ldi temp,0b01001111
	ret
load4:
	ldi temp, 0b01100110
	ret
load5:
	ldi temp, 0b01101101
	ret
load6:
	ldi temp, 0b01111101
	ret
load7:
	ldi temp, 0b00000111
	ret
load8:
	ldi temp, 0b01111111
	ret
load9:
	ldi temp, 0b01101111
	ret
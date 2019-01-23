; define constants
.equ	BAUD_RATE	=9600
;.equ	CPU_CLOCK	=3686400
.equ	CPU_CLOCK	=4000000
.equ	BAUD_DIV	=(CPU_CLOCK/(16*BAUD_RATE))-1

.equ    TMR0_PRESCL	=0x05	; this is the prescaler setting for CK/1024

.equ	FIFOSIZE	=50		; establish a buffer of size 50

; define register aliases
.def	SENTCHAR	=r0		; sent character
.def	RECCHAR		=r21		; received character
.def	TEMP		=r16	; temporary register
.def	TEMP1		=r17	; another temporary register
.def    FIFOHEAD		=r22	; index of beginning of FIFO
.def    FIFOTAIL		=r23	; index of end of FIFO

;**************************************************************************
;  REGISTERS
;**************************************************************************
.def   XL_Tmp = r1                    	; low  part temporary register
.def   XH_Tmp = r2                    	; high part temporary register

.def   XL_LUT = r3              	; number of LUT-Element (low byte)
.def   XH_LUT = r4              	; number of LUT-Element (high byte)                        

.def   x_SW = r18                    	; step width

.def   tmp  = r19                   	; temp register

.def KEYREAD = r24
.def CNT = r25

;**************************************************************************
;**************************************************************************
.equ     Xtal      = 4000000            ; system clock frequency
.equ     prescaler = 1                  ; timer1 prescaler
.equ     N_samples = 128                ; Number of samples in lookup table
.equ     Fck = Xtal/prescaler           ; timer1 working frequency
.equ	 SW_500	= 13			; LUT step width

; data segment
        .dseg
fifo:	.byte	FIFOSIZE ; this is the FIFO area of size FIFOSIZE

; code segment
.cseg
.org    $000
	jmp	reset		; $000 HW reset or watchdog
.org    $012
    jmp    tim1_ovf                    ; Timer1 overflow Handle
.org	$01A
	jmp	REC_INT		; $01A UART Rx complete
;**************************************************************************
; Interrupt timer1
;**************************************************************************
tim1_ovf:
   push   tmp    			; Store temporary register
   in     tmp,SREG
   push   tmp                           ; Store status register
   push   ZL
   push   ZH                            ; Store Z-Pointer
   push   r0                            ; Store R0 Register

   mov    XL_Tmp,XL_LUT			; The current OCR value is stored
   mov    XH_Tmp,XH_LUT			; at this position in the LUT
   add    XL_LUT,x_SW
   clr    tmp                           ; (tmp is cleared, but not the carry flag)
   adc    XH_LUT,tmp                	; Refresh pointer for the next sample


   ldi    tmp,0x7f
   and    XL_Tmp,tmp                  	; module 128 (samples number sine table)

   ldi    ZL,low(sine_tbl*2)		; Program memory is organized as words
   ldi    ZH,high(sine_tbl*2)		; so, a "label" is a word count 
   add    ZL,XL_Tmp
   clr    tmp
   adc    ZH,tmp                        ; Z is a pointer to the correct
                                        ; sine_tbl value

   lpm					; read the OCR value
   out     OCR1BL,r0                   	; send the current value to PWM

   pop     r0                           ; Restore R0 Register
   pop     ZH
   pop     ZL                           ; Restore Z-Pointer
   pop     tmp
   out     SREG,tmp                     ; Restore SREG
   pop     tmp                          ; Restore temporary register;
   reti

; begin main code
reset:
	sbi		DDRD,PD4                      ; Set pin PD5 as output
	ldi 	TEMP, low(RAMEND)		; initialize stack pointer
	out		SPL, TEMP
	ldi 	TEMP, high(RAMEND)
	out 	SPH, TEMP

   	rcall   clrFIFO				; initialize FIFO

	ldi		TEMP, $FF			; port B all outputs
	out		DDRB, TEMP
    out     PORTB, TEMP			; initially all LEDs off
    ldi     TEMP, TMR0_PRESCL		; initialize timer0
    out     TCCR0, TEMP			; prescale 1024
	ldi		TEMP, low(BAUD_DIV)		; set UART baud rate
	out		UBRRL, TEMP
	ldi		TEMP, high(BAUD_DIV)		; set UART baud rate
	out		UBRRH, TEMP
        
	sbi     UCSRB, TXEN			; enable serial transmitter
	sbi     UCSRB, RXEN			; enable serial receiver
    sbi     UCSRB, RXCIE		; enable receiver interrupts

	;Initialization of the registers
    clr   XL_LUT
    clr   XH_LUT			; Set table pointer to 0x0000
    ldi   X_SW, SW_500			; set the step width

;enable timer1 interrupt
    ldi   tmp,(1<<TOIE1)
    out   TIMSK,tmp                     ; Enable Timer1_ovf interrupt

;set timer1 PWM mode
     ldi   tmp,(1<<WGM10)+(1<<COM1B1)
     out   TCCR1A,tmp                   ; 8 bit PWM non-inverting (Fck/510)
     ldi   tmp,(1<<CS10)
     out   TCCR1B,tmp                   ; prescaler = 1

    sei							; enable interrupts
mloop:
	rcall	FIFOget			; get the next character from the FIFO
	brcc	RRR_no_inp			;
	mov		SENTCHAR, RECCHAR
	rcall   putchar			; transmit character 
	mov		KEYREAD, RECCHAR
	cpi		KEYREAD, $41
	breq	MORSE_A
	jmp		PASS1
MORSE_A:
	ldi CNT, $00
	rcall dot
	rcall dash
	rjmp mloop
PASS1:
	cpi	KEYREAD, $42
	breq MORSE_B
	jmp PASS2
MORSE_B:
	ldi CNT, $00
	rcall dash
	rcall dot
	rcall dot
	rcall dot
	rjmp mloop
PASS2:
	cpi	KEYREAD, $43
	breq MORSE_C
	jmp PASS3
MORSE_C:
	ldi CNT, $00
	rcall dash
	rcall dot
	ldi CNT, $00
	rcall dash
	rcall dot
	rjmp mloop
PASS3:
	cpi	KEYREAD, $44
	breq MORSE_D
	jmp PASS4
MORSE_D:
	ldi CNT, $00
	rcall dash
	rcall dot
	rcall dot
	rjmp mloop
PASS4:
	cpi	KEYREAD, $45
	breq MORSE_E
	jmp PASS5
RRR_no_inp:
	rjmp RR_no_inp
MORSE_E:	
   rcall dot
   rjmp mloop
PASS5:
    cpi KEYREAD, $46
    breq MORSE_F
    jmp PASS6
MORSE_F:	
   ldi CNT, $00
    rcall dot
    rcall dot
    rcall dash
    rcall dot
    rjmp mloop
PASS6:
    cpi KEYREAD, $47
    breq MORSE_G
    jmp PASS7
MORSE_G:
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
    rcall dot
    rjmp mloop
PASS7:
    cpi KEYREAD, $48
    breq MORSE_H
    jmp PASS8
MORSE_H:
	ldi CNT, $00
    rcall dot
    rcall dot
    rcall dot
	rcall dot
    rjmp mloop
PASS8:
    cpi KEYREAD, $49
    breq MORSE_I
    jmp PASS9
MORSE_I:
	ldi CNT, $00
    rcall dot
    rcall dot
    rjmp mloop
PASS9:
    cpi KEYREAD, $4A
    breq MORSE_I
    jmp PASS10
MORSE_J:
    rcall dot
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
	rcall dash
	ldi CNT, $00
	rcall dash
    rjmp mloop
PASS10:
    cpi KEYREAD, $4B
    breq MORSE_K
    jmp PASS11
RR_no_inp:
	rjmp R_no_inp
MORSE_K:
	ldi CNT, $00
    rcall dash
	rcall dot
	ldi CNT, $00
	rcall dash
    rjmp mloop
PASS11:
    cpi KEYREAD, $4C
    breq MORSE_L
    jmp PASS12
MORSE_L:
	ldi CNT, $00
    rcall dot
	rcall dash
	rcall dot
	rcall dot
    rjmp mloop
PASS12:
    cpi KEYREAD, $4D
    breq MORSE_L
    jmp PASS13
MORSE_M:
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
	rcall dash
    rjmp mloop
PASS13:
    cpi KEYREAD, $4E
    breq MORSE_N
    jmp PASS14
MORSE_N:
	ldi CNT, $00
    rcall dash
	rcall dot
    rjmp mloop
PASS14:
    cpi KEYREAD, $4F
    breq MORSE_O
    jmp PASS15
MORSE_O:
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS15:
    cpi KEYREAD, $50
    breq MORSE_P
    jmp PASS16
MORSE_P:
    rcall dot
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
    rjmp mloop
PASS16:
    cpi KEYREAD, $51
    breq MORSE_Q
    jmp PASS17
MORSE_Q:
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS17:
    cpi KEYREAD, $52
    breq MORSE_R
    jmp PASS18
MORSE_R:
	rcall dot
	ldi CNT, $00
    rcall dash
	rcall dot
    rjmp mloop
PASS18:
    cpi KEYREAD, $53
    breq MORSE_S
    jmp PASS19
MORSE_S:
	rcall dot
	rcall dot
	rcall dot
    rjmp mloop
PASS19:
    cpi KEYREAD, $54
    breq MORSE_T
    jmp PASS20
MORSE_T:
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS20:
    cpi KEYREAD, $55
    breq MORSE_U
    jmp PASS21
MORSE_U:
	rcall dot
	rcall dot
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS21:
    cpi KEYREAD, $56
    breq MORSE_V
    jmp PASS22
MORSE_V:
	rcall dot
	rcall dot
	rcall dot
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS22:
    cpi KEYREAD, $57
    breq MORSE_W
    jmp PASS23
MORSE_W:
	rcall dot
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS23:
    cpi KEYREAD, $58
    breq MORSE_X
    jmp PASS24
MORSE_X:
	ldi CNT, $00
    rcall dash
	rcall dot
	rcall dot
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS24:
    cpi KEYREAD, $59
    breq MORSE_Y
    jmp PASS25
MORSE_Y:
	ldi CNT, $00
    rcall dash
	rcall dot
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS25:
    cpi KEYREAD, $5A
    breq MORSE_Z
    jmp PASS26
MORSE_Z:
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
	rcall dot
    rjmp mloop
PASS26:
    cpi KEYREAD, $30
    breq MORSE_0
    jmp PASS27
MORSE_0:
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
    rjmp mloop
R_no_inp:
	rjmp no_inp
PASS27:
    cpi KEYREAD, $31
    breq MORSE_1
    jmp PASS28
MORSE_1:
    rcall dot
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS28:
    cpi KEYREAD, $32
    breq MORSE_2
    jmp PASS29
MORSE_2:
    rcall dot
	rcall dot
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS29:
    cpi KEYREAD, $33
    breq MORSE_3
    jmp PASS30
MORSE_3:
    rcall dot
	rcall dot
	rcall dot
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS30:
    cpi KEYREAD, $34
    breq MORSE_4
    jmp PASS31
MORSE_4:
    rcall dot
	rcall dot
	rcall dot
	rcall dot
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS31:
    cpi KEYREAD, $35
    breq MORSE_5
    jmp PASS32
MORSE_5:
    rcall dot
	rcall dot
	rcall dot
	rcall dot
	rcall dot
    rjmp mloop
PASS32:
    cpi KEYREAD, $36
    breq MORSE_6
    jmp PASS33
MORSE_6:
    ldi CNT, $00
    rcall dash
	rcall dot
	rcall dot
	rcall dot
	rcall dot
    rjmp mloop
PASS33:
    cpi KEYREAD, $37
    breq MORSE_7
    jmp PASS34
MORSE_7:
    ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
	rcall dot
	rcall dot
    rjmp mloop
PASS34:
    cpi KEYREAD, $38
    breq MORSE_8
    jmp PASS35
MORSE_8:
    ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
	rcall dot
    rjmp mloop
PASS35:
    cpi KEYREAD, $39
    breq MORSE_9
    jmp PASS36
MORSE_9:
    ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
    rjmp mloop
PASS36:
    cpi KEYREAD, $3A
    breq MORSE_COLON
    jmp PASS37
MORSE_COLON:
    ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
	rcall dot
	rcall dot
    rjmp mloop
PASS37:
    cpi KEYREAD, $3B
    breq MORSE_SEMICOLON
    jmp PASS38
MORSE_SEMICOLON:
    ldi CNT, $00
    rcall dash
	rcall dot
	ldi CNT, $00
    rcall dash
	rcall dot
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS38:
    cpi KEYREAD, $3F
    breq MORSE_QMARK
    jmp PASS39
MORSE_QMARK:
	rcall dot
	rcall dot
    ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
	rcall dot
    rjmp mloop
PASS39:
    cpi KEYREAD, $2C
    breq MORSE_COMMA
    jmp PASS40
MORSE_COMMA:
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
	rcall dot
    ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS40:
    cpi KEYREAD, $2E
    breq MORSE_PERIOD
    jmp PASS41
MORSE_PERIOD:
	rcall dot
	ldi CNT, $00
    rcall dash
	rcall dot
    ldi CNT, $00
    rcall dash
	rcall dot
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS41:
    cpi KEYREAD, $2F
    breq MORSE_SLASH
    jmp PASS42
MORSE_SLASH:
	ldi CNT, $00
    rcall dash
	rcall dot
	rcall dot
    ldi CNT, $00
    rcall dash
	rcall dot
    rjmp mloop
PASS42:
    cpi KEYREAD, $2D
    breq MORSE_DASH
    jmp PASS43
MORSE_DASH:
	ldi CNT, $00
    rcall dash
	rcall dot
	rcall dot
	rcall dot
	rcall dot
    ldi CNT, $00
    rcall dash
    rjmp mloop
PASS43:
    cpi KEYREAD, $60
    breq MORSE_APOSTROPHE
    jmp PASS44
MORSE_APOSTROPHE:
	rcall dot
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
    rjmp mloop
PASS44:
    cpi KEYREAD, $28
    breq MORSE_PAREN
    jmp PASS45
MORSE_PAREN:
	ldi CNT, $00
    rcall dash
	rcall dot
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
	ldi CNT, $00
    rcall dash
    rjmp mloop
PASS45:
    cpi KEYREAD, $29
    breq MORSE_PAREN
	cpi KEYREAD, $5F
	breq MORSE_UNDERDASH
    rjmp mloop
MORSE_UNDERDASH:
	rcall dot
	rcall dot
	ldi CNT, $00
    rcall dash
	ldi CNT, $00
    rcall dash
	rcall dot
	ldi CNT, $00
    rcall dash
    rjmp mloop




no_inp: 
  rcall   delay     ; here we are supposed to be doing the work
  rcall   delay     ;
  ldi TEMP,0
  out DDRA, TEMP
  ldi TEMP,0
  out DDRD,TEMP 
  rjmp  mloop
dot:
	rcall delay
	sbi DDRD,PD4	; open the PD4 register
	ldi TEMP, $FF
	out DDRA, R16
	rcall delay ;making a delay for beep song
	ldi TEMP,0
	out DDRA, TEMP
	ldi TEMP,0; silencing the buzzer
	out DDRD,TEMP
	ret
dash:
	rcall delay
	inc CNT
	sbi DDRD,PD4	;open the PD4 register
	ldi TEMP, $FF
	out DDRA, R16
	rcall delay	;making a delay for beep song
	cpi CNT,$03	; counter for dash song that 3 times of dot song
	brne dash
	ldi TEMP, $00
	out DDRA, TEMP
	ldi TEMP,$00
	out DDRD,TEMP
	ret
; subroutines
putchar:
        sbis    UCSRA, UDRE		; loop until USR:UDRE is 1
        rjmp    putchar
        out     UDR, SENTCHAR		; write SENTCHAR to transmitter buffer
        ret


; Interrupt Handler
REC_INT:
        push    TEMP			; save registers
        in      TEMP, SREG
        push	TEMP
        push	RECCHAR
        
        in      RECCHAR, UDR		; read UART receive data
        mov	TEMP, RECCHAR
        out     PORTB, TEMP		; display data on LEDs
        rcall   FIFOput			; place data in the FIFO
                
        pop	RECCHAR			; restore registers
        pop	TEMP
        out     SREG, TEMP                
        pop     TEMP
        reti					; return from interrupt

;FIFO stuff
clrFIFO:
        clr     FIFOHEAD		; head = tail -> 0
        clr     FIFOTAIL
        ret

FIFOput:
        push    YH				; save registers
        push    YL
        push    TEMP
        
        clr     TEMP
        ldi     YL, low(fifo)	; Y = fifo base
        ldi     YH, high(fifo)
        add     YL, FIFOTAIL    ; add offset to the end 
        adc     YH, TEMP		;

        st      Y, RECCHAR		; store data in FIFO
        inc     FIFOTAIL		; update current depth
        cpi     FIFOTAIL, FIFOSIZE
        brlo    tnowrap
        clr     FIFOTAIL		; start from begining when full
tnowrap:
	pop	TEMP			; restore registers
        pop     YL
        pop     YH
        ret				; return

; function FIFOget
; if data was available, carry is set
; if no data was available, carry is clear
FIFOget:
        cp      FIFOHEAD, FIFOTAIL	; check if empty
        brne    N_EMP
        clc							; clear carry if empty
        ret
N_EMP:
        push    YH					; save registers
        push    YL
        clr     RECCHAR
        ldi     YL, low(fifo)		; Y = FIFO base
        ldi     YH, high(fifo)
        add     YL, FIFOhead        ; add offset to get to
        adc     YH, RECCHAR			;   the beginning (head) of FIFO
        ld      RECCHAR, Y			; fetch first element in queue
        inc     FIFOHEAD				; update FIFO head pointer
        cpi     FIFOHEAD, FIFOSIZE
        brlo    hnowrap
        clr     FIFOHEAD            ; wraparound to 0 when needed
hnowrap:
        pop     YL                  ; restore registers
        pop     YH
        sec                         ; set carry to indicate data
        ret

; function delay
; delay 1/16 second
delay:
        push    TEMP
        push    TEMP1
        in      TEMP1, TCNT0		; get current timer count
delay1:
        in      TEMP, TCNT0
        cp      TEMP1, TEMP
        breq    delay1			; wait until timer increments
delay2:
        in      TEMP, TCNT0
        cp      TEMP1, TEMP
        brne    delay2			; wait until original count
        
        pop     TEMP1
        pop     TEMP
        ret				; return

;*************************** SIN TABLE *************************************
; Samples table : one period sampled on 128 samples and
; quantized on 7 bit
;******************************************************************************
sine_tbl:
.db 64,67
.db 70,73
.db 76,79
.db 82,85
.db 88,91
.db 94,96
.db 99,102
.db 104,106
.db 109,111
.db 113,115
.db 117,118
.db 120,121
.db 123,124
.db 125,126
.db 126,127
.db 127,127
.db 127,127
.db 127,127
.db 126,126
.db 125,124
.db 123,121
.db 120,118
.db 117,115
.db 113,111
.db 109,106
.db 104,102
.db 99,96
.db 94,91
.db 88,85
.db 82,79
.db 76,73
.db 70,67
.db 64,60
.db 57,54
.db 51,48
.db 45,42
.db 39,36
.db 33,31
.db 28,25
.db 23,21
.db 18,16
.db 14,12
.db 10,9
.db 7,6
.db 4,3
.db 2,1
.db 1,0
.db 0,0
.db 0,0
.db 0,0
.db 1,1
.db 2,3
.db 4,6
.db 7,9
.db 10,12
.db 14,16
.db 18,21
.db 23,25
.db 28,31
.db 33,36
.db 39,42
.db 45,48
.db 51,54
.db 57,60

;
;
;
;
;
		; initialize the Analog to Digital conversion

		ldi r16, 0x87
		sts ADCSRA, r16
		ldi r16, 0x40
		sts ADMUX, r16

		; initialize PORTB and PORTL for ouput
		ldi	r16, 0xFF
		out DDRB,r16
		sts DDRL,r16

		clr r0
		call display
lp:
		call check_button
		tst r24
		breq lp
		mov	r0, r24

		call display
		ldi r20, 99
		call delay
		ldi r20, 0
		mov r0, r20
		call display
		rjmp lp

;
;
; Returns in r24:
;	0 - no button pressed
;	1 - right button pressed
;	2 - up button pressed
;	4 - down button pressed
;	8 - left button pressed
;	16- select button pressed
;
; this function uses registers:
;	r24
;
; if you consider the word:
;	 value = (ADCH << 8) +  ADCL
; then:
;
; value > 0x3E8 - no button pressed
;
; Otherwise:
; value < 0x032 - right button pressed
; value < 0x0C3 - up button pressed
; value < 0x17C - down button pressed
; value < 0x22B - left button pressed
; value < 0x316 - select button pressed
;
check_button:
		push r16
		push r17
		push r18
		push r19

		; start a2d
		lds	r16, ADCSRA
		ori r16, 0x40
		sts	ADCSRA, r16

		; wait for it to complete
wait:		lds r16, ADCSRA
		andi r16, 0x40
		brne wait

		; read the value
		lds r16, ADCL
		lds r17, ADCH

		; put your new logic here:
		clr r24
		.def hComp = r18
		.def lComp = r19

		; check if no button value > 0x3E8
		ldi hComp, 0x3 ; high bit threshold
		ldi lComp, 0xE8 ; low bit (+1 because we want strictly greater than)
		cp r17, hComp
		brlo ckRT ; if h_val < hComp then some button must be pressed
		cp r16, lComp
		brlo ckRT ; if l_val < lComp then some button mus tbe pressed
		jmp fin
		; check if right value < 0x032
		ckRT:
		ldi hComp, 0x1
		ldi lComp, 0x32
		cp r17, hComp ; if high bit greater than or equal to high threshhold then branch to next check
		brsh ckUP
		cp r16, lComp ; if low bit greater than or equal to low threshhold then branch to next check
		brsh ckUP
		jmp rtBtn ; else value is  less than 0x032 thus jump to rtBtn
		; check if up value < 0x0C3
		ckUP:
		ldi hComp, 0x1
		ldi lComp, 0xC3
		cp r17, hComp
		brsh ckDN
		cp r16, lComp
		brsh ckDN
		jmp upBtn
		; check if down value < 0x17C
		ckDN:
		ldi hComp, 0x2
		ldi lComp, 0x7C
		cp r17, hComp
		brsh ckLF
		cp r16, lComp
		brsh ckLF
		jmp dnBtn
		; check if left value < 0x22B
		ckLF:
		ldi hComp, 0x3
		ldi lComp, 0x2B
		cp r17, hComp
		brsh ckSE
		cp r16, lComp
		brsh ckSE
		jmp lfBtn
		; check if select value < 0x316
		ckSE:
		ldi hComp, 0x4
		ldi lComp, 0x16
		cp r17, hComp
		brsh fin
		cp r16, lComp
		brsh fin
		jmp seBtn

		rtBtn:
		ldi r24, 1
		jmp fin

		upBtn:
		ldi r24, 2
		jmp fin

		dnBtn:
		ldi r24, 4
		jmp fin

		lfBtn:
		ldi r24, 8
		jmp fin

		seBtn:
		ldi r24, 16

		fin:

		pop r19
		pop r18
		pop r17
		pop r16

		ret

;
; delay
;
; set r20 before calling this function
; r20 = 0x40 is approximately 1 second delay
;
; this function uses registers:
;
;	r20
;	r21
;	r22
;
delay:
del1:		nop
		ldi r21,0xFF
del2:		nop
		ldi r22, 0xFF
del3:		nop
		dec r22
		brne del3
		dec r21
		brne del2
		dec r20
		brne del1
		ret

;
; display
;
; display the value in r0 on the 6 bit LED strip
;
; registers used:
;	r0 - value to display
;
display:

push r16
push r17
push r18
push r19

;create value for PORT B:
clr r18 ;set r18 to 0 to be used as output value for PORT B later on
;create value for PORT L:
clr r19 ;set r19 to 0 to be used as output value for PORT L later on
;create working copy of number in r0 and store in r16:
mov r16, r0
;use r17 as a mask to check each bit:
ldi r17, 0b00100000 ; keep bit x
;use the mask to clear every bit except x in r16:
and r16, r17 ;mutate r16
;compare r16 and r17 setting Z flag if x bit is 1:
cp r16, r17 ; r16 - r17, set Z if == 0
;if bit x is 1 then light up led on PORT B at bit 1:
breq xbit ;jump to xbit if x is set
next1:	mov r16, r0
ldi r17, 0b00010000 ; keep y bit
and r16, r17
cp r16, r17
breq ybit
next2:	mov r16, r0
ldi r17, 0b00001000
and r16, r17
cp r16, r17
breq ibit
next3:	mov r16, r0
ldi r17, 0b00000100
and r16, r17
cp r16, r17
breq jbit
next4:	mov r16, r0
ldi r17, 0b00000010
and r16, r17
cp r16, r17
breq kbit
next5:	mov r16, r0
ldi r17, 0b00000001
and r16, r17
cp r16, r17
breq lbit

; put the values in r17 and r18 into PORT B and PORT L
next6:
out PORTB, r18
sts PORTL, r19

jmp end ; subroutine end



xbit:	ldi r17, 0b00000010 ; store PORT B output val for x bit
add r18, r17 ; add val to working copy of PORT B val
jmp next1 ; go back to next compare

ybit:	ldi r17, 0b00001000
add r18, r17
jmp next2

ibit:	ldi r17, 0b00000010
add r19, r17
jmp next3

jbit:	ldi r17, 0b00001000
add r19, r17
jmp next4

kbit:	ldi r17, 0b00100000
add r19, r17
jmp next5

lbit:	ldi r17, 0b10000000
add r19, r17
jmp next6

end:
pop r19
pop r18
pop r17
pop r16

		ret

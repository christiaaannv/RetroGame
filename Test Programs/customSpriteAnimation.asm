

	processor 6502

	org $1001

	dc.w	end
	dc.w	1234
	dc.b	$9e, "4110", 0

end
	dc.w	0
	
	

	
start

chrout					.equ	$ffd2   ; kernal routine
chrin					.equ	$ffcf   ; kernal routine
GETIN					.equ	$FFE4

FIGHTERSTAND			.equ	$1c00	; default stance
FIGHTERSTEP				.equ	$1d00	; mid step (store starting at 256 bytes since the blank space character is at 248 bytes and we can't overwrite that as we need to use it to clear the screen)
										; this is not necessary since character codes are custom now, any memory not stored over is empty space

ACR						.equ	$911B 	;912B - bit6
IFR						.equ	$911D 	;912B
IER						.equ	$911E 	;912E


T1LOWCOUNT				.equ	$9114
T1HGHCOUNT				.equ	$9115
T1LOWLATCH				.equ	$9116
T1HGHLATCH				.equ	$9117
T2LOW					.equ	$9118
T2HIGH					.equ	$9119

VOLandAUXCOLOR			.equ	$900E	; upper 4 bits auxiliary color setting (0-15)
COLORCONTROL			.equ	$9600	
SCREENMEMORY			.equ	$1E00

main
	.org	$1200

	
	jsr		clearScreen
	

; transfers the smileSmoking image into memory where the data for T currently is
; if you store the screen code for 'T' in screen memory, this will be drawn instead (not the ascii code)
	ldx		#$00
loop1
	lda		smileSmoking,x	
;	sta		$1ca0,x		
	inx		
	cpx		#$08
	bne		loop1

	
	
	lda		#$FF					; load code for telling vic chip where to look for character data (this code is hardwired and tells it to look at 7168)
	sta		$9005					; store in Vic chip
	
	
	lda		VOLandAUXCOLOR			
	ora		#$80					; set the bit for auxiliary color = orange
	sta		VOLandAUXCOLOR
	
	
		
	ldx		#$0B
	stx		$900f		; set background color to black and border color to cyan -- see appendices for codes and memory locations to store in 


	
	; store addresses to screen memory blocks in zero page (x1f76 is 6 rows from the bottom of the screen where fighter starts)
	ldx		#$76
	stx		$01
	ldx		#$1f
	stx		$02
	

	; store where top left of fighter is in screen memory into ram locations (basically represents x,y coordinates)
	ldx		#$76
	stx		ram_00
	ldx		#$1f
	stx		ram_01


	lda		#$00
	sta		ram_02			; ram_02 will be used to store the character code to begin drawing from depending on the current state of animation.
	jsr		drawFighter

	
	
	
mainLoop	SUBROUTINE

	jsr		getInput
	

.checkLeft	
	cmp		#$02			; was left pressed
	bne		.checkRight

	lda		ram_00
	cmp		#$76			; is character at left edge of screen
	beq		mainLoop		; if so, no movement left
	
	jsr		clearFighter	; otherwise, clear character
	
	lda		ram_00			; make new character position 1 column to left
	sec
	sbc		#$01
	sta		ram_00
	jmp		.doStepAnimation
	


.checkRight
	cmp		#$03			; was right pressed
	bne		mainLoop
	
	lda		ram_00
	cmp		#$88			; is character at right edge of screen
	beq		mainLoop		; if so, no movement left

	jsr		clearFighter	; otherwise, clear character
	
	lda		ram_00			; make new character position 1 column to right
	clc
	adc		#$01
	sta		ram_00
	
	
.doStepAnimation
	lda		#$18			; draw fighter graphic starting from character code 32 (x20)
	sta		ram_02
	jsr		drawFighter
	jsr		wait			; busy loop (likely be implemented using interrupts in the final version)
	jsr		wait
	lda		#$00			;  draw fighter graphic starting from character code 0
	sta		ram_02
	jsr		drawFighter
	jsr		waitShort		; busy loop
		
	jsr		clearInputBufferB
	jmp		mainLoop
	
	
	
	
	
	
	
waitShort			SUBROUTINE
	lda		ACR
	and		#$DF		; set timer to operate in 1 shot mode		
	sta		ACR
	
	lda		#$00
	sta		T2LOW		; store low order byte of timer		
	lda		#$8F
	sta		T2HIGH		; store high order byte of timer (also starts the countdown)
		
.loop 
    lda		T2HIGH
	and		#$FF
    bne		.loop

	rts
		
	
	
	
	
wait				SUBROUTINE
	lda		ACR
	and		#$DF		; set timer to operate in 1 shot mode		
	sta		ACR
	
	lda		#$00
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$FF
	sta		T2HIGH		; store high order byte of timer (also starts the countdown)
		
.loop 
    lda		T2HIGH
	and		#$FF
    bne		.loop

	rts
	

	
	

; draws empty space characters over the entire screen	
clearScreen		SUBROUTINE
	lda		#$00				; first code is upper left cell in fighter step (a blank cell)

	ldx		#$00
.loop1
	sta		$1e00,x
	inx
	cpx		#$FF
	bne		.loop1


	ldx		#$00
.loop2
	sta		$1eFF,x
	inx
	cpx		#$FF
	bne		.loop2
	
	rts
	
	
	
	
	
	
	
	
	
getInput		SUBROUTINE		; loads a with..
								; 0 -> up
								; 1 -> down
								; 2	-> left
								; 3 -> right
								 
								; registers ruined..
								; a
								; x
	
	jsr		GETIN				; read from input buffer
	cmp		#$00				; check if buffer was empty
	bne		.checkForUpKey		; if so, process input

	rts							; else return
	
.checkForUpKey
	cmp		#$91				; ascii code for up key	
	bne		.checkForDownKey
		
	lda		#$00
	rts
		
.checkForDownKey
	cmp		#$11				; ascii code for down key	
	bne		.checkForLeftKey
	
	lda		#$01
	rts
	
.checkForLeftKey
	cmp		#$9d				; ascii code for left key			
	bne		.checkForRightKey

	lda		#$02
	rts
	
.checkForRightKey
	cmp		#$1d				; ascii code for right key			
	bne		.return				

	lda		#$03
	rts

.return	
	rts
	
	
	
	
	
; clears all data from the input buffer (glitchy)
clearInputBufferA		SUBROUTINE

.loop
	jsr		GETIN				; read from input buffer
	cmp		#$00				; check if buffer was empty
	bne		.loop				; if not, extract again
	rts
	
	
	

	
; clears all data from the input buffer except for the first character in the buffer
; use to eliminate input queue growth resultant of multiple key presses during animations 
clearInputBufferB		SUBROUTINE

	ldy		#$00
	lda		#$00
.loop
	sta		$0278,y				; store 0 in buffer

	iny
	cpy		#$09				; repeat for entire buffer
	bne		.loop				; if not, extract again
	rts	
	
	
	
	
	
; draws the fighter's current animation frame
; ram_00 must hold the lower byte of the address in screen memory for the top left cell of the character
; ram_01 must hold the upper byte of the address in screen memory for the top left cell of the character
; ram_02 must hold the character code to begin printing from (depends on the fighter's animation frame) 	


drawFighter	 SUBROUTINE	
	
	lda		ram_00			; ram_00 must hold the lower byte of the address in screen memory for the top left cell of the character
	sta		$01				; store in 0 page for indirect indexed addressing
	sta		ram_15			; store in ram_15 for intermediate calculations

	lda		ram_02			
	clc
	adc		#$06
	sta		ram_03			
	ldx		ram_02			; start with screen code 32
	ldy		#$00			; start at screen memory location 1ee4 + 0
	sty		ram_16			; store 0 in ram_16 - used for tracking the character code to print next
	
.loop1	
	txa						
	clc
	adc		ram_16			; ram_16 holds the current character code offset for printing (from 0 - 23 for our 4x6 cell fighter)
	sta		($01),y			; store screen codes in screen memory where character currently resides, offset by y = {0, 22, 44, ... 132} for successive columns 

	tya
	clc
	adc		#$16			; add 22 to y to move down one cell in screen memory since each row is 22 cells (x16 = 22)
	tay
	
	inx						; note, ram starts at $1B00 so $1B03 is ram_03
	cpx		$1B03			; print 6 screen codes from top to bottom for current column (fighter step codes are from 32(x20) - 56(x38)) 
	bne		.loop1
	
	
	
	ldx		ram_15			; load lower byte of the address in screen memory for the current cell being printed
	inx						; add 1 to move on to printing the next column
	stx		ram_15			; store it in ram for next time
	stx		$01				; store in zero page for indirect indexed addressing
	
	lda		ram_16			; load current character code offset
	clc
	adc		#$06			; add 6 for printing the next 6 codes (6 codes per column)
	cmp		#$18			; need to print 24 character codes in total for the fighter (x18 = 24)
	beq		.return			; if equal, we are done

	
	
	ldx		ram_02			; otherwise, reset x and y for printing the next column
	ldy		#$00
	sta		ram_16			; store the current character code in ram
	jmp		.loop1
	
	
.return	
	rts	
	
	
	
	

	
	
clearFighter	 SUBROUTINE		; draws blank spaces over the fighter's leftmost and rightmost columns	
	
	lda		ram_00
	sta		$01

	ldx		#$00				; use blank spaces to clear character
	ldy		#$00			
.loop1	
	txa
	sta		($01),y				; store screen codes in screen memory where character currently resides, offset by y = {0, 22, 44, ... 132} for successive columns 

	tya
	clc
	adc		#$16				; add 22 to move down one cell in screen memory since each row is 22 cells
	tay
	
	cpy		#$84				; print first 6 screen codes from top to bottom
	bne		.loop1


	lda		ram_00				; move to 4th column of character in screen memory and repeat
	clc
	adc		#$03
	sta		$01

	ldx		#$00
	ldy		#$00
.loop4	
	txa
	sta		($01),y

	tya
	clc
	adc		#$16
	tay
	
	cpy		#$84
	bne		.loop4
	
	
	
	rts	
	
	
	
	
	
	
	
	SEG.U	RAM				; force our RAM to start at $1B00 - 256 bytes before fighter graphics

	ORG		$1B00
	
ram_00		.byte	$00
ram_01		.byte	$00
ram_02		.byte	$00
ram_03		.byte	$00
ram_04		.byte	$00
ram_05		.byte	$00
ram_06		.byte	$00
ram_07		.byte	$00
ram_08		.byte	$00
ram_09		.byte	$00
ram_10		.byte	$00
ram_11		.byte	$00
ram_12		.byte	$00
ram_13		.byte	$00
ram_14		.byte	$00
ram_15		.byte	$00
ram_16		.byte	$00
ram_17		.byte	$00
ram_18		.byte	$00
ram_19		.byte	$00
ram_20		.byte	$00
ram_21		.byte	$00
ram_22		.byte	$00
ram_23		.byte	$00

	SEG
	
	
	
	
	ORG		$1C00		; forces our fighter graphics to begin where Vic is obtaining its character information from (character code 0 refers to the first 8 bytes starting at 1C00, and so on)

fighter					; 192 bytes (character codes 0 - 23)

	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $03, $07, $0f, $0e, $0e, $06, $07, $07
	.byte	$02, $05, $16, $0a, $0a, $0a, $02, $02, $02, $32, $3e, $3e, $3f, $7f, $7f, $7b, $7c, $7f, $7f, $1f, $18, $1e, $0f, $0f, $0c, $06, $07, $0f, $0f, $0e, $1e, $1e, $1e, $3e, $3c, $3c, $78, $f8, $f8, $f0, $c0, $c0, $00, $00, $00, $00, $00, $c0 
	.byte	$80, $50, $a0, $20, $a0, $a0, $a0, $80, $80, $bc, $b7, $ff, $fb, $fb, $fb, $e8, $c8, $08, $c8, $f8, $f8, $38, $f0, $f0, $30, $60, $e0, $f0, $f8, $78, $3c, $1c, $1e, $1e, $0f, $07, $07, $03, $03, $03, $03, $03, $03, $03, $03, $01, $01, $01 
	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0c, $0c, $3c, $f0, $f0, $c0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $c0, $c0, $c0, $80, $80, $80, $80, $80, $c0, $e0, $f8


fighterStep					; 192 bytes (character codes 24 - 47)

	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte	$02, $05, $16, $0a, $0a, $0a, $02, $02, $02, $32, $3e, $3e, $3f, $7f, $7f, $7b, $7c, $7f, $7f, $1f, $18, $1e, $0f, $0f, $0c, $06, $07, $0f, $0f, $0e, $1e, $1e, $1e, $3e, $3c, $3c, $38, $38, $78, $70, $70, $70, $71, $f1, $f1, $61, $71, $7d
	.byte	$80, $50, $a0, $20, $a0, $a0, $a0, $80, $80, $bc, $b7, $ff, $fb, $fb, $fb, $e8, $c8, $08, $c8, $f8, $f8, $38, $f0, $f0, $30, $60, $e0, $f0, $f0, $f0, $f0, $70, $70, $70, $70, $70, $78, $78, $78, $f8, $f0, $f0, $e0, $e0, $e0, $c0, $e0, $f8
	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0c, $0c, $3c, $f0, $f0, $c0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	

	

smileSmoking	
	.byte	$3c
	.byte	$42
	.byte	$a5
	.byte	$81
	.byte	$a5
	.byte	$99
	.byte	$46
	.byte	$3d



	

	
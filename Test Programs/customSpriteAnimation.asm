

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
	sta		$1ca0,x		
	inx		
	cpx		#$08
	bne		loop1

	
	
	lda		#$FF					; load code for telling vic chip where to look for character data (this code is hardwired and tells it to look at 7168)
	sta		$9005					; store in Vic chip
	
	
	lda		VOLandAUXCOLOR			
	ora		#$80					; set the bit for auxiliary color = orange
	sta		VOLandAUXCOLOR
	

storeFighter	SUBROUTINE	
	ldx		#$00
	ldy		#$00
.loop1								; stores 48 bytes in custom char location representing the left column of the player (loops 48x)
	lda		fighter,x
	sta		FIGHTERSTAND,y
	
	txa
	clc
	adc		#$04
	tax	
	

	iny
	
	cpy		#$30					;48
	bne		.loop1


	ldx		#$01
	ldy		#$30					; start at y = 48
.loop2								; stores 48 bytes in custom char location representing the second from the left column of the player (loops 48x)
	lda		fighter,x
	sta		FIGHTERSTAND,y
	
	txa
	clc
	adc		#$04
	tax	
	

	iny
	
	cpy		#$60					;96
	bne		.loop2

	
	ldx		#$02
	ldy		#$60					; start at y = 96
.loop3								; stores 48 bytes in custom char location representing the third from the left column of the player (loops 48x)
	lda		fighter,x
	sta		FIGHTERSTAND,y
	
	txa
	clc
	adc		#$04
	tax	
	

	iny
	
	cpy		#$90					;144
	bne		.loop3
	
	
	
	ldx		#$03
	ldy		#$90					; start at y = 144
.loop4								; stores 48 bytes in custom char location representing the final column of the player (loops 48x)
	lda		fighter,x
	sta		FIGHTERSTAND,y
	
	txa
	clc
	adc		#$04
	tax	
	
	iny
	
	cpy		#$C0					;192
	bne		.loop4
	
	
	
	
	
	
	
	
	
storeFighterStep	SUBROUTINE	
	ldx		#$00
	ldy		#$00
.loop1								; stores 48 bytes in custom char location representing the left column of the player (loops 48x)
	lda		fighterStep,x
	sta		FIGHTERSTEP,y
	
	txa
	clc
	adc		#$04
	tax	
	

	iny
	
	cpy		#$30					;48
	bne		.loop1


	ldx		#$01
	ldy		#$30					; start at y = 48
.loop2								; stores 48 bytes in custom char location representing the second from the left column of the player (loops 48x)
	lda		fighterStep,x
	sta		FIGHTERSTEP,y
	
	txa
	clc
	adc		#$04
	tax	
	

	iny
	
	cpy		#$60					;96
	bne		.loop2

	
	ldx		#$02
	ldy		#$60					; start at y = 96
.loop3								; stores 48 bytes in custom char location representing the third from the left column of the player (loops 48x)
	lda		fighterStep,x
	sta		FIGHTERSTEP,y
	
	txa
	clc
	adc		#$04
	tax	
	

	iny
	
	cpy		#$90					;144
	bne		.loop3
	
	
	
	ldx		#$03
	ldy		#$90					; start at y = 144
.loop4								; stores 48 bytes in custom char location representing the final column of the player (loops 48x)
	lda		fighterStep,x
	sta		FIGHTERSTEP,y
	
	txa
	clc
	adc		#$04
	tax	
	
	iny
	
	cpy		#$C0					;192
	bne		.loop4
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	ldx		#$0B
	stx		$900f		; set background color to black and border color to cyan -- see appendices for codes and memory locations to store in 


	
	; store addresses to screen memory blocks in zero page (x1f76 is 6 rows from the bottom of the screen where fighter starts)
	ldx		#$76
	stx		$01
	ldx		#$1f
	stx		$02
	

	; store where top left of fighter is in screen memory into ram locations
	ldx		#$76
	stx		ram_00
	ldx		#$1f
	stx		ram_01

	
mainLoop	SUBROUTINE


	ldx		#$00
	stx		ram_02			; ram_02 will be used to store the character code to begin drawing from depending on the current state of animation.
	
	jsr		drawDefault


	jsr		getInput
	

.checkLeft	
	cmp		#$02			; was left pressed
	bne		.checkRight

	jsr		clearFighter
	
	lda		ram_00
	sec
	sbc		#$01
	sta		ram_00

	jsr		drawStep
	jsr		wait
	jsr		wait
	jsr		drawDefault
	jsr		waitShort
	
	jsr		clearInputBuffer

.checkRight
	cmp		#$03
	bne		mainLoop
	

	jsr		clearFighter
	
	lda		ram_00
	clc
	adc		#$01
	sta		ram_00

	
	jsr		drawStep
	jsr		wait
	jsr		wait
	jsr		drawDefault
	jsr		waitShort

	jsr		clearInputBuffer
	
	jmp		mainLoop
	
	
	
	
	
	
	
waitShort			SUBROUTINE
	lda		ACR
	and		#$DF		; set timer to operate in 1 shot mode		
	sta		ACR
	
	lda		#$FF
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
	
	lda		#$FF
	sta		T2LOW		; store low order byte of timer		
	lda		#$FF
	sta		T2HIGH		; store high order byte of timer (also starts the countdown)
		
.loop 
    lda		T2HIGH
	and		#$FF
    bne		.loop

	rts
	

	
	
	
	
clearScreen		SUBROUTINE
	lda		#$20			; code for an empty space

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

	jsr		clearInputBuffer
	rts							; else return
	
.checkForUpKey
	cmp		#$91				; ascii code for up key	
	bne		.checkForDownKey
		
	lda		#$00
	rts
		
.checkForDownKey
	cmp		#$11		
	bne		.checkForLeftKey
	
	lda		#$01
	rts
	
.checkForLeftKey
	cmp		#$9d		
	bne		.checkForRightKey

	lda		#$02
	rts
	
.checkForRightKey
	cmp		#$1d		
	bne		.return				

	lda		#$03
	rts

.return	
	rts
	
	
	

clearInputBuffer		SUBROUTINE

.loop
	jsr		GETIN				; read from input buffer
	cmp		#$00				; check if buffer was empty
	bne		.loop				; if not, extract again
	rts
	
	
	
	
	
drawDefault	 SUBROUTINE		
	
	lda		ram_00
	sta		$01

	ldx		#$00			; start with screen code 0
	ldy		#$00			; start at screen memory location 1ee4 + 0
.loop1	
	txa
	sta		($01),y			; store screen codes in screen memory, offset by x

	tya
	clc
	adc		#$16			; add 22 to move down one cell in screen memory since each row is 22 cells
	tay
	
	inx
	cpx		#$06			; print first 6 screen codes from top to bottom
	bne		.loop1

	
	
	
	lda		ram_00
	clc
	adc		#$01
	sta		$01

	ldx		#$06			; column 2 starts with screen code 6
	ldy		#$00
.loop2	
	txa
	sta		($01),y			; 1ee5 is 1 cell to the right of 1ee4 (one column to the right)

	tya
	clc
	adc		#$16
	tay
	
	inx
	cpx		#$0C
	bne		.loop2
	
	

	lda		ram_00
	clc
	adc		#$02
	sta		$01

	ldx		#$0C
	ldy		#$00
.loop3	
	txa
	sta		($01),y

	tya
	clc
	adc		#$16
	tay
	
	inx
	cpx		#$12
	bne		.loop3

	

	lda		ram_00
	clc
	adc		#$03
	sta		$01

	ldx		#$12
	ldy		#$00
.loop4	
	txa
	sta		($01),y

	tya
	clc
	adc		#$16
	tay
	
	inx
	cpx		#$18
	bne		.loop4	
	
	
	
	rts
	
	
	
	
	
	
	



drawStep	 SUBROUTINE		; can shorten by 4x if, each time 6 codes are printed, I change the column, load y with 0 and branch back to loop
	
	lda		ram_00
	sta		$01

	ldx		#$20			; start with screen code 32
	ldy		#$00			; start at screen memory location 1ee4 + 0
.loop1	
	txa
	sta		($01),y			; store screen codes in screen memory, offset by y

	tya
	clc
	adc		#$16			; add 22 to move down one cell in screen memory since each row is 22 cells
	tay
	
	inx
	cpx		#$26			; print first 6 screen codes from top to bottom
	bne		.loop1
	
	
	lda		ram_00
	clc
	adc		#$01
	sta		$01

	ldx		#$26			; column 2 starts with screen code 38
	ldy		#$00
.loop2	
	txa
	sta		($01),y			; 1ee5 is 1 cell to the right of 1ee4 (one column to the right)

	tya
	clc
	adc		#$16
	tay
	
	inx
	cpx		#$2C
	bne		.loop2
	
	

	lda		ram_00
	clc
	adc		#$02
	sta		$01

	ldx		#$2C
	ldy		#$00
.loop3	
	txa
	sta		($01),y

	tya
	clc
	adc		#$16
	tay
	
	inx
	cpx		#$32
	bne		.loop3

	

	lda		ram_00
	clc
	adc		#$03
	sta		$01

	ldx		#$32
	ldy		#$00
.loop4	
	txa
	sta		($01),y

	tya
	clc
	adc		#$16
	tay
	
	inx
	cpx		#$38
	bne		.loop4
	
	
	rts	
	
	
	
	

	
	
clearFighter	 SUBROUTINE		
	
	lda		ram_00
	sta		$01

	ldx		#$20			; use blank spaces to clear character
	ldy		#$00			; start at screen memory location 1ee4 + 0
.loop1	
	txa
	sta		($01),y			; store screen codes in screen memory, offset by y

	tya
	clc
	adc		#$16			; add 22 to move down one cell in screen memory since each row is 22 cells
	tay
	
	cpy		#$84			; print first 6 screen codes from top to bottom
	bne		.loop1


	lda		ram_00
	clc
	adc		#$03
	sta		$01

	ldx		#$20
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
	
	
	
	
	
	
	
DATA	

ram_00		.byte	$00
ram_01		.byte	$00
ram_02		.byte	$00
ram_03		.byte	$00
ram_04		.byte	$00
ram_05		.byte	$00
ram_06		.byte	$00
ram_07		.byte	$00

	
	
fighter
	.byte	$00, $02, $80, $00
	.byte	$00, $05, $50, $00
	.byte	$00, $16, $a0, $00
	.byte	$00, $0a, $20, $00
	.byte	$00, $0a, $a0, $00
	.byte	$00, $0a, $a0, $00
	.byte	$00, $02, $a0, $00
	.byte	$00, $02, $80, $00
	.byte	$00, $02, $80, $00
	.byte	$00, $32, $bc, $00
	.byte	$00, $3e, $b7, $0c
	.byte	$00, $3e, $ff, $0c
	.byte	$00, $3f, $fb, $3c
	.byte	$00, $7f, $fb, $f0
	.byte	$00, $7f, $fb, $f0
	.byte	$00, $7b, $e8, $c0
	.byte	$00, $7c, $c8, $00
	.byte	$00, $7f, $08, $00
	.byte	$00, $7f, $c8, $00
	.byte	$00, $1f, $f8, $00
	.byte	$00, $18, $f8, $00
	.byte	$00, $1e, $38, $00
	.byte	$00, $0f, $f0, $00
	.byte	$00, $0f, $f0, $00
	.byte	$00, $0c, $30, $00
	.byte	$00, $06, $60, $00
	.byte	$00, $07, $e0, $00
	.byte	$00, $0f, $f0, $00
	.byte	$00, $0f, $f8, $00
	.byte	$00, $0e, $78, $00
	.byte	$00, $1e, $3c, $00
	.byte	$00, $1e, $1c, $00
	.byte	$00, $1e, $1e, $00
	.byte	$00, $3e, $1e, $00
	.byte	$00, $3c, $0f, $00
	.byte	$00, $3c, $07, $80
	.byte	$00, $78, $07, $80
	.byte	$00, $f8, $03, $c0
	.byte	$00, $f8, $03, $c0
	.byte	$01, $f0, $03, $c0
	.byte	$03, $c0, $03, $80
	.byte	$07, $c0, $03, $80
	.byte	$0f, $00, $03, $80
	.byte	$0e, $00, $03, $80
	.byte	$0e, $00, $03, $80
	.byte	$06, $00, $01, $c0
	.byte	$07, $00, $01, $e0
	.byte	$07, $c0, $01, $f8

fighterStep
	.byte	$00, $02, $80, $00
	.byte	$00, $05, $50, $00
	.byte	$00, $16, $a0, $00
	.byte	$00, $0a, $20, $00
	.byte	$00, $0a, $a0, $00
	.byte	$00, $0a, $a0, $00
	.byte	$00, $02, $a0, $00
	.byte	$00, $02, $80, $00
	.byte	$00, $02, $80, $00
	.byte	$00, $32, $bc, $00
	.byte	$00, $3e, $b7, $0c
	.byte	$00, $3e, $ff, $0c
	.byte	$00, $3f, $fb, $3c
	.byte	$00, $7f, $fb, $f0
	.byte	$00, $7f, $fb, $f0
	.byte	$00, $7b, $e8, $c0
	.byte	$00, $7c, $c8, $00
	.byte	$00, $7f, $08, $00
	.byte	$00, $7f, $c8, $00
	.byte	$00, $1f, $f8, $00
	.byte	$00, $18, $f8, $00
	.byte	$00, $1e, $38, $00
	.byte	$00, $0f, $f0, $00
	.byte	$00, $0f, $f0, $00
	.byte	$00, $0c, $30, $00
	.byte	$00, $06, $60, $00
	.byte	$00, $07, $e0, $00
	.byte	$00, $0f, $f0, $00
	.byte	$00, $0f, $f0, $00
	.byte	$00, $0e, $f0, $00
	.byte	$00, $1e, $f0, $00
	.byte	$00, $1e, $70, $00
	.byte	$00, $1e, $70, $00
	.byte	$00, $3e, $70, $00
	.byte	$00, $3c, $70, $00
	.byte	$00, $3c, $70, $00
	.byte	$00, $38, $78, $00
	.byte	$00, $38, $78, $00
	.byte	$00, $78, $78, $00
	.byte	$00, $70, $f8, $00
	.byte	$00, $70, $f0, $00
	.byte	$00, $70, $f0, $00
	.byte	$00, $71, $e0, $00
	.byte	$00, $f1, $e0, $00
	.byte	$00, $f1, $e0, $00
	.byte	$00, $61, $c0, $00
	.byte	$00, $71, $e0, $00
	.byte	$00, $7d, $f8, $00
	


smileSmoking	
	.byte	$3c
	.byte	$42
	.byte	$a5
	.byte	$81
	.byte	$a5
	.byte	$99
	.byte	$46
	.byte	$3d



	

	


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

CUSTOMCHARLOCATION		.equ	$1c00

ACR			.equ	$911B ;912B - bit6
IFR			.equ	$911D ;912B
IER			.equ	$911E ;912E


T1LOWCOUNT	.equ	$9114
T1HGHCOUNT	.equ	$9115
T1LOWLATCH	.equ	$9116
T1HGHLATCH	.equ	$9117
T2LOW		.equ	$9118
T2HIGH		.equ	$9119

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

	
	
	lda		#$FF		; load code for telling vic chip where to look for character data (this code is hardwired and tells it to look at 7168)
	sta		$9005		; store in Vic chip



storeFighter	SUBROUTINE	
	ldx		#$00
	ldy		#$00
.loop1								; stores 48 bytes in custom char location representing the left column of the player (loops 48x)
	lda		fighter,x
	sta		CUSTOMCHARLOCATION,y
	
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
	sta		CUSTOMCHARLOCATION,y
	
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
	sta		CUSTOMCHARLOCATION,y
	
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
	sta		CUSTOMCHARLOCATION,y
	
	txa
	clc
	adc		#$04
	tax	
	
	iny
	
	cpy		#$C0					;192
	bne		.loop4
	
	
	
	ldx		#$08
	stx		$900f		; set background color and border color to black -- see appendices for codes and memory locations to store in 



	; the data for our fighter is now stored at 7168 - 7360
	; earlier I told the Vic chip to look at location 7168 for its character data
	; the screen codes 0 to 23 inclusive (fighter is 4cells x 6cells = 24cells) will now print a cell for our character starting from the top to bottom then left to right, column by column
	; note that 1ee4 is in screen memory
	

printColumn1 SUBROUTINE

	ldy		#$00			; start with screen code 0
	ldx		#$00			; start at screen memory location 1ee4 + 0
.loop1	
	tya
	sta		$1ee4,x			; store screen codes in screen memory, offset by x

	txa
	clc
	adc		#$16			; add 22 to move down one cell in screen memory since each row is 22 cells
	tax
	
	iny
	cpy		#$06			; print first 6 screen codes from top to bottom
	bne		.loop1

	
printColumn2 SUBROUTINE

	ldy		#$06			; column 2 starts with screen code 6
	ldx		#$00
.loop1	
	tya
	sta		$1ee5,x			; 1ee5 is 1 cell to the right of 1ee4 (one column to the right)

	txa
	clc
	adc		#$16
	tax
	
	iny
	cpy		#$0C
	bne		.loop1
	
	
printColumn3 SUBROUTINE		; same for column 3

	ldy		#$0C
	ldx		#$00
.loop1	
	tya
	sta		$1ee6,x

	txa
	clc
	adc		#$16
	tax
	
	iny
	cpy		#$12
	bne		.loop1

	
printColumn4 SUBROUTINE		; same for column 4

	ldy		#$12
	ldx		#$00
.loop1	
	tya
	sta		$1ee7,x

	txa
	clc
	adc		#$16
	tax
	
	iny
	cpy		#$18
	bne		.loop1
	
	
	
	
	
	
infiniteLoop
	clc
	bcc		infiniteLoop
	
	
	
	
	
	
	
	
	
wait
	lda		ACR
	and		#$DF		; set timer to operate in 1 shot mode		
	sta		ACR
	
	lda		#$FF
	sta		T2LOW		; store low order byte of timer		
	lda		#$FF
	sta		T2HIGH		; store high order byte of timer (also starts the countdown)
		
loop 
    lda		T2HIGH
	and		#$FF
    bne		loop

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
	
	
	
	
DATA	

ram_00
	.byte	$00

fighter
	.byte	$00, $00, $00, $00
	.byte	$00, $00, $00, $00
	.byte	$00, $00, $00, $00
	.byte	$00, $07, $00, $00
	.byte	$00, $0f, $80, $00
	.byte	$00, $0e, $80, $00
	.byte	$00, $0f, $80, $00
	.byte	$00, $07, $80, $00
	.byte	$00, $07, $00, $00
	.byte	$00, $07, $00, $00
	.byte	$00, $0f, $80, $18
	.byte	$00, $3f, $e0, $18
	.byte	$00, $7f, $f0, $78
	.byte	$00, $7f, $fd, $f0
	.byte	$00, $7f, $ff, $c0
	.byte	$00, $7f, $f7, $00
	.byte	$00, $7f, $f0, $00
	.byte	$00, $7f, $fe, $00
	.byte	$00, $3f, $fe, $00
	.byte	$00, $3f, $fc, $00
	.byte	$00, $3f, $e0, $00
	.byte	$00, $3f, $e0, $00
	.byte	$00, $3f, $e0, $00
	.byte	$00, $3f, $e0, $00
	.byte	$00, $3f, $e0, $00
	.byte	$00, $1f, $c0, $00
	.byte	$00, $1f, $c0, $00
	.byte	$00, $1f, $c0, $00
	.byte	$00, $0f, $80, $00
	.byte	$00, $0f, $80, $00
	.byte	$00, $1f, $c0, $00
	.byte	$00, $1f, $e0, $00
	.byte	$00, $1c, $e0, $00
	.byte	$00, $18, $60, $00
	.byte	$00, $38, $70, $00
	.byte	$00, $38, $38, $00
	.byte	$00, $70, $3c, $00
	.byte	$00, $70, $1e, $00
	.byte	$00, $f0, $0e, $00
	.byte	$00, $f0, $0e, $00
	.byte	$01, $e0, $0e, $00
	.byte	$01, $c0, $06, $00
	.byte	$03, $c0, $07, $00
	.byte	$07, $80, $03, $00
	.byte	$0f, $00, $03, $c0
	.byte	$0e, $00, $03, $c0
	.byte	$07, $00, $01, $c0
	.byte	$07, $80, $01, $f0
	
fighter1
	.byte	$18
	.byte	$24
	.byte	$42
	.byte	$7e
	.byte	$42
	.byte	$42
	.byte	$42
	.byte	$00

smileSmoking	
	.byte	$3c
	.byte	$42
	.byte	$a5
	.byte	$81
	.byte	$a5
	.byte	$99
	.byte	$46
	.byte	$3d


fullCell
	.byte	$ee
	.byte	$ee
	.byte	$ee
	.byte	$ee
	.byte	$ee
	.byte	$ee
	.byte	$ee
	.byte	$ee

pacman
	.byte	$3C, $7E, $FF, $FF, $FF, $FF, $7E, $3C 
	
	

	
	processor 6502

	org $1001

	dc.w	end
	dc.w	1234
	dc.b	$9e, "4110", 0

end
	dc.w	0
	
	

	
start

chrout	.equ	$ffd2   ; kernal routine
chrin	.equ	$ffcf   ; kernal routine
GETIN	.equ	$ffe4

;FOR I- 7168 TO 7679: POKE I, PEEK(I+ 25600): NEXT
	
main
	.org	$1200

	
	ldx		#$08
	stx		$900f		; set background color and border color to black -- see appendices for codes and memory locations to store in 

	; store addresses to screen memory blocks in zero page (upper half of screen 0x1E16)
	ldx		#$16
	stx		$01
	ldx		#$1e
	stx		$02

	; store addresses to screen memory blocks in zero page (lower half of screen 0x1F08)
	ldx		#$08
	stx		$03
	ldx		#$1f
	stx		$04


	lda		#$00
	sta		ram_00		; x coord starts at 0
	sta		ram_02		; which half of screen the ball is on (0 = bottom half, 1 = top half)

	lda		#$dc		; 220 (half of screen height)
	sta		ram_01		; y coord starts at 220

	ldy		#$dc		; (dc = 220) offset from top of bottom half of screen (ball starts at bottom left corner)
	lda		#$51		; load code for ball graphic
	sta		($03),y		; store in screen memory at 0x1F08 + DC
	
	
top	
	jsr		GETIN		; read from input buffer
	cmp		#$00		; check if buffer was empty
	beq		top			; if so, keep checking
	
	
checkForUpKey
	cmp		#$91				; ascii code for up key	
	bne		checkForDownKey
		
	lda		ram_01				; load y coord
	cmp		#$00				; is it 0?
	bne		okayToMoveUp		; if so...
	lda		ram_02				; ...check which half of screen it's on
	cmp		#$01
	beq		top					; if on top half, we're done, otherwise...

	jsr		eraseBall
	
	lda		#$dc				; ...store 220 for offset from top of top half of screen
	sta		ram_01			
	lda		#$01
	sta		ram_02
	jsr		drawBall
	
okayToMoveUp
	jsr		eraseBall

	lda		ram_01
	sec
	sbc		#$16				; subtract 22 from y offset
	sta		ram_01				; store it
	jsr		drawBall
	
checkForDownKey
	cmp		#$11		
	bne		checkForLeftKey
	
	lda		ram_01
	cmp		#$dc				; is the y offset 220?
	bne		okayToMoveDown		; if not, ball can move down freely
	lda		ram_02				; ...check which half of screen it's on
	cmp		#$00
	beq		top					; if on bottom half, we're done, otherwise...

	jsr		eraseBall
	
	lda		#$00
	sta		ram_01
	lda		#$00
	sta		ram_02
	jsr		drawBall
	
okayToMoveDown
	jsr		eraseBall

	lda		ram_01
	clc
	adc		#$16
	sta		ram_01
	jsr		drawBall
	
checkForLeftKey
	cmp		#$9d		
	bne		checkForRightKey

	lda		ram_00
	cmp		#$00				; is x == 0
	beq		top					; if so, ball cannot move left

	jsr		eraseBall
	
	lda		ram_00
	sec
	sbc		#$01				; subtract 1 from x coord				
	sta		ram_00
	
	jsr		drawBall

checkForRightKey
	cmp		#$1d		
	bne		jmpToTop			; branch instructions can only travel -127 to +128 bytes from current position

	lda		ram_00
	cmp		#$15				; is x == 21
	beq		jmpToTop			; if so, ball cannot move right

	jsr		eraseBall
	
	lda		ram_00
	clc
	adc		#$01				; add 1 to x coord				
	sta		ram_00
	
	jsr		drawBall

	
jmpToTop						
	jmp top
	
	
drawBall SUBROUTINE
	clc
	lda		ram_01
	adc		ram_00

	sta		ram_03
	
	lda		#$51
	ldy		ram_02
	cpy		#$01
	beq		.drawInUpperHalf

	ldy		ram_03
	sta		($03),y
	jmp		top
	
.drawInUpperHalf	
	ldy		ram_03
	sta		($01),y
	jmp top
	
	rts
	

eraseBall SUBROUTINE
	clc
	lda		ram_01
	adc		ram_00
	
	sta		ram_03

	lda		#$20
	ldy		ram_02
	cpy		#$01
	beq		.eraseInUpperHalf
	
	ldy		ram_03
	sta		($03),y
	rts
	
.eraseInUpperHalf	
	ldy		ram_03
	sta		($01),y
	
	rts
	
	
	
DATA

ram_00
	.byte	$00
	
ram_01
	.byte	$00
	
ram_02
	.byte	$00

ram_03
	.byte	$00
	
ram_04
	.byte	$00
	
ram_05
	.byte	$00
	
	
fighter
	.byte	$00, $00, $00, $00
	.byte	$00, $00, $00, $00

	.byte	$00, $00, $00, $00
	.byte	$00, $07, $00, $00

	.byte	$00, $07, $80, $00
	.byte	$00, $07, $80, $00

	.byte	$00, $07, $80, $00
	.byte	$00, $07, $80, $00

	.byte	$00, $07, $00, $00
	.byte	$00, $07, $00, $00

	.byte	$00, $0f, $80, $00
	.byte	$00, $3f, $e0, $00

	.byte	$00, $7f, $f0, $00
	.byte	$00, $7f, $f0, $00

	.byte	$00, $7f, $f0, $00
	.byte	$00, $7f, $f0, $00

	.byte	$00, $7f, $f0, $00
	.byte	$00, $7f, $f0, $00

	.byte	$00, $3f, $e0, $00
	.byte	$00, $3f, $e0, $00

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

	.byte	$07, $00, $03, $80
	.byte	$06, $00, $01, $80

	.byte	$07, $00, $01, $c0
	.byte	$07, $80, $01, $e0

	
	
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
	
	

	
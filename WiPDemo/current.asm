

	processor 6502

	org $1001

	dc.w	end
	dc.w	1234
	dc.b	$9e, "4110", 0, 0

end
	dc.w	0
	
	

	
start

chrout					.equ	$ffd2   ; kernal routine
chrin					.equ	$ffcf   ; kernal routine
GETIN					.equ	$FFE4


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

SPEAKER1				.equ	$900A
SPEAKER2				.equ	$900B
SPEAKER3				.equ	$900C
SPEAKER4				.equ	$900D
VOLUME					.equ	$900E 

RASTERVAL				.equ	$9004
JIFFYLOW				.equ	$00A2
IRQLOW					.equ	$0314
IRQHIGH					.equ	$0315





main

	lda		#$20
	jsr		fillScreen
	
	
	ldx		#$0B
	stx		$900f		; set background color to black and border color to cyan -- see appendices for codes and memory locations to store in 


	; load the address of a custom interrupt routine into Vic memory where the IRQ vector resides
	lda		<#irqHandler
	sta		IRQLOW
	lda		>#irqHandler
	sta		IRQHIGH
	cli


	lda		#$a0		; bit 7 = 1 and bit 5 = 1. This means we are enabling interrupts (bit 7) for timer 2 (bit 5)
	sta		IER			; store in the interrupt enable register
	
	lda		ACR
	and		#$DF		; set timer2 to operate in 1 shot mode		
	sta		ACR

	; This will interrupt 125x per second
	lda		#$40
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$1F
	sta		T2HIGH		; store high order byte of timer (also starts the countdown AND CLEARS INTERRUPT FLAG)


	
	lda		#$FE					; load code for telling vic chip where to look for character data (this code is hardwired and tells it to look at 6144)
	sta		$9005					; store in Vic chip
	
	lda		#$00
	jsr		fillScreen


	
	
	; store addresses to screen memory blocks in zero page (x1f76 is 6 rows from the bottom of the screen where fighter starts)
	ldx		#$7A
	stx		$01
	ldx		#$1f
	stx		$02
	
	; store where top left of fighter is in screen memory into ram locations (basically represents x,y coordinates)
	ldx		#$7A
	stx		characterXPos
	ldx		#$1f
	stx		characterYPos

	
	
	; store addresses to screen memory blocks in zero page (x1f84 is 6 rows from the bottom of the screen where opponent starts)
	ldx		#$84
	stx		$03
	ldx		#$1f
	stx		$04


	; store where top left of opponent is in screen memory into ram locations (basically represents x,y coordinates)
	ldx		#$84
	stx		opponentXPos
	ldx		#$1f
	stx		opponentYPos

	

	
	lda		#$51		; D1 with high bit off
	sta		SPEAKER2


	lda		#$04
	sta		VOLUME
	
	lda		#$80
	sta		ram_05
	
	lda		#0
	sta		ram_03

	
	
	
	
	
mainLoop	SUBROUTINE



	jsr		getInput
	sta		userPress
	jsr		doUserAction


	jsr		getOpponentNextAction
	jsr		doOpponentAction


	jsr		clearInputBufferB

	jmp		mainLoop


	
	
	
	
	
	
	
	
doUserAction		SUBROUTINE
	
	lda		characterAction		; If not 0, character is mid animation, do not process input
	beq		.drawUserDefault
	rts


.drawUserDefault	
	lda		#$00			; draw fighter graphic starting from character code 0
	sta		drawCode
	lda		characterXPos
	sta		drawXPos
	jsr		drawFighter



	
.checkKick
	lda		userPress
	cmp		#$00
	beq		.doKickAnimation


	
.checkLeft	
	cmp		#$02			; was left pressed
	bne		.checkRight

	lda		characterXPos
	cmp		#$76			; is character at left edge of screen
	bne		.moveLeft		; if not, move left
	rts		
.moveLeft	
	lda		characterXPos
	sta		drawXPos
	jsr		clearFighterLeftRight	; otherwise, clear character
	dec		characterXPos			; make new character position 1 column to left
	jmp		.doStepAnimation
	


.checkRight
	cmp		#$03			; was right pressed
	beq		.tryRight
	rts
.tryRight	
	lda		characterXPos
	clc
	adc		#4
	cmp		opponentXPos	; is character at right edge of screen
	bne		.moveRight		; if so, no movement left
	rts
.moveRight
	lda		characterXPos
	sta		drawXPos
	jsr		clearFighterLeftRight	; otherwise, clear character
	inc		characterXPos			; make new character position 1 column to right
	

	
.doStepAnimation
	lda		#$18			; draw fighter graphic starting from character code 24 (x18)
	sta		drawCode
	lda		characterXPos
	sta		drawXPos
	jsr		drawFighter
	
	lda		#4
	sta		characterAction
	lda		#8				
	sta		characterAnimTimer
	rts


	
.doKickAnimation
	lda		#$30			; draw fighter kick graphic starting from character code 48 (x30)
	sta		drawCode
	lda		characterXPos
	sta		drawXPos
	jsr		drawFighter

	lda		#1
	sta		characterAction
	lda		#16						
	sta		characterAnimTimer
	
	lda		#1
	sta		charIsStriking
	rts
	
	
	
	
	
	
	
	

getOpponentNextAction		SUBROUTINE


;opponentAction			0 = nothing
;						1 = kick
;						2 = punch
;						3 = block
;						4 = step

;opponentDir			
;						0 = up
;						1 = down	
;						2 = left
;						3 = right

	lda		opponentTimeOut
	beq		.continue
	rts
	
	
.continue
	lda		opponentWasStruck			; If opponent was struck last frame, weight his action towards moving right
	cmp		#0
	beq		.wasntStruckLastFrame

	lda		opponentXPos
	cmp		#$88
	beq		.wasntStruckLastFrame		; If at right edge of screen, act as if wasn't struck
	
	
	jsr		rand
	cmp		#10
	bmi		.wasntStruckLastFrame		; act as if he wasn't struck if the weighted random to move right fails
	jmp		.moveRight
	

.wasntStruckLastFrame
	lda		charIsStriking				; If being struck, give random chance to block (weight higher for ^ difficulty lvl)
	cmp		#0
	beq		.notBeingStruck

.newRand0
	lda		#0
	sta		charIsStriking
	jsr		rand
	cmp		#29
	beq		.newRand0		
	bpl		.notBeingStruck				; If random block fails, act as if opponent is not being struck
	
	lda		#3
	sta		opponentAction

	rts
	
	
.notBeingStruck
	lda		opponentXPos
	sec
	sbc		characterXPos				; If within striking range, high chance to strike
	cmp		#5
	bpl		.notWithinRange

	jsr		rand
	cmp		#20
	bmi		.notWithinRange				; If random strike fails, act as if not within striking range

.newRand1
	jsr		rand
	cmp		#29
	beq		.newRand1
	bpl		.kick
	
	lda		#2
	sta		opponentAction
	rts
	
.kick
	lda		#1
	sta		opponentAction
	rts

.notWithinRange
	lda		opponentXPos
	sec
	sbc		characterXPos				; If not actually not within range, move toward character
	cmp		#5
	bpl		.moveLeft
	

.moveRight
	lda		#3
	sta		opponentDir
	lda		#4
	sta		opponentAction

	rts
	

.moveLeft
	lda		#2
	sta		opponentDir
	lda		#4
	sta		opponentAction
	
	rts
	
	
	
	
	
	
	
	
doOpponentAction		SUBROUTINE

;opponentAction			0 = nothing
;						1 = kick
;						2 = punch
;						3 = block
;						4 = step

;opponentDir			
;						0 = up
;						1 = down	
;						2 = left
;						3 = right


	lda		opponentAction
	bne		.checkTimeOut

	
.drawOpponentDefault	
	lda		#$00			; draw fighter graphic starting from character code 0
	sta		drawCode
	lda		opponentXPos
	sta		drawXPos
	jsr		drawFighter	
	rts
	
	
.checkTimeOut
	lda		opponentTimeOut
	beq		.checkKick
	rts
	
.checkKick
	lda		opponentAction
	cmp		#1
	bne		.checkPunch	

	lda		#$30			; draw fighter kick graphic starting from character code 48 (x30)
	sta		drawCode
	lda		opponentXPos
	sta		drawXPos
	jsr		drawFighter

	lda		#16						
	sta		opponentAnimTimer	
	jmp		.end

	
.checkPunch
	cmp		#2
	bne		.checkBlock
	
	lda		#$30			; draw fighter kick graphic starting from character code 48 (x30)
	sta		drawCode
	lda		opponentXPos
	sta		drawXPos
	jsr		drawFighter

	lda		#16						
	sta		opponentAnimTimer	
	jmp		.end
	
.checkBlock
	cmp		#3
	bne		.checkDirection
	jmp		.doStepAnimation
	jmp		.end

	
.checkDirection
	lda		opponentDir
	cmp		#2
	bne		.checkRight

	lda		opponentXPos
	sec
	sbc		#4
	cmp		characterXPos			; is opponent touching character
	beq		.end					; if so, no movement left
	
	lda		opponentXPos
	sta		drawXPos
	jsr		clearFighterLeftRight	; otherwise, clear opponent

	
	lda		opponentXPos			; make new opponent position 1 column to left
	sec
	sbc		#$01
	sta		opponentXPos
	jmp		.doStepAnimation	

			
	
.checkRight	
	cmp		#3
	bne		.end

	lda		opponentXPos
	cmp		#$88					; is opponent at right edge of screen
	beq		.end					; if so, no movement right
	
	lda		opponentXPos
	sta		drawXPos
	jsr		clearFighterLeftRight	; otherwise, clear opponent

	
	lda		opponentXPos			; make new opponent position 1 column to left
	clc
	adc		#$01
	sta		opponentXPos
	
	
	
.doStepAnimation
	lda		#$18				; draw fighter graphic starting from character code 24 (x18)
	sta		drawCode
	lda		opponentXPos
	sta		drawXPos
	jsr		drawFighter
	lda		#16				
	sta		opponentAnimTimer
	
	


.end
	lda		#24
	sta		opponentTimeOut

	rts
	
	
	
	
	
	
	
	
	
	
	

rand	 SUBROUTINE			; Pseudo Random Number Generator
							; Seems like 29 is the mean - if result is 29, discard and call again
							
								; Returns a semi-random number in register a

								; registers ruined..
								; a

	lda		RASTERVAL
	and		JIFFYLOW
	
	beq		.eor
	asl
	bcc		.done
.eor
	eor		#$1d

.done

	rts
	

	
	
	
	
	
	
	
	
;waitShort			SUBROUTINE
;	lda		ACR
;	and		#$DF		; set timer to operate in 1 shot mode		
;	sta		ACR
	
;	lda		#$00
;	sta		T2LOW		; store low order byte of timer		
;	lda		#$8F
;	sta		T2HIGH		; store high order byte of timer (also starts the countdown)
		
;.loop 
;    lda		T2HIGH
;	and		#$FF
;   bne		.loop

;	rts
		
	
	
	
	
	
	
;wait				SUBROUTINE
;	lda		ACR
;	and		#$DF		; set timer to operate in 1 shot mode		
;	sta		ACR
	
;	lda		#$00
;	sta		T2LOW		; store low order byte of timer	countdown	
;	lda		#$FF
;	sta		T2HIGH		; store high order byte of timer (also starts the countdown)
		
;.loop 
;   lda		T2HIGH
;	and		#$FF
;   bne		.loop

;	rts
	

	
	
	
	

; draws empty space characters over the entire screen
; load "a" with the screen code to fill the screen with
fillScreen		SUBROUTINE

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
	jmp		.return
	
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
	lda		#$FF				; no keys pressed (bogus return value so calling routine will not erroneously find a valid value in register a)
	rts							; else return
	
	
	
	
	

	
; clears all data from the input buffer (glitchy)
;clearInputBufferA		SUBROUTINE

;.loop
;	jsr		GETIN				; read from input buffer
;	cmp		#$00				; check if buffer was empty
;	bne		.loop				; if not, extract again
;	rts
	
	
	

	
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
; drawXPos must hold the lower byte of the address in screen memory for the top left cell of the character
; drawYPos must hold the upper byte of the address in screen memory for the top left cell of the character
; drawCode must hold the character code to begin printing from (depends on the fighter's animation frame)


drawFighter	 SUBROUTINE	
	
	lda		drawXPos			; drawXPos must hold the lower byte of the address in screen memory for the top left cell of the character
	sta		$01				; store in 0 page for indirect indexed addressing

	lda		drawCode			
	clc
	adc		#$06
	sta		ram_14			
	ldx		drawCode			; start with screen code in drawCode
	ldy		#$00
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
	
	inx
	txa		
	cmp		ram_14			; print 6 screen codes from top to bottom for current column
	bne		.loop1
	
	
	
	ldx		drawXPos		; load lower byte of the address in screen memory for the current cell being printed
	inx						; add 1 to move on to printing the next column
	stx		drawXPos		; store it in ram for next time
	stx		$01				; store in zero page for indirect indexed addressing
	
	lda		ram_16			; load current character code offset
	clc
	adc		#$06			; add 6 for printing the next 6 codes (6 codes per column)
	cmp		#$18			; need to print 24 character codes in total for the fighter (x18 = 24)
	beq		.return			; if equal, we are done

	
	
	ldx		drawCode			; otherwise, reset x and y for printing the next column
	ldy		#$00
	sta		ram_16			; store the current character code in ram
	jmp		.loop1
	
	
.return	
	rts	
	
	
	
	

	
	
clearFighterLeftRight	 SUBROUTINE		
; draws blank spaces over the fighter's leftmost and rightmost columns	
; the position of the leftmost column must be stored in drawXPos before called
	lda		drawXPos
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


	lda		drawXPos			; move to 4th column of character in screen memory and repeat
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
	
	
	
	
	
;	ORG		$1D00		; 256 bytes before where screen memory starts
irqHandler

	ldy		ram_00
	iny
	sty		ram_00
	cpy		#6
	beq		.toggleSounds
	jmp		.skipMusic

.toggleSounds	
	lda		#0
	sta		ram_00		; reset the counter
	
	lda		SPEAKER2	; flip the msb to toggle repeating F on or off
	eor		#$80
	sta		SPEAKER2

	ldy		ram_03
	lda		melody,y
	sta		SPEAKER3
	clc
;	adc		#$39
;	adc		#$49
	adc		#$43
	sta		SPEAKER4


.dropTheBass
	ldy		ram_03
	cpy		#0
	bne		.continue1
	lda		#$D1			; change to alter the repeating note
	sta		SPEAKER2
	ldx		#0
	jmp		.bass

.continue1
	cpy		#32
	bne		.continue2
	lda		#$D1			; change to alter the repeating note (D9)
	sta		SPEAKER2
	ldx		#1
	jmp		.bass
	
.continue2
	cpy		#64
	bne		.continue3
	lda		#$C7			; change to alter the repeating note (C7)
	sta		SPEAKER2
	ldx		#2
	jmp		.bass
	
.continue3
	cpy		#96
	bne		.increment
	lda		#$BB			; change to alter the repeating note (BB)
	sta		SPEAKER2
	ldx		#3
	jmp		.bass

.continue4
	cpy		#122
	bmi		.increment
	ldx		#3
	
.bass
	lda		bass,x
	sta		SPEAKER1

	
.increment
	iny
	cpy		#128
	bne		.store

	ldy		#0

	
.store
	sty		ram_03

	
	
	
.skipMusic	

	lda		IFR			; load the interrupt flag register
	
	and		#$20		; test if the 5th bit was set (timer 2 time out flag)
	beq		.notTimer


.decCharAnimTimer	
	lda		characterAction
	beq		.decOppAnimTimer			; If the character is not mid action, do opponent check

	dec		characterAnimTimer			; Otherwise, decrement their animation timer
	bne		.decOppAnimTimer			; If it reaches 0, set their action to 0 (default stance)
	
.setCharAction	
	lda		#0
	sta		characterAction
	
	
.decOppAnimTimer
	lda		opponentAction
	beq		.decOppTimeout				; If the opponent is not mid action, skip
	
	dec		opponentAnimTimer			; Otherwise, decrement their animation timer
	bne		.resetTimer					; If it reaches 0, set their action to 0
	
.setOppAction
	lda		#0
	sta		opponentAction
	
.decOppTimeout	
	lda		opponentTimeOut
	beq		.resetTimer

	dec		opponentTimeOut
	
.resetTimer	
	; 125x per second (1000,000 / 125 = 8000 = 0x1F40)
	lda		#$40
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$1F
	sta		T2HIGH		; store high order byte of timer (also starts the countdown AND CLEARS INTERRUPT FLAG)
	
.notTimer
	jmp		$EABF		; jump to the kernel's irq handler
	
	
	
	
	
	
	
	
melody
	.byte	$B3, $00, $E8, $00, $E8, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $00, $00, $00, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $E8, $00, $AF, $00, $00, $00
	.byte	$B3, $00, $E8, $00, $E8, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $00, $00, $00, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $E8, $00, $AF, $00, $00, $00
	.byte	$B3, $00, $E8, $00, $E8, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $00, $00, $00, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $E8, $00, $AF, $00, $00, $00
	.byte	$B3, $00, $00, $00, $00, $00, $BB, $00, $00, $00, $00, $00, $C7, $00, $00, $00, $00, $00, $CA, $00, $00, $00, $00, $00, $C7, $00, $00, $00, $C3, $CB, $D1, $D9	


	
bass
	.byte	$A3, $B3, $C7, $BB, $00
	
	
	
	
	

	
characterXPos		.byte	$00
characterYPos		.byte	$00
characterAction		.byte	$00
characterAnimTimer	.byte	$00


opponentXPos		.byte	$00
opponentYPos		.byte	$00
opponentAction		.byte	$00
opponentAnimTimer	.byte	$00
opponentTimeOut		.byte	$00

drawXPos			.byte	$00
drawCode			.byte	$00

ram_00				.byte	$00
ram_01				.byte	$00
ram_02				.byte	$00
ram_03				.byte	$00
ram_04				.byte	$00
ram_05				.byte	$00
ram_06				.byte	$00
ram_07				.byte	$00
ram_08				.byte	$00
ram_09				.byte	$00
ram_10				.byte	$00
ram_11				.byte	$00
ram_12				.byte	$00
ram_13				.byte	$00
ram_14				.byte	$00
ram_15				.byte	$00
ram_16				.byte	$00
ram_17				.byte	$00
ram_18				.byte	$00
ram_19				.byte	$00
ram_20				.byte	$00
ram_21				.byte	$00
ram_22				.byte	$00
ram_23				.byte	$00


charIsStriking		.byte	$00
charWasStruck		.byte	$00
opponentWasStruck	.byte	$00
opponentDir			.byte	$00
opponentBlocked		.byte	$00
		
distanceApart		.byte	$00
userPress			.byte	$00

	
	
	
	
	ORG		$1800		; forces our fighter graphics to begin where Vic is obtaining its character information from (character code 0 refers to the first 8 bytes starting at 1800, and so on)

fighter					; 192 bytes (character codes 1 - 23)

	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $03, $07, $0f, $0e, $0e, $06, $07, $07
	.byte	$02, $05, $16, $0a, $0a, $0a, $02, $02, $02, $32, $3e, $3e, $3f, $7f, $7f, $7b, $7c, $7f, $7f, $1f, $18, $1e, $0f, $0f, $0c, $06, $07, $0f, $0f, $0e, $1e, $1e, $1e, $3e, $3c, $3c, $78, $f8, $f8, $f0, $c0, $c0, $00, $00, $00, $00, $00, $c0 
	.byte	$80, $50, $a0, $20, $a0, $a0, $a0, $80, $80, $bc, $b7, $ff, $fb, $fb, $fb, $e8, $c8, $08, $c8, $f8, $f8, $38, $f0, $f0, $30, $60, $e0, $f0, $f8, $78, $3c, $1c, $1e, $1e, $0f, $07, $07, $03, $03, $03, $03, $03, $03, $03, $03, $01, $01, $01 
	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0c, $0c, $3c, $f0, $f0, $c0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $c0, $c0, $c0, $80, $80, $80, $80, $80, $c0, $e0, $f8


fighterStep					; 192 bytes (character codes 24 - 47)

	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte	$02, $05, $16, $0a, $0a, $0a, $02, $02, $02, $32, $3e, $3e, $3f, $7f, $7f, $7b, $7c, $7f, $7f, $1f, $18, $1e, $0f, $0f, $0c, $06, $07, $0f, $0f, $0e, $1e, $1e, $1e, $3e, $3c, $3c, $38, $38, $78, $70, $70, $70, $71, $f1, $f1, $61, $71, $7d
	.byte	$80, $50, $a0, $20, $a0, $a0, $a0, $80, $80, $bc, $b7, $ff, $fb, $fb, $fb, $e8, $c8, $08, $c8, $f8, $f8, $38, $f0, $f0, $30, $60, $e0, $f0, $f0, $f0, $f0, $70, $70, $70, $70, $70, $78, $78, $78, $f8, $f0, $f0, $e0, $e0, $e0, $c0, $e0, $f8
	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0c, $0c, $3c, $f0, $f0, $c0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	

fighterKick					; 192 bytes (character codes 48 - 71)

	.byte	$00, $00, $00, $00, $00, $00, $14, $2a, $b5, $71, $5d, $5d, $1c, $3e, $7f, $ff, $ff, $ff, $ff, $ff, $7f, $3d, $18, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $03, $0f 
	.byte	$00, $00, $00, $00, $00, $00, $00, $80, $00, $00, $00, $00, $70, $f8, $ff, $ff, $e7, $f0, $f8, $fc, $fe, $ff, $ff, $7f, $7f, $3f, $1f, $1f, $1f, $1e, $3e, $3e, $3c, $7c, $78, $78, $70, $70, $f0, $e0, $e0, $e0, $e0, $e0, $e0, $c0, $c0, $c0 
	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $70, $f0, $f0, $80, $00, $00, $03, $0f, $3f, $fc, $f8, $f0, $e0, $c0, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1f, $3f, $7c, $f8, $e0, $c0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
	


	
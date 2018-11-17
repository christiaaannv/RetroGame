

	processor 6502

	org $0401

	dc.w	end
	dc.w	1234
	dc.b	$9e, "1038", 0, 0

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
COLORCONTROL1			.equ	$9600	
SCREENMEMORY1			.equ	$1E00
COLORCONTROL2			.equ	$96FF	; COLORCONTROL1 + 255
SCREENMEMORY2			.equ	$1EFF


SPEAKER1				.equ	$900A
SPEAKER2				.equ	$900B
SPEAKER3				.equ	$900C
SPEAKER4				.equ	$900D
VOLUME					.equ	$900E 

RASTERVAL				.equ	$9004
JIFFYLOW				.equ	$00A2
IRQLOW					.equ	$0314
IRQHIGH					.equ	$0315


P1LIFEBARSTART			.equ	#7725	
P2LIFEBARSTART			.equ	#7738

P1LIFEBARSTARTCOLOR		.equ	#38445
P2LIFEBARSTARTCOLOR		.equ	#38458


DEBUGSCR1				.equ	$1E00
DEBUGSCR2				.equ	$1E02
DEBUGSCR3				.equ	$1E04
DEBUGSCR4				.equ	$1E06


main

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
	

	
	; store addresses to screen memory blocks in zero page (x1f7A is 6 rows from the bottom of the screen where fighter starts)
	ldx		#$7A
	stx		$01
	ldx		#$1f
	stx		$02
	
	; store where top left of fighter is in screen memory into ram locations (basically represents x,y coordinates)
	ldx		#$7A
	stx		p1XPos
	ldx		#$1f
	stx		p1YPos

	
	
	; store addresses to screen memory blocks in zero page (x1f84 is 6 rows from the bottom of the screen where opponent starts)
	ldx		#$84
	stx		$03
	ldx		#$1f
	stx		$04


	; store where top left of opponent is in screen memory into ram locations (basically represents x,y coordinates)
	ldx		#$84
	stx		p2XPos
	ldx		#$1f
	stx		p2YPos

	
	lda		#$51		; D1 with high bit off
	sta		SPEAKER2


	lda		#$04
	sta		VOLUME
	
	lda		#$80
	sta		ram_02
	
	lda		#0
	sta		ram_01

	


	ldx		#1
	jsr		fillScreen

	jsr		initColors


	lda		#16
	sta		currentLevelTimeOut
	
	
mainLoop	SUBROUTINE


	jsr		getInput
	sta		userPress
	jsr		doUserAction

	jsr		getAINextAction
	jsr		doAIAction

	jsr		checkP1Struck
	jsr		checkP2Struck

	jsr		updateHUD
	jsr		drawLifebars
	

	jsr		clearInputBufferB
	
	jmp		mainLoop


	


	
	
checkP1Struck	SUBROUTINE

	lda		p2IsStriking		; if p2 is not striking, don't update the p2WasStruck state
	beq		.end

	ldx		#0					

	lda		p2XPos		
	sec
	sbc		p1XPos
	cmp		#5					; check if within striking range
	bpl		.setStruckState		; if not, set p1WasStruck to 0 - false
	
	
.wasP1Struck	
	lda		p1Action			; check if p1 was blocking during the strike
	cmp		#3
	beq		.setStruckState
	ldx		#1

.setStruckState
	stx		p1WasStruck
	jmp		.end

	

	lda		p2IsStriking
	beq		.end
	
	
	lda		p2XPos
	sec
	sbc		p1XPos
	cmp		#5					; check if within striking range
	bpl		.end

	lda		p1IsBlocking
	bne		.end

	lda		#1
	sta		p1WasStruck
	

.end
	rts

	
	
	
	
	
	
	
	
; Continually sets p2WasStruck each iteration of the game loop
; p2WasStruck is consumed when the p1 strike animation ends, so if p2 blocked
; or moved during the animation, they will avoid the strike from p1
checkP2Struck	SUBROUTINE

	lda		p1IsStriking		; if p1 is not striking, don't update the p2WasStruck state
	beq		.end

	ldx		#0					

	lda		p2XPos		
	sec
	sbc		p1XPos
	cmp		#5					; check if within striking range
	bpl		.setStruckState
	
	
.wasP2Struck	
	lda		p2Action			; check if p2 was blocking during the strike
	cmp		#3
	beq		.setStruckState
	ldx		#1

.setStruckState
	stx		p2WasStruck


.end
	rts	
	
	
	
	
	
	
	
	
	
	
updateHUD		SUBROUTINE


.updateP1HealthBar	
	lda		p1WasStruck
	beq		.updateP2HealthBar
	
	ldy		#6
.loop1
	
	ldx		p1LifeBarTicks,y
	cpx		#1
	bne		.skip1
	
	lda		#0
	sta		p1LifeBarTicks,y
	sta		p1WasStruck
	
	lda		emptySpaceCode
	sta		P1LIFEBARSTART,y
	
	jmp		.updateP2HealthBar
	
.skip1	
	dey
	bpl		.loop1

	
	
.updateP2HealthBar	
	lda		p1Action				; when the animation timer resets p1Action,...
	bne		.end
	lda		p2WasStruck				; ...update p2 health if p2Was struck.
	beq		.end

	
	ldy		#6
.loop2
	
	ldx		p2LifeBarTicks,y
	cpx		#1
	bne		.skip2
	
	lda		#0
	sta		p2LifeBarTicks,y
	sta		p2WasStruck
	
	lda		emptySpaceCode
	sta		P2LIFEBARSTART,y
	
	jmp		.end

.skip2	
	dey
	bpl		.loop2
	


	
.end	
	rts



	
	
	
	
	
	
	

initColors		SUBROUTINE


	ldy		#6
	lda		#5						; set the life bars to green
.loop1
	
	sta		P1LIFEBARSTARTCOLOR,y
	sta		P2LIFEBARSTARTCOLOR,y
	
	dey
	bpl		.loop1
	
	

	rts
	
	
	
	
	
	
	
	
	
	
	

drawLifebars	 SUBROUTINE

	clc										
										
	lda		#169					; load the left lifebar graphic code (empty version)
	adc		p1LifeBarTicks			; add the number of ticks remaining in the leftmost lifebar
	sta		P1LIFEBARSTART			; store in screen memory

	lda		#169
	adc		p2LifeBarTicks
	sta		P2LIFEBARSTART

	
	ldy		#1						; start at 1 since the first section is a different graphic	
.loop1								; run loop for 5 middle lifebar sections
	
	lda		#171					; load the middle lifebar graphic code (empty version)
	adc		p1LifeBarTicks,y		; add the number of life ticks remaining in that section
	sta		P1LIFEBARSTART,y		; store in screen memory

	lda		#171					; load the middle lifebar graphic code (empty version)
	adc		p2LifeBarTicks,y	; add the number of life ticks remaining in that section
	sta		P2LIFEBARSTART,y		; store in screen memory
	
	iny
	cpy		#6
	bne		.loop1

	clc
	
	lda		#173					; load the right lifebar graphic code (empty version)
	adc		p1LifeBarTicks,y		; add the number of life ticks remaining in that section
	sta		P1LIFEBARSTART,y		; store in screen memory
					
	lda		#173					; load the right lifebar graphic code (empty version)
	adc		p2LifeBarTicks,y	; add the number of life ticks remaining in that section
	sta		P2LIFEBARSTART,y		; store in screen memory

					
	rts
	



	
	
	
	
doUserAction		SUBROUTINE
;p1Action				0 = nothing
;						1 = kick
;						2 = punch
;						3 = block
;						4 = step

	
	lda		p1Action		; If not 0, p1 is mid animation, do not process input (set to 0 when anim timer reaches 0)
	beq		.drawUserDefault
	rts


.drawUserDefault	
	lda		#0
	sta		p1IsBlocking
	sta		p1IsStriking


	lda		#0				; draw fighter graphic starting from p1 code 0
	sta		drawCode
	lda		p1XPos
	sta		drawXPos
	lda		<#RyuStandMask
	sta		$05
	lda		>#RyuStandMask
	sta		$06
	jsr		drawFighter

	
.checkPunch
	lda		userPress
	bne		.checkBlock

.doPunchAnimation
	lda		p1XPos
	sta		drawXPos
	jsr		clearFighter		
	lda		#31
	sta		drawCode
	lda		p1XPos
	sta		drawXPos
	lda		<#RyuPunchMask
	sta		$05
	lda		>#RyuPunchMask
	sta		$06

	jsr		drawFighter

	lda		#2
	sta		p1Action
	lda		#16				
	sta		p1AnimTimer
	
	lda		#1
	sta		p1IsStriking
	rts


.checkBlock
	cmp		#1
	bne		.checkKick
	
.doBlockAnimation	
	lda		p1XPos
	sta		drawXPos
	jsr		clearFighter		
	lda		#65
	sta		drawCode
	lda		p1XPos
	sta		drawXPos
	lda		<#RyuBlockMask
	sta		$05
	lda		>#RyuBlockMask
	sta		$06

	jsr		drawFighter

	lda		#3
	sta		p1Action
	lda		#16				
	sta		p1AnimTimer

	lda		#1
	sta		p1IsBlocking
	rts		
	
.checkKick
	cmp		#4
	bne		.checkLeft

	
.doKickAnimation
	lda		p1XPos
	sta		drawXPos
	jsr		clearFighter		
	lda		#48
	sta		drawCode
	lda		p1XPos
	sta		drawXPos
	lda		<#RyuKickMask
	sta		$05
	lda		>#RyuKickMask
	sta		$06

	jsr		drawFighter

	lda		#1
	sta		p1Action
	lda		#16						
	sta		p1AnimTimer
	
	lda		#1
	sta		p1IsStriking
	rts
	
	
.checkLeft	
	cmp		#$02			; was left pressed
	bne		.checkRight
.tryLeft
	lda		p1XPos
	cmp		#$76			; is p1 at left edge of screen
	bne		.moveLeft		; if not, move left
	rts		
.moveLeft	
	lda		p1XPos
	sta		drawXPos
	jsr		clearFighter	; otherwise, clear p1
	dec		p1XPos			; make new p1 position 1 column to left
	jmp		.doStepAnimation
	


.checkRight
	cmp		#$03			; was right pressed
	beq		.tryRight
	rts
.tryRight	
	lda		p1XPos
	clc
	adc		#4
	cmp		p2XPos	; is p1 at right edge of screen
	bne		.moveRight		; if so, no movement left
	rts
.moveRight
	lda		p1XPos
	sta		drawXPos
	jsr		clearFighter	; otherwise, clear p1
	inc		p1XPos			; make new p1 position 1 column to right
	

	
.doStepAnimation
	lda		#16			; draw fighter graphic starting from p1 code 16
	sta		drawCode
	lda		p1XPos
	sta		drawXPos
	lda		<#RyuStepMask
	sta		$05
	lda		>#RyuStepMask
	sta		$06
	jsr		drawFighter
	
	lda		#4
	sta		p1Action
	lda		#8				
	sta		p1AnimTimer
	rts


	
	
	
	
	
	
	
	
	

getAINextAction		SUBROUTINE


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

	lda		aiTimeOut
	beq		.continue
	rts
	
	
.continue
	lda		p2WasStruck					; If p2 was struck last frame, weight his action towards moving right
	beq		.wasntStruckLastFrame
	
	lda		p2XPos
	cmp		#$88
	beq		.wasntStruckLastFrame		; If at right edge of screen, act as if wasn't struck
	
	
	jsr		rand
	cmp		#10
	bmi		.wasntStruckLastFrame		; act as if he wasn't struck if the weighted random to move right fails
	jmp		.moveRight
	

.wasntStruckLastFrame
	lda		p1IsStriking				; If being struck, give random chance to block (weight higher for ^ difficulty lvl)
	beq		.notBeingStruck

	lda		p2XPos						; Check if user is even in range
	sec
	sbc		p1XPos				
	cmp		#5
	bpl		.notWithinRange				; If so, do random roll for block

.newRand0
	jsr		rand
	cmp		#60
;	beq		.newRand0		
	bpl		.notBeingStruck				; If random block fails, store state vars and act as if not being struck
	
	lda		#3
	sta		p2Action
	rts

.notBeingStruck
	lda		p2XPos
	sec
	sbc		p1XPos				; If within striking range, random chance to strike
	cmp		#5
	bpl		.notWithinRange

	jsr		rand
	cmp		#20
	bmi		.notWithinRange				; If random strike chance fails, act as if not within striking range

.newRand1
	jsr		rand						; Randomize punch/kick
	cmp		#29
	beq		.newRand1
	bpl		.kick
	
	lda		#2
	sta		p2Action
	rts
	
.kick
	lda		#1
	sta		p2Action
	rts

	
.notWithinRange
	lda		p2XPos
	sec
	sbc		p1XPos				; If not actually not within range, move toward p1
	cmp		#5
	bpl		.moveLeft
	

.moveRight							
	lda		#3
	sta		aiDir
	lda		#4
	sta		p2Action

	rts
	

.moveLeft
	lda		#2
	sta		aiDir
	lda		#4
	sta		p2Action
	
	rts
	
	
	
	
	
	
	
	
doAIAction		SUBROUTINE

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

	lda		#0
	sta		p2IsStriking

	lda		p2Action
	bne		.checkTimeOut

	
.drawp2Default	
	lda		#0
	sta		p2IsBlocking


	lda		#82			; draw fighter graphic starting from character code 0
	sta		drawCode
	lda		p2XPos
	sta		drawXPos
	lda		<#KenStandMask
	sta		$05
	lda		>#KenStandMask
	sta		$06

	jsr		drawFighter	
	rts
	
	
.checkTimeOut
	lda		aiTimeOut
	beq		.checkKick
	rts
	
.checkKick
	lda		p2Action
	cmp		#1
	bne		.checkPunch	

	lda		#1
	sta		p2IsStriking

	lda		#134			; draw fighter kick graphic starting from character code 134
	sta		drawCode
	lda		p2XPos
	sta		drawXPos
	lda		<#KenKickMask
	sta		$05
	lda		>#KenKickMask
	sta		$06

	lda		p2XPos
	sta		drawXPos
	jsr		clearFighter		

	jsr		drawFighter

	lda		#16						
	sta		p2AnimTimer	
	jmp		.end

	
.checkPunch
	cmp		#2
	bne		.checkBlock

	lda		#1
	sta		p2IsStriking
	
	lda		#117			; draw fighter punch graphic starting from character code 117
	sta		drawCode
	lda		p2XPos
	sta		drawXPos
	lda		<#KenPunchMask
	sta		$05
	lda		>#KenPunchMask
	sta		$06
	lda		p2XPos
	sta		drawXPos
	jsr		clearFighter		

	jsr		drawFighter

	lda		#16						
	sta		p2AnimTimer	
	jmp		.end
	
.checkBlock
	cmp		#3
	bne		.checkDirection

	lda		#1
	sta		p2IsBlocking

	lda		#151			; draw fighter block graphic starting from character code 151
	sta		drawCode
	lda		p2XPos
	sta		drawXPos
	lda		<#KenBlockMask
	sta		$05
	lda		>#KenBlockMask
	sta		$06
	lda		p2XPos
	sta		drawXPos
	jsr		clearFighter		

	jsr		drawFighter

	lda		#16						
	sta		p2AnimTimer	
	
	jmp		.end

	
.checkDirection
	lda		aiDir
	cmp		#2
	bne		.checkRight

	lda		p2XPos
	sec
	sbc		#4
	cmp		p1XPos					; is p2 touching p1
	beq		.end					; if so, no movement left
	
	lda		p2XPos
	sta		drawXPos
	jsr		clearFighter			; otherwise, clear p2

	
	lda		p2XPos					; make new p2 position 1 column to left
	sec
	sbc		#$01
	sta		p2XPos
	jmp		.doStepAnimation	

			
	
.checkRight	
	cmp		#3
	bne		.end

	lda		p2XPos
	cmp		#$88					; is p2 at right edge of screen
	beq		.end					; if so, no movement right
	
	lda		p2XPos
	sta		drawXPos
	jsr		clearFighter			; otherwise, clear p2

	
	lda		p2XPos					; make new p2 position 1 column to left
	clc
	adc		#$01
	sta		p2XPos
	
	
	
.doStepAnimation
	lda		#100					; draw fighter step graphic starting from character code 100
	sta		drawCode
	lda		p2XPos
	sta		drawXPos
	lda		<#KenStepMask
	sta		$05
	lda		>#KenStepMask
	sta		$06
	lda		p2XPos
	sta		drawXPos
	jsr		clearFighter		

	jsr		drawFighter
	lda		#16				
	sta		p2AnimTimer
	
	


.end
	lda		currentLevelTimeOut
	sta		aiTimeOut

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
	

	
	
	
	
	
	

; draws empty space characters over the entire screen
; load 'x' with the color to set for all screen characters
fillScreen		SUBROUTINE

	ldy		#$00
.loop1
	txa
	sta		COLORCONTROL1,y
	lda		emptySpaceCode
	sta		SCREENMEMORY1,y
	iny
	cpy		#$FF
	bne		.loop1


	ldy		#$00
.loop2
	txa	
	sta		COLORCONTROL2,y
	lda		emptySpaceCode
	sta		SCREENMEMORY2,y
	iny
	cpy		#$FF
	bne		.loop2
	
	rts
	
	
	
	
	
getInput		SUBROUTINE		; loads a with..
								; 0 -> down (punch)
								; 1 -> s (block)
								; 2	-> a (left)
								; 3 -> d (right)
								; 4 -> right (kick)
								 
								; registers ruined..
								; a
								; x
	
	jsr		GETIN				; read from input buffer
	cmp		#0					; check if buffer was empty
	bne		.checkForDownKey	; if so, process input
	jmp		.return

	
.checkForDownKey
	cmp		#17					; ascii code for down key	
	bne		.checkForSKey
	
	lda		#0
	rts

	
.checkForSKey
	cmp		#83					; ascii code for S key	
	bne		.checkForAKey
		
	lda		#1
	rts
		
	
.checkForAKey
	cmp		#65					; ascii code for A key			
	bne		.checkForDKey

	lda		#2
	rts

	
.checkForDKey
	cmp		#68					; ascii code for D key			
	bne		.checkForRightKey				

	lda		#3
	rts

	
.checkForRightKey
	cmp		#29
	bne		.return
	
	lda		#4
	rts
	
.return
	lda		#$FF				; no keys pressed (bogus return value so calling routine will not erroneously find a valid value in register a)
	rts							; else return
	
	
	
	
	

	

	
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
; zero page $05 and $06 must hold the address of the draw mask to use for the 

drawFighter	 SUBROUTINE	
	
	lda		drawXPos		; drawXPos must hold the lower byte of the address in screen memory for the top left cell of the character
	sta		$01				; store in 0 page for indirect indexed addressing

	

	ldy		#0
	lda		($05),y			; load number of character codes composing current fighter frame being drawn
	sta		counter			; store as outer loop counter
	inc		$05

	lda		($05),y			; load number of character codes in first column
	sta		ram_15			
	clc
	adc		drawCode		; add this value to drawCode 
	sta		ram_14			; store as inner loop control variable		
	inc		$05
	
	ldy		#0
	sty		ram_16			; store 0 in ram_16 - used for tracking the character code to print next
	ldx		drawCode		; start with screen code in drawCode

	
.loadMask
	lda		($05),y			; load then store the mask byte for the column
	sta		columnMask
	inc		$05

.loop1
	lda		columnMask		; test if the current cell is blank or not
	clc
	asl
	sta		columnMask
	bcc		.empty			; if so, fill with empty space
	txa						; otherwise, transfer the drawCode into a
	clc
	adc		ram_16			; add ram_16 (holds the current character code offset for beginning of column)
	sta		($01),y			; store screen codes in screen memory offset by y = {0, 22, 44, ... 132} for successive columns 
	inx						; move to next character code
	jmp		.skipEmpty
	
.empty	
	lda		#168
	sta		($01),y

.skipEmpty
	tya
	clc
	adc		#22				; add 22 to y to move down one cell in screen memory since each row is 22 cells (x16 = 22)
	tay

	
	txa						; transfer x into a for comparison
	cmp		ram_14			; ram_14 holds the code to stop at for the current column, a holds the current draw code
	bne		.loop1
	
	
	inc		$01				; increment to move to printing the next column

	
	lda		ram_16			; load current character code offset
	clc
	adc		ram_15			; add number of codes printed for that column
	sta		ram_16			; store new offset from beginning of character codes for current graphic
	cmp		counter			; test if all codes for that graphic were printed
	beq		.return			; if equal, we are done


	ldy		#0
	lda		($05),y			; load number of character codes in next column
	sta		ram_15
	clc
	adc		drawCode
	sta		ram_14			; store as loop control variable		
	inc		$05

	
	ldx		drawCode		; otherwise, reset x and y for printing the next column
	ldy		#0
	jmp		.loadMask
	
	
.return	
	rts	

		
	
counter
	.byte		$00
	
columnMask
	.byte		$00

	




	
clearFighter	 SUBROUTINE		
; draws blank spaces over the fighter	
; the position of the leftmost cell of the player must be stored in drawXPos before calling this function
	lda		drawXPos
	sta		$01

	ldx		#4
	
.top
	ldy		#0			
.loop1
	lda		#168
	sta		($01),y				; store screen codes in screen memory where character currently resides, offset by y = {0, 22, 44, ... 132} for successive columns 

	tya
	clc
	adc		#$16				; add 22 to move down one cell in screen memory since each row is 22 cells
	tay
	
	cpy		#$84				; print first 6 screen codes from top to bottom
	bne		.loop1

	
	inc		$01
	dex
	bne		.top
	
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

	ldy		ram_01
	lda		melody,y
	sta		SPEAKER3
	clc
;	adc		#$39
;	adc		#$49
	adc		#$43
	sta		SPEAKER4


.dropTheBass
	ldy		ram_01
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
	sty		ram_01

	
	
	
.skipMusic	

	lda		IFR			; load the interrupt flag register
	
	and		#$20		; test if the 5th bit was set (timer 2 time out flag)
	beq		.notTimer


	
; Reset animations in progress to default stance if animation timer reaches 0

.decP1AnimTimer	
	lda		p1Action
	beq		.decP2AnimTimer				; If the character is not mid action, do p2 check

	dec		p1AnimTimer					; Otherwise, decrement their animation timer
	bne		.decP2AnimTimer				; If it reaches 0, set their action to 0 (default stance)
	
.setP1Action	
	lda		#0
	sta		p1Action
	
	
.decP2AnimTimer
	lda		p2Action
	beq		.decAiTimeOut				; If the p2 is not mid action, skip
	
	dec		p2AnimTimer					; Otherwise, decrement their animation timer
	bne		.resetTimer					; If it reaches 0, set their action to 0
	
.setP2Action
	lda		#0
	sta		p2Action
	
.decAiTimeOut	
	lda		aiTimeOut
	beq		.resetTimer

	dec		aiTimeOut
	
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
	
	
	
defaultCharacterColor
	.byte	#1
	
emptySpaceCode
	.byte	#168
	

timer
	.byte	#120
	
	
p1XPos				.byte	$00
p1YPos				.byte	$00
p1Action			.byte	$00
p1AnimTimer			.byte	$00


p2XPos				.byte	$00
p2YPos				.byte	$00
p2Action			.byte	$00
p2AnimTimer			.byte	$00
aiTimeOut			.byte	$00

drawXPos			.byte	$00
drawCode			.byte	$00

ram_00				.byte	$00		; used in irq handler, volatile
ram_01				.byte	$00		; used in irq handler, volatile
ram_02				.byte	$00		; used in irq handler, volatile
ram_03				.byte	$00		; not yet used ...
ram_04				.byte	$00
ram_05				.byte	$00
ram_06				.byte	$00
ram_07				.byte	$00
ram_08				.byte	$00
ram_09				.byte	$00
ram_10				.byte	$00
ram_11				.byte	$00
ram_12				.byte	$00
ram_13				.byte	$00		; ...
ram_14				.byte	$00		; used in drawFighter
ram_15				.byte	$00		; used in drawFighter
ram_16				.byte	$00		; used in drawFighter
ram_17				.byte	$00		; not yet used ...
ram_18				.byte	$00
ram_19				.byte	$00
ram_20				.byte	$00
ram_21				.byte	$00
ram_22				.byte	$00
ram_23				.byte	$00		; ...


p1HitPoints			.byte	$00
p1IsStriking		.byte	$00
p1IsBlocking		.byte	$00
p1WasStruck			.byte	$00

p2HitPoints			.byte	$00
p2IsStriking		.byte	$00
p2WasStruck			.byte	$00
p2IsBlocking		.byte	$00


aiDir				.byte	$00
currentLevelTimeOut	.byte	$00		
		
distanceApart		.byte	$00
userPress			.byte	$00



p1LifeBarTicks
	.byte		#1, #1, #1, #1, #1, #1, #1		; change to use bit mask instead

p2LifeBarTicks
	.byte		#1, #1, #1, #1, #1, #1, #1		; change to use bit mask instead

	
startScreenCodes	; [rows], [columns], [code0], [code1],... [code(rows*columns)]	-> 98 bytes
S
	.byte	#4, #2, #233, #223, #95, #118, #117, #223, #95, #105

T
	.byte	#4, #3, #32, #111, #111, #78, #93, #32, #32, #93, #32, #32, #93, #32

R
	.byte	#5, #3, #67, #67, #73, #67, #199, #66, #77, #67, #75, #115, #77, #32, #93, #32, #77

e
	.byte	#3, #3, #233, #105, #95, #105, #111, #233, #223, #111, #111
	
E
	.byte	#3, #3, 106, #105, #119, #106, #67, #91, #106, #223, #111

F
	.byte	#4, #4, #106, #105, #119, #126, #106, #67, #73, #32, #106, #32, #32, #32, #106, #223, #32, #32

I
	.byte	#3, #1, #219, #219, #219

G
	.byte	#4, #2, #105, #95, #223, #233, #32, #106, #111, #233

H
	.byte	#4, #3, #116, #90, #106, #223, #100, #233, #105, #99, #95, #116, #90, #106

r
	.byte	#3, #2, #105, #95, #116, #32, #116, #32
	
	
startScreenLayout			; -> 39 bytes
	.byte	<#S, >#S, #46
	.byte	<#T, >#T, #48
	.byte	<#R, >#R, #29
	.byte	<#e, >#e, #76
	.byte	<#e, >#e, #79
	.byte	<#T, >#T, #60
	
	.byte	<#F, >#F, #156
	.byte	<#I, >#I, #181
	.byte	<#G, >#G, #205
	.byte	<#H, >#H, #164
	.byte	<#T, >#T, #167
	.byte	<#E, >#E, #190
	.byte	<#r, >#r, #192
		
	
	
	
	

;make sure none of these cross a page boundary (can be separated from one another but not broken intrinsically)

	ORG		$17A5
RyuStandMask
	.byte		#16, #5, $7C, #5, $7C, #5, $7C, #1, $04

RyuStepMask
	.byte		#15, #2, $60, #5, $7C, #5, $7C, #3, $1C

RyuPunchMask
	.byte		#17, #5, $7C, #5, $7C, #5, $7C, #2, $14

RyuKickMask
	.byte		#17, #4, $78, #5, $7C, #5, $7C, #3, $38

RyuBlockMask
	.byte		#17, #2, $60, #5, $7C, #5, $7C, #5, $7C


KenStandMask
	.byte		#18, #3, $1C, #5, $7C, #5, $7C, #5, $7C

KenStepMask
	.byte		#17, #3, $1C, #5, $7C, #5, $7C, #4, $78

KenPunchMask
	.byte		#17, #2, $30, #5, $7C, #5, $7C, #5, $7C

KenKickMask
	.byte		#17, #3, $38, #5, $7C, #5, $7C, #4, $78

KenBlockMask
	.byte		#17, #4, $74, #5, $7C, #5, $7C, #3, $70
	



	
	ORG		$1800		; forces our fighter graphics to begin where Vic is obtaining its character information from (character code 0 refers to the first 8 bytes starting at 1800, and so on)

RyuStand		; code 0
	.byte	$00, $00, $00, $00, $00, $00, $00, $3f, $3f, $03, $07, $0e, $0c, $00, $01, $01, $03, $04, $04, $0c, $1e, $1f, $1c, $1c, $1c, $0c, $06, $00, $00, $00, $00, $00, $01, $03, $07, $0d, $18, $20, $20, $3f
	.byte	$1f, $60, $40, $80, $80, $ff, $ff, $ff, $80, $8e, $83, $c3, $40, $c0, $27, $20, $10, $08, $0f, $40, $40, $c0, $c0, $c0, $c0, $c0, $ff, $94, $94, $84, $80, $84, $04, $04, $0a, $8a, $f1, $11, $11, $f1 
	.byte	$c0, $30, $10, $10, $10, $f0, $f0, $f0, $10, $30, $50, $50, $10, $10, $90, $38, $64, $46, $82, $07, $4f, $7f, $67, $27, $2f, $6f, $ee, $20, $20, $20, $20, $20, $38, $08, $08, $1e, $f3, $00, $00, $ff 
	.byte	$00, $00, $00, $00, $00, $80, $80, $80 



RyuStep			; code 16
	.byte	$00, $00, $00, $00, $00, $00, $00, $1f, $1f, $00, $0f, $0f, $00, $00, $00, $00 
	.byte	 $0f, $30, $20, $40, $40, $7f, $7f, $ff, $c0, $c7, $c1, $61, $20, $20, $33, $10, $10, $08, $7b, $40, $40, $40, $f0, $fc, $e4, $ef, $ed, $6e, $7d, $22, $20, $20, $20, $20, $60, $70, $9f, $80, $80, $ff 
	.byte	$e0, $18, $08, $08, $08, $f8, $f8, $f8, $08, $18, $a8, $a8, $08, $08, $c8, $18, $30, $20, $de, $01, $01, $23, $27, $3f, $33, $f3, $97, $97, $1f, $1c, $04, $84, $84, $84, $84, $cf, $79, $c0, $40, $ff 
	.byte	$00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $80, $40, $40, $c0 



RyuPunch		; code 31
	.byte	$00, $01, $01, $02, $02, $03, $03, $ff, $fe, $0e, $1e, $3b, $31, $01, $01, $00, $00, $00, $00, $01, $03, $07, $07, $07, $07, $07, $03, $03, $00, $00, $01, $01, $01, $01, $03, $03, $04, $04, $04, $07 
	.byte	$7f, $80, $00, $00, $00, $ff, $ff, $ff, $00, $38, $0d, $0d, $00, $00, $9e, $80, $81, $41, $e2, $1c, $00, $80, $e0, $20, $60, $60, $7f, $ea, $8a, $82, $00, $04, $04, $06, $07, $89, $f8, $04, $02, $fe 
	.byte	$00, $c0, $40, $40, $40, $c0, $c0, $c0, $40, $c0, $40, $40, $40, $40, $40, $c0, $80, $a0, $ff, $00, $20, $3f, $20, $20, $20, $20, $e0, $20, $20, $20, $20, $20, $20, $20, $10, $c8, $ff, $80, $80, $ff 
	.byte	$04, $0e, $ff, $07, $07, $ef, $1f, $1e, $00, $00, $00, $00, $00, $80, $40, $c0 

RyuKick			; code 48
	.byte	$00, $03, $02, $04, $04, $07, $07, $ff, $fc, $1c, $3c, $76, $62, $06, $09, $01, $01, $06, $08, $08, $18, $3c, $3f, $39, $39, $39, $19, $0f, $00, $00, $00, $00
	.byte	$fe, $01, $00, $00, $00, $ff, $ff, $ff, $00, $71, $1a, $1a, $00, $00, $3c, $01, $c1, $3e, $00, $00, $80, $80, $c0, $e0, $a0, $9f, $8f, $8b, $0a, $0a, $08, $08, $08, $08, $08, $08, $0f, $08, $08, $0f 
	.byte	$00, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $87, $8f, $bf, $a7, $67, $6f, $af, $3e, $21, $12, $1c, $38, $70, $e0, $81, $06, $88, $90, $a0, $40, $40, $40, $40, $40, $40, $e0, $10, $08, $f8 
	.byte	$00, $00, $00, $00, $03, $05, $09, $11, $31, $59, $89, $09, $09, $1f, $20, $40, $80, $00, $00, $00, $00, $00, $00, $00


RyuBlock		; code 65
	.byte	$00, $00, $00, $00, $00, $00, $00, $03, $03, $00, $00, $00, $00, $00, $00, $00
	.byte	$01, $06, $04, $08, $08, $0f, $0f, $ff, $f8, $38, $78, $ec, $c4, $04, $06, $02, $02, $01, $03, $04, $08, $08, $08, $04, $06, $02, $03, $02, $02, $02, $04, $04, $04, $04, $0c, $0e, $13, $10, $10, $1f 
	.byte	$fc, $03, $01, $01, $01, $ff, $ff, $ff, $01, $e3, $35, $35, $01, $01, $79, $03, $07, $06, $8b, $70, $00, $00, $1f, $e0, $00, $00, $ff, $28, $28, $08, $00, $10, $10, $18, $1c, $27, $e3, $12, $0a, $fb 
	.byte	$00, $00, $00, $00, $00, $00, $00, $00, $00, $3e, $76, $77, $77, $67, $7f, $7f, $d7, $f2, $c2, $02, $0c, $10, $e0, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $40, $20, $fc, $02, $01, $ff 

	
	
KenStand		; code 82
	.byte 	$00, $00, $00, $00, $00, $00, $03, $03, $03, $03, $03, $03, $01, $00, $00, $00, $00, $00, $00, $01, $03, $02, $02, $03 
	.byte	$07, $08, $08, $18, $30, $60, $60, $60, $69, $76, $20, $38, $14, $14, $14, $10, $10, $18, $2c, $6e, $8f, $e4, $24, $1c, $3c, $4c, $6c, $2f, $fc, $fc, $08, $18, $10, $30, $f0, $8f, $80, $00, $00, $ff 
	.byte	$fc, $04, $03, $03, $00, $00, $00, $00, $68, $94, $04, $76, $c2, $c2, $c2, $02, $0a, $f3, $04, $04, $f8, $88, $88, $90, $a0, $40, $00, $ff, $14, $14, $04, $00, $30, $30, $48, $cf, $84, $84, $84, $87 
	.byte	$00, $00, $80, $80, $c0, $40, $40, $20, $20, $20, $20, $20, $20, $20, $20, $20, $60, $a0, $30, $48, $84, $9c, $92, $f2, $f2, $fa, $fa, $f2, $fc, $fc, $20, $20, $20, $30, $3c, $c6, $07, $01, $01, $ff 

KenStep			; code 100
	.byte	$00, $00, $00, $00, $00, $00, $03, $03, $03, $03, $03, $03, $01, $00, $00, $00, $00, $00, $00, $01, $03, $02, $02, $03 
	.byte	$07, $08, $08, $18, $30, $60, $60, $60, $69, $76, $20, $38, $14, $14, $14, $10, $10, $18, $2c, $6e, $8f, $e4, $24, $1c, $3c, $4c, $6c, $2f, $fc, $fc, $08, $18, $10, $30, $f1, $8f, $87, $04, $04, $ff 
	.byte	$fc, $04, $03, $03, $00, $00, $00, $00, $68, $94, $04, $76, $c2, $c2, $c2, $02, $0a, $f3, $04, $06, $f9, $98, $9b, $92, $be, $5e, $1f, $ff, $3e, $1f, $1f, $01, $c1, $c1, $21, $df, $81, $01, $01, $ff 
	.byte	$00, $00, $80, $80, $c0, $40, $40, $20, $20, $20, $20, $20, $20, $20, $20, $20, $60, $40, $60, $80, $00, $80, $80, $40, $40, $40, $40, $40, $40, $80, $00, $00

KenPunch		; code 117
	.byte	$00, $00, $00, $00, $00, $00, $7f, $ff, $ff, $ff, $c6, $ff, $00, $00, $00, $00
	.byte	$00, $00, $01, $03, $06, $06, $07, $02, $03, $01, $01, $01, $01, $00, $00, $f1, $9e, $80, $00, $ff, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $03, $0e, $18, $10, $1f 
	.byte	$7f, $80, $80, $00, $00, $96, $69, $00, $87, $4c, $4c, $4c, $00, $cf, $e0, $bf, $11, $11, $12, $9c, $7f, $ff, $f7, $c6, $ff, $80, $80, $80, $ff, $85, $85, $81, $84, $84, $0a, $fb, $0c, $08, $08, $ff 
	.byte	$c0, $38, $38, $0c, $04, $82, $42, $42, $62, $22, $22, $26, $b8, $60, $40, $b0, $08, $04, $04, $22, $c1, $a1, $92, $14, $f8, $08, $08, $08, $f8, $08, $08, $08, $08, $08, $08, $f8, $08, $08, $08, $f8 

KenKick			; code 134
	.byte	$00, $00, $00, $00, $c0, $a0, $90, $88, $8c, $9a, $91, $90, $f0, $08, $04, $02, $01, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $01, $03, $03, $03, $01, $01, $00, $00, $00, $f0, $fc, $e2, $e1, $f7, $f4, $7c, $84, $48, $38, $1c, $0e, $07, $81, $40, $20, $12, $0a, $06, $02, $02, $02, $02, $02, $07, $08, $10, $1f 
	.byte	$3f, $40, $c0, $80, $00, $4b, $b4, $00, $c3, $a6, $a6, $a6, $80, $67, $70, $df, $12, $24, $28, $30, $01, $01, $03, $07, $05, $f9, $f1, $d1, $50, $50, $10, $10, $10, $10, $10, $10, $f0, $10, $10, $f0 
	.byte	$e0, $18, $1c, $06, $02, $41, $a1, $21, $b1, $11, $11, $13, $5c, $b0, $20, $e0, $10, $10, $10, $10, $18, $3c, $fc, $9c, $9c, $9c, $98, $f0, $00, $00, $00, $00

KenBlock		; code 151
	.byte	$00, $00, $00, $00, $01, $7d, $7d, $f4, $f4, $e4, $fc, $fc, $f4, $74, $44, $44, $47, $40, $40, $3f, $00, $00, $00, $00, $00, $00, $00, $00, $03, $06, $04, $07 
	.byte	$1f, $20, $60, $c0, $80, $a5, $da, $80, $e1, $53, $53, $53, $40, $33, $38, $6f, $84, $04, $04, $e7, $1f, $3f, $3d, $31, $3f, $20, $20, $20, $3f, $21, $21, $20, $21, $21, $42, $fe, $83, $02, $02, $ff 
	.byte	$f0, $0e, $0e, $03, $01, $a0, $50, $10, $d8, $08, $08, $09, $2e, $d8, $10, $ec, $42, $41, $81, $08, $f0, $e8, $e4, $85, $fe, $02, $02, $02, $fe, $42, $42, $42, $02, $02, $82, $fe, $02, $02, $02, $fe 
	.byte	$00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $00, $00, $00, $00, $00, $00, $00, $80, $40, $40, $80, $00

emptySpace		; code 168										
	.byte	$00, $00, $00, $00, $00, $00, $00, $00

lifebarCodes	; code 169
	.byte	$7f, $80, $80, $80, $80, $80, $80, $7f 
	.byte	$7f, $80, $bb, $bb, $bb, $bb, $80, $7f 
	.byte	$ff, $00, $00, $00, $00, $00, $00, $ff 
	.byte	$ff, $00, $bb, $bb, $bb, $bb, $00, $ff 
	.byte	$fe, $01, $01, $01, $01, $01, $01, $fe 
	.byte	$fe, $01, $bb, $bb, $bb, $bb, $01, $fe 
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	


	
	
	
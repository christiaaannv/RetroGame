

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


P1LIFEBARSTART			.equ	#7680	
P2LIFEBARSTART			.equ	#7695
P1LIFEBARCOLORSTART		.equ	#38400
P2LIFEBARCOLORSTART		.equ	#38415

P1ROUNDWINSSTART		.equ	#7746	
P2ROUNDWINSSTART		.equ	#7761
P1ROUNDWINSCOLORSTART	.equ	#38466
P2ROUNDWINSCOLORSTART	.equ	#38481


PRINTROUNDSTART			.equ	#7841
PRINTROUNDCOLORSTART	.equ	#38561


DEBUGSCR1				.equ	$1E00
DEBUGSCR2				.equ	$1E02
DEBUGSCR3				.equ	$1E04
DEBUGSCR4				.equ	$1E06


DEBUGSCR5				.equ	$1FD0
DEBUGSCR6				.equ	$1FD2
DEBUGSCR7				.equ	$1FD4
DEBUGSCR8				.equ	$1FD6

DEBUGSCR9				.equ	$1FD8
DEBUGSCR10				.equ	$1FDA
DEBUGSCR11				.equ	$1FDC
DEBUGSCR12				.equ	$1FDE


DEBUGSCRA				.equ	$1E16
DEBUGSCRB				.equ	$1E18
DEBUGSCRC				.equ	$1E1A
DEBUGSCRD				.equ	$1E1C



main

;	lda		#128
;	sta		$028A
	

	ldx		#$08
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


	; Init Music
	lda		#$51		; D1 with high bit off (gets toggled on/off in irq)
	sta		SPEAKER2


	lda		#$04
	sta		VOLUME
	
	lda		#$80
	sta		ram_02
	
	lda		#0
	sta		ram_01

	lda		#6
	sta		ram_00
	; Finish Init Music

	
	lda		#32
	sta		emptySpaceCode

	ldx		#2
	jsr		fillScreen

	jsr		drawStreetFighterBanner

	
nebro
	jsr		getInput
	cmp		#1
	bne		nebro


	lda		#154
	sta		emptySpaceCode

	
	
	lda		#$FE					; load code for telling vic chip where to look for character data (this code is hardwired and tells it to look at 6144)
	sta		$9005					; store in Vic chip
	
	
	; store where top left of fighter is in screen memory into ram locations (basically represents x,y coordinates)
	ldx		#$7A
	stx		p1XPos
	ldx		#$1f
	stx		p1YPos


	; store where top left of opponent is in screen memory into ram locations (basically represents x,y coordinates)
	ldx		#$84
	stx		p2XPos
	ldx		#$1f
	stx		p2YPos	


	ldx		#1
	jsr		fillScreen

	jsr		initColors
	jsr		initRoundIndicators


	lda		#6
	sta		p1Color
	
	lda		#4
	sta		p2Color
	
	lda		#20
	sta		aiDodgeRand				; the higher this is, the more likely ai will move right when struck
	lda		#60
	sta		aiBlockRand				; the higher this is, the more likely ai will block successfully
	lda		#40
	sta		aiStrikeRand			; the higher this is, the more likely ai will strike when in range
	lda		#12
	sta		currentLevelTimeOut		; the lower this is, the faster ai will make decisions

	
	
	lda		#1
	sta		currentRound
	sta		drawRoundBanner
	
	
mainLoop	SUBROUTINE

	lda		drawRoundBanner
	beq		.skip

	jsr		drawCurrentRound

	
.skip
	jsr		checkRoundWin


	jsr		clearInputBufferB
	jsr		getInput
	sta		userPress
	jsr		doUserAction

	jsr		checkP1Struck
	jsr		checkP2Struck
	
	jsr		getAINextAction
	jsr		doAIAction


	jsr		updateHUD
	jsr		drawLifebars
	

	jsr		checkMatchWin

	
	
	jmp		mainLoop


	
	
	
	
	
	


	
; Can probably combine checkP1Struck and checkP2Struck by adding a little something something.
; RAM values for attackerIsStriking, defenderIsBlocking
checkP1Struck	SUBROUTINE

	lda		p2IsStriking		; if p2 is not striking, don't update the p2WasStruck state
	beq		.end

	ldx		#0					

	lda		p2XPosPrev		
	sec
	sbc		p1XPosPrev
	cmp		#4					; check if within striking range
	bne		.setStruckState		; if not, set p1WasStruck to 0 - false
	
	
.wasP1Struck	
	lda		p1Action			; check if p1 was blocking during the strike
	cmp		#3
	beq		.setStruckState
	ldx		#1

.setStruckState
	stx		p1WasStruck
	jmp		.end

	

.end
	rts

	
	
	
	
	
	
	
	
; Continually sets p2WasStruck each iteration of the game loop
; p2WasStruck is consumed when the p1 strike animation ends, so if p2 blocked
; or moved during the animation, they will avoid the strike from p1
checkP2Struck	SUBROUTINE

	lda		p1IsStriking		; if p1 is not striking, don't update the p2WasStruck state
	beq		.end

	ldx		#0					

	lda		p2XPosPrev		
	sec
	sbc		p1XPosPrev
	cmp		#4					; check if within striking range
	bne		.setStruckState
	
	
.wasP2Struck	
	lda		p2Action			; check if p2 was blocking during the strike
	cmp		#3
	beq		.setStruckState
	ldx		#1

.setStruckState
	stx		p2WasStruck


.end
	rts	
	
	
	
	
	
	
	
checkRoundWin	SUBROUTINE
	
.checkP1
	lda		p1LifeBarTicks
	bne		.checkP2

	ldx		#0
.top1
	lda		p2RoundWins,x
	inx
	cmp		#1
	beq		.top1

	dex
	lda		#1
	sta		p2RoundWins,x
	sta		drawRoundBanner
	jsr		initLifebars
	jmp		.end

	
.checkP2
	lda		p2LifeBarTicks
	bne		.end

	ldx		#0
.top2
	lda		p1RoundWins,x
	inx
	cmp		#1
	beq		.top2

	dex
	lda		#1
	sta		p1RoundWins,x
	sta		drawRoundBanner
	jsr		initLifebars

	
.end
	rts
	
	






checkMatchWin		SUBROUTINE

	ldx		#3
	lda		p1RoundWins,x
	beq		.checkP2Win

	
	lda		#1
	sta		p1WonMatch
	sta		currentRound
	jsr		initRoundIndicators
	jsr		initLifebars
	jsr		wait
	jsr		wait
	jmp		.end

	
.checkP2Win	
	ldx		#3
	lda		p2RoundWins,x
	beq		.end

	lda		#1
	sta		p2WonMatch
	sta		currentRound
	jsr		initRoundIndicators
	jsr		initLifebars
	jsr		wait
	jsr		wait

	
.end
	rts



	
; initialize life bars to full health for both players
initLifebars		SUBROUTINE	

	lda		#2
	ldy		#6
.loop1
	
	sta		p1LifeBarTicks,y
	sta		p2LifeBarTicks,y
	dey
	bpl		.loop1
	
	
	rts
	


; initialize round win indicators to 0 rounds won for both players	
initRoundIndicators		SUBROUTINE
	
	
	lda		#0
	ldy		#3
.loop2
	
	sta		p1RoundWins,y
	sta		p2RoundWins,y
	dey
	bpl		.loop2
	
	
	rts
	
	


	
	
	
; update the HUD with respect to the current game state	
updateHUD		SUBROUTINE


.updateP1HealthBar
	lda		p2Action				; when the animation timer resets p2Action,...
	bne		.updateP2HealthBar
	lda		p1WasStruck				; check if p1 blocked or dodged during that action (if it was a strike)
	beq		.updateP2HealthBar
	
;	lda		#5
;	sta		p1Action
;	lda		#4
;	sta		p1AnimTimer
;	lda		#$B3
;	sta		SPEAKER3
;	adc		#$43
;	sta		SPEAKER4

	
	ldy		#6
.loop1
	
	ldx		p1LifeBarTicks,y
	beq		.skip1

	dex
	txa
	sta		p1LifeBarTicks,y
	lda		#0
	sta		p1WasStruck
	
	lda		emptySpaceCode
	sta		P1LIFEBARSTART,y

	
	
	jmp		.updateP2HealthBar
	
.skip1	
	dey
	bpl		.loop1

	
	
.updateP2HealthBar	
	lda		p1Action				; when the animation timer resets p1Action,...
	bne		.roundStatistics
	lda		p2WasStruck				; ...update p2 health if p2Was struck.
	beq		.roundStatistics

	
;	lda		#5
;	sta		p1Action
;	lda		#4
;	sta		p1AnimTimer
;	lda		#$B3
;	sta		SPEAKER3
;	adc		#$43
;	sta		SPEAKER4
	
	
	ldy		#6
.loop2
	
	ldx		p2LifeBarTicks,y
	beq		.skip2
	
	dex
	txa
	sta		p2LifeBarTicks,y
	lda		#0
	sta		p2WasStruck
	
	lda		emptySpaceCode
	sta		P2LIFEBARSTART,y
	
	jmp		.roundStatistics

.skip2	
	dey
	bpl		.loop2
	

	
.roundStatistics

	
	ldx		#3
	ldy		#6
.loop3
	lda		p1RoundWins,x
	beq		.empty1

	lda		#170
	jmp		.draw1
	
.empty1
	lda		#169

.draw1
	sta		P1ROUNDWINSSTART,y
	dey
	dey
	dex
	bpl		.loop3

	
	
.p2Stats
	ldx		#3
	ldy		#0
.loop4
	lda		p2RoundWins,x
	beq		.empty2

	lda		#170
	jmp		.draw2
	
.empty2
	lda		#169

.draw2
	sta		P2ROUNDWINSSTART,y
	iny
	iny
	dex
	bpl		.loop4



	
	
.end	
	rts



	
	
	
	
	
	
	

initColors		SUBROUTINE


	ldy		#6
	lda		#5						; set the life bars to green
.loop1
	
	sta		P1LIFEBARCOLORSTART,y
	sta		P2LIFEBARCOLORSTART,y
	
	dey
	bpl		.loop1


	ldy		#6
	lda		#7						; set the round indicators to yellow
.loop2
	
	sta		P1ROUNDWINSCOLORSTART,y
	sta		P2ROUNDWINSCOLORSTART,y
	
	dey
	bpl		.loop2
	
	

	rts
	
	
	
	
	
	
	
	
	
	
	

drawLifebars	 SUBROUTINE

	clc										
										
	lda		#155					; load the left lifebar graphic code (empty version)
	adc		p1LifeBarTicks			; add the number of ticks remaining in the leftmost lifebar
	sta		P1LIFEBARSTART			; store in screen memory

	lda		#155
	adc		p2LifeBarTicks
	sta		P2LIFEBARSTART

	
	ldy		#1						; start at 1 since the first section is a different graphic	
.loop1								; run loop for 5 middle lifebar sections
	
	lda		#158					; load the middle lifebar graphic code (empty version)
	adc		p1LifeBarTicks,y		; add the number of life ticks remaining in that section
	sta		P1LIFEBARSTART,y		; store in screen memory

	lda		#158					; load the middle lifebar graphic code (empty version)
	adc		p2LifeBarTicks,y		; add the number of life ticks remaining in that section
	sta		P2LIFEBARSTART,y		; store in screen memory
	
	iny
	cpy		#6
	bne		.loop1

	clc
	
	lda		#161					; load the right lifebar graphic code (empty version)
	adc		p1LifeBarTicks,y		; add the number of life ticks remaining in that section
	sta		P1LIFEBARSTART,y		; store in screen memory
					
	lda		#161					; load the right lifebar graphic code (empty version)
	adc		p2LifeBarTicks,y		; add the number of life ticks remaining in that section
	sta		P2LIFEBARSTART,y		; store in screen memory

	
	rts
	



	
	
	
	
doUserAction		SUBROUTINE
;p1Action				0 = nothing
;						1 = kick
;						2 = punch
;						3 = block
;						4 = step
;						5 = was struck
;						6 = flying kick

	
	lda		p1Action		; If not 0, p1 is mid animation, do not process input (set to 0 when anim timer reaches 0)
	beq		.drawUserDefault
	
	cmp		#3
	beq		.checkContinueBlock
	rts

.checkContinueBlock	
	lda		userPress
	cmp		#1
	bne		.notContinued
	lda		#16
	sta		p1AnimTimer
	
.notContinued	
	rts

	
.drawUserDefault	
	lda		#0
	sta		p1IsBlocking
	sta		p1IsStriking


	lda		#0				; draw fighter graphic starting from p1 code 0
	sta		drawCode
	lda		<#RyuStandMask
	sta		$05
	lda		>#RyuStandMask
	sta		$06

	lda		p1XPos
	sta		drawXPos
	jsr		drawFighterB

	
.checkPunch
	lda		userPress
	bne		.checkBlock

.doPunchAnimation
	lda		#30
	sta		drawCode
	lda		<#RyuPunchMask
	sta		$05
	lda		>#RyuPunchMask
	sta		$06

	lda		#2
	sta		p1Action
	
	lda		#1
	sta		p1IsStriking
	jmp		.draw


.checkBlock
	cmp		#1
	bne		.checkKick
	
.doBlockAnimation	
	lda		#59
	sta		drawCode
	lda		<#RyuBlockMask
	sta		$05
	lda		>#RyuBlockMask
	sta		$06

	lda		#3
	sta		p1Action

	lda		#1
	sta		p1IsBlocking
	jmp		.draw

	
.checkKick
	cmp		#4
	bne		.checkLeft

	
.doKickAnimation
	lda		#44
	sta		drawCode
	lda		p1XPos
	sta		drawXPos
	lda		<#RyuKickMask
	sta		$05
	lda		>#RyuKickMask
	sta		$06

	lda		#1
	sta		p1Action
	
	lda		#1
	sta		p1IsStriking
	jmp		.draw
	
	
.checkLeft	
	cmp		#$02			; was left pressed
	bne		.checkRight
.tryLeft
	lda		p1XPos
	cmp		#$78			; is p1 at left edge of screen
	bpl		.moveLeft		; if not, move left
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
	cmp		p2XPos			; is p1 at p2?
	bne		.moveRight		; if so, no movement right
	rts
.moveRight
	lda		p1XPos
	sta		drawXPos
	jsr		clearFighter	; otherwise, clear p1
	inc		p1XPos			; make new p1 position 1 column to right
	

	
.doStepAnimation
	lda		#15			; draw fighter graphic starting from p1 code 16
	sta		drawCode
	lda		<#RyuStepMask
	sta		$05
	lda		>#RyuStepMask
	sta		$06

	lda		#4
	sta		p1Action

	
	
.draw

	lda		p1XPos
	sta		drawXPos
	jsr		clearFighter
	jsr		drawFighterB

	lda		#16			
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
	cmp		aiDodgeRand
	bpl		.wasntStruckLastFrame		; act as if he wasn't struck if the weighted random to move right fails
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
	cmp		aiBlockRand
	bpl		.notBeingStruck				; If random block fails, store state vars and act as if not being struck
	
	lda		#3
	sta		p2Action
	rts

.notBeingStruck
	lda		p2XPos
	sec
	sbc		p1XPos						; If within striking range, random chance to strike
	cmp		#5
	bpl		.notWithinRange

	jsr		rand
	cmp		aiStrikeRand
	bpl		.notWithinRange				; If random strike chance fails, act as if not within striking range

.newRand1
	jsr		rand						; Randomize punch/kick
	cmp		#30
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
	cmp		#4
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
	
	
	
	
	
	
	
; Can shorten reasonably well
; better to do this once we decide if we are adding more characters
; instead of loading and storing the appropriate mask every time, load it once at the beginning
; then, knowing that each mask is 3 bytes long, add the appropriate offset to the lower half of
; the address (will work as long as the masks don't cross a page boundary) 
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

	
.drawP2Default	
	lda		#0
	sta		p2IsBlocking


	lda		#73			; draw fighter graphic starting from character code 0
	sta		drawCode
	lda		<#KenStandMask
	sta		$05
	lda		>#KenStandMask
	sta		$06

	lda		p2XPos
	sta		drawXPos
	jsr		drawFighterB	
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

	lda		#123			; draw fighter kick graphic starting from character code 134
	sta		drawCode
	lda		<#KenKickMask
	sta		$05
	lda		>#KenKickMask
	sta		$06

	jmp		.draw

	
.checkPunch
	cmp		#2
	bne		.checkBlock

	lda		#1
	sta		p2IsStriking
	
	lda		#106			; draw fighter punch graphic starting from character code 117
	sta		drawCode
	lda		<#KenPunchMask
	sta		$05
	lda		>#KenPunchMask
	sta		$06

	jmp		.draw
	
.checkBlock
	cmp		#3
	bne		.checkDirection

	lda		#1
	sta		p2IsBlocking

	lda		#139			; draw fighter block graphic starting from character code 151
	sta		drawCode
	lda		<#KenBlockMask
	sta		$05
	lda		>#KenBlockMask
	sta		$06

	jmp		.draw

	
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

	
	dec		p2XPos					; make new p2 position 1 column to left
	jmp		.doStepAnimation	

			
	
.checkRight	
	cmp		#3
	bne		.end

	lda		p2XPos
	cmp		#$89					; is p2 at right edge of screen
	beq		.end					; if so, no movement right
	
	lda		p2XPos
	sta		drawXPos
	jsr		clearFighter			; otherwise, clear p2

	
	inc		p2XPos					; make new p2 position 1 column to right
	
	
	
.doStepAnimation
	lda		#89					; draw fighter step graphic starting from character code 100
	sta		drawCode
	lda		<#KenStepMask
	sta		$05
	lda		>#KenStepMask
	sta		$06



.draw

	lda		p2XPos
	sta		drawXPos
	jsr		clearFighter		
	jsr		drawFighterB

	lda		#16						
	sta		p2AnimTimer	

	
	lda		currentLevelTimeOut
	sta		aiTimeOut

.end
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
	
	
	
	
; don't really need this routine
; just jsr GETIN and use the value provided to determine actions

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
; drawYPos must hold the upper byte of the address in screen memory for the top left cell of the character (future - jumpn')
; drawCode must hold the character code to begin printing from (depends on the fighter's animation frame)
; zero page $05 and $06 must hold the address of the draw mask to use for the fighter graphic


drawFighterB		SUBROUTINE


	lda		drawCode		; use the current draw code to choose character color
	tax						; transfer to x for later
	cmp		#73				; might not work so well with more than two characters
	bpl		.itsP2
	lda		p1Color
	sta		drawColor
	jmp		.drawTop

.itsP2
	lda		p2Color
	sta		drawColor


.drawTop	

	ldy		#0				; load the mask for the first 2 rows of the fighter graphic
	lda		($05),y
	sta		columnMask
	ldy		drawXPos		; load the offset from SCREENMEMORY2 to begin drawing the fighter graphic
	lda		#6		
	sta		ram_03			; nRows per fighter graphic

.loop1Init
	lda		#4
	sta		ram_04			; nColumns per row Row

.loop1
	lda		columnMask		; test if the current cell is blank or not
	clc
	asl
	sta		columnMask
	bcc		.empty			; if so, fill with empty space
	
	txa						; otherwise, transfer the drawCode into a
	inx						; increment character code for next iteration
	jmp		.skipEmpty
	
.empty	
	lda		emptySpaceCode	; load the empty space code
	
	
.skipEmpty
	sta		SCREENMEMORY2,y	; store screen code in screen memory offset by y
	lda		drawColor
	sta		COLORCONTROL2,y	; store color code in color control offset by y
	iny						; increment current offset for each cell drawn

	dec		ram_04			; decrement nColumns left in current row
	bne		.loop1			; if not done, do next cell in current row

	tya
	clc
	adc		#18				; currentOffset = currentOffset + (nColumnsInScreen(22) - nColumnsInGraphic(4))
	tay						; move back into y
	
	dec		ram_03			; decrement number of rows left in fighter graphic
	beq		.return			; if 0 rows left, we're done drawing
	lda		ram_03
	clc
	lsr						; test if it's odd (each column mask covers 2 rows, so ..
	bcs		.loop1Init		; ..if odd, print next row with second half of same mask)

	sty		ram_06			; save current offset in ram
	inc		$05				; otherwise...
	ldy		#0				; use for indirect indexed addressing
	lda		($05),y			; load the next mask
	sta		columnMask
	ldy		ram_06			; restore current offset
	jmp		.loop1Init		; draw next two rows
	
	
	
.return	
	rts	

		

	
columnMask
	.byte		$00

	




	
clearFighter	 SUBROUTINE		
; draws blank spaces over the fighter	
; the position of the leftmost cell of the player must be stored in drawXPos before calling this function
	
	ldy		drawXPos
	ldx		#6
	
.initLoop1
	lda		#4			; nColumns
	sta		ram_04
	lda		emptySpaceCode
	

.loop1
	sta		SCREENMEMORY2,y		; store screen codes in screen memory where character currently resides, offset by y

	iny
	dec		ram_04
	bne		.loop1

	dex
	beq		.end
	
	tya
	clc
	adc		#18					; add 18 to move to next column (22 columns on screen - 4 columns in fighter graphic)
	tay
	jmp		.initLoop1
	
.end	
	rts	
	
	
	
	
	
	
	
	
drawStreetFighterBanner		SUBROUTINE	


	lda		#0
	sta		ram_04						; loop control for drawing all letter graphics

	lda		<#SCREENMEMORY1				; store the address of screen memory in zero page
	sta		$03
	lda		>#SCREENMEMORY1
	sta		$04

	
	
.outerTop	
	ldy		ram_04
	lda		startScreenLayout,y			; load then store low half of address of next graphic to draw
	sta		$01
	iny
	lda		startScreenLayout,y			; load then store high half of address of next graphic to draw
	sta		$02
	iny
	lda		startScreenLayout,y			; load the offset in screen memory to begin drawing graphic
	tax
	sta		ram_09
		
		ldy		#0
		lda		($01),y					; load the number of rows in graphic
		sta		ram_05					; loop control variable
		inc		$01
	
		lda		($01),y					; load the number of columns in graphic
		sta		ram_06					; inner loop control variable
		sta		ram_07					; store the number of columns to init inner loop control variable each row
		inc		$01
		
.innerTop
		ldy		#0
		lda		($01),y					; load screen code to draw for this cell
		ldy		ram_09					; load the current offset into 'y'
		sta		($03),y					; store in screen memory offset by 'y'
		inc		$01
		inc		ram_09					; increment the current offset
		dec		ram_06					; decrement the loop control variable
		bne		.innerTop
			
		lda		#22						; skip 22 - nColumns cells on screen to move to next row
		sec
		sbc		ram_07					; 22 - nColumns
		sta		ram_08					; store to add to current offset
		lda		ram_09					; load the current offset into 'a'
		clc
		adc		ram_08					; currentOffset = currentOffset + (22 - nColumns)
		sta		ram_09					; save the new offset for drawing the next row
			
		lda		ram_07					; load nColumns
		sta		ram_06					; store in loop control variable
		dec		ram_05					; decrement n rows left to draw
		bne		.innerTop				; if not 0, go to top

		inc 	ram_04					; increment once to skip low address of next letter graphic to draw
		inc		ram_04					; increment once to skip high address of next letter graphic to draw
		inc		ram_04					; increment once to skip offset in screen memory to begin drawing at

		jsr		wait
		
		lda		ram_04
		cmp		#39						; if not 39 (STREET FIGHTER).length() == 13 * 3 bytes of info per entry
										; (see startScreenLayout)
		bmi		.outerTop				; go to top
		
		
		cmp		#42
		beq		.printInstructions

		
		lda		<#SCREENMEMORY2				; store the address of screen memory in zero page
		sta		$03							; this is done outside of the loop because the V is drawn in the bottom
		lda		>#SCREENMEMORY2				; of the screen and the offset from SCREENMEMORY1 is greater than 255
		sta		$04
		jmp		.outerTop

		

.printInstructions
	ldx		#19
	ldy		#249
.loop    
	lda		startGameString,x

	sta		SCREENMEMORY2,y
	
	dey
	dex
	bpl		.loop
	rts

	
	rts


	
	
	
	
	
	
drawCurrentRound			SUBROUTINE


	ldx		#164
	ldy		#0
	sty		drawRoundBanner
	
.loop
	txa
	sta		PRINTROUNDSTART,y
	lda		#2
	sta		PRINTROUNDCOLORSTART,y

	iny
	inx
	cpy		#5
	bne		.loop


	lda		currentRound
	clc
	adc		#171
	
	ldy		#7
	sta		PRINTROUNDSTART,y
	lda		#2
	sta		PRINTROUNDCOLORSTART,y
	
	
	inc 	currentRound
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		eraseCurrentRound

	

	rts


	
	

	
	
eraseCurrentRound			SUBROUTINE

	lda		emptySpaceCode
	ldy		#8
	
.loop
	sta		PRINTROUNDSTART,y

	dey
	bpl		.loop

	
	rts

	

	
	
	
wait				SUBROUTINE
	lda		ACR
	and		#$DF		; set timer to operate in 1 shot mode		
	sta		ACR
	
	ldy		#3

.top	
	lda		#$00
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$FF
	sta		T2HIGH		; store high order byte of timer (also starts the countdown)
		
.loop 
    lda		T2HIGH
	and		#$FF
    bne		.loop

	dey
	bne		.top
	
	rts
	
	
	
	
	
	
	
	
	
;	ORG		$1D00		; 256 bytes before where screen memory starts
irqHandler

	
	dec		ram_00
	beq		.beginMusic
	jmp		.skipMusic

.beginMusic	
	lda		#6
	sta		ram_00		; reset the counter
	
	lda		SPEAKER2	; flip the msb to toggle repeating F on or off
	eor		#$80
	sta		SPEAKER2

	
	lda		p1Action
	cmp		#5
	beq		.dropTheBass

	lda		p2ScreamTimer
	cmp		#5
	beq		.dropTheBass

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
;	lda		#$D1			; change to alter the repeating note
;	sta		SPEAKER2
	ldx		#0
	jmp		.bass

.continue1
	cpy		#32
	bne		.continue2
;	lda		#$D1			; change to alter the repeating note
;	sta		SPEAKER2
	ldx		#1
	jmp		.bass
	
.continue2
	cpy		#64
	bne		.continue3
;	lda		#$C7			; change to alter the repeating note
;	sta		SPEAKER2
	ldx		#2
	jmp		.bass
	
.continue3
	cpy		#96
	bne		.increment
;	lda		#$BB			; change to alter the repeating note
;	sta		SPEAKER2
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


	
	

	lda		p1Action
	cmp		#5
	bne		.checkP2Scream
	jmp		.playerScream
	
.checkP2Scream
	lda		p2ScreamTimer
	cmp		#5
	bne		.skipMusic
	jmp		.playerScream
	
	
.playerScream
	dec		SPEAKER3
	dec		SPEAKER3
	dec		SPEAKER3
	


	
	
.skipMusic	

	lda		IFR			; load the interrupt flag register
	
	and		#$20		; test if the 5th bit was set (timer 2 time out flag)
	beq		.notTimer

	
	dec		updateXPosPrevs				
	bne		.decP1AnimTimer
	
	lda		#8
	sta		updateXPosPrevs
	
	lda		p1XPos
	sta		p1XPosPrev
	lda		p2XPos
	sta		p2XPosPrev

	
; Reset animations in progress to default stance if their animation timer reaches 0
; decrement animTimers each timer interrupt

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
	.byte	$00
	

	

p1XPos				.byte	$00
p1XPosPrev			.byte	$00
p1XPosColor			.byte	$00
p1YPos				.byte	$00
p1Action			.byte	$00
p1AnimTimer			.byte	$00
p1Color				.byte	$00
p1Score				.byte	$00
p1ScreamTimer		.byte	$00


p2DrawCodesStart	.byte	#73
p2XPos				.byte	$00
p2XPosPrev			.byte	$00
p2XPosColor			.byte	$00
p2YPos				.byte	$00
p2Action			.byte	$00
p2AnimTimer			.byte	$00
p2Color				.byte	$00
p2Score				.byte	$00
p2ScreamTimer		.byte	$00



aiTimeOut			.byte	$00
aiDodgeRand			.byte	$00
aiBlockRand			.byte	$00
aiStrikeRand		.byte	$00

drawXPos			.byte	$00
drawCode			.byte	$00
drawColor			.byte	$00

currentRound		.byte	$00
roundsPerMatch		.byte	$00
drawRoundBanner		.byte	$00


updateXPosPrevs		.byte	$00


ram_00				.byte	$00		; used in irq handler, volatile
ram_01				.byte	$00		; used in irq handler, volatile
ram_02				.byte	$00		; used in irq handler, volatile
ram_03				.byte	$00		; used in drawFighter, usable in other routines
ram_04				.byte	$00		; used in drawFighter, usable in other routines
ram_05				.byte	$00		; used in drawFighter, usable in other routines
ram_06				.byte	$00		; used in drawStreetFighterBanner, usable in other routines
ram_07				.byte	$00		; used in drawStreetFighterBanner, usable in other routines
ram_08				.byte	$00		; used in drawStreetFighterBanner, usable in other routines
ram_09				.byte	$00		; used in drawStreetFighterBanner, usable in other routines
ram_10				.byte	$00		; not yet used ...
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
ram_23				.byte	$00		; ...


p1HitPoints			.byte	$00
p1IsStriking		.byte	$00
p1IsBlocking		.byte	$00
p1WasStruck			.byte	$00
p1WonMatch			.byte	$00

p2HitPoints			.byte	$00
p2IsStriking		.byte	$00
p2WasStruck			.byte	$00
p2IsBlocking		.byte	$00
p2WonMatch			.byte	$00

aiDir				.byte	$00
currentLevelTimeOut	.byte	$00		
		
distanceApart		.byte	$00
userPress			.byte	$00


p1RoundWins
	.byte		#0, #0, #0, #0
	
p2RoundWins
	.byte		#0, #0, #0, #0
	

p1LifeBarTicks
	.byte		#2, #2, #2, #2, #2, #2, #2		; change to use bit mask instead

p2LifeBarTicks
	.byte		#2, #2, #2, #2, #2, #2, #2		; change to use bit mask instead


	
startGameString
    .byte	#16, #18, #5, #19, #19, #32, #40, #19, #41, #32, #20, #15, #32, #6, #9, #7, #8, #20, #33, #33
	
	
startScreenLayout	; jump table for skipping to the next appropriate grapic in STREET FIGHTER graphics
					; [low of address for graphic], [high of address for graphic], [scr memory offset to draw at]
	.byte	<#S, >#S, #24
	.byte	<#T, >#T, #27
	.byte	<#R, >#R, #52
	.byte	<#E, >#E, #55
	.byte	<#E, >#E, #58
	.byte	<#T, >#T, #40
	
	.byte	<#F, >#F, #132
	.byte	<#I, >#I, #136
	.byte	<#G, >#G, #160
	.byte	<#H, >#H, #140
	.byte	<#T, >#T, #144
	.byte	<#E, >#E, #169
	.byte	<#R, >#R, #173
	
	.byte	<#V, >#V, #37



	
	ORG		#5951 ; -> page boundaries: 5888 [page] 6144
	
startScreenCodes	; [rows], [columns], [code0], [code1],... [code(rows*columns)]	-> 145 bytes
S
	.byte	#4, #2, #233, #223, #95, #118, #117, #223, #95, #105

T
	.byte	#4, #2, #103, #101, #122, #76, #80, #79, #103, #223

R
	.byte	#3, #2, #105, #95, #116, #32, #116, #32

E
	.byte	#3, #3, #233, #105, #95, #105, #111, #233, #223, #111, #111

F
	.byte	#4, #4, #106, #105, #119, #126, #106, #67, #73, #32, #106, #32, #32, #32, #106, #223, #32, #32

I
	.byte	#4, #1, #126, #97, #97, #97

G
	.byte	#4, #2, #105, #95, #223, #233, #32, #106, #111, #233

H
	.byte	#4, #4, #106, #32, #32, #32, #106, #20, #13, #32, #106, #32, #32, #32, #106, #105, #95, #32

	
V
	.byte	#7, #10, #95, #204, #32, #32, #32, #32, #32, #32, #250, #105, #32, #95, #223, #32, #32, #32, #32, #233, #105, #32
	.byte	#32, #32, #160, #32, #32, #32, #32, #160, #32, #32, #32, #32, #95, #223, #32, #32, #233, #105, #32, #32
	.byte	#32, #32, #32, #160, #32, #32, #160, #32, #32, #32, #32, #32, #32, #95, #223, #233, #105, #32, #32, #32
	.byte	#32, #32, #32, #32, #95, #105, #32, #32, #32, #32
	

	; make sure none of these cross a page boundary (unless aligned such that one mask ends right at a boundary)
	; zero page memory is used to reference these masks and inc $01 will wrap around to $0 if a page is crossed.

	; [bitmask for rows 1 & 2], [bitmask for rows 3 & 4], [bitmask for rows 5 & 6] 
	; the bitmask is used to draw empty cells where the fighter graphic had one, only non empty cells are stored
	; 30 bytes

RyuStandMask
	.byte		$07, $77, $77

RyuStepMask
	.byte		$07, $77, $77

RyuPunchMask
	.byte		$0E, $E7, $67

RyuKickMask
	.byte		$0C, $FF, $E6

RyuBlockMask
	.byte		$06, $77, $77


KenStandMask
	.byte		$0E, $EE, $EF

KenStepMask
	.byte		$07, $7F, $FE

KenPunchMask
	.byte		$07, $FF, $77

KenKickMask
	.byte		$07, $FF, $76

KenBlockMask
	.byte		$0E, $EF, $6E

	
	ORG		#6144		; forces our fighter graphics to begin where Vic is obtaining its character information from (character code 0 refers to the first 8 bytes starting at 6144, and so on)

RyuStand		; starts at code 0
	.byte	$00, $00, $00, $01, $01, $01, $01, $7f, $3f, $c0, $80, $00, $00, $ff, $ff, $ff, $80, $60, $20, $20, $20, $e0, $e0, $e0 
	.byte	$7f, $07, $0f, $1d, $18, $01, $02, $02, $00, $1c, $06, $86, $80, $80, $4f, $40, $20, $60, $a0, $a0, $20, $20, $20, $70 
	.byte	$06, $08, $08, $18, $3c, $3f, $39, $39, $20, $10, $1f, $80, $80, $80, $80, $80, $c8, $8c, $04, $0e, $9e, $fe, $ce, $4e 
	.byte	$39, $19, $0d, $01, $01, $01, $01, $01, $80, $80, $ff, $28, $28, $08, $00, $08, $5e, $de, $dc, $40, $40, $40, $40, $40 
	.byte	$02, $06, $0e, $1b, $31, $40, $40, $7f, $08, $08, $14, $14, $e3, $22, $22, $e3, $70, $10, $10, $3c, $e6, $01, $01, $ff  

RyuStep			; starts at code 15
	.byte	$00, $00, $00, $01, $01, $01, $01, $7f, $3f, $c0, $80, $00, $00, $ff, $ff, $ff, $80, $60, $20, $20, $20, $e0, $e0, $e0 
	.byte	$7f, $03, $3f, $3d, $00, $00, $00, $00, $00, $1c, $06, $86, $80, $80, $cf, $40, $20, $60, $a0, $a0, $20, $20, $20, $60 
	.byte	$00, $00, $01, $01, $01, $01, $03, $03, $40, $20, $ef, $00, $00, $00, $c0, $f0, $c0, $80, $78, $04, $04, $8c, $9c, $fe 
	.byte	$03, $03, $03, $01, $01, $00, $00, $00, $90, $bf, $b6, $ba, $f4, $88, $80, $82, $ce, $ce, $5e, $5e, $7c, $70, $10, $10 
	.byte	$00, $00, $01, $01, $02, $02, $02, $03, $82, $82, $82, $c3, $7d, $03, $01, $ff, $10, $10, $10, $3c, $e6, $01, $01, $ff 

RyuPunch		; starts at code 30
	.byte	$00, $00, $00, $00, $00, $00, $00, $1f, $0f, $30, $20, $40, $40, $7f, $7f, $ff, $e0, $18, $08, $08, $08, $f8, $f8, $f8
	.byte	$1f, $01, $03, $07, $06, $00, $00, $00, $c0, $c7, $c1, $61, $20, $20, $33, $10, $08, $18, $a8, $a8, $08, $08, $c8, $18
	.byte	$10, $08, $1c, $23, $60, $f0, $fc, $e4, $30, $38, $5f, $80, $04, $07, $04, $04, $04, $0e, $ff, $07, $07, $ef, $1f, $1e
	.byte	$ec, $ec, $6f, $7d, $11, $10, $20, $20, $04, $04, $fc, $44, $44, $44, $04, $84
	.byte	$20, $20, $60, $71, $9f, $80, $80, $ff, $c4, $c4, $a2, $39, $1f, $90, $50, $df, $00, $00, $00, $00, $e0, $10, $08, $f8 
	
RyuKick			; starts at code 44
	.byte	$00, $03, $02, $04, $04, $07, $07, $ff, $fc, $02, $01, $01, $01, $ff, $ff, $ff 
	.byte	$fc, $1c, $3c, $76, $62, $06, $09, $01, $00, $70, $1a, $1a, $00, $00, $3c, $01, $80, $80, $80, $87, $8f, $bf, $a7, $67, $00, $00, $00, $00, $03, $05, $09, $11 
	.byte	$01, $06, $08, $08, $18, $3c, $3f, $39, $c1, $3e, $00, $00, $80, $80, $c0, $e0, $6f, $af, $3e, $21, $12, $1c, $38, $70, $31, $59, $89, $09, $09, $1f, $20, $c0 
	.byte	$39, $39, $19, $0f, $00, $00, $00, $00, $a0, $9f, $8f, $8b, $0a, $0a, $08, $08, $e1, $83, $04, $88, $90, $a0, $40, $40
	.byte	$08, $08, $08, $08, $0f, $08, $08, $0f, $40, $40, $40, $40, $e0, $10, $08, $f8

RyuBlock		; starts at code 59
	.byte	$01, $06, $04, $08, $08, $0f, $0f, $ff, $fc, $03, $01, $01, $01, $ff, $ff, $ff
	.byte	$f8, $38, $78, $ec, $c4, $04, $06, $02, $01, $e3, $35, $35, $01, $01, $79, $03, $00, $3e, $76, $77, $77, $67, $7f, $7f 
	.byte	$02, $01, $03, $04, $08, $08, $08, $04, $07, $06, $8b, $70, $00, $00, $1f, $e0, $d7, $f2, $c2, $02, $0c, $10, $e0, $80 
	.byte	$06, $02, $03, $02, $02, $02, $04, $04, $00, $00, $ff, $28, $28, $08, $00, $10, $80, $80, $80, $80, $80, $80, $80, $80 
	.byte	$04, $04, $0c, $0e, $13, $10, $10, $1f, $10, $18, $1c, $27, $e3, $12, $0a, $fb, $80, $80, $40, $20, $fc, $02, $01, $ff 	
	
	
	
	
	
KenStand		; starts at code 73
	.byte	$01, $02, $02, $06, $0c, $18, $18, $18, $ff, $01, $00, $00, $00, $00, $00, $00, $00, $00, $e0, $e0, $30, $10, $10, $08
	.byte	$1a, $1d, $08, $0e, $05, $05, $05, $04, $5a, $a5, $01, $1d, $30, $30, $30, $00, $08, $08, $08, $88, $88, $88, $88, $88
	.byte	$04, $06, $0b, $1b, $23, $39, $c9, $c7, $02, $3c, $01, $81, $fe, $22, $22, $24, $98, $e8, $0c, $12, $22, $2e, $29, $39
	.byte	$cf, $d3, $db, $cb, $7f, $3f, $02, $06, $28, $10, $00, $ff, $05, $05, $01, $00, $39, $39, $39, $f9, $3d, $3f, $08, $08
	.byte	$04, $0c, $3c, $63, $e0, $80, $80, $ff, $0c, $0c, $12, $f3, $21, $21, $21, $e1, $08, $0c, $0f, $f1, $01, $00, $00, $ff, $00, $00, $00, $80, $c0, $40, $40, $c0

KenStep			; starts at code 89
	.byte	$07, $08, $08, $18, $30, $60, $60, $60, $fc, $04, $03, $03, $00, $00, $00, $00, $00, $00, $80, $80, $c0, $40, $40, $20 
	.byte	$69, $76, $20, $38, $14, $14, $14, $10, $68, $94, $04, $76, $c2, $c2, $c2, $02, $20, $20, $20, $20, $20, $20, $20, $20 
	.byte	$00, $00, $00, $00, $00, $00, $03, $03, $10, $18, $2c, $6e, $8f, $e4, $24, $1c, $0a, $f3, $04, $06, $f9, $98, $9b, $92, $60, $40, $60, $80, $00, $80, $80, $40 
	.byte	$03, $03, $03, $03, $01, $00, $00, $00, $3c, $4c, $6c, $2f, $fc, $fc, $08, $18, $be, $5e, $1f, $ff, $3e, $1f, $1f, $01, $40, $40, $40, $40, $40, $80, $00, $00 
	.byte	$00, $00, $00, $01, $03, $02, $02, $03, $10, $30, $f1, $8f, $87, $04, $04, $ff, $c1, $c1, $21, $df, $81, $01, $01, $ff

KenPunch		; starts at code 106
	.byte	$03, $04, $0c, $18, $30, $34, $3b, $10, $fe, $01, $01, $00, $00, $b4, $4a, $02, $00, $80, $c0, $60, $20, $10, $10, $10 
	.byte	$00, $00, $00, $00, $00, $00, $78, $ff, $1c, $0a, $0a, $0a, $08, $06, $07, $8d, $3b, $61, $61, $61, $05, $7b, $02, $fd, $10, $10, $10, $30, $c0, $00, $00, $80 
	.byte	$c0, $c8, $88, $7e, $03, $00, $00, $00, $f0, $00, $20, $10, $c3, $3f, $07, $06, $88, $88, $90, $e1, $fe, $fd, $38, $30, $40, $20, $10, $08, $04, $04, $88, $90 
	.byte	$07, $04, $07, $04, $04, $04, $04, $04, $ff, $00, $ff, $14, $14, $04, $30, $28, $e0, $20, $e0, $20, $20, $20, $20, $20 
	.byte	$04, $04, $08, $1f, $70, $c0, $80, $ff, $28, $24, $44, $c7, $48, $50, $50, $df, $10, $10, $10, $f0, $10, $10, $10, $f0  

KenKick			; starts at code 123
	.byte	$00, $00, $00, $01, $03, $03, $03, $01, $3f, $40, $c0, $80, $00, $4b, $b4, $00, $e0, $18, $1c, $06, $02, $41, $a1, $21 
	.byte	$00, $00, $00, $00, $c0, $a0, $90, $88, $01, $00, $00, $00, $f0, $fc, $e2, $e1, $c3, $a6, $a6, $a6, $80, $67, $70, $df, $b1, $11, $11, $13, $5c, $b0, $20, $e0 
	.byte	$8c, $9a, $91, $90, $f0, $08, $04, $03, $f7, $f4, $7c, $84, $48, $38, $1c, $0e, $12, $24, $28, $30, $01, $01, $03, $07, $10, $10, $10, $10, $18, $3c, $fc, $9c 
	.byte	$87, $81, $40, $20, $12, $0a, $06, $02, $05, $f9, $f1, $d1, $50, $50, $10, $10, $9c, $9c, $98, $f0, $00, $00, $00, $00 
	.byte	$02, $02, $02, $02, $07, $08, $10, $1f, $10, $10, $10, $10, $f0, $10, $10, $f0

KenBlock		; starts at code 139
	.byte	$00, $00, $00, $00, $01, $31, $79, $e9, $1f, $20, $60, $c0, $80, $a5, $da, $00, $f0, $18, $1c, $06, $02, $a1, $51, $22
	.byte	$e9, $c8, $f8, $f8, $e8, $78, $40, $44, $c3, $a6, $a6, $a6, $80, $67, $70, $df, $b2, $12, $12, $16, $5c, $98, $10, $ec 
	.byte	$23, $20, $20, $1c, $03, $00, $00, $00, $82, $02, $02, $07, $8f, $ff, $39, $31, $22, $21, $40, $08, $f0, $e8, $c4, $85, $00, $00, $80, $40, $40, $40, $80, $00 
	.byte	$1f, $10, $1f, $10, $10, $20, $21, $42, $fe, $02, $fe, $a2, $a2, $22, $82, $42
	.byte	$00, $00, $01, $01, $07, $0c, $08, $0f, $42, $84, $04, $fc, $04, $05, $05, $fd, $41, $21, $21, $7f, $81, $01, $01, $ff

	
	
	
emptySpace		; code 154										
	.byte	$00, $00, $00, $00, $00, $00, $00, $00

	
	
lifeBarGraphics	; code 155
	.byte	$7f, $80, $80, $80, $80, $80, $80, $7f 
	.byte	$7f, $80, $b0, $b0, $b0, $b0, $80, $7f 
	.byte	$7f, $80, $b6, $b6, $b6, $b6, $80, $7f 
	
	.byte	$ff, $00, $00, $00, $00, $00, $00, $ff 
	.byte	$ff, $00, $e0, $e0, $e0, $e0, $00, $ff 
	.byte	$ff, $00, $ee, $ee, $ee, $ee, $00, $ff 
	
	.byte	$fe, $01, $01, $01, $01, $01, $01, $fe 
	.byte	$fe, $01, $e1, $e1, $e1, $e1, $01, $fe 
	.byte	$fe, $01, $ed, $ed, $ed, $ed, $01, $fe 
	
	

	
ROUND 			; codes 164 through 168 
	.byte	$00, $fc, $82, $82, $fc, $84, $82, $82 
	.byte	$00, $38, $44, $82, $82, $82, $44, $38 
	.byte	$00, $82, $82, $82, $82, $82, $44, $38 
	.byte	$00, $82, $c2, $a2, $92, $8a, $86, $82 
	.byte	$00, $f8, $84, $82, $82, $82, $84, $f8 

ballGraphics 	; codes 169, 170
	.byte	$3c, $42, $81, $81, $81, $81, $42, $3c 
	.byte	$3c, $7e, $ff, $ff, $ff, $ff, $7e, $3c 

digits 			; codes 171 through 180
	.byte	$00, $18, $24, $42, $42, $42, $24, $18 
	.byte	$00, $08, $18, $78, $08, $08, $08, $08 
	.byte	$00, $3c, $42, $44, $08, $10, $20, $7e 
	.byte	$00, $3c, $46, $02, $0c, $02, $46, $3c 
	.byte	$00, $0c, $14, $24, $7e, $04, $04, $04 
	.byte	$00, $7e, $40, $5c, $62, $02, $42, $3c 
	.byte	$00, $3c, $42, $40, $7c, $42, $42, $3c 
	.byte	$00, $7e, $02, $04, $08, $10, $20, $40 
	.byte	$00, $3c, $42, $42, $3c, $42, $42, $3c
	.byte	$00, $3c, $42, $42, $3e, $02, $42, $3c 	
	
	
	
; code 178	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	


	
	
	


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

GAMEMODESCREENLOC1		.equ	#8142
GAMEMODESCREENLOC2		.equ	#8164

CHARACTERSELECTSCREENLOC .equ 	#7902

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


P1SCORESTART			.equ	#7812
P2SCORESTART			.equ	#7829


PRINTROUNDSTART			.equ	#7841
PRINTROUNDCOLORSTART	.equ	#38561

PRINTROUNDNUMSTART		.equ	#7848
PRINTROUNDNUMCOLORSTART	.equ	#38569


EMPTYSPACEADDR			.equ	#6488

CHARACTERSELECT01		.equ	#45			;offset from SCREENMEMORY1
CHARACTERSELECT02		.equ	#53			;offset from SCREENMEMORY1
CHARACTERSELECT03		.equ	#61			;offset from SCREENMEMORY1
CHARACTERSELECT04		.equ	#7739		; not right yet
CHARACTERSELECT05		.equ	#7874		; not right yet
CHARACTERSELECT06		.equ	#8003		; not right yet
CHARSELECTINDICATOR1	.equ	#7702		
CHARSELECTINDICATOR2	.equ	#8032	

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
DEBUGSCRE				.equ	$1E1E

DEBUGSCRF				.equ	$1E2C
DEBUGSCRG				.equ	$1E42


P1INITXPOS				.equ	#$7A
P1INITYPOS				.equ	#$1f

P2INITXPOS				.equ	#$87
P2INITYPOS				.equ	#$1f



EMPTYSPACECODE			.equ	#0
LIFELEFTCODES			.equ	#1
LIFEMIDCODES			.equ	#4
LIFERIGHTCODES			.equ	#7

ROUNDLETTERCODES		.equ	#10

EMPTYBALLCODE			.equ	#15
FULLBALLCODE			.equ	#16

DIGITCODES				.equ	#17
	
AKEY					.equ	#0
RIGHTKEY				.equ	#1
DOWNKEY					.equ	#2
SKEY					.equ	#3
DKEY					.equ	#4
WKEY					.equ	#$FE


STANDING				.equ	#0
KICKING					.equ	#1
PUNCHING				.equ	#2
BLOCKING				.equ	#3
STEPPING				.equ	#4
KEELING					.equ	#5
FLYING					.equ	#6



BLACK					.equ	#0
WHITE					.equ	#1
RED						.equ	#2
CYAN					.equ	#3
PURPLE					.equ	#4
GREEN					.equ	#5
BLUE					.equ	#6
YELLOW					.equ	#7


MASKSPERCHARACTER		.equ	#18

main

;	lda		#128
;	sta		$028A
	
	lda		<#RyuStandMask
	sta		ram_03
	lda		>#RyuStandMask
	sta		ram_04
	lda		<#RyuStand
	sta		ram_05
	lda		>#RyuStand
	sta		ram_06
	lda		RyuDrawableCellsCount
	sta		ram_07

	jsr		flipCharacterData
	jsr		swapCharacterData
	jsr		flipCharacterDrawMasks


	lda		<#KenStand
	sta		$01
	lda		>#KenStand
	sta		$02
	lda		<#FangKick
	sta		$03
	lda		>#FangKick
	sta		$04
	ldy		#128
	jsr		swapData

	
	ldx		#$08
	stx		$900f		; set background color to black and border color to black

	; load the address of a custom interrupt routine into Vic memory where the IRQ vector resides
	lda		<#irqHandler
	sta		IRQLOW
	lda		>#irqHandler
	sta		IRQHIGH
	cli

	lda		#$a0		; bit 7 = 1 and bit 5 = 1. This means we are enabling interrupts (bit 7) for timer 2 (bit 5)
	sta		IER			; store in the interrupt enable register
	


	; This will interrupt 125x per second
	lda		#$40
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$1F
	sta		T2HIGH		; store high order byte of timer (also starts the countdown AND CLEARS INTERRUPT FLAG)


	; Init Music
	lda		#$51		; D1 with high bit off (gets toggled on/off in irq)
	sta		SPEAKER2

;	lda		#1
;	sta		musicOnOffState

	lda		#$80
	sta		ram_02
	
	lda		#0
	sta		ram_01

	lda		#6
	sta		ram_00
	sta		VOLUME
	; Finish Init Music

	
	lda		#32					; fill screen uses the current empty space code to fill the screen

	jsr		fillScreen

	lda		#RED				; character color
	jsr		colorScreen
	
	
	jsr		drawStreetFighterBanner
	jsr		drawGameModeIndicator

	
; loop in start screen processing user input
nogo
	jsr		getInput
	cmp		#AKEY
	bne		.checkDKey
	lda		#0
	sta		gameplayMode
	jsr		drawGameModeIndicator
	jmp		nogo
	
.checkDKey
	cmp		#DKEY
	bne		.checkStart
	lda		#1
	sta		gameplayMode
	jsr		drawGameModeIndicator
	jmp		nogo
	
.checkStart
	cmp		#SKEY
	bne		nogo
; out of start screen loop
	
	lda		#32					; fill screen uses the current empty space code to fill the screen
	jsr		fillScreen
	
	lda		#RED				; character color
	jsr		colorScreen

	
;	jsr		fadeMusicOut
;	jsr		musicOff
;	jsr		fadeMusicIn
	jsr		drawCharacterSelectIntro
	
	
	lda		#$FD					; load code for telling vic chip where to look for character data
	sta		$9005					; store in Vic chip (36869)

	
	lda		#EMPTYSPACECODE		
	jsr		fillScreen				; fill screen with custom empty space code after changing character memory location

	
	jsr		drawCharacterSelectionScreen
	lda		#2
	sta		p1CharacterSelect
	sta		p2CharacterSelect
	jsr		drawCharSelectIndicator
nogo2
	jsr		getInput
	cmp		#AKEY
	bne		.checkDKey2

	lda		p1CharacterSelect
	cmp		#2
	beq		nogo2
	sec
	sbc		#8
	sta		p1CharacterSelect
	jsr		drawCharSelectIndicator
	jmp		nogo2	

	
.checkDKey2
	cmp		#DKEY
	bne		.checkWKey
	
	lda		p1CharacterSelect
	cmp		#18
	beq		nogo2
	clc
	adc		#8
	sta		p1CharacterSelect
	jsr		drawCharSelectIndicator	
	jmp		nogo2

.checkWKey
	cmp		#WKEY
	bne		.checkStart2

	ldy		p1Color
	iny
	cpy		#8
	bne		.allG
	ldy		#1

.allG	
	sty		p1Color
	jsr		drawCharacterSelectionScreen
	jmp		nogo2
	
.checkStart2
	cmp		#SKEY
	bne		nogo2	
	
	
	
	
	
	
	
	lda		#EMPTYSPACECODE		
	sta		emptySpaceCode

	jsr		fillScreen				; fill screen with custom empty space code after changing character memory location

	lda		#RED
	jsr		colorScreen

	
	lda		<#KenStand
	sta		$01
	lda		>#KenStand
	sta		$02
	lda		<#FangKick
	sta		$03
	lda		>#FangKick
	sta		$04
	ldy		#128
	jsr		swapData

	
	lda		p1CharacterSelect
	cmp		#2
	bne		.kenAndFang
	jmp		.ryu

	
	
.kenAndFang
	
	lda		<#RyuDrawCodes
	sta		$01
	lda		>#RyuDrawCodes
	sta		$02
	lda		<#p2DrawCodes
	sta		$03
	lda		>#p2DrawCodes
	sta		$04
	ldy		#6
	jsr		transferData

	lda		<#RyuStandMask
	sta		p2MasksAddrLow
	lda		>#RyuStandMask
	sta		p2MasksAddrHigh	


	lda		<#FangStand
	sta		ram_05
	lda		>#FangStand
	sta		ram_06

	lda		<#p1DrawCodes
	sta		$03
	lda		>#p1DrawCodes
	sta		$04

	
	lda		p1CharacterSelect
	cmp		#10	
	beq		.doKen
	jmp		.doFang
	
.doKen
	lda		<#KenDrawCodes
	sta		$01
	lda		>#KenDrawCodes
	sta		$02
	ldy		#6
	jsr		transferData

	jsr		swapKenAndFang
	
	lda		<#KenStandMask
	sta		p1MasksAddrLow
	lda		>#KenStandMask
	sta		p1MasksAddrHigh
	
	lda		<#KenStandMask
	sta		ram_03
	lda		>#KenStandMask
	sta		ram_04

	lda		KenDrawableCellsCount
	sta		ram_07

	
	jmp		.allGo
	
	
.doFang
	lda		<#FangDrawCodes
	sta		$01
	lda		>#FangDrawCodes
	sta		$02
	ldy		#6
	jsr		transferData

	lda		<#FangStandMask
	sta		p1MasksAddrLow
	lda		>#FangStandMask
	sta		p1MasksAddrHigh
	
	lda		<#FangStandMask
	sta		ram_03
	lda		>#FangStandMask
	sta		ram_04

	
	lda		FangDrawableCellsCount
	sta		ram_07
	jmp		.allGo

	
		
.ryu
	lda		<#RyuStandMask
	sta		ram_03
	lda		>#RyuStandMask
	sta		ram_04
	lda		<#RyuStand
	sta		ram_05
	lda		>#RyuStand
	sta		ram_06
	lda		RyuDrawableCellsCount
	sta		ram_07

	
	jsr		rand
	cmp		#29
	bmi		.allGo
	
	jsr		swapKenAndFang
	
	lda		<#KenDrawCodes
	sta		$01
	lda		>#KenDrawCodes
	sta		$02
	lda		<#p2DrawCodes
	sta		$03
	lda		>#p2DrawCodes
	sta		$04
	ldy		#6
	jsr		transferData
	

	lda		<#KenStandMask
	sta		p2MasksAddrLow
	lda		>#KenStandMask
	sta		p2MasksAddrHigh	
	
.allGo	
	jsr		flipCharacterData
	jsr		swapCharacterData
	jsr		flipCharacterDrawMasks


.test1	
;	jsr		fadeMusicOut
;	jsr		musicOn
;	jsr		fadeMusicIn
	

	jsr		initColors				; init colors of static screen items (lifebars, etc.)
	jsr		initRoundIndicators		; init and draw orund indicators



	
mainLoop	SUBROUTINE

	jsr		processWinState	
	
	jsr		drawScore
	
	jsr		clearInputBuffer		; clears user input from buffer (presses can accumulate leading to strange behavior)
	
	lda		#0
	sta		userPress
	
	jsr		getInput				
	sta		userPress				; store result in ram location (not efficient but more explicit)			


	lda		p1AnimTimer
	and		#$1F
	sta		p1AnimTimer

;	lda		#$78
;	sta		maxLeft
;	lda		p2XPos
;	sta		maxRight

;	lda		<#p1Action
;	sta		$01
;	lda		>#p1Action
;	sta		$02
;	lda		<#userAction
;	sta		$03
;	lda		>#userAction
;	sta		$04
;	ldy		#15
;	jsr		transferData

	lda		p1Color
	sta		drawColor
	jsr		doUserAction			; process the user's input possibly producing some action

	
;	lda		<#userAction
;	sta		$01
;	lda		>#userAction
;	sta		$02
;	lda		<#p1Action
;	sta		$03
;	lda		>#p1Action
;	sta		$04
;	ldy		#7
;	jsr		transferData


	jsr		getAINextAction
	lda		p2Color
	sta		drawColor
	jsr		doAIAction

	
	jsr		checkP1Struck
	jsr		checkP2Struck


	jsr		checkRoundWin			; checks if the round was won this iteration and updates state vars accordingly
									; updateHUD uses information from round win check to draw HUD

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
	
	stx		p2IsStriking

	
.wasP1Struck	
	lda		p1Action			; check if p1 was blocking during the strike
	cmp		#BLOCKING
	beq		.setStruckState
	cmp		#KEELING
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

	stx		p1IsStriking
	
	
.wasP2Struck	
	lda		p2Action			; check if p2 was blocking during the strike
	cmp		#BLOCKING
	beq		.setStruckState
	cmp		#KEELING
	beq		.setStruckState
	ldx		#1

.setStruckState
	stx		p2WasStruck


.end
	rts	
	
	




	
	
	
updateScore		SUBROUTINE
	
	lda		p1WonMatch
	beq		.player2Won
	
	lda		<#p1Score
	sta		$01
	lda		>#p1Score
	sta		$02

	lda		<#p2RoundWins
	sta		$05
	lda		>#p2RoundWins
	sta		$06
	jmp		.tallyScore
	
	
.player2Won
	lda		<#p2Score
	sta		$01
	lda		>#p2Score
	sta		$02

	lda		<#p1RoundWins
	sta		$05
	lda		>#p1RoundWins
	sta		$06



	
.tallyScore
	ldy		#2
	lda		($01),y				; load current 100s digit
	clc
	adc		#20					; add 2000 for match win
	
	sta		ram_03				; store 100s digit for processing (carries)
	

	
.getOpponentRoundWins

	ldy		#3
.loop4
	lda		($05),y
	bne		.break
	dey
	bpl		.loop4

	
.break
	iny

	sty		ram_04
	lda		ram_03				; load 100's digit
	sec
	sbc		ram_04				; subtract 100 for each opponent round win
	
	
	ldx		#0
.checkForCarries
	cmp		#27					; check for carry in 100s digit
	bmi		.noCarry
	inx							; tally number of carries
	sec
	sbc		#10
	jmp		.checkForCarries

	
	
.noCarry
	ldy		#2
	sta		($01),y				; store 100's digit

	stx		ram_03				; store number of carries
	dey
	lda		($01),y				; load 1000's digit
	clc
	adc		ram_03				; add number of carries


	cmp		#27
	bmi		.noCarry2
	sec		
	sbc		#10
	jmp		.carry
	
.noCarry2	
	sta		($01),y				
	jmp		.end


.carry
	sta		($01),y
	dey
	lda		($01),y
	clc
	adc		#1
	sta		($01),y
	
	
.end	
	rts

	
	
	
	


processWinState		SUBROUTINE

	

	lda		roundWasWon
	beq		.skip1
	
.loop1
	lda		p1Action
	adc		p2Action
	bne		.loop1
	
	inc 	currentRound
	jsr		initLifebars
	jsr		initRound
	jsr		drawCurrentRound
	lda		#0
	sta		roundWasWon
	
.skip1

	lda		matchWasWon
	beq		.end

	lda		gameplayMode
	bne		.skip2
	
	lda		p1WonMatch
	beq		.skip2					; if p1 won match, increase difficulty
	clc
	lda		#25
	adc		aiStrikeRand
	sta		aiStrikeRand
	lda		#25
	adc		aiBlockRand
	sta		aiBlockRand
	dec		currentLevelTimeOut
	dec		currentLevelTimeOut
	lda		currentLevelTimeOut
	cmp		#0
	bne		.skip2
	lda		#2
	sta		currentLevelTimeOut
	
	


.skip2
	jsr		updateScore

	jsr		initRoundIndicators
	jsr		initLifebars

	
	lda		#0
	sta		matchWasWon
	sta		p1WonMatch
	sta		p2WonMatch

	

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
	sta		roundWasWon

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
	sta		roundWasWon

	
.end
	rts
	
	






checkMatchWin		SUBROUTINE

	ldx		#3
	lda		p1RoundWins,x
	beq		.checkP2Win

	
	ldy		#1
	sty		p1WonMatch
	sty		matchWasWon
	dey
	sty		currentRound
	ldy		#8
	jsr		wait

	jsr		initRound
	jmp		.end

	
.checkP2Win	
	ldx		#3
	lda		p2RoundWins,x
	beq		.end

	ldy		#1
	sty		p2WonMatch
	sty		matchWasWon
	dey
	sty		currentRound
	ldy		#8
	jsr		wait

	jsr		initRound
	
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
	
	
	
	
	
initRound		SUBROUTINE
	
	lda		p1XPos
	sta		drawXPos
	jsr		clearFighter

	lda		p2XPos
	sta		drawXPos
	jsr		clearFighter

	
	lda		#P1INITXPOS
	sta		p1XPos
	lda		#P1INITYPOS
	sta		p1YPos
	
	lda		#P2INITXPOS
	sta		p2XPos
	lda		#P2INITYPOS
	sta		p2YPos

	
	rts

	
	
	
; update the HUD with respect to the current game state	
updateHUD		SUBROUTINE


.updateP1HealthBar
	lda		p2Action				; when the animation timer resets p2Action,...
	bne		.updateP2HealthBar
	lda		p1WasStruck				; check if p1 blocked or dodged during that action (if it was a strike)
	beq		.updateP2HealthBar
	

	lda		#KEELING
	sta		p1Action
	lda		#$B3
	sta		SPEAKER3
	adc		#$43
	sta		SPEAKER4

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

	
	lda		#KEELING
	sta		p2Action
	lda		#$B3
	sta		SPEAKER3
	adc		#$43
	sta		SPEAKER4
	
	
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

	lda		#FULLBALLCODE
	jmp		.draw1
	
.empty1
	lda		#EMPTYBALLCODE

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

	lda		#FULLBALLCODE
	jmp		.draw2
	
.empty2
	lda		#EMPTYBALLCODE

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
	lda		#GREEN					; set the life bars to green
.loop1
	
	sta		P1LIFEBARCOLORSTART,y
	sta		P2LIFEBARCOLORSTART,y
	
	dey
	bpl		.loop1


	ldy		#6
	lda		#YELLOW					; set the round indicators to yellow
.loop2
	
	sta		P1ROUNDWINSCOLORSTART,y
	sta		P2ROUNDWINSCOLORSTART,y
	 
	dey
	bpl		.loop2
	
	

	rts
	
	
	
	
	
	
	
	
	
	
	

drawLifebars	 SUBROUTINE

	clc										
										
	lda		#LIFELEFTCODES			; load the left lifebar graphic code (empty version)
	adc		p1LifeBarTicks			; add the number of ticks remaining in the leftmost lifebar
	sta		P1LIFEBARSTART			; store in screen memory

	lda		#LIFELEFTCODES
	adc		p2LifeBarTicks
	sta		P2LIFEBARSTART

	
	ldy		#1						; start at 1 since the first section is a different graphic	
.loop1								; run loop for 5 middle lifebar sections
	
	lda		#LIFEMIDCODES			; load the middle lifebar graphic code (empty version)
	adc		p1LifeBarTicks,y		; add the number of life ticks remaining in that section
	sta		P1LIFEBARSTART,y		; store in screen memory

	lda		#LIFEMIDCODES			; load the middle lifebar graphic code (empty version)
	adc		p2LifeBarTicks,y		; add the number of life ticks remaining in that section
	sta		P2LIFEBARSTART,y		; store in screen memory
	
	iny
	cpy		#6
	bne		.loop1

	clc
	
	lda		#LIFERIGHTCODES			; load the right lifebar graphic code (empty version)
	adc		p1LifeBarTicks,y		; add the number of life ticks remaining in that section
	sta		P1LIFEBARSTART,y		; store in screen memory
					
	lda		#LIFERIGHTCODES			; load the right lifebar graphic code (empty version)
	adc		p2LifeBarTicks,y		; add the number of life ticks remaining in that section
	sta		P2LIFEBARSTART,y		; store in screen memory

	
	rts
	



	
	
	
	
doUserAction		SUBROUTINE
;p1Action				0 = standing
;						1 = kick
;						2 = punch
;						3 = block
;						4 = step
;						5 = flying kick
;						6 = was struck

	lda		<#SCREENMEMORY2
	sta		$01
	lda		>#SCREENMEMORY2
	sta		$02
	lda		<#COLORCONTROL2
	sta		$03
	lda		>#COLORCONTROL2
	sta		$04

	lda		p1MasksAddrHigh
	sta		$06

	lda		p1Action
	cmp		#KEELING
	beq		.keeling1
	bne		.notKeeling1
	
.keeling1
	lda		p1IsMidKeel
	cmp		#0
	bne		.rts
	lda		#1
	sta		p1IsMidKeel
	jmp		.draw
	
.rts
	rts

	
.notKeeling1	
	lda		p1Action			; If not 0, p1 is mid animation (set to 0 in irq when anim timer reaches 0)
	beq		.drawUserDefault	

	cmp		#BLOCKING			; If mid block and block is pressed again, add to block animation timer
	beq		.checkContinueBlock
	rts

.checkContinueBlock	
	lda		userPress
	cmp		#BLOCKING
	bne		.notContinued
	lda		#16
	sta		p1AnimTimer
	
.notContinued	
	rts

	
.drawUserDefault				; when p1Action is set to 0 in the IRQ, draw the fighter's default stance
	lda		p1DrawCodes		; draw fighter graphic starting from p1 code 0
	sta		drawCode
	lda		p1MasksAddrLow
	sta		$05
	lda		p1MasksAddrHigh
	sta		$06
	lda		p1XPos
	sta		drawXPos
	jsr		drawFighterB


checkTimeOut
	lda		p1Timeout
	beq		.processInput
	rts
	
	
.processInput
	lda		userPress
	beq		.tryLeft
	cmp		#4
	beq		.tryRight
	cmp		#$FE
	beq		.jmpEnd
	cmp		#$FF
	bne		.valid
	
.jmpEnd	
	jmp		.end

.valid	
	sta		p1Action


.checkBlock
	cmp		#BLOCKING
	bne		.checkKeeling

	lda		#1
	sta		p1IsBlocking
	jmp		.draw

	
.checkKeeling
	cmp		#KEELING
	bne		.playerIsStriking
	jmp		.draw
	
	
.playerIsStriking	
	lda		#1
	sta		p1IsStriking
	jmp		.draw

	
.tryLeft	
	lda		p1XPos
	cmp		#$78				; is p1 at left edge of screen
	bpl		.moveLeft			; if not, move left
	rts		
.moveLeft	
	lda		p1XPos
	sta		drawXPos
	jsr		clearFighter		; otherwise, clear p1
	dec		p1XPos			; make new p1 position 1 column to left
	jmp		.setActionStepping

.tryRight
	lda		p1XPos
	clc
	adc		#4
	cmp		p2XPos			; is p1 at p2?
	bne		.moveRight			; if so, no movement right
	rts
.moveRight
	lda		p1XPos
	sta		drawXPos
	jsr		clearFighter		; otherwise, clear p1
	inc		p1XPos			; make new p1 position 1 column to right


.setActionStepping
	lda		#STEPPING
	sta		p1Action

	
	
.draw
	lda		p1Action			; each mask is 3 bytes, and each action corresponds to a mask for that graphic
	tay
	clc
	adc		p1Action
	adc		p1Action			; skip 3 * p1Action bytes from the beginning of the graphic masks for that fighter
	sta		ram_04
	lda		p1MasksAddrLow
	adc		ram_04
	sta		$05					; store for indirect indexed addressing in drawFighter

	lda		p1DrawCodes,y		; store the draw code for the beginning of the graphic being drawn
	sta		drawCode
	
	lda		p1XPos				; store the current position of the fighter as a screen memory offset
	sta		drawXPos
	jsr		drawFighterB

	lda		p1Action
	cmp		#KEELING
	beq		.keeling2
	lda		#16
	jmp		.setTimer
	
.keeling2
	lda		#27
	
.setTimer	
	sta		p1AnimTimer

	
	lda		#2
	sta		p1Timeout
	
.end
	rts
	
	
	
	
	
	

getAINextAction		SUBROUTINE

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
	
	lda		#BLOCKING
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
	cmp		aiKickPunchRand
	bpl		.kick
	
	lda		#PUNCHING
	sta		p2Action
	rts
	
.kick
	lda		#KICKING
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
	lda		#STEPPING
	sta		p2Action

	
	rts
	

.moveLeft
	lda		#2
	sta		aiDir
	lda		#STEPPING
	sta		p2Action

	
	rts
	
	
	
	
	
	
	
	
	
doAIAction		SUBROUTINE


	lda		<#SCREENMEMORY2
	sta		$01
	lda		>#SCREENMEMORY2
	sta		$02
	lda		<#COLORCONTROL2
	sta		$03
	lda		>#COLORCONTROL2
	sta		$04
	
	lda		p2Action
	cmp		#KEELING
	beq		.keeling1
	bne		.notKeeling1
	
.keeling1
	lda		p2IsMidKeel
	cmp		#0
	bne		.rts
	lda		#1
	sta		p2IsMidKeel
	jmp		.draw
	
.rts
	rts

	
.notKeeling1	
	lda		p2Action
	bne		.checkTimeOut

	
.drawP2Default	
	lda		p2DrawCodes		; fighter default stance code
	sta		drawCode
	lda		p2MasksAddrLow
	sta		$05
	lda		p2MasksAddrHigh
	sta		$06

	lda		p2XPos
	sta		drawXPos
	jsr		drawFighterB	
	rts
	
	
.checkTimeOut
	lda		aiTimeOut
	beq		.checkBlock
	rts
	
	
.checkBlock
	lda		p2Action
	cmp		#BLOCKING
	bne		.checkKeeling
	
	lda		#1
	sta		p2IsBlocking
	jmp		.draw

.checkKeeling
	cmp		#KEELING
	bne		.checkKick
	jmp		.draw

	
.checkKick
	lda		p2Action
	cmp		#KICKING
	bne		.checkPunch	

	lda		#1
	sta		p2IsStriking

	jmp		.draw

	
.checkPunch
	cmp		#PUNCHING
	bne		.checkDirection

	lda		#1
	sta		p2IsStriking
	
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
	jmp		.draw	

			
	
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
	jmp		.draw
	
	



.draw

	lda		p2Action			; each mask is 3 bytes, and each action corresponds to a mask for that graphic
	tay
	clc
	adc		p2Action
	adc		p2Action			; skip 3 * p1Action bytes from the beginning of the graphic masks for that fighter
	sta		ram_04
	lda		p2MasksAddrLow
	adc		ram_04
	sta		$05					; store for indirect indexed addressing in drawFighter
	lda		p2MasksAddrHigh
	sta		$06
	
	lda		p2DrawCodes,y		; store the draw code for the beginning of the graphic being drawn
	sta		drawCode
	
	lda		p2XPos				; store the current position of the fighter as a screen memory offset
	sta		drawXPos
	jsr		drawFighterB

	
	lda		p2Action
	cmp		#KEELING
	beq		.keeling2
	lda		#16
	jmp		.setTimer
	
.keeling2
	lda		#44		
	
.setTimer	
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

	ldy		#255
.loop3
	sta		SCREENMEMORY1,y
	dey
	cpy		#255
	bne		.loop3


	ldy		#250
.loop4
	sta		SCREENMEMORY2,y
	dey
	cpy		#255
	bne		.loop4
	
	rts
	

	
colorScreen			SUBROUTINE

	ldy		#255
.loop3
	sta		COLORCONTROL1,y
	dey
	cpy		#255
	bne		.loop3


	ldy		#250
.loop4
	sta		COLORCONTROL2,y
	dey
	cpy		#255
	bne		.loop4
	
	rts

	
	
	
	
	
;p1Action				0 = standing
;						1 = kick
;						2 = punch
;						3 = block
;						4 = step
;						5 = flying kick
;						6 = was struck

	
	
getInput		SUBROUTINE		; loads a with..
								; 2 -> down (punch)
								; 3 -> s (block)
								; 0	-> a (left)
								; 4 -> d (right)
								; 1 -> right (kick)
								 
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
	
	lda		#DOWNKEY
	rts

	
.checkForSKey
	cmp		#83					; ascii code for S key	
	bne		.checkForAKey
		
	lda		#SKEY
	rts
		
	
.checkForAKey
	cmp		#65					; ascii code for A key			
	bne		.checkForDKey

	lda		#AKEY
	rts

	
.checkForDKey
	cmp		#68					; ascii code for D key			
	bne		.checkForRightKey				

	lda		#DKEY
	rts

	
.checkForRightKey
	cmp		#29
	bne		.checkForWKey
	
	lda		#RIGHTKEY
	rts
	
	
.checkForWKey
	cmp		#87
	bne		.return
	
	lda		#WKEY
	rts
	
.return
	lda		#$FF				; no keys pressed (bogus return value so calling routine will not erroneously find a valid value in register a)
	rts							; else return
	
	
	
	
	

	

	
; clears all data from the input buffer except for the first character in the buffer
; use to eliminate input queue growth resultant of multiple key presses during animations 
clearInputBuffer		SUBROUTINE

	ldy		#$00
	lda		#$00
.loop
	sta		$0278,y				; store 0 in buffer

	iny
	cpy		#$09				; repeat for entire buffer
	bne		.loop				; if not, extract again
	rts	
	
	
	
	
	





	
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

		ldy		#4
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

	lda		#49						; '1'
	sta		GAMEMODESCREENLOC2

	ldy		#14
	lda		#50
	sta		GAMEMODESCREENLOC2,y	; '2'
	

	ldx		#5
	ldy		#21						
.loop1    
	lda		startGameString,x
	sta		GAMEMODESCREENLOC2,y
	
	dey
	dex
	bpl		.loop1

	tya
	cmp		#14
	bmi		.end

	
	ldx		#5
	sec
	sbc		#8
	tay
	jmp		.loop1
	
	
.end	
	rts


	
	
	
drawScore		SUBROUTINE

	ldy		#4
.loop
	lda		p1Score,y
	sta		P1SCORESTART,y
	
	lda		p2Score,y
	sta		P2SCORESTART,y
	
	dey
	bpl		.loop

	.rts
	
	
	
	
	
drawCurrentRound			SUBROUTINE


	ldx		#ROUNDLETTERCODES
	
	ldy		#0
.loop
	txa
	sta		PRINTROUNDSTART,y

	iny
	inx
	cpy		#5
	bne		.loop


	lda		currentRound
	clc
	adc		#DIGITCODES
	
	sta		PRINTROUNDNUMSTART
	
	
	ldy		#30
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

	



drawGameModeIndicator		SUBROUTINE	

	lda		#32
	ldy		#21
.loop1
	sta		GAMEMODESCREENLOC1,y
	dey
	bpl		.loop1
	


	lda		gameplayMode
	beq		.onePlayer
	ldy		#21
	jmp		.draw
	
.onePlayer
	ldy		#7

.draw	

	lda		#68
	ldx		#7
.loop2
	sta		GAMEMODESCREENLOC1,y
	dey
	dex
	bpl		.loop2

	
	rts


	
	
; load ram_03 with the player 1 selection
; load ram_04 with the player 2 selection
; 2  - ryu
; 12 - ken
; 20 - fang
drawCharSelectIndicator		SUBROUTINE	

	lda		#EMPTYSPACECODE
	ldy		#21
.loop1
	sta		CHARSELECTINDICATOR1,y
	dey
	bpl		.loop1

;	ldy		#21
;.loop2
;	sta		CHARSELECTINDICATOR2,y
;	dey
;	bpl		.loop2

	
	
	lda		#16

	ldy		p1CharacterSelect
	sta		CHARSELECTINDICATOR1,y
	
;	ldy		p2CharacterSelect
;	sta		CHARSELECTINDICATOR2,y


	rts

	
	

drawCharacterSelectIntro		SUBROUTINE

	ldy		#0
	sty		ram_04
	
.loop
	ldy		ram_04
	lda		CharacterSelectionString,y
	sta		CHARACTERSELECTSCREENLOC,y

	lda		#$E8
	sta		SPEAKER3

	ldy		#1
	jsr		wait

	lda		#0
	sta		SPEAKER3

	ldy		#1
	jsr		wait

	
	inc		ram_04
	lda		ram_04
	cmp		#18
	bne		.loop
	

	ldy		#20
	jsr		wait

	
	rts
	
	
	
	
	
drawCharacterSelectionScreen		SUBROUTINE

	
	lda		<#SCREENMEMORY1
	sta		$01
	lda		>#SCREENMEMORY1
	sta		$02
	lda		<#COLORCONTROL1
	sta		$03
	lda		>#COLORCONTROL1
	sta		$04

	
	lda		p1Color
	sta		drawColor

	
	lda		RyuDrawCodes
	sta		drawCode
	lda		<#RyuStandMask
	sta		$05
	lda		>#RyuStandMask
	sta		$06
	lda		#CHARACTERSELECT01
	sta		drawXPos
	jsr		drawFighterB

	ldy		#1
	lda		#130
	sta		drawCode
	lda		<#KenStandMask
	sta		$05
	lda		>#KenStandMask
	sta		$06
	lda		#CHARACTERSELECT02
	sta		drawXPos
	jsr		drawFighterB

	lda		FangDrawCodes
	sta		drawCode
	lda		<#FangStandMask
	sta		$05
	lda		>#FangStandMask
	sta		$06
	lda		#CHARACTERSELECT03
	sta		drawXPos
	jsr		drawFighterB
	
	rts
	
	

	
	
	
wait				SUBROUTINE
;	lda		ACR
;	and		#$DF		; set timer to operate in 1 shot mode		
;	sta		ACR
	

.top	
	lda		#$00
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$AF
	sta		T2HIGH		; store high order byte of timer (also starts the countdown)
		
.loop 
    lda		T2HIGH
	and		#$FF
    bne		.loop

	dey
	bne		.top
	
	rts
	
	
	
	
; changes ram_05 and ram_06
; Swaps character data positions - used in conjunction with flipCharacterData and flipCharacterDrawMasks
; Used to reverse the direction a character is facing during runtime
; Implemented to support character selection and in preparation for jumping over another character

swapCharacterData		SUBROUTINE
	
	lda		ram_03			; used for loading masks sequentially
	sta		$01
	lda		ram_04
	sta		$02

	
	lda		ram_05			; used for swapping data from one location to another
	sta		$03
	sta		$05
	lda		ram_06
	sta		$04
	sta		$06
		
	lda		#0
	sta		ram_07			; First half of mask storage
	sta		ram_08			; second half of mask storage
	sta		ram_10			; loop control over nMasks
	
.init
	lda		#0
	sta		ram_09			
	

	ldy		ram_10
	cpy		#MASKSPERCHARACTER
	bne		.notDone
	jmp		.rts
	
.notDone
	lda		($01),y			; load the next mask
	sta		ram_11
	
.top1
	lda		ram_11
	ldy		#0				; init num drawable cells in current mask
	ldx		#4
.loop1
	clc
	asl
	bcc		.noCarry1
	iny						
	
.noCarry1
	dex		
	bne		.loop1

	sta		ram_11
	lda		ram_09
	bne		.secondHalf
	sty		ram_07
	jmp		.continue

.secondHalf	
	sty		ram_08

.continue	
	inc		ram_09
	lda		ram_09
	cmp		#2
	bne		.top1

	inc		ram_10			; move to mext mask

	lda		ram_07
	sta		ram_09

.top2
	lda		ram_09
	asl
	asl
	asl
	sta		ram_13
	sta		ram_09
	beq		.nextRow


	
	sec
	sbc		#8
	sta		ram_11
	lda		$03
	clc
	adc		ram_11
	sta		$05
	bcc		.noCarry2
	inc		$06
.noCarry2	


.top3
	ldy		#0
	
.loop2
	lda		($03),y
	sta		ram_12
	lda		($05),y
	sta		($03),y
	lda		ram_12
	sta		($05),y
	iny
	cpy		#8
	bne		.loop2
	
	lda		ram_09
	cmp		#32
	bne		.nextRow
	dec		ram_09


	lda		$03
	clc
	adc		#8
	sta		$03
	bcc		.noCarry3
	inc		$04
.noCarry3

	
	lda		$05
	sec
	sbc		#8
	sta		$05
	cmp		#248
	bpl		.borrow
	jmp		.noBorrow
	
.borrow
;	dec		$06

.noBorrow	
	jmp		.top3
	
	
.nextRow
	lda		ram_05
	clc
	adc		ram_13
	sta		$03
	sta		$05
	sta		ram_05
	bcc		.noCarry5
	inc		ram_06
	
.noCarry5
	lda		ram_06
	sta		$04
	sta		$06
	
	lda		ram_08
	beq		.jmpInit
	sta		ram_09
	lda		#0
	sta		ram_08
	jmp		.top2
		

.jmpInit
	jmp		.init
		
.rts		
	rts
	
	
	
	
	
	
	
; ram_05 lower half of address of character data
; ram_06 upper half of address of character data
; ram_07 number of drawable cells for character (total number of draw codes)
; flips character data, byte by byte, so that each byte is flipped end for end.
; 1010 0011 -> 1100 0101
	
flipCharacterData		SUBROUTINE

	lda		ram_05
	sta		$03
	lda		ram_06
	sta		$04
	
	lda		#8
	sta		ram_10			; flip bytes in character data - flip (ram_07 * 8) bytes thus we repeat 8x

.top1	
	
	ldy		#0
;	dey
.top2
	lda		#0
	sta		ram_08			; temp for storing flipped byte
	lda		($03),y			; load a byte of character data
	
	
	; ********** Begin flip a byte **********
	ldx		#8
.loop2						; flip the bits (end for end) and store in ram_08
	lsr		ram_08
	clc
	asl						; check if next bit is on
	sta		ram_09			
	lda		ram_08			
	bcc		.noCarry1
	ora		#$80			; if so, set msb of ram_08 on
	
.noCarry1
	sta		ram_08
	lda		ram_09
	dex	
	bne		.loop2
	; ********** End flip a byte **********

	lda		ram_08
	sta		($03),y			; overwrite old data
	
	iny						; move to next byte of data
	cpy		ram_07
	bne		.top2

	
	lda		$03
	clc
	adc		ram_07
	sta		$03
	bcc		.noCarry2
	inc		$04
	
.noCarry2
	dec		ram_10
	bne		.top1
	
	
	
.end
	rts
	
	
	
	
	
	
	
	


; ram_03		low half of address for that character's draw masks
; ram_04		high half of address for that character's draw masks
; flips the draw masks for the character such that they correspond to the character facing the opposite direction

flipCharacterDrawMasks		SUBROUTINE

	lda		ram_03
	sta		$01
	lda		ram_04
	sta		$02

	
	ldx		#MASKSPERCHARACTER
	ldy		#0
.loop	
	lda		#0
	sta		ram_03

	lda		($01),y
	and		#$F0
	
	
.firstHalf
	cmp		#$70
	bne		.next1
	lda		#$E0
	jmp		.secondHalf
	
.next1	
	cmp		#$E0
	bne		.next2
	lda		#$70
	jmp		.secondHalf

.next2	
	cmp		#$C0
	bne		.next3
	lda		#$30
	jmp		.secondHalf

.next3	
	cmp		#$30
	bne		.secondHalf
	lda		#$C0

		
	
.secondHalf
	sta		ram_03
	lda		($01),y
	and		#$0F
	
	cmp		#$07
	bne		.next5
	lda		#$0E
	jmp		.nextMask

.next5	
	cmp		#$0E
	bne		.next6
	lda		#$07
	jmp		.nextMask

.next6	
	cmp		#$0C
	bne		.next7
	lda		#$03
	jmp		.nextMask

.next7	
	cmp		#$03
	bne		.nextMask
	lda		#$0C

	

.nextMask	
	ora		ram_03
	sta		($01),y
	iny
	dex
	bne		.loop

	rts
	
	
	
	
	
	
	
; $01 - lower half of from address
; $02 - upper half of from address
; #03 - lower half of to address
; $04 - upper half of to address
; y - nBytes to swap
	
swapData			SUBROUTINE

	dey
	
.loop
	lda		($01),y
	sta		ram_03
	lda		($03),y
	sta		($01),y
	lda		ram_03
	sta		($03),y
	

	dey
	bpl		.loop

	rts


	
	
swapKenAndFang			SUBROUTINE

	lda		<#KenStand
	sta		$01
	lda		>#KenStand
	sta		$02
	lda		<#FangStand
	sta		$03
	lda		>#FangStand
	sta		$04
	ldy		#255
	jsr		transferData

	lda		$01
	clc		
	adc		#255
	sta		$01
	bcc		.noCarry1
	inc		$02
.noCarry1
	
	lda		$03
	clc		
	adc		#255
	sta		$03
	bcc		.noCarry2
	inc		$04
	
.noCarry2
	ldy		#255
	jsr		transferData

	lda		$01
	clc		
	adc		#255
	sta		$01
	bcc		.noCarry3
	inc		$02
.noCarry3
	
	lda		$03
	clc		
	adc		#255
	sta		$03
	bcc		.noCarry4
	inc		$04
	
.noCarry4
	ldy		#250
	jsr		transferData


	rts


	
	
	
;	ORG		$1D00		; 256 bytes before where screen memory starts
irqHandler

;	lda		musicOnOffState
;	bne 	.decTimer
;	jmp		.skipMusic
	
.decTimer
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
	cmp		#KEELING
	beq		.dropTheBass

	lda		p2Action
	cmp		#KEELING
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
	cmp		#KEELING
	bne		.checkP2Scream
	jmp		.playerScream
	
.checkP2Scream
	lda		p2Action
	cmp		#KEELING
	bne		.skipMusic

	
	
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
	
	lda		#16
	sta		updateXPosPrevs
	
	lda		p1XPos
	sta		p1XPosPrev
	lda		p2XPos
	sta		p2XPosPrev

	
; Reset animations in progress to default stance if their animation timer reaches 0
; decrement animTimers each timer interrupt

.decP1AnimTimer	
	lda		p1Action
	beq		.decP1TimeOut				; If the p2 is 
;	beq		.decP2AnimTimer				; If the character is not mid action, do p2 check

	dec		p1AnimTimer					; Otherwise, decrement their animation timer
	bne		.decP2AnimTimer				; If it reaches 0, set their action to 0 (default stance)
	
.setP1Action	
	lda		#0
	sta		p1Action
	sta		p1IsBlocking
	sta		p1IsStriking
	sta		p1IsMidKeel

.decP1TimeOut	
	lda		p1Timeout
	beq		.decP2AnimTimer

	dec		p1Timeout

	
.decP2AnimTimer
	lda		p2Action
	beq		.decAiTimeOut				; If the p2 is not mid action, skip
	
	dec		p2AnimTimer					; Otherwise, decrement their animation timer
	bne		.resetTimer					; If it reaches 0, set their action to 0
	
.setP2Action
	lda		#0
	sta		p2Action
	sta		p2IsBlocking
	sta		p2IsStriking
	sta		p2IsMidKeel
	
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
	

	

p1Action			.byte	$00
p1AnimTimer			.byte	$00
p1IsBlocking		.byte	$00
p1IsStriking		.byte	$00
p1IsMidKeel			.byte	$00
p1XPos				.byte	#P1INITXPOS
p1Timeout			.byte	$00
p1MasksAddrLow		.byte	<#RyuStandMask
p1MasksAddrHigh		.byte	>#RyuStandMask
p1DrawCodes
	.byte	#27, #42, #57, #71, #85, #100
p1XPosPrev			.byte	$00
p1YPos				.byte	#P1INITYPOS
p1Score				
	.byte	#DIGITCODES, #DIGITCODES, #DIGITCODES, #DIGITCODES, #DIGITCODES
p1WasStruck			.byte	$00
p1WonMatch			.byte	$00
p1Color				.byte	#BLUE


p2Action			.byte	$00
p2AnimTimer			.byte	$00
p2IsBlocking		.byte	$00
p2IsStriking		.byte	$00
p2IsMidKeel			.byte	$00
p2XPos				.byte	#P2INITXPOS
p2Timeout			.byte	$00
p2MasksAddrLow		.byte	<#FangStandMask
p2MasksAddrHigh		.byte	>#FangStandMask
p2DrawCodes
	.byte	#114, #130, #146, #163, #179, #196
p2XPosPrev			.byte	$00
p2YPos				.byte	#P2INITYPOS
p2Score				
	.byte	#DIGITCODES, #DIGITCODES, #DIGITCODES, #DIGITCODES, #DIGITCODES
p2WasStruck			.byte	$00
p2WonMatch			.byte	$00
p2Color				.byte	#RED


	


aiTimeOut			.byte	$00
aiDodgeRand			.byte	#12 ; the higher this is, the more likely ai will move right when struck
aiBlockRand			.byte	#60 ; the higher this is, the more likely ai will block successfully
aiStrikeRand		.byte	#40 ; the higher this is, the more likely ai will strike when in range
aiKickPunchRand		.byte	#29 ; the higher this is, the more likely the ai will punch rather than kick when striking



updateXPosPrevs		.byte	#16

roundWasWon			.byte	#1
matchWasWon			.byte	$00


;userAction			.byte	$00
;userAnimTimer		.byte	$00
;userIsBlocking		.byte	$00
;userIsStriking		.byte	$00
;userIsMidKeel		.byte	$00
;userXPos			.byte	$00
;userTimeOut			.byte	$00
;userMasksAddrLow	.byte	$00
;userMasksAddrHigh	.byte	$00
;userDrawCodes		.byte	$00, $00, $00, $00, $00, $00
;maxLeft				.byte	$00
;maxRight			.byte	$00


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
ram_10				.byte	$00
ram_11				.byte	$00
ram_12				.byte	$00
ram_13				.byte	$00
ram_14				.byte	$00
ram_15				.byte	$00
ram_16				.byte	$00
ram_17				.byte	$00


aiDir				.byte	$00
currentLevelTimeOut	.byte	#12  ; the lower this is, the faster ai will make decisions
		
		
userPress			.byte	$00

gameplayMode		.byte	$00			; 0 -> 1 Player			1 -> 2 Player
;musicOnOffState		.byte	$00




p1CharacterSelect	.byte	$00




p2CharacterSelect	.byte	$00


	
	
p1RoundWins
	.byte		#0, #0, #0, #0
	
p2RoundWins
	.byte		#0, #0, #0, #0
	

p1LifeBarTicks
	.byte		#2, #2, #2, #2, #2, #2, #2		; change to use bit mask instead

p2LifeBarTicks
	.byte		#2, #2, #2, #2, #2, #2, #2		; change to use bit mask instead


; player
startGameString
    .byte	#16, #12, #1, #25, #5, #18
	
; Select A Character	
CharacterSelectionString
    .byte	#19, #5, #12, #5, #3, #20, #32, #1, #32, #3, #8, #1, #18, #1, #3, #20, #5, #18

	
	
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

	
RyuDrawCodes
	.byte	#27, #42, #57, #71, #85, #100

RyuDrawableCellsCount
	.byte	#87
	
KenDrawCodes
	.byte	#114, #130, #146, #163, #178, #195
	
KenDrawableCellsCount
	.byte	#95
	
FangDrawCodes
	.byte	#114, #130, #146, #163, #179, #196
	
FangDrawableCellsCount
	.byte	#97

	
	
	ORG		#4903 ; -> page boundaries: 4864 [page] 5120
	
startScreenCodes	; [rows], [columns], [code0], [code1],... [code(rows*columns)]	-> 163 bytes
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
	; 54 bytes

RyuStandMask
	.byte		$07, $77, $77 ;(15)

RyuKickMask
	.byte		$0C, $FF, $E6 ;(15)

RyuPunchMask
	.byte		$0E, $E7, $67 ;(14)

RyuBlockMask
	.byte		$06, $77, $77 ;(14)

RyuStepMask
	.byte		$07, $77, $77 ;(15)

RyuKeelMask
	.byte		$0F, $76, $73 ;(14)
	

KenStandMask
	.byte		$0E, $EE, $EF ;(16)

KenKickMask
	.byte		$07, $FF, $76 ;(16)

KenPunchMask
	.byte		$07, $FF, $77 ;(17)

KenBlockMask
	.byte		$0E, $EF, $6E ;(15)

KenStepMask
	.byte		$07, $7F, $FE ;(17)

KenKeelMask
	.byte		$0E, $EF, $66 ;(14)
	
	
FangStandMask
	.byte		$06, $EF, $FE ;(16)

FangKickMask
	.byte		$03, $FF, $F6 ;(16)

FangPunchMask
	.byte		$06, $FF, $F7 ;(17)

FangBlockMask
	.byte		$06, $FF, $77 ;(16)

FangStepMask
	.byte		$06, $FF, $FE ;(17)

FangKeelMask
	.byte		$0E, $EE, $EE ;(15)
	
	ORG		#5120		; forces our fighter graphics to begin where Vic is obtaining its character information from (character code 0 refers to the first 8 bytes starting at 6144, and so on)
	
	
emptySpace		; code 0
	.byte	$00, $00, $00, $00, $00, $00, $00, $00

	
	
lifeBarGraphics	; 1
	.byte	$7f, $80, $80, $80, $80, $80, $80, $7f 
	.byte	$7f, $80, $b0, $b0, $b0, $b0, $80, $7f 
	.byte	$7f, $80, $b6, $b6, $b6, $b6, $80, $7f 
	
	.byte	$ff, $00, $00, $00, $00, $00, $00, $ff 
	.byte	$ff, $00, $e0, $e0, $e0, $e0, $00, $ff 
	.byte	$ff, $00, $ee, $ee, $ee, $ee, $00, $ff 
	
	.byte	$fe, $01, $01, $01, $01, $01, $01, $fe 
	.byte	$fe, $01, $e1, $e1, $e1, $e1, $01, $fe 
	.byte	$fe, $01, $ed, $ed, $ed, $ed, $01, $fe 
	
	

	
ROUND 			; 10 through 14 
	.byte	$00, $fc, $82, $82, $fc, $84, $82, $82 
	.byte	$00, $38, $44, $82, $82, $82, $44, $38 
	.byte	$00, $82, $82, $82, $82, $82, $44, $38 
	.byte	$00, $82, $c2, $a2, $92, $8a, $86, $82 
	.byte	$00, $f8, $84, $82, $82, $82, $84, $f8 

ballGraphics 	; codes 15, 16
	.byte	$3c, $42, $81, $81, $81, $81, $42, $3c 
	.byte	$3c, $7e, $ff, $ff, $ff, $ff, $7e, $3c 

digits 			; codes 17 through 26
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

	
; code 27	
	
RyuStand		
	.byte	$00, $00, $00, $01, $01, $01, $01, $7f, $3f, $c0, $80, $00, $00, $ff, $ff, $ff, $80, $60, $20, $20, $20, $e0, $e0, $e0 
	.byte	$7f, $07, $0f, $1d, $18, $01, $02, $02, $00, $1c, $06, $86, $80, $80, $4f, $40, $20, $60, $a0, $a0, $20, $20, $20, $70 
	.byte	$06, $08, $08, $18, $3c, $3f, $39, $39, $20, $10, $1f, $80, $80, $80, $80, $80, $c8, $8c, $04, $0e, $9e, $fe, $ce, $4e 
	.byte	$39, $19, $0d, $01, $01, $01, $01, $01, $80, $80, $ff, $28, $28, $08, $00, $08, $5e, $de, $dc, $40, $40, $40, $40, $40 
	.byte	$02, $06, $0e, $1b, $31, $40, $40, $7f, $08, $08, $14, $14, $e3, $22, $22, $e3, $70, $10, $10, $3c, $e6, $01, $01, $ff  
	
RyuKick			
	.byte	$00, $03, $02, $04, $04, $07, $07, $ff, $fc, $02, $01, $01, $01, $ff, $ff, $ff 
	.byte	$fc, $1c, $3c, $76, $62, $06, $09, $01, $00, $70, $1a, $1a, $00, $00, $3c, $01, $80, $80, $80, $87, $8f, $bf, $a7, $67, $00, $00, $00, $00, $03, $05, $09, $11 
	.byte	$01, $06, $08, $08, $18, $3c, $3f, $39, $c1, $3e, $00, $00, $80, $80, $c0, $e0, $6f, $af, $3e, $21, $12, $1c, $38, $70, $31, $59, $89, $09, $09, $1f, $20, $c0 
	.byte	$39, $39, $19, $0f, $00, $00, $00, $00, $a0, $9f, $8f, $8b, $0a, $0a, $08, $08, $e1, $83, $04, $88, $90, $a0, $40, $40
	.byte	$08, $08, $08, $08, $0f, $08, $08, $0f, $40, $40, $40, $40, $e0, $10, $08, $f8

	
RyuPunch		
	.byte	$00, $00, $00, $00, $00, $00, $00, $1f, $0f, $30, $20, $40, $40, $7f, $7f, $ff, $e0, $18, $08, $08, $08, $f8, $f8, $f8
	.byte	$1f, $01, $03, $07, $06, $00, $00, $00, $c0, $c7, $c1, $61, $20, $20, $33, $10, $08, $18, $a8, $a8, $08, $08, $c8, $18
	.byte	$10, $08, $1c, $23, $60, $f0, $fc, $e4, $30, $38, $5f, $80, $04, $07, $04, $04, $04, $0e, $ff, $07, $07, $ef, $1f, $1e
	.byte	$ec, $ec, $6f, $7d, $11, $10, $20, $20, $04, $04, $fc, $44, $44, $44, $04, $84
	.byte	$20, $20, $60, $71, $9f, $80, $80, $ff, $c4, $c4, $a2, $39, $1f, $90, $50, $df, $00, $00, $00, $00, $e0, $10, $08, $f8 


RyuBlock		
	.byte	$01, $06, $04, $08, $08, $0f, $0f, $ff, $fc, $03, $01, $01, $01, $ff, $ff, $ff
	.byte	$f8, $38, $78, $ec, $c4, $04, $06, $02, $01, $e3, $35, $35, $01, $01, $79, $03, $00, $3e, $76, $77, $77, $67, $7f, $7f 
	.byte	$02, $01, $03, $04, $08, $08, $08, $04, $07, $06, $8b, $70, $00, $00, $1f, $e0, $d7, $f2, $c2, $02, $0c, $10, $e0, $80 
	.byte	$06, $02, $03, $02, $02, $02, $04, $04, $00, $00, $ff, $28, $28, $08, $00, $10, $80, $80, $80, $80, $80, $80, $80, $80 
	.byte	$04, $04, $0c, $0e, $13, $10, $10, $1f, $10, $18, $1c, $27, $e3, $12, $0a, $fb, $80, $80, $40, $20, $fc, $02, $01, $ff 	
	

RyuStep			
	.byte	$00, $00, $00, $01, $01, $01, $01, $7f, $3f, $c0, $80, $00, $00, $ff, $ff, $ff, $80, $60, $20, $20, $20, $e0, $e0, $e0 
	.byte	$7f, $03, $3f, $3d, $00, $00, $00, $00, $00, $1c, $06, $86, $80, $80, $cf, $40, $20, $60, $a0, $a0, $20, $20, $20, $60 
	.byte	$00, $00, $01, $01, $01, $01, $03, $03, $40, $20, $ef, $00, $00, $00, $c0, $f0, $c0, $80, $78, $04, $04, $8c, $9c, $fe 
	.byte	$03, $03, $03, $01, $01, $00, $00, $00, $90, $bf, $b6, $ba, $f4, $88, $80, $82, $ce, $ce, $5e, $5e, $7c, $70, $10, $10 
	.byte	$00, $00, $01, $01, $02, $02, $02, $03, $82, $82, $82, $c3, $7d, $03, $01, $ff, $10, $10, $10, $3c, $e6, $01, $01, $ff 


RyuKeel
	.byte	$00, $00, $00, $03, $07, $07, $07, $06, $00, $00, $fc, $f0, $e1, $87, $0d, $1b, $00, $00, $00, $00, $00, $80, $c0, $c0, $00, $00, $00, $00, $00, $0c, $18, $00 
	.byte	$4c, $ef, $ff, $f8, $fb, $3c, $01, $3f, $c0, $e0, $e0, $e1, $8b, $0f, $ff, $ff, $00, $40, $e0, $f0, $e0, $c0, $80, $00 
	.byte	$37, $37, $38, $38, $10, $00, $06, $07, $fe, $fc, $3c, $bc, $be, $bf, $7e, $f9
	.byte	$03, $03, $02, $00, $03, $03, $01, $01, $c7, $af, $2f, $99, $b0, $e0, $e0, $e0, $80, $c0, $e0, $f0, $f0, $70, $70, $70 
	.byte	$f0, $f0, $f0, $70, $20, $18, $3e, $00, $70, $70, $08, $3c, $1e, $00, $00, $00 



;	ORG 	#6032	

SecondCharacterBegin	

FangStand
	.byte	$00, $00, $00, $e3, $9c, $80, $ff, $80, $00, $00, $00, $80, $80, $80, $80, $80
	.byte	$7f, $00, $01, $03, $03, $f0, $9e, $c0, $ff, $80, $bc, $31, $81, $f1, $93, $83, $ff, $80, $80, $80, $bf, $21, $61, $06
	.byte	$40, $78, $1c, $12, $21, $21, $40, $c1, $ff, $00, $63, $36, $1c, $84, $60, $18, $0c, $1b, $11, $09, $18, $10, $10, $10, $00, $00, $00, $80, $80, $80, $c0, $40 
	.byte	$83, $82, $86, $f4, $f8, $f8, $f8, $f8, $84, $82, $81, $fc, $83, $80, $80, $8e, $18, $14, $94, $74, $f2, $13, $13, $13, $40, $40, $40, $60, $e0, $f0, $f0, $f0 
	.byte	$01, $01, $01, $01, $03, $06, $08, $0f, $0a, $0b, $09, $89, $c9, $19, $31, $e0, $10, $10, $10, $30, $58, $06, $83, $ff

FangKick
	.byte	$3c, $27, $20, $3f, $20, $ff, $20, $27, $f0, $90, $10, $f0, $10, $ff, $20, $20 
	.byte	$00, $00, $00, $00, $00, $f8, $88, $88, $00, $00, $38, $2c, $26, $1b, $08, $08, $2c, $6c, $c0, $e0, $3c, $a0, $20, $3f, $20, $20, $60, $60, $5e, $c2, $c2, $c6 
	.byte	$88, $9c, $92, $81, $e1, $30, $10, $18, $08, $0e, $06, $0c, $08, $c8, $78, $38, $00, $00, $00, $07, $3c, $04, $04, $04, $0c, $08, $70, $a0, $30, $10, $08, $0c 
	.byte	$06, $03, $00, $00, $00, $00, $00, $00, $0c, $04, $83, $81, $c0, $70, $10, $10, $06, $02, $07, $05, $c4, $6d, $3b, $0b, $04, $04, $04, $fe, $fe, $7e, $7e, $7e 
	.byte	$18, $0c, $04, $02, $03, $01, $01, $00, $0b, $08, $0c, $04, $3e, $02, $83, $ff

FangPunch	
	.byte	$00, $00, $00, $07, $04, $04, $07, $04, $00, $00, $00, $1c, $e4, $04, $fc, $04
	.byte	$03, $00, $00, $00, $00, $00, $07, $04, $ff, $04, $04, $0d, $19, $1c, $87, $f4, $ff, $04, $e4, $84, $8c, $0c, $88, $9b, $fe, $00, $00, $00, $00, $fc, $84, $84 
	.byte	$04, $04, $07, $00, $f0, $ff, $e0, $f0, $04, $07, $c0, $63, $51, $58, $fc, $01, $18, $f8, $00, $18, $b0, $e0, $20, $00, $18, $60, $d8, $88, $4c, $c4, $84, $86 
	.byte	$fe, $f1, $00, $00, $00, $00, $00, $00, $10, $f0, $10, $10, $1f, $04, $04, $04, $c0, $20, $10, $0c, $e3, $1f, $00, $70, $c2, $c2, $a2, $a2, $a3, $97, $9f, $9f 
	.byte	$0c, $08, $18, $1c, $36, $60, $41, $7f, $50, $50, $50, $5d, $45, $c4, $86, $03, $9f, $80, $80, $c0, $60, $18, $0c, $fc 

FangBlock
	.byte	$00, $00, $00, $07, $04, $04, $07, $04, $00, $00, $00, $1c, $e4, $04, $fc, $04
	.byte	$03, $00, $00, $f8, $c8, $e8, $e9, $f9, $ff, $04, $04, $0d, $19, $1c, $e7, $14, $ff, $04, $e4, $84, $8c, $2c, $c8, $1b, $ec, $00, $00, $00, $00, $fc, $84, $84 
	.byte	$f9, $89, $89, $46, $40, $20, $21, $3e, $04, $c7, $a0, $33, $19, $08, $e2, $31, $18, $f8, $00, $18, $b0, $e0, $20, $00, $18, $60, $d8, $88, $4c, $c4, $84, $86 
	.byte	$08, $04, $04, $04, $07, $04, $04, $04, $c0, $20, $10, $0c, $e3, $1f, $00, $70, $c2, $c2, $a2, $a2, $a3, $97, $9f, $9f 
	.byte	$0c, $08, $18, $1c, $36, $60, $41, $7f, $50, $50, $50, $5d, $45, $c4, $86, $03, $9f, $80, $80, $c0, $60, $18, $0c, $fc 

FangStep
	.byte	$00, $00, $00, $71, $4e, $40, $7f, $40, $00, $00, $00, $c0, $40, $40, $c0, $40
	.byte	$3f, $00, $00, $00, $01, $01, $78, $4f, $ff, $40, $4e, $d8, $98, $c0, $78, $49, $ff, $40, $40, $40, $c0, $cf, $88, $b8, $c0, $00, $00, $00, $00, $c0, $40, $40 
	.byte	$40, $40, $7c, $06, $0d, $09, $18, $10, $41, $7f, $00, $31, $1b, $8e, $c2, $20, $81, $86, $0d, $88, $04, $0c, $08, $08, $00, $00, $80, $80, $c0, $40, $40, $60 
	.byte	$20, $61, $42, $7c, $7c, $7c, $7d, $01, $8c, $42, $41, $40, $fe, $81, $00, $06, $08, $0c, $0a, $ca, $3a, $f9, $09, $09, $20, $20, $20, $20, $30, $f0, $f0, $f0 
	.byte	$02, $06, $08, $10, $70, $80, $80, $ff, $06, $0e, $0a, $32, $62, $42, $82, $83, $08, $08, $08, $0c, $0e, $03, $03, $ff

FangKeel
	.byte	$01, $01, $01, $01, $01, $ff, $01, $01, $e7, $3c, $00, $ff, $00, $ff, $bb, $d7, $80, $80, $80, $80, $80, $ff, $00, $00 
	.byte	$01, $01, $01, $f9, $f9, $fd, $7d, $3f, $ef, $d7, $bb, $ff, $82, $fe, $fe, $ff, $00, $00, $00, $3e, $3e, $fe, $fc, $e6 
	.byte	$0f, $07, $1b, $7d, $fc, $f9, $f3, $f7, $ff, $39, $93, $c7, $f7, $7f, $bf, $ff, $ce, $de, $df, $df, $df, $df, $df, $df 
	.byte	$f7, $f1, $ff, $ff, $3f, $01, $01, $01, $c4, $04, $04, $04, $ff, $ff, $ff, $ff, $1e, $3e, $38, $38, $f0, $e0, $e0, $e0 
	.byte	$03, $03, $07, $04, $0e, $1f, $1f, $1f, $f7, $f7, $f7, $f7, $71, $f1, $e1, $c0, $e0, $e0, $e0, $90, $b8, $fe, $ff, $ff 

	
	
;	ORG		#6808
	
KenStand		
	.byte	$01, $02, $02, $06, $0c, $18, $18, $18, $ff, $01, $00, $00, $00, $00, $00, $00, $00, $00, $e0, $e0, $30, $10, $10, $08
	.byte	$1a, $1d, $08, $0e, $05, $05, $05, $04, $5a, $a5, $01, $1d, $30, $30, $30, $00, $08, $08, $08, $88, $88, $88, $88, $88
	.byte	$04, $06, $0b, $1b, $23, $39, $c9, $c7, $02, $3c, $01, $81, $fe, $22, $22, $24, $98, $e8, $0c, $12, $22, $2e, $29, $39
	.byte	$cf, $d3, $db, $cb, $7f, $3f, $02, $06, $28, $10, $00, $ff, $05, $05, $01, $00, $39, $39, $39, $f9, $3d, $3f, $08, $08
	.byte	$04, $0c, $3c, $63, $e0, $80, $80, $ff, $0c, $0c, $12, $f3, $21, $21, $21, $e1, $08, $0c, $0f, $f1, $01, $00, $00, $ff, $00, $00, $00, $80, $c0, $40, $40, $c0
	
KenKick
	.byte	$00, $00, $00, $01, $03, $03, $03, $01, $3f, $40, $c0, $80, $00, $4b, $b4, $00, $e0, $18, $1c, $06, $02, $41, $a1, $21 
	.byte	$00, $00, $00, $00, $c0, $a0, $90, $88, $01, $00, $00, $00, $f0, $fc, $e2, $e1, $c3, $a6, $a6, $a6, $80, $67, $70, $df, $b1, $11, $11, $13, $5c, $b0, $20, $e0 
	.byte	$8c, $9a, $91, $90, $f0, $08, $04, $03, $f7, $f4, $7c, $84, $48, $38, $1c, $0e, $12, $24, $28, $30, $01, $01, $03, $07, $10, $10, $10, $10, $18, $3c, $fc, $9c 
	.byte	$87, $81, $40, $20, $12, $0a, $06, $02, $05, $f9, $f1, $d1, $50, $50, $10, $10, $9c, $9c, $98, $f0, $00, $00, $00, $00 
	.byte	$02, $02, $02, $02, $07, $08, $10, $1f, $10, $10, $10, $10, $f0, $10, $10, $f0
	
KenPunch
	.byte	$03, $04, $0c, $18, $30, $34, $3b, $10, $fe, $01, $01, $00, $00, $b4, $4a, $02, $00, $80, $c0, $60, $20, $10, $10, $10 
	.byte	$00, $00, $00, $00, $00, $00, $78, $ff, $1c, $0a, $0a, $0a, $08, $06, $07, $8d, $3b, $61, $61, $61, $05, $7b, $02, $fd, $10, $10, $10, $30, $c0, $00, $00, $80 
	.byte	$c0, $c8, $88, $7e, $03, $00, $00, $00, $f0, $00, $20, $10, $c3, $3f, $07, $06, $88, $88, $90, $e1, $fe, $fd, $38, $30, $40, $20, $10, $08, $04, $04, $88, $90 
	.byte	$07, $04, $07, $04, $04, $04, $04, $04, $ff, $00, $ff, $14, $14, $04, $30, $28, $e0, $20, $e0, $20, $20, $20, $20, $20 
	.byte	$04, $04, $08, $1f, $70, $c0, $80, $ff, $28, $24, $44, $c7, $48, $50, $50, $df, $10, $10, $10, $f0, $10, $10, $10, $f0  

KenBlock
	.byte	$00, $00, $00, $00, $01, $31, $79, $e9, $1f, $20, $60, $c0, $80, $a5, $da, $00, $f0, $18, $1c, $06, $02, $a1, $51, $22
	.byte	$e9, $c8, $f8, $f8, $e8, $78, $40, $44, $c3, $a6, $a6, $a6, $80, $67, $70, $df, $b2, $12, $12, $16, $5c, $98, $10, $ec 
	.byte	$23, $20, $20, $1c, $03, $00, $00, $00, $82, $02, $02, $07, $8f, $ff, $39, $31, $22, $21, $40, $08, $f0, $e8, $c4, $85, $00, $00, $80, $40, $40, $40, $80, $00 
	.byte	$1f, $10, $1f, $10, $10, $20, $21, $42, $fe, $02, $fe, $a2, $a2, $22, $82, $42
	.byte	$00, $00, $01, $01, $07, $0c, $08, $0f, $42, $84, $04, $fc, $04, $05, $05, $fd, $41, $21, $21, $7f, $81, $01, $01, $ff

	
KenStep
	.byte	$07, $08, $08, $18, $30, $60, $60, $60, $fc, $04, $03, $03, $00, $00, $00, $00, $00, $00, $80, $80, $c0, $40, $40, $20 
	.byte	$69, $76, $20, $38, $14, $14, $14, $10, $68, $94, $04, $76, $c2, $c2, $c2, $02, $20, $20, $20, $20, $20, $20, $20, $20 
	.byte	$00, $00, $00, $00, $00, $00, $03, $03, $10, $18, $2c, $6e, $8f, $e4, $24, $1c, $0a, $f3, $04, $06, $f9, $98, $9b, $92, $60, $40, $60, $80, $00, $80, $80, $40 
	.byte	$03, $03, $03, $03, $01, $00, $00, $00, $3c, $4c, $6c, $2f, $fc, $fc, $08, $18, $be, $5e, $1f, $ff, $3e, $1f, $1f, $01, $40, $40, $40, $40, $40, $80, $00, $00 
	.byte	$00, $00, $00, $01, $03, $02, $02, $03, $10, $30, $f1, $8f, $87, $04, $04, $ff, $c1, $c1, $21, $df, $81, $01, $01, $ff
	
	
	
KenKeel
	.byte	$00, $03, $07, $0f, $0f, $0c, $09, $0b, $00, $ff, $ff, $ff, $01, $7c, $fd, $7b, $00, $80, $c0, $e0, $f0, $38, $98, $dc
	.byte	$03, $03, $03, $01, $01, $00, $00, $00, $b1, $df, $3f, $f8, $f7, $7f, $1f, $03, $cc, $ec, $ec, $ec, $ec, $ec, $e0, $98
	.byte	$00, $00, $00, $03, $07, $0f, $1e, $7c, $3c, $7d, $fd, $fe, $bf, $3f, $1f, $0f, $3c, $be, $bf, $bf, $e7, $c3, $9f, $9f, $00, $00, $00, $80, $80, $80, $80, $00, 
	.byte	$07, $07, $03, $04, $0f, $0f, $1f, $1f, $c0, $fc, $fe, $06, $3e, $5e, $ee, $1e
	.byte	$3e, $7c, $7c, $78, $60, $f0, $f0, $00, $0e, $0e, $0e, $1e, $00, $3e, $7e, $00
	

;	ORG		#7570
	
	
	
	
;fadeMusicOut		SUBROUTINE	

;.loop
;	dec		VOLUME
;	ldy		#3
;	jsr		wait
;	lda		VOLUME
;	bne		.loop	
	

;	rts


	
;fadeMusicIn		SUBROUTINE	

;.loop
;	inc		VOLUME
;	ldy		#3
;	jsr		wait
;	lda		VOLUME
;	cmp		#8
;	bne		.loop	
	

;	rts
	
		

;musicOff		SUBROUTINE	

;	lda		#0
;	sta		musicOnOffState
;	lda		SPEAKER1
;	sta		ram_14
;	lda		SPEAKER2
;	sta		ram_15
;	lda		SPEAKER3
;	sta		ram_16
;	lda		SPEAKER4
;	sta		ram_17
;	lda		#0
;	sta		SPEAKER1
;	sta		SPEAKER2
;	sta		SPEAKER3
;	sta		SPEAKER4

;	rts


	
;musicOn		SUBROUTINE	

;	lda		ram_14
;	sta		SPEAKER1
;	lda		ram_15
;	sta		SPEAKER2
;	lda		ram_16
;	sta		SPEAKER3
;	lda		ram_17
;	sta		SPEAKER4
	
;	lda		#1
;	sta		musicOnOffState

;	rts

	




drawXPos			.byte	$00
drawCode			.byte	$00
drawColor			.byte	$00

currentRound		.byte	$00
roundsPerMatch		.byte	$00

columnMask			.byte	$00





	
; draws the fighter's current animation frame
; drawXPos must hold the lower byte of the address in screen memory for the top left cell of the character
; drawYPos must hold the upper byte of the address in screen memory for the top left cell of the character (future - jumpn')
; drawCode must hold the character code to begin printing from (depends on the fighter's animation frame)
; zero page $05 and $06 must hold the address of the draw mask to use for the fighter graphic


drawFighterB		SUBROUTINE

	ldx		drawCode
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
	inx						; increment draw code for next iteration
	jmp		.skipEmpty
	
.empty	
	lda		emptySpaceCode	; load the empty space code
	
	
.skipEmpty
	sta		($01),y			; store screen code in screen memory offset by y
	lda		drawColor
	sta		($03),y			; store color code in color control offset by y
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
	ldy		#0				; set for indirect indexed addressing
	lda		($05),y			; load the next mask
	sta		columnMask
	ldy		ram_06			; restore current offset
	jmp		.loop1Init		; draw next two rows
	
	
	
.return	
	rts	

		


	

	
	
	
	
transferData		SUBROUTINE

		
	dey
.loop
	lda		($01),y
	sta		($03),y
	
	dey
	bne		.loop
	
	lda		($01),y
	sta		($03),y
	

	rts
	
	
	
	
	
















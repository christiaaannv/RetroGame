

	processor 6502

	org $1001

	dc.w	end
	dc.w	1234
	dc.b	$9e, "4110", 0

end
	dc.w	0
	
	

	
start

chrout				.equ	$ffd2   ; kernal routine
chrin				.equ	$ffcf   ; kernal routine
GETIN				.equ	$ffe4

SPEAKER1			.equ	$900A
SPEAKER2			.equ	$900B
SPEAKER3			.equ	$900C
SPEAKER4			.equ	$900D
VOLUME				.equ	$900E 

ACR					.equ	$911B ;912B - bit6
IFR					.equ	$911D ;912B
IER					.equ	$911E ;912E


T1LOWCOUNT			.equ	$9114
T1HGHCOUNT			.equ	$9115
T1LOWLATCH			.equ	$9116
T1HGHLATCH			.equ	$9117
T2LOW				.equ	$9118
T2HIGH				.equ	$9119

IRQLOW				.equ	$0314
IRQHIGH				.equ	$0315

SCREENMEMORY		.equ	$1e00


; cli instruction enables interrupts
; read around page 218 - 226 for interrupts

	
main
	.org	$1200

	lda		#$04
	sta		VOLUME
	
	
	; load the address of a custom interrupt routine into Vic memory where the IRQ vector resides
	sei
	lda		#$00
	sta		IRQLOW
	lda		#$1D
	sta		IRQHIGH
	cli


	lda		#$a0		; bit 7 = 1 and bit 5 = 1. This means we are enabling interrupts (bit 7) for timer 2 (bit 5)
	sta		IER			; store in the interrupt enable register

	
	ldx		#$08
	stx		$900f		; set background color and border color to black -- see appendices for codes and memory locations to store in 

	
	lda		ACR
	and		#$DF		; set timer2 to operate in 1 shot mode		
	sta		ACR
	
	lda		#$FF
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$FF
	sta		T2HIGH		; store high order byte of timer (also starts the countdown)


	
	lda		#$51		; D1 with high bit off
	sta		SPEAKER2
	
	lda		#$80
	sta		ram_05
	
	
	rts					; return to BASIC prompt



	
	ORG		$1D00		; 256 bytes before where screen memory starts
irqHandler
	ldy		ram_00
	iny
	sty		ram_00
	cpy		#6
	beq		.toggleSounds
	jmp		.setTimer

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

	
	ldy		ram_04
	cpy		#128
	beq		.dropTheBass
	iny
	sty		ram_04

	
	ldy		ram_05
	iny		
	sty		ram_05
	
	
.melodyOff	
	lda		ram_05
	sta		SPEAKER1
	lda		#0
	sta		SPEAKER2


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
	bne		.continue4
	lda		#$BB			; change to alter the repeating note (BB)
	sta		SPEAKER2
	ldx		#3
	jmp		.bass

.continue4
	cpy		#122
	bmi		.increment
;	lda		#$00			; change to alter the repeating note (BB)
;	sta		SPEAKER2	
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

	
	
	
.setTimer	

	lda		IFR			; load the interrupt flag register
	
	and		#$20		; test if the 5th bit was set (timer 2 time out flag)
	beq		.notTime

	
	lda		#$FF
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$FF
	sta		T2HIGH		; store high order byte of timer (also starts the countdown AND CLEARS INTERRUPT FLAG)
	

	
.notTime
	jmp		$EABF		; jump to the kernel's irq handler


RAM

ram_00		.byte	$00
ram_01		.byte	$00
ram_02		.byte	$00
ram_03		.byte	$00
ram_04		.byte	$00
ram_05		.byte	$00
	
	
	
	
melody
	.byte	$B3, $00, $E8, $00, $E8, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $00, $00, $00, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $E8, $00, $AF, $00, $00, $00
	.byte	$B3, $00, $E8, $00, $E8, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $00, $00, $00, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $E8, $00, $AF, $00, $00, $00
	.byte	$B3, $00, $E8, $00, $E8, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $00, $00, $00, $00, $BB, $00, $00, $00, $00, $00, $B3, $00, $E8, $00, $AF, $00, $00, $00
	.byte	$B3, $00, $00, $00, $00, $00, $BB, $00, $00, $00, $00, $00, $C7, $00, $00, $00, $00, $00, $CA, $00, $00, $00, $00, $00, $C7, $00, $00, $00, $C3, $CB, $D1, $D9	


	
bass
	.byte	$A3, $B3, $C7, $BB, $00
	

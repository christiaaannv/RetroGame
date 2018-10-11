

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

SPEAKERA			.equ	$900A
SPEAKERB			.equ	$900B
SPEAKERC			.equ	$900C
SPEAKERD			.equ	$900D
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

	
	
	
	; load the address of a custom interrupt routine into Vic memory where the IRQ vector resides
	lda		#$00
	sta		IRQLOW
	lda		#$1D
	sta		IRQHIGH
	cli


	lda		#$a0		; bit 7 = 1 and bit 5 = 1. This means we are enabling interrupts (bit 7) for timer 2 (bit 5)
	sta		IER			; store in the interrupt enable register
	
	
	
	ldx		#$08
	stx		$900f		; set background color and border color to black -- see appendices for codes and memory locations to store in 

	
	lda		#$00
	sta		$1E00		; chow character code 0 at the top left of the screen
	
	lda		ACR
	and		#$DF		; set timer2 to operate in 1 shot mode		
	sta		ACR
	
	lda		#$FF
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$FF
	sta		T2HIGH		; store high order byte of timer (also starts the countdown)


	ldx		#$0
loop    
	lda		info,x
	jsr		chrout   
	inx
	cpx		#$6d
	bne		loop


	rts					; return to BASIC prompt







wait SUBROUTINE
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




	
	
	
	
	ORG		$1D00		; 256 bytes before where screen memory starts
irqHandler
	lda		IFR			; load the interrupt flag register
	
	and		#$20		; test if the 5th bit was set (timer 2 time out flag)
	beq		notTimer

	lda		$1E00		; load the character currently in the top left of the screen
	clc
	adc		#$01
	sta		$1E00		; store the next character code there
	
	lda		#$FF
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$FF
	sta		T2HIGH		; store high order byte of timer (also starts the countdown AND CLEARS INTERRUPT FLAG)
	

	
notTimer	
	jmp		$EABF		; jump to the kernel's irq handler
	
	
	




	
	
	
	
info
	.byte	"TIMER BASED INTERRUPTS ARE USED TO CHANGE THE UPPER LEFT CHARACTER - THE VIC CAN STILL BE USED SIMULTANEOUSLY"
	
	

	

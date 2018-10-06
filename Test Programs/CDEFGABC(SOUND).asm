

	processor 6502

	org $1001

	dc.w	end
	dc.w	1234
	dc.b	$9e, "4110", 0

end
	dc.w	0
	
	

	
start

chrout		.equ	$ffd2   ; kernal routine
chrin		.equ	$ffcf   ; kernal routine
GETIN		.equ	$ffe4

SPEAKERA	.equ	$900A
SPEAKERB	.equ	$900B
SPEAKERC	.equ	$900C
SPEAKERD	.equ	$900D
VOLUME		.equ	$900E 

ACR			.equ	$911B ;912B - bit6
IFR			.equ	$911D ;912B
IER			.equ	$911E ;912E


T1LOWCOUNT	.equ	$9114
T1HGHCOUNT	.equ	$9115
T1LOWLATCH	.equ	$9116
T1HGHLATCH	.equ	$9117
T2LOW		.equ	$9118
T2HIGH		.equ	$9119

; cli instruction enables interrupts
; read around pages 220 for interrupts

	
main
	.org	$1200

	
begin
	lda		#$04
	sta		VOLUME
	
	
	ldy		#$04
topF
	lda		#$CF
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait


	lda		#$DB
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait
	
	
	lda		#$E1
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait


	lda		#$E7
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait

	dey
	bne		topF

	
	

	ldy		#$04
topAm
	lda		#$DB
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait


	lda		#$DF
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait
	
	
	lda		#$E4
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait


	lda		#$E8
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait

	dey
	bne		topAm
	
	
	
	
		ldy		#$04
topG
	lda		#$D4
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait


	lda		#$DF
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait
	
	
	lda		#$E1
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait


	lda		#$E4
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait

	dey
	bne		topG
	
	
	
	ldy		#$04
topC
	lda		#$E7
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait


	lda		#$E1
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait

	dey
	bne		topC
	


	ldy		#$04
topC2
	lda		#$E7
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait


	lda		#$F0
	sta		SPEAKERA
	jsr		wait
	jsr		wait
	lda		#$00
	sta		SPEAKERA
	jsr		wait

	dey
	bne		topC2
	
	
	
	jmp		begin
	

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
	
	
waitLonger SUBROUTINE

	ldy		#$00
.top

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

	iny
	cpy		#$05
	bne		.top
	
	rts
	



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
	

; transfers the image into memory where the data for T currently is
; if you store the screen code for 'T' in screen memory, this will be drawn instead (not the ascii code)
	ldx		#$00
top0
	lda		smileMultiC,x	
	sta		$1ca0,x		
	inx		
	cpx		#$08
	bne		top0

	
	
	lda		#$FF					; load code for telling vic chip where to look for character data (this code is hardwired and tells it to look at 7168)
	sta		$9005					; store in Vic chip
	
	
	

	
	jsr		clearScreen
	

	ldx		#$00
	ldy		#$08
top1	
	lda		#$14
	sta		SCREENMEMORY,x


	tya
	sta		COLORCONTROL,x

	inx
	lda		#$00
	sta		SCREENMEMORY,x

	iny
	inx
	cpx		#$10
	bne		top1

	
	
	ldx		#$00
top2	
	lda		VOLandAUXCOLOR			
	clc
	adc		#$10
	sta		VOLandAUXCOLOR

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
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		wait
	jsr		wait

	inx
	cpx		#$10
	bne		top2
	
	
	
infinite
	clc
	bcc		infinite
	
	
	rts
	
	
	
	
	
	
	
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



smileMultiC
	.byte	$3c
	.byte	$eb
	.byte	$eb
	.byte	$eb
	.byte	$d7
	.byte	$d7
	.byte	$d7
	.byte	$3c



	

	
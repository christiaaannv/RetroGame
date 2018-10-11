

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

	
main
	.org	$1200

	
	
top	
	ldx		#$00
loop	
	lda		DATA,x
	jsr		chrout   

	jsr		wait
	inx		
	cpx		#$2c
	bne		loop
	
	jmp		top
	
	
	
	
wait				SUBROUTINE
	lda		ACR
	and		#$DF		; set timer to operate in 1 shot mode		
	sta		ACR
	
	lda		#$00
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$FF
	sta		T2HIGH		; store high order byte of timer (also starts the countdown)
		
.loop 
    lda		T2HIGH
	and		#$FF
    bne		.loop

	rts
	

	rts
	
	
	
DATA	
	.byte	"ALL WORK AND NO PLAY MAKES JACK A DULL BOY  "
	
	
	
	
	
	
	
	
	
	

	


	processor 6502

	org $1001

	dc.w	end
	dc.w	1234
	dc.b	$9e, "4110", 0

end
	dc.w	0
	
	

	
start


chrout	.equ   $ffd2   	; kernal routine
chrin	.equ   $ffcf   	; kernal routine

main
	.org	$1200

	ldx		#0			; load 0 into x
loop1    				; loop to print chars of GAME OVER
	lda		text,x
	jsr		chrout   
	inx
	cpx		#9
	bne		loop1
	jsr		chrin
	

	ldx 	#$0A 		;load x with 10
loop2 					; loop to changed the background colour
	ldy 	#$0D		; load black with green border
	sty 	$900F
	dex 				; decrement x
	ldy		#$3A		; load cyan with red border
	sty 	$900F
	bne 	loop2 		; branch on not zero
	rts
	

text
    .byte  "GAME OVER"
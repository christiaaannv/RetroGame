

	processor 6502

	org $1001

	dc.w	end
	dc.w	1234
	dc.b	$9e, "4110", 0

end
	dc.w	0
	
	

	
start

chrout	.equ   $ffd2   ; kernal routine
chrin	.equ   $ffcf   ; kernal routine

	
main
	.org	$1200
	ldx		#0

loop    
	lda		text,x
	jsr		chrout   
	inx
	cpx		#11
	bne		loop
	jsr		chrin
	rts

text
    .byte  "HELLO WORLD"
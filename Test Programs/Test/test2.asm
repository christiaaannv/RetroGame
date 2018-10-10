

	processor 6502

	org $1001

	dc.w	end
	dc.w	1234
	dc.b	$9e, "4110", 0

end
	dc.w	0
	
	

	
start


main

    lda		#$20				; first code is upper left cell in fighter step (a blank cell)

	ldx		#$00
.loop1    
	sta		$1e00,x             ;... top-part of the screen 
	inx
	cpx		#$FF
	bne		.loop1

	ldx		#$00
.loop2
	sta		$1eFF,x             ;... botton-part of the screen
	inx
	cpx		#$FF
	bne		.loop2

    rts


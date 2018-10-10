

	processor 6502

	org $1001

	dc.w	end
	dc.w	1234
	dc.b	$9e, "4110", 0

end
	dc.w	0
	
	

	
start



ACR						.equ	$911B 	;912B - bit6
T2LOW					.equ	$9118
T2HIGH					.equ	$9119


TOPHALFCHAR         .equ    $1ee0
TOPHALFCOLOR        .equ    $96e0


main
	.org	$1200
	jsr		clearScreen
	

infinite 

    jsr     displaySymbol

wait10
    jsr     wait 


    lda     ram_01
    clc 
    adc     #$01 
    sta     ram_01
    lda     ram_01
    cmp     #$10
    bne     wait10
        
    lda     #$00 
    sta     ram_01 

    jmp infinite

    rts







displaySymbol   SUBROUTINE 

    ldx     #$00 
.jump 

    jsr     getColor 

    lda     ram_00
    sta     TOPHALFCOLOR,x

    lda     #$51 
    sta     TOPHALFCHAR,x 

    inx 
    inx


    cpx     #$0a    
    bne     .jump 

    rts


getColor     SUBROUTINE


    lda     ram_00  ;... color flag
    clc 
    adc     #$01
    sta     ram_00  ;... increment ram_00 by 1 

    lda     ram_00 
    cmp     #$08    ;... reach last color for char
    beq     .setToZero 
    jmp     .end

.setToZero
    lda     #$00 
    sta     ram_00
.end
    rts





wait        SUBROUTINE

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

ram_00      .byte   $00 
ram_01      .byte   $00 


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

TOPHALFCHAR             .equ    $1e00
BOTTOMHALFCHAR          .equ    $1eff

TOPHALFCOLOR            .equ    $9600 
BOTTONHALDCOLOR         .equ    $96ff

GETIN					.equ	$FFE4



main
	.org	$1200


    jsr     clearScreen

    jsr     backgroundColor


    lda     #$00
    sta     ram_00 

    lda     #$00 
    sta     ram_01

    jsr     addSymbol




infinite

    jmp infinite






addSymbol   SUBROUTINE


    ldx     #$00

.jump1
    
    jsr     getSymbol

    lda     ram_01
    sta     TOPHALFCHAR,x

    jsr     getColor
    lda     ram_00
    sta     TOPHALFCOLOR,x 

    inx
    cpx     #$ff
    bne     .jump1

    ldx     #$00
.jump2 

    jsr     getSymbol
    lda     ram_01
    sta     BOTTOMHALFCHAR,x

    jsr     getColor
    lda     ram_00 
    sta     BOTTONHALDCOLOR,x

    inx  
    cpx     #$fb
    bne     .jump2

    ;restart 

    jsr     wait
    jsr     wait
    jsr     wait

    jsr     backgroundColor

    ;infinite recursive call
    jsr     addSymbol
    

    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getColor   SUBROUTINE

    lda     ram_00
    clc
    adc     #$01
    sta     ram_00 

    lda     ram_00 
    cmp     #$07
    beq     .setToZero

    jmp     .end
.setToZero 

    lda    #$00 
    sta    ram_00 

.end
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getSymbol   SUBROUTINE

    lda     ram_01 
    clc
    adc     #$01 
    sta     ram_01 

    lda     ram_01 
    cmp     #$7f 
    beq     .setToZero

    jmp     .end

.setToZero
    lda     #$00
    sta     ram_01

.end
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
backgroundColor SUBROUTINE 

    jsr     getBackground

    lda     ram_02
    sta     $900f

    rts


getBackground   SUBROUTINE 

    lda     ram_02 
    clc
    adc     #$01 
    sta     ram_02 

    lda     ram_02 
    cmp     #$ff 
    beq     .setToStart

    ;CHECK COLORS
    lda     ram_03 
    clc 
    adc     #$01 
    sta     ram_03 

    lda     ram_03
    cmp     #$09       ;... reach and end of the color, pg 265 in book 
    beq     .plus16

    jmp     .end

.setToStart
    lda     #$08 
    sta     ram_02  
    jmp     .end

.plus16 
    lda     #$00 
    sta     ram_03

    lda     ram_02 
    clc 
    adc     #$10 
    sta     ram_02

.end
    rts 




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wait				SUBROUTINE
	lda		ACR
	and		#$DF		; set timer to operate in 1 shot mode		
	sta		ACR
	
	lda		#$00
	sta		T2LOW		; store low order byte of timer	countdown	
	lda		#$ff
	sta		T2HIGH		; store high order byte of timer (also starts the countdown)
		
.loop 
    lda		T2HIGH
	and		#$FF
    bne		.loop

	rts
	



; draws empty space characters over the entire screen

clearScreen		SUBROUTINE
	lda		#$20				; first code is upper left cell in fighter step (a blank cell)

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


ram_00     .byte $00 
ram_01     .byte $00 
ram_02     .byte $00 
ram_03     .byte $00 

	
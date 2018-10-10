

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main
	.org	$1200


    jsr     clearScreen         ;... Clear screen 

infinite

    jsr     backgroundColor     ;... change backgroundColor
    jsr     updateScreen        ;... change characters, and their prospect colors 

                                ;... slowdown the program 
                                ;... so its noticeble by the user 
wait10
    jsr     wait 


    lda     ram_04
    clc 
    adc     #$01 
    sta     ram_04
    lda     ram_04
    cmp     #$0a
    bne     wait10
        
    lda     #$00 
    sta     ram_04 

    jmp infinite

    jmp infinite



updateScreen   SUBROUTINE


    ldx     #$00
.jump1                          ;...handles top-part of screeen
    
    jsr     getSymbol

    lda     ram_01
    sta     TOPHALFCHAR,x       ;...insert new ASCII symbol 

    jsr     getColor
    lda     ram_00
    sta     TOPHALFCOLOR,x      ;...insert new color into the the box

    inx                         ;increment register x, to move to next box
    cpx     #$ff
    bne     .jump1              ;... check if reach end of top-part of screen
                                ;... if no, loop again
                                ;... otherwise move to .jump2 for to continue in bottom-part

    ldx     #$00
.jump2                          ;... handles bottom-part of screen

    jsr     getSymbol
    lda     ram_01
    sta     BOTTOMHALFCHAR,x    ;... insert new ASCII symbol 

    jsr     getColor
    lda     ram_00 
    sta     BOTTONHALDCOLOR,x   ;... insert new color into the box 

    inx                         ;... increment register x, to move to next box
    cpx     #$fb                
    bne     .jump2              ;... check if reach end of screen
                                ;... if no, looop again
                                ;... otherwise end program

    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getColor   SUBROUTINE

    lda     ram_00
    clc
    adc     #$01
    sta     ram_00              ;... increments the color flag(ram_00) by 1

    lda     ram_00 
    cmp     #$07
    beq     .setToZero          ;... check if reach last pasible color for CHAR
                                ;... if yes, set back to first color, otherwise return 

    jmp     .end
.setToZero 

    lda    #$00 
    sta    ram_00               ;... set ram_00 to the first color for CHAR 

.end
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getSymbol   SUBROUTINE

    lda     ram_01  
    clc
    adc     #$01 
    sta     ram_01              ;... increments the symbols flag(ram_01) by 1

    lda     ram_01 
    cmp     #$7f 
    beq     .setToZero          ;... check if we reach last symbol that we want
                                ;... if yes, reset to flag to the first symbol in the table 
                                ;... no return back to main function

    jmp     .end

.setToZero
    lda     #$00
    sta     ram_01              ;... set symbol flag (ram_01) to first char in the ASCII table 

.end
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
backgroundColor SUBROUTINE 

    jsr     getBackground       ;update background color flag (ram_02)

    lda     ram_02              ;update background color
    sta     $900f

    rts


getBackground   SUBROUTINE 

    lda     ram_02      
    clc
    adc     #$01            
    sta     ram_02              ;... increment ram_02 

    lda     ram_02              
    cmp     #$ff 
    beq     .setToStart         ;... check if we have reach last possible color (255)

    ;CHECK COLORS               
    ;between some colors there is a difference of 16 per colors, such as 
    ;15 to 24, 31 to 40 and etc... 
    ;we check if we reach one of those ends, and add 16 to move to the next color
    ; *** check page 265 in the textbook *** 

    lda     ram_03               ;... ram_03 is the flag to know we need to add 16
    clc 
    adc     #$01                    
    sta     ram_03              

    lda     ram_03
    cmp     #$09       ;... reach and end of the color, pg 265 in book 
    beq     .plus16

    jmp     .end

.setToStart
    lda     #$08        ;... reach 255, thus set the flag back to the first color
    sta     ram_02      ;... which is 8
    jmp     .end

.plus16 
    lda     #$00 
    sta     ram_03      ;... reset the ram_03 flag

    lda     ram_02      
    clc 
    adc     #$10 
    sta     ram_02      ;... add 16 to ram_02 to move to the next color

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
ram_04     .byte $00 

	
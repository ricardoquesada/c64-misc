;--------------------------------------------------------------------------
;
; fli viewer
; original code taken from: https://github.com/jkotlinski/vicpack
;
;--------------------------------------------------------------------------

; exported by the linker
.import __MAIN_LOAD__, __SIDMUSIC_LOAD__


MUSIC_INIT := __SIDMUSIC_LOAD__
MUSIC_PLAY := __SIDMUSIC_LOAD__ + 3

.segment "CODE"
	jmp	start


.segment "MAIN"

start:
	jsr MUSIC_INIT

	sei

	; turn off BASIC + Kernal. More RAM
	lda #$35
	sta $01

	ldx #<irq
	ldy #>irq
	stx $fffe
	sty $ffff

	lda #00
	sta $d01a

	jsr sync_irq_timer
	cli

	jmp *

irq:
	pha			; saves A, X, Y
	txa
	pha
	tya
	pha

	inc $0400
	jsr MUSIC_PLAY

	asl $d019
	lda $dc0d

	pla			; restores A, X, Y
	tay
	pla
	tax
	pla
	rti			; restores previous PC, status


sync_irq_timer:

	lda #$00
	sta $dc0e		; stop timer

	ldy #$08
@wait:
	cpy $d012
	bne @wait
	lda $d011
	bmi @wait

	lda $02a6
	beq @ntsc

	; 50hz on PAL
	lda #<((63*312)-1)
	ldy #>((63*312)-1)
	jmp @nontsc
@ntsc:
	; 50hz on NTSC
	lda #<($4fb4)
	ldy #>($4fb4)
@nontsc:

	sta $dc04		; set timer
	sty $dc05

	lda #$11		; start timer, load latch into the timer once
	sta $dc0e
	rts



.segment "SIDMUSIC"
	 .incbin "1_45_Tune.sid",$7e



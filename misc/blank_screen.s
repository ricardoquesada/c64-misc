;--------------------------------------------------------------------------
;
; simple effect that blanks the screen
; by enable extended color mode and multicolor mode
;
;--------------------------------------------------------------------------

.segment "CODE"

	sei

	; turn off BASIC + Kernal. More RAM
	lda #$35
	sta $01

	; turn off cia interrups
	lda #$7f
	sta $dc0d
	sta $dd0d

	lda $d011
	and #$7f
	sta $d011

	lda rasterpos_top
	sta $d012

	ldx #<irq_top
	ldy #>irq_top
	stx $fffe
	sty $ffff

	; enable raster irq
	lda #01
	sta $d01a

	; ack possible interrups
	lda $dc0d
	lda $dd0d
	asl $d019

	cli

:	inc $3fff
	jmp :-

irq_top:
	pha			; saves A, X, Y
	txa
	pha
	tya
	pha

	lda #$00
	sta $d020

	; multicolor mode + extended color causes the bug that blanks the screen
	lda #%01011011
	sta $d011		; extended color mode: on
	lda #%00011000
	sta $d016		; turn on multicolor


	lda rasterpos_bottom
	sta $d012

	ldx #<irq_bottom
	ldy #>irq_bottom
	stx $fffe
	sty $ffff

	
	asl $d019

	pla			; restores A, X, Y
	tay
	pla
	tax
	pla
	rti			; restores previous PC, status

irq_bottom:
	pha			; saves A, X, Y
	txa
	pha
	tya
	pha

	lda #$0f
	sta $d020
	lda #%00011011
	sta $d011		; extended color mode: off
	lda #%00001000
	sta $d016		; turn off multicolor

	dec $d020

	lda rasterpos_top
	sta $d012

	ldx #<irq_top
	ldy #>irq_top
	stx $fffe
	sty $ffff
	
	asl $d019

	pla			; restores A, X, Y
	tay
	pla
	tax
	pla
	rti			; restores previous PC, status


rasterpos_top:	   .byte  $60
rasterpos_bottom:  .byte  $a0

; koala viewer

; exported by the linker
.import __KOALA_LOAD__

;--------------------------------------------------------------------------
; Macros
;--------------------------------------------------------------------------
.macpack mymacros		; my own macros

KOALA_BITMAP_DATA = __KOALA_LOAD__
KOALA_CHARMEM_DATA = KOALA_BITMAP_DATA + $1f40
KOALA_COLORMEM_DATA = KOALA_BITMAP_DATA + $2328
KOALA_BACKGROUND_DATA = KOALA_BITMAP_DATA + $2710

.segment "CODE"

	sei

	lda #$35
	sta $01			; disable all ROMs

	lda #$7f
	sta $dc0d		; no timer IRQs
	lda $dc0d		; clear timer IRQ flags

        ; multi color
	lda #%00011000
	sta $d016

	; hires bitmap mode
	lda #%00111011
	sta $d011

        ; bitmap at $2000
	lda #%00011111
	sta $d018

	lda #$00
	sta $d020
	lda KOALA_BACKGROUND_DATA
	sta $d021

        jsr init_koala_colors

	; enable raster irq
	lda #01
	sta $d01a

        ldx #<irq
        ldy #>irq
        stx $fffe
        sty $ffff

        lda #72
        sta $d012

	; clear interrupts and ACK irq
	asl $d019

        cli

        jmp *


;--------------------------------------------------------------------------
; IRQ handler
;--------------------------------------------------------------------------
irq:
	pha			; saves A, X, Y
	txa
	pha
	tya
	pha

	STABILIZE_RASTER

        .repeat 37
                nop
        .endrepeat

	sei

        .repeat 6
		; 7 "Good" lines: I must consume 63 cycles
                .repeat 7
                        lda colors,x	        ; +4
			sta $d020		; +4
			;sta $d021		; +4
                        nop
                        nop
			inx			; +2
			.repeat 23
				nop		; +2 * 23
			.endrepeat
			bit $00			; +3 = 63 cycles
		.endrepeat
		; 1 "Bad lines": I must consume 23 cycles
                lda colors,x	        	; +4
		sta $d020			; +4
		;sta $d021			; +4
                nop
                nop
		inx				; +2
		.repeat 3
			nop			; +2 * 3 
		.endrepeat
	.endrepeat

	ldx #<irq
	ldy #>irq
	stx $fffe
	sty $ffff

	lda #72
	sta $d012

	asl $d019
	cli

	pla			; restores A, X, Y
	tay
	pla
	tax
	pla
	rti			; restores previous PC, status

.align 256
colors:
        .byte $02,$02
        .byte $00,$00
        .byte $02,$02
        .byte $00,$00,$00,$00,$00,$00
        .byte $02,$02
        .byte $00,$00
        .byte $02,$02
        .byte $00,$00,$00,$00,$00,$00
        .byte $02,$02
        .byte $00,$00
        .byte $02,$02
        .byte $00,$00,$00,$00,$00,$00
        .byte $02,$02
        .byte $00,$00
        .byte $02,$02
        .byte $00,$00,$00,$00,$00
        .byte $00


;--------------------------------------------------------------------------
; init_koala_colors(void)
;--------------------------------------------------------------------------
; Args: -
; puts the koala colors in the correct address
; Assumes that bimap data was loaded in the correct position
;--------------------------------------------------------------------------
.proc init_koala_colors

	; Koala format
	; bitmap:           $0000 - $1f3f = $1f40 ( 8000) bytes
	; color %01 - %10:  $1f40 - $2327 = $03e8 ( 1000) bytes
	; color %11:        $2328 - $270f = $03e8 ( 1000) bytes
	; color %00:        $2710         =     1 (    1) byte
	; total:                    $2710 (10001) bytes

	ldx #$00
@loop:
	; $0400: colors %01, %10
	lda KOALA_CHARMEM_DATA,x
	sta $0400,x
	lda KOALA_CHARMEM_DATA+$0100,x
	sta $0400+$0100,x
	lda KOALA_CHARMEM_DATA+$0200,x
	sta $0400+$0200,x
	lda KOALA_CHARMEM_DATA+$02e8,x
	sta $0400+$02e8,x

	; $d800: color %11
	lda KOALA_COLORMEM_DATA,x
	sta $d800,x
	lda KOALA_COLORMEM_DATA+$0100,x
	sta $d800+$100,x
	lda KOALA_COLORMEM_DATA+$0200,x
	sta $d800+$200,x
	lda KOALA_COLORMEM_DATA+$02e8,x
	sta $d800+$02e8,x

	inx
	bne @loop
	rts
.endproc


.segment "KOALA"
         .incbin "pvm.koa",2


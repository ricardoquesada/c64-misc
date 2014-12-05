; code downloaded from: http://codebase64.org/doku.php?id=magazines:chacking3#rasters_-_what_they_are_and_how_to_use_them
; 
; modified it to compile with ACME
;
; run it with:
; sys 49152
;

!cpu 6502
!to "build/double-raster2.prg",cbm    ; output file

;============================================================
; BASIC loader with start address $c000
;============================================================

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152

* = $c000     				; start address for 6502 code

; some equates

COLOUR1 = 0
COLOUR2 = 1
LINE1 = 20
LINE2 = 150

; code starts

		sei                           ; disable interrupts

		lda #$7f                      ; turn off the cia interrupts
		sta $dc0d

		lda $d01a                     ; enable raster irq
		ora #$01
		sta $d01a

		lda $d011                     ; clear high bit of raster line
		and #$7f
		sta $d011

		lda #LINE1                    ; line number to go off at
		sta $d012                     ; low byte of raster line

		lda #<intcode                 ; get low byte of target routine
		sta $0314                     ; put into interrupt vector
		lda #>intcode                 ; do the same with the high byte
		sta $0315

		cli                           ; re-enable interrupts
		rts                           ; return to caller

intcode

		lda modeflag                  ; determine whether to do top or
		                              ; bottom of screen
		beq mode1
		jmp mode2

mode1

		lda #$01                      ; invert modeflag
		sta modeflag

		lda #COLOUR1                  ; set our colour
		sta $d020

		lda #LINE1                    ; setup line for NEXT interrupt
		sta $d012                     ; (which will activate MODE2)

		lda $d019
		sta $d019

		jmp $ea31                     ; MODE1 exits to Rom

mode2

		lda #$00                      ; invert modeflag
		sta modeflag

		lda #COLOUR2                  ; set our colour
		sta $d020

		lda #LINE2                    ; setup line for NEXT interrupt
		sta $d012                     ; (which will activate MODE1)

		lda $d019
		sta $d019

		pla                           ; we exit interrupt entirely.
		tay                           ; since happening 120 times per
		pla                           ; second, only 60 need to go to
		tax                           ; hardware Rom. The other 60 simply
		pla                           ; end
		rti

modeflag !byte 0
;coded by Graham/Oxyron

; code downloaded from: http://codebase64.org/doku.php?id=base:rasterbars_small_source
;
; modified it to compile with ACME
;
; run it with:
; sys 49152
;

!cpu 6502
!to "build/rasterbars.prg",cbm    ; output file


* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152

	*= $c000

	lda #$7f
	sta $dc0d
	and $d011
	sta $d011
	lda #$32
	sta $d012

	sei
	lda #<irq
	sta $0314
	lda #>irq
	sta $0315
	lda #$01
	sta $d01a
	cli
	rts

irq:
	lda #$ff
	sta $d019

	ldx #$05
d	dex
	bne d

	ldx #$00
c	ldy #$08
a	lda colors,x
	sta $d020
	sta $d021
	inx
	dey
	beq c

	txa
	ldx #$07
b	dex
	bne b
	tax

	cpx #$8c
	bcc a

	jmp $ea34

	*= $c100
colors
	!byte $09,$02,$08,$0a,$0f,$07,$01,$07,$0f,$0a,$08,$02,$09,$00
	!byte $06,$04,$0e,$05,$03,$0d,$01,$0d,$03,$05,$0e,$04,$06,$00
	!byte $09,$02,$08,$0a,$0f,$07,$01,$07,$0f,$0a,$08,$02,$09,$00
	!byte $06,$04,$0e,$05,$03,$0d,$01,$0d,$03,$05,$0e,$04,$06,$00
	!byte $09,$02,$08,$0a,$0f,$07,$01,$07,$0f,$0a,$08,$02,$09,$00
	!byte $06,$04,$0e,$05,$03,$0d,$01,$0d,$03,$05,$0e,$04,$06,$00
	!byte $09,$02,$08,$0a,$0f,$07,$01,$07,$0f,$0a,$08,$02,$09,$00
	!byte $06,$04,$0e,$05,$03,$0d,$01,$0d,$03,$05,$0e,$04,$06,$00
	!byte $09,$02,$08,$0a,$0f,$07,$01,$07,$0f,$0a,$08,$02,$09,$00
	!byte $06,$04,$0e,$05,$03,$0d,$01,$0d,$03,$05,$0e,$04,$06,$00

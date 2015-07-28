;--------------------------------------------------------------------------
;
; fli viewer
; original code taken from: https://github.com/jkotlinski/vicpack
;
;--------------------------------------------------------------------------

; exported by the linker
.import __MAIN_LOAD__, __FLI_LOAD__


.segment "CODE"
	jmp	start

tab18   = $0e00
tab11   = $0f00

.segment "MAIN"

irq0:	pha
	dec $d019
	inc $d012
	lda #<irq1
	sta $fffe		; set up 2nd IRQ to get a stable IRQ
	cli

	; Following here: A bunch of NOPs which allow the 2nd IRQ
	; to be triggered with either 0 or 1 clock cycle delay
	; resulting in an \"almost\" stable IRQ.

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
irq1:
	nop
	nop
	lda #$09
	sta $d018		; setup first color RAM address early
	lda #$38
	sta $d011		; setup first DMA access early
	pla
	pla
	pla
	dec $d019
	lda #$2d
	sta $d012
	lda #<irq0
	sta $fffe		; switch IRQ back to first stabilizer IRQ
	lda $d012
	cmp $d012		; stabilize last jittering cycle
	beq fj
fj:
	ldx #$0f
ff:	dex
	bne ff


				; Following here is the main FLI loop which forces the VIC-II to read
				; new color data each rasterline. The loop is exactly 23 clock cycles
				; long so together with 40 cycles of color DMA this will result in
				; 63 clock cycles which is exactly the length of a PAL C64 rasterline.
l0:
	inx
	lda tab18,x
	sta $d018		; set new color RAM address
	lda tab11,x
	sta $d011		; force new color DMA
	cpx #199		; last rasterline?
	bne l0
        lda #$30
        sta $d011		; open upper/lower border
	pla
nmi:
	rti

start:
	sei
	lda #$35
	sta $01			; disable all ROMs
	lda #$7f
	sta $dc0d		; no timer IRQs
	lda $dc0d		; clear timer IRQ flags
	lda #$2b
	sta $d011
	lda #$2d
	sta $d012
	lda #$18
	sta $d016
	lda #$09
	sta $d018
	lda #$96		; VIC bank $4000-$7FFF
	sta $dd00

;	ldx #__BORDERCOLOR__
	ldx #0
	stx $d020
	ldx __FLI_LOAD__ + $4340; backgrounnd color
	stx $d021
	; COPY 3c00-3fff to d800-dbff
	ldy #$04
	ldx #$00
	stx $d015		; disable sprites
ll:	lda $3c00,x
	sta $d800,x		; copy color RAM data
	inx
	bne ll
	inc ll+2
	inc ll+5
	dey
	bne ll
	; COPY done

	lda #<irq0
	sta $fffe
	lda #>irq0
	sta $ffff
	lda #<nmi
	sta $fffa
	lda #>nmi
	sta $fffb		; dummy NMI to avoid crashing due to RESTORE
	lda #$01
	sta $d01a		; enable raster IRQs

	; x = 0 (init val)
uv8:	
	txa
	asl
	asl
	asl
	asl

	; a = x << 4
	and #%01110000		; video matrixes at $4000 - 5FFF
	ora #8			; bitmap data at $6000
	sta tab18,x		; calculate $D018 table ; 8, 18, ... 78. alternate video matrix
	txa
	and #$07
	ora #$38		; bitmap
	sta tab11,x		; calculate $D011 table ; 38, 39, ... 3f. modify smooth scroll to y-position
	inx
	bne uv8

	dec $d019		; clear raster IRQ flag
	cli
	jmp *			; that's it, no more action needed

; link a demo picture
.segment "FLI"
	.incbin "test.fli",2
;	.incbin "pvm-color-sensitive.fli",2
;	.incbin "pvm-yuv-distance.fli",2
;	.incbin "pvm-rgb-distance.fli",2

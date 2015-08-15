;--------------------------------------------------------------------------
;
; vic detect
;
;--------------------------------------------------------------------------

;--------------------------------------------------------------------------
; Macros
;--------------------------------------------------------------------------
.macpack cbm			; adds support for scrcode

.segment "CODE"

	lda #$35
	sta $01

	jsr detect_pal_paln_ntsc

	cmp #$01
	beq pal_it_is

	cmp #$2f
	beq paln_it_is

	cmp #$2e
	beq ntsc_old_it_is

	cmp #$28
	beq ntsc_it_is

	; error it is
	ldx #<label_error
	jmp print

pal_it_is:
	ldx #<label_pal
	jmp print

paln_it_is:
	ldx #<label_paln
	jmp print

ntsc_old_it_is:
	ldx #<label_ntsc_old
	jmp print

ntsc_it_is:
	ldx #<label_ntsc
	jmp print

print:
	stx addr_ptr

	ldx #$00
addr_ptr = *+1
:	lda label_ntsc,x
	cmp #$ff
	beq end
	sta $0400,x
	inx
	bne :-

end:
	jmp *

label_ntsc:
	scrcode "--- ntsc ---" 
	.byte $ff

label_ntsc_old:
	scrcode "--- ntsc-old ---"
	.byte $ff

label_pal:
	scrcode "--- pal ---"
	.byte $ff

label_paln:
	scrcode "--- pal-n ---"
	.byte $ff

label_error:
	scrcode "--- error ---"
	.byte $ff


;--------------------------------------------------------------------------
; char detect_pal_paln_ntsc(void)
;--------------------------------------------------------------------------
; It counts how many rasterlines were drawn in 312*63-1 (19655) cycles. 
;
; In PAL,      (312 by 63)  19655/63 = 312  -> 312 % 312   (00, $00)
; In PAL-N,    (312 by 65)  19655/65 = 302  -> 302 % 312   (46, $2e)
; In NTSC,     (263 by 65)  19655/65 = 302  -> 302 % 263   (39, $27)
; In NTSC Old, (262 by 64)  19655/64 = 307  -> 307 % 262   (45, $2d) 
;
; Return values:
;   $01 --> PAL
;   $2F --> PAL-N
;   $28 --> NTSC
;   $2e --> NTSC-OLD
;
;--------------------------------------------------------------------------
.export vic_video_type
vic_video_type: .byte $00

.export detect_pal_paln_ntsc
.proc detect_pal_paln_ntsc
	sei

	; wait for start of raster (more stable results)
:	lda $d012
:	cmp $d012
	beq :-
	bmi :--

	lda #$00
	sta $dc0e

	lda #$00
	sta $d01a		; no raster IRQ
	lda #$7f
	sta $dc0d		; no timer IRQ
	sta $dd0d

	lda #$00
	sta sync

	ldx #<(312*63-1)	; set the timer for PAL
	ldy #>(312*63-1)
	stx $dc04
	sty $dc05

	lda #%00001001		; one-shot only
	sta $dc0e

	ldx #<timer_irq
	ldy #>timer_irq
	stx $fffe
	sty $ffff

	lda $dc0d		; clear possible interrupts
	lda $dd0d


	lda #$81
	sta $dc0d		; enable time A interrupts
	cli

:	lda sync
	beq :-

	lda vic_video_type
	rts

timer_irq:
	pha			; only saves A
	
	sei
	; timer A interrupt
	lda $dc0d		; clear the interrupt

	lda $d012
	sta vic_video_type

	inc sync
	cli

	pla			; restoring A
	rti

sync:		.byte $00

.endproc


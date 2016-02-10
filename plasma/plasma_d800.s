;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
;
; Simple plasma, based on the cc65 samples/plasma.c example
;
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;

; Use 1 to enable raster lines
DEBUG = 1

.segment "CODE"

        jsr clear_screen                ; clear screen

        lda #0
        sta $d020                       ; border color
        lda #0
        sta $d021                       ; background color

        lda #%00001000                  ; no scroll, hires (mono color),40-cols
        sta $d016

        sei

        lda #$7f                        ; turn off cia interrups
        sta $dc0d
        sta $dd0d

        lda #01                         ; enable raster irq
        sta $d01a

        ldx #<irq                       ; setup IRQ vector
        ldy #>irq
        stx $314
        sty $315

        lda $dc0d                       ; ack possible interrupts
        lda $dd0d
        asl $d019

        cli

main_loop:
        lda sync
        beq main_loop
        dec sync

.if DEBUG=1
        inc $d020
.endif
        jsr do_plasma
.if DEBUG=1
        dec $d020
.endif
        jmp main_loop


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; irq vector
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
irq:
        asl $d019

        inc sync

        jmp $ea81

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; clear_screen
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc clear_screen
        lda #$a0
        ldx #$00
loop1:  sta $0400,x                     ; clears the screen memory
        sta $0500,x
        sta $0600,x
        sta $06e8,x
        inx
        bne loop1

        lda #01
        ldx #$00
loop2:  sta $d800,x                    ; clears the color RAM
        sta $d900,x
        sta $da00,x
        sta $dae8,x
        inx
        bne loop2
        rts
.endproc

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; do_plasma
; animates the plasma
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc do_plasma
        ldx x_idx_a
        ldy y_idx_a
        .repeat 13, YY
                lda sine_table, x
                adc sine_table, y
                sta y_buf + YY
                txa
                clc
                adc #4                  ; 4
                tax
                tya
                clc
                adc #9                  ; 9
                tay
        .endrepeat

        lda x_idx_a
        clc
        adc #03                         ; 3
        sta x_idx_a
        lda y_idx_a
        sec
        sbc #02                         ; -5
        sta y_idx_a

        ;----------

        ldx x_idx_b
        ldy y_idx_b

        .repeat 40, XX
                lda sine_table, x
                adc sine_table, y
                sta x_buf + XX
                txa
                clc
                adc #3                  ; 3
                tax
                tya
                clc
                adc #7                  ; 7
                tay
        .endrepeat

        lda x_idx_b
        clc
        adc #02                         ; 2
        sta x_idx_b
        lda y_idx_b
        sec
        sbc #3                          ; -3
        sta y_idx_b

        .repeat 13, YY
        .repeat 40, XX
                lda x_buf + XX
                adc y_buf + YY
                tax
                lda luminances, x
                sta $d800 + YY * 40 + XX
                sta $d800 + (24-YY) * 40 + XX
        .endrepeat
        .endrepeat

        rts

x_idx_a:
        .byte 0
y_idx_a:
        .byte 128
x_idx_b:
        .byte 0
y_idx_b:
        .byte 128
.endproc




;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; global variables
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.DATA
sync:
        .byte 0

luminances:
.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
.byte $0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d
.byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
.byte $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
.byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
.byte $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
.byte $0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a
.byte $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
.byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
.byte $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
.byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
.byte $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
.byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
.byte $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09
.byte $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

sine_table:
; autogenerated table: easing_table_generator.py -s128 -m255 -aTrue -r bezier:0,0.02,0.98,1
.byte   0,  0,  1,  1,  2,  2,  3,  4
.byte   4,  5,  6,  7,  8, 10, 11, 12
.byte  14, 15, 17, 18, 20, 21, 23, 25
.byte  27, 29, 31, 33, 35, 37, 39, 41
.byte  44, 46, 48, 51, 53, 55, 58, 60
.byte  63, 66, 68, 71, 73, 76, 79, 82
.byte  84, 87, 90, 93, 96, 98,101,104
.byte 107,110,113,116,119,122,125,128
.byte 130,133,136,139,142,145,148,151
.byte 154,157,159,162,165,168,171,173
.byte 176,179,182,184,187,189,192,195
.byte 197,200,202,204,207,209,211,214
.byte 216,218,220,222,224,226,228,230
.byte 232,234,235,237,238,240,241,243
.byte 244,245,247,248,249,250,251,251
.byte 252,253,253,254,254,255,255,255
; reversed
.byte 255,255,254,254,253,253,252,251
.byte 251,250,249,248,247,245,244,243
.byte 241,240,238,237,235,234,232,230
.byte 228,226,224,222,220,218,216,214
.byte 211,209,207,204,202,200,197,195
.byte 192,189,187,184,182,179,176,173
.byte 171,168,165,162,159,157,154,151
.byte 148,145,142,139,136,133,130,128
.byte 125,122,119,116,113,110,107,104
.byte 101, 98, 96, 93, 90, 87, 84, 82
.byte  79, 76, 73, 71, 68, 66, 63, 60
.byte  58, 55, 53, 51, 48, 46, 44, 41
.byte  39, 37, 35, 33, 31, 29, 27, 25
.byte  23, 21, 20, 18, 17, 15, 14, 12
.byte  11, 10,  8,  7,  6,  5,  4,  4
.byte   3,  2,  2,  1,  1,  0,  0,  0

.BSS

x_buf:
.res 40
y_buf:
.res 25


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
;
; Bitmap Multicolor plotter
;
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;

; Use 1 to enable raster lines
DEBUG = 1

.segment "CODE"

        sei

        jsr clear_screen                ; clear screen

        lda #0
        sta $d020                       ; border color
        sta $d021                       ; background color

        lda #%00011011                  ; text on
        sta $d011

        lda #%00011000                  ; no scroll, multi color,40-cols
        sta $d016

        lda #%00011000                  ; charset = $2000, screen $0400,
        sta $d018

        lda #$7f                        ; turn off cia interrups
        sta $dc0d
        sta $dd0d

        lda #01                         ; enable raster irq
        sta $d01a

        lda #$35
        sta $01                         ; No BASIC, no KERNAL. Yes IO

        ldx #<irq_vector                ; setup IRQ vector
        ldy #>irq_vector
        stx $fffe
        sty $ffff

        lda #50
        sta $d012                       ; trigger IRQ at beginning of border

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

        jsr shift_sin_table
        jsr do_plotter

.if DEBUG=1
        dec $d020
.endif

        jmp main_loop


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; clear_screen
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc clear_screen

        ldx #0                          ; clear charset: $2000 - $2800
        lda #$00
@l0:
        .repeat 8, XX
                sta $2000 + $0100 * XX, x
        .endrepeat

        dex
        bne @l0

        ldx #0
        lda #$ff
@l1:    sta $0400, x
        sta $0500, x
        sta $0600, x
        sta $06e8, x
        dex
        bne @l1

        ldx #0
        .repeat 16, YY
                .repeat 16, XX
                        lda ident_array, x
                        sta $0400 + 40 * YY + XX
                        inx
                .endrepeat
        .endrepeat

        ldx #0                          ; color #3: bitmask 11
        lda #$03
@l2:    sta $d800, x
        sta $d900, x
        sta $da00, x
        sta $dae8, x
        dex
        bne @l2

        rts
.endproc

ident_array:
        .repeat 256, AA
                .byte AA
        .endrepeat

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; void plot(int x, int y, a=color)
; uses $f8/$f9 as tmp variable
; modifies Y
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.macro PLOT_PIXEL
        lda table_y_lo, y
        sta $f8

        lda table_y_hi, y
        sta $f9

        ldy table_x_lo, x

        lda ($f8), y
        eor table_mask, x
        sta ($f8), y
.endmacro

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; do_plotter
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc do_plotter

        ldx #127

@l0:
        lda sin_table, x
        tay

        PLOT_PIXEL

        dex
        bne @l0

        rts
.endproc

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; shift_sin_table
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc shift_sin_table

        ldx sin_table

        .repeat 127, XX
                lda sin_table + XX + 1
                sta sin_table + XX + 0
        .endrepeat

        stx sin_table + 127

        rts
.endproc

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; irq_vector
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc irq_vector
        pha                             ; saves A, X, Y
        txa
        pha
        tya
        pha

        asl $d019                       ; clears raster interrupt

        inc sync

        pla                             ; restores A, X, Y
        tay
        pla
        tax
        pla
        rti                             ; restores previous PC, status

.endproc


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; address = (table_y + table_x) % table_x_mask
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
BITMAP_ADDR = $2000
table_y_lo:
        .repeat 16, YY
                .byte <(BITMAP_ADDR + 0 + 128 * YY)
                .byte <(BITMAP_ADDR + 1 + 128 * YY)
                .byte <(BITMAP_ADDR + 2 + 128 * YY)
                .byte <(BITMAP_ADDR + 3 + 128 * YY)
                .byte <(BITMAP_ADDR + 4 + 128 * YY)
                .byte <(BITMAP_ADDR + 5 + 128 * YY)
                .byte <(BITMAP_ADDR + 6 + 128 * YY)
                .byte <(BITMAP_ADDR + 7 + 128 * YY)
        .endrepeat

table_y_hi:
        .repeat 16, YY
                .byte >(BITMAP_ADDR + 0 + 128 * YY)
                .byte >(BITMAP_ADDR + 1 + 128 * YY)
                .byte >(BITMAP_ADDR + 2 + 128 * YY)
                .byte >(BITMAP_ADDR + 3 + 128 * YY)
                .byte >(BITMAP_ADDR + 4 + 128 * YY)
                .byte >(BITMAP_ADDR + 5 + 128 * YY)
                .byte >(BITMAP_ADDR + 6 + 128 * YY)
                .byte >(BITMAP_ADDR + 7 + 128 * YY)
        .endrepeat

table_x_lo:
        .repeat 16, XX
                .byte <(XX * 8)
                .byte <(XX * 8)
                .byte <(XX * 8)
                .byte <(XX * 8)
                .byte <(XX * 8)
                .byte <(XX * 8)
                .byte <(XX * 8)
                .byte <(XX * 8)
        .endrepeat

table_x_hi:
        .repeat 16, XX
                .byte >(XX * 8)
                .byte >(XX * 8)
                .byte >(XX * 8)
                .byte >(XX * 8)
                .byte >(XX * 8)
                .byte >(XX * 8)
                .byte >(XX * 8)
                .byte >(XX * 8)
        .endrepeat

table_mask:
        .repeat 16
                .byte %11000000
                .byte %11000000
                .byte %00110000
                .byte %00110000
                .byte %00001100
                .byte %00001100
                .byte %00000011
                .byte %00000011
        .endrepeat

table_mask_neg:
        .repeat 16
                .byte %00111111
                .byte %00111111
                .byte %11001111
                .byte %11001111
                .byte %11110011
                .byte %11110011
                .byte %11111100
                .byte %11111100
        .endrepeat

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
;
; variables
;
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
sync:
        .byte 0

sin_table:
; autogenerated table: easing_table_generator.py -s64 -m128 -aTrue -r bezier:0,0.01,0.99,1
.byte   0,  0,  1,  2,  2,  3,  5,  6
.byte   7,  9, 10, 12, 14, 16, 18, 20
.byte  23, 25, 27, 30, 33, 35, 38, 41
.byte  44, 46, 49, 52, 55, 58, 61, 64
.byte  67, 70, 73, 76, 79, 82, 84, 87
.byte  90, 93, 95, 98,101,103,105,108
.byte 110,112,114,116,118,119,121,122
.byte 123,125,126,126,127,128,128,128
; reversed
.byte 128,128,127,126,126,125,123,122
.byte 121,119,118,116,114,112,110,108
.byte 105,103,101, 98, 95, 93, 90, 87
.byte  84, 82, 79, 76, 73, 70, 67, 64
.byte  61, 58, 55, 52, 49, 46, 44, 41
.byte  38, 35, 33, 30, 27, 25, 23, 20
.byte  18, 16, 14, 12, 10,  9,  7,  6
.byte   5,  3,  2,  2,  1,  0,  0,  0

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

        lda #%00111011                  ; bitmap on
        sta $d011

        lda #%00011000                  ; no scroll, multi color,40-cols
        sta $d016

        lda #%00011100                  ; bitmap = $2000, screen $0400,
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

        jsr do_plotter
        jsr shift_sin_table

.if DEBUG=1
        dec $d020
.endif

        jmp main_loop


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; clear_screen
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc clear_screen

        ldx #0                          ; clear bitmap area
        lda #$00
@l0:
        .repeat 32, XX
                sta $2000 + $0100 * XX, x
        .endrepeat

        dex
        bne @l0

        ldx #0                          ; screen RAM colors #1 & #2. bitmask 01 & 10
        lda #$11                        ; white / white
@l1:    sta $0400, x
        sta $0500, x
        sta $0600, x
        sta $06e8, x
        dex
        bne @l1

        ldx #0                          ; color #3: bitmask 11
        lda #$01
@l2:    sta $d800, x
        sta $d900, x
        sta $da00, x
        sta $dae8, x
        dex
        bne @l2

        rts
.endproc

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; void plot(int x, int y, a=color)
; uses $f8/$f9 as tmp variable
; modifies Y
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.macro PLOT_PIXEL
        clc
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

        ldx #0

@l0:
        lda sin_table, x
        tay

        PLOT_PIXEL

        inx
        bne @l0

        rts
.endproc

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; shift_sin_table
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc shift_sin_table

        ldx sin_table

        ldy #0
@l0:
        lda sin_table + 1, y
        sta sin_table, y

        iny
        bne @l0

        stx sin_table + 255

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
        .repeat 25, YY
                .byte <(BITMAP_ADDR + 0 + 320 * YY)
                .byte <(BITMAP_ADDR + 1 + 320 * YY)
                .byte <(BITMAP_ADDR + 2 + 320 * YY)
                .byte <(BITMAP_ADDR + 3 + 320 * YY)
                .byte <(BITMAP_ADDR + 4 + 320 * YY)
                .byte <(BITMAP_ADDR + 5 + 320 * YY)
                .byte <(BITMAP_ADDR + 6 + 320 * YY)
                .byte <(BITMAP_ADDR + 7 + 320 * YY)
        .endrepeat

table_y_hi:
        .repeat 25, YY
                .byte >(BITMAP_ADDR + 0 + 320 * YY)
                .byte >(BITMAP_ADDR + 1 + 320 * YY)
                .byte >(BITMAP_ADDR + 2 + 320 * YY)
                .byte >(BITMAP_ADDR + 3 + 320 * YY)
                .byte >(BITMAP_ADDR + 4 + 320 * YY)
                .byte >(BITMAP_ADDR + 5 + 320 * YY)
                .byte >(BITMAP_ADDR + 6 + 320 * YY)
                .byte >(BITMAP_ADDR + 7 + 320 * YY)
        .endrepeat

table_x_lo:
        .repeat 40, XX
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
        .repeat 40, XX
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
        .repeat 40
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
        .repeat 40
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
; autogenerated table: easing_table_generator.py -s256 -m199 -aTrue sin
.byte   2,  5,  7, 10, 12, 15, 17, 20
.byte  22, 24, 27, 29, 32, 34, 36, 39
.byte  41, 44, 46, 48, 51, 53, 55, 58
.byte  60, 62, 65, 67, 69, 72, 74, 76
.byte  78, 81, 83, 85, 87, 89, 92, 94
.byte  96, 98,100,102,104,106,109,111
.byte 113,115,117,119,120,122,124,126
.byte 128,130,132,134,135,137,139,141
.byte 142,144,146,147,149,151,152,154
.byte 155,157,158,160,161,163,164,165
.byte 167,168,169,171,172,173,174,176
.byte 177,178,179,180,181,182,183,184
.byte 185,186,187,187,188,189,190,190
.byte 191,192,192,193,194,194,195,195
.byte 196,196,196,197,197,198,198,198
.byte 198,198,199,199,199,199,199,199
.byte 199,199,199,199,199,198,198,198
.byte 198,198,197,197,196,196,196,195
.byte 195,194,194,193,192,192,191,190
.byte 190,189,188,187,187,186,185,184
.byte 183,182,181,180,179,178,177,176
.byte 174,173,172,171,169,168,167,165
.byte 164,163,161,160,158,157,155,154
.byte 152,151,149,147,146,144,142,141
.byte 139,137,135,134,132,130,128,126
.byte 124,122,120,119,117,115,113,111
.byte 109,106,104,102,100, 98, 96, 94
.byte  92, 89, 87, 85, 83, 81, 78, 76
.byte  74, 72, 69, 67, 65, 62, 60, 58
.byte  55, 53, 51, 48, 46, 44, 41, 39
.byte  36, 34, 32, 29, 27, 24, 22, 20
.byte  17, 15, 12, 10,  7,  5,  2,  0

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; Scroller using bitmap
; 
; Compile using:
;    cl65 -o bitmap-1x2-scroller.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg bitmap-1x2-scroller.s
;       
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; Macros
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.macpack cbm                            ; adds support for scrcode

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; Constants
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.include "c64.inc"                      ; c64 constants

DEBUG = 1                               ; rasterlines:1, music:2, all:3

BITMAP_ADDR = $2000 + 8 * 40 * 12


.segment "CODE"
        sei

        lda #$35                        ; no basic, no kernal
        sta $01

        jsr clear_screen                ; clear screen
        jsr init_bitmap

        lda #0
        sta $d020                       ; border color
        lda #0
        sta $d021                       ; background color

        lda #%00001000                  ; no scroll, hires (mono color), 40-cols
        sta $d016
        
        lda #%00111011                  ; bitmap mode, default scroll-Y position, 25-rows
        sta $d011

        lda #%00011100                  ; bitmap addr: $2000, charset $1800 (not-used), video RAM: $0400
        sta $d018

        lda #$7f                        ; turn off cia interrups
        sta $dc0d
        sta $dd0d

        lda #01                         ; enable raster irq
        sta $d01a

        ldx #<irq                       ; setup IRQ vector
        ldy #>irq
        stx $fffe
        sty $ffff

        
        lda #$50
        sta $d012

        lda $dc0d                       ; ack possible interrupts
        lda $dd0d
        asl $d019

        cli

main_loop:
        lda sync_raster
        beq :+
        jsr do_raster_anims
:
        jmp main_loop

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; do_raster_anims
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc do_raster_anims
.if (::DEBUG & 1)
        inc $d020
.endif
        lda #0
        sta sync_raster
        jsr animate_scroll
.if (::DEBUG & 1)
        dec $d020
.endif
        rts
.endproc

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; animate_scroll
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc animate_scroll

        ; zero page variables f0-f9 are being used by the sid player (I guess)
        ; use fa-ff then
        lda #0
        sta $fa                         ; tmp variable

        ldx #<charset
        ldy #>charset
        stx $fc
        sty $fd                         ; pointer to charset

load_scroll_addr = * + 1
        lda scroll_text                 ; self-modifying
        cmp #$ff
        bne next
        ldx #0
        stx bit_idx
        ldx #<scroll_text
        ldy #>scroll_text
        stx load_scroll_addr
        sty load_scroll_addr+1
        lda scroll_text

next:
        clc                             ; char_idx * 8
        asl
        rol $fa
        asl
        rol $fa
        asl
        rol $fa

        tay                             ; char_def = ($fc),y
        sty $fb                         ; to be used in the bottom part of the char

        clc
        lda $fd
        adc $fa                         ; A = charset[char_idx * 8]
        sta $fd

        ; scroll top 8 bytes (right to left, and left to right)
        ; YY = char rows
        ; SS = bitmap cols
        .repeat 8, YY
                lda ($fc),y
                ldx bit_idx             ; set C according to the current bit index
:               asl
                dex
                bpl :-

                php                     ; save carry

                ; right to left
                .repeat 20, SS
                        rol BITMAP_ADDR + (39 - SS) * 8 + YY
                .endrepeat

                plp                     ; restore carry

                ; left to right
                .repeat 20, SS
                        ror BITMAP_ADDR + SS * 8 + YY
                .endrepeat
                iny                     ; byte of the char
        .endrepeat


        ; fetch bottom part of the char
        ; and repeat the same thing
        ; which is 1024 chars appart from the previous.
        ; so, I only have to add #4 to $fd
        clc
        lda $fd
        adc #04                         ; the same thing as adding 1024
        sta $fd

        ldy $fb                         ; restore Y from tmp variable

        ; scroll middle 8 bytes
        ; YY = char rows
        ; SS = bitmap cols
        .repeat 8, YY
                lda ($fc),y
                ldx bit_idx             ; set C according to the current bit index
:               asl
                dex
                bpl :-

                php

                .repeat 20, SS
                        rol BITMAP_ADDR + 40 * 8 + (39 - SS) * 8 + YY
                .endrepeat

                plp

                .repeat 20, SS
                        ror BITMAP_ADDR + 40 * 8 + SS * 8 + YY
                .endrepeat
                iny                     ; byte of the char
        .endrepeat

        ldx bit_idx
        inx
        cpx #8
        bne l1

        ldx #0
        clc
        lda load_scroll_addr
        adc #1
        sta load_scroll_addr
        bcc l1
        inc load_scroll_addr+1
l1:
        stx bit_idx

        rts

bit_idx:
        .byte 0                         ; points to the bit displayed
.endproc

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; init_bitmap
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc init_bitmap

        lda #$00
        tax
       
l0:
        .repeat 32,II                   ; clear bitmap memory
        sta $2000 + 256 * II,x
        .endrepeat
        dex
        bne l0


        lda #%00010000                  ; white foreground, black background
l1:
        sta $400,x
        sta $500,x
        sta $600,x
        sta $6e8,x
        dex
        bne l1
        
        rts
.endproc

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; clear_screen
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc clear_screen
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
; irq vector
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc irq
        pha                             ; saves A, X, Y
        txa
        pha
        tya
        pha

        asl $d019                       ; clears raster interrupt

        lda #1
        sta sync_raster

        pla                             ; restores A, X, Y
        tay
        pla
        tax
        pla
        rti                             ; restores previous PC, status
.endproc




;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; global variables
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
sync_raster:            .byte 0         ; used to sync raster


; starts with an empty (white) palette

scroll_text:
        scrcode "...Hola amiguitos... como les va che... probando scroll con bitmap... nada del otro mundo aca, solo un scroll simple... es modo bitmap hi-res. "
        .byte 96,97
        .byte 96,97
        .byte 96,97
        .byte $ff


; charset to be used for sprites here
charset:
        .incbin "font_caren_1x2-charset.bin"


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; Scroller using 8 sprites
; 
; Compile using:
;    cl65 -o sprite-1x2-scroller.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg sprite-1x2-scroller.s
;       
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;

SPRITE_ADDR = $2000

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; Macros
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.macpack cbm                            ; adds support for scrcode

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; Constants
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.include "c64.inc"                      ; c64 constants

DEBUG = 0                               ; rasterlines:1, music:2, all:3


.segment "CODE"
        sei

        lda #$35                        ; no basic, no kernal
        sta $01

        jsr clear_screen                ; clear screen

        lda #0
        sta $d020                       ; border color
        lda #0
        sta $d021                       ; background color

        jsr init_sprites

        lda #%00001000                  ; no scroll, hires (mono color),40-cols
        sta $d016

        lda #$7f                        ; turn off cia interrups
        sta $dc0d
        sta $dd0d

        lda #01                         ; enable raster irq
        sta $d01a

        ldx #<irq                       ; setup IRQ vector
        ldy #>irq
        stx $fffe
        sty $ffff

        lda #%00011011                  ; set char mode
        sta $d011
        
        lda #$00                        ; open top/bottom borders
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
        ; use 2a-2f then
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


        ; scroll top 8 bytes
        ; YY = sprite rows
        ; SS = sprite number
        .repeat 8, YY
                lda ($fc),y
                ldx bit_idx             ; set C according to the current bit index
:               asl
                dex
                bpl :-

        .repeat 8, SS
                rol SPRITE_ADDR + (7 - SS) * 64 + YY * 3 + 2
                rol SPRITE_ADDR + (7 - SS) * 64 + YY * 3 + 1
                rol SPRITE_ADDR + (7 - SS) * 64 + YY * 3 + 0
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
        ; YY = sprite rows
        ; SS = sprite number
        .repeat 8, YY
                lda ($fc),y
                ldx bit_idx             ; set C according to the current bit index
:               asl
                dex
                bpl :-

        .repeat 8, SS
                rol SPRITE_ADDR + (7 - SS) * 64 + YY * 3 + 24 + 2
                rol SPRITE_ADDR + (7 - SS) * 64 + YY * 3 + 24 + 1
                rol SPRITE_ADDR + (7 - SS) * 64 + YY * 3 + 24 + 0
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
; init_sprites 
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc init_sprites
        lda #255; enable all sprites
        sta VIC_SPR_ENA

        lda #0
        sta $d010                       ; no 8-bit on for sprites x
        sta $d017                       ; no y double resolution
        sta $d01d                       ; no x double resolution
        sta $d01c                       ; no sprite multi-color. hi-res only


        ldx #7
        ldy #14
l1:
        lda sprite_x_pos,x
        sta VIC_SPR0_X,y
        lda #128
        sta VIC_SPR0_Y,y
        lda #1                          ; white color
        sta VIC_SPR0_COLOR,x            ; all sprites are white
        lda sprite_pointers,x
        sta $07f8,x                     ; sprite pointers
        dey
        dey
        dex
        bpl l1

        lda #0                          ; all sprites are clean
        tax
l2:     sta SPRITE_ADDR,x               ; 8 sprites = 512 bytes = 64 * 8
        sta SPRITE_ADDR+$100,x
        dex
        bne l2

        rts
sprite_x_pos:
.byte 183-24*4, 183-24*3, 183-24*2, 183-24*1
.byte 183+24*0, 183+24*1, 183+24*2, 183+24*3
sprite_pointers:
        .byte (SPRITE_ADDR/64)+0, (SPRITE_ADDR/64)+1, (SPRITE_ADDR/64)+2, (SPRITE_ADDR/64)+3
        .byte (SPRITE_ADDR/64)+4, (SPRITE_ADDR/64)+5, (SPRITE_ADDR/64)+6, (SPRITE_ADDR/64)+7
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
; clear_screen
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc clear_screen
        lda #$20
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
; global variables
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
sync_raster:            .byte 0         ; used to sync raster


; starts with an empty (white) palette

scroll_text:
        scrcode "...Hola amiguitos... como les va che... probando scroll con sprites... nada del otro mundo aca... "
        .byte 96,97
        .byte 96,97
        .byte 96,97
        .byte $ff


; charset to be used for sprites here
charset:
        .incbin "font_caren_1x2-charset.bin"


;
; scrolling 2x2 test
; Compile it with KickAssembler: http:;www.theweb.dk/KickAssembler/Main.php
;


; Use 1 to enable raster-debugging in music
DEBUG = 0

SCROLL_AT_LINE = 12
RASTER_START = 50

SCREEN = $0400 + SCROLL_AT_LINE * 40
SPEED = 3

MUSIC_INIT = $1000
MUSIC_PLAY = $1003

.macpack cbm                                    ; adds support for scrcode

.segment "CODE"

        jsr $ff81                                   ; Init screen

        ; default is #$15  #00010101
        lda #%00011110
        sta $d018                                   ; Logo font at $3800

        sei

        ; turn off cia interrups
        lda #$7f
        sta $dc0d
        sta $dd0d

        lda $d01a                                   ; enable raster irq
        ora #$01
        sta $d01a

        lda $d011                                   ; clear high bit of raster line
        and #$7f
        sta $d011

        ; irq handler
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        ; raster interrupt
        lda #RASTER_START+SCROLL_AT_LINE*8-1
        sta $d012

        ; clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019

        lda #$00
        tax
        tay

        ; init music
        lda #0
        jsr MUSIC_INIT

        cli

        ; set multi colors
        lda #$01
        sta $d021
        lda #$02
        sta $d022
        lda #$0c
        sta $d023

        ; char color
        ldx #0
        lda #$0b
:       sta $d800 + SCROLL_AT_LINE * 40,x
        inx
        cpx #80
        bne :-



mainloop:
        lda sync                                    ; init sync
        and #$00
        sta sync
:       cmp sync
        beq :-

        jsr scroll
        jmp mainloop

irq1:
        ; make the raster more stable
.repeat 10
        nop
.endrepeat
        asl $d019

        lda #<irq2
        sta $0314
        lda #>irq2
        sta $0315

        lda #RASTER_START+(SCROLL_AT_LINE+2)*8
        sta $d012

        lda #0
        sta $d020

        lda scroll_x
        ora #%00010000          ; set MCM on
        sta $d016

        jmp $ea81


irq2:
        asl $d019

        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        ; FIXME If I don't add the -1 it won't scroll correctly.
        ; FIXME Raster is not stable.
        lda #RASTER_START+SCROLL_AT_LINE*8-1
        sta $d012

        lda #1
        sta $d020

        ; no scrolling, 40 cols
        lda #%00011000
        sta $d016

        inc sync

.if DEBUG=1
        inc $d020
.endif
        jsr MUSIC_PLAY
.if DEBUG=1
        dec $d020
.endif

        jmp $ea31

scroll:
        ; speed control
        ldx scroll_x

.repeat SPEED
        dec scroll_x
.endrepeat

        lda scroll_x
        and #07
        sta scroll_x

        cpx scroll_x
        bcc :+
        rts

:
        ; move the chars to the left
        ldx #0
:       lda SCREEN+1,x                          ; scroll top part of 1x2 char
        sta SCREEN,x
        lda SCREEN+40+1,x                       ; scroll bottom part of 1x2 char
        sta SCREEN+40,x
        inx
        cpx #39
        bne :-

        ; put next char in column 40
        ldx lines_scrolled
        lda label,x
        cmp #$ff
        bne :+

        ; reached $ff ? Then start from the beginning
        lda #0
        sta lines_scrolled
        sta half_char
        lda label

:       ora half_char                           ; right part ? left part will be 0

        sta SCREEN+39                           ; top part of the 2x2
        ora #$80                                ; bottom part is 128 chars ahead in the charset
        sta SCREEN+40+39                        ; bottom part of the 1x2 char

        ; half char
        lda half_char
        eor #$40
        sta half_char
        bne endscroll

        ; only inc lines_scrolled after 2 chars are printed
        inx
        stx lines_scrolled

endscroll:
        rts


; variables
sync:           .byte 1
scroll_x:       .byte 7
speed:          .byte SPEED
lines_scrolled: .byte 0
half_char:      .byte 0

label:
                scrcode  "hello world, testing 2x2 multi color scroller abcdefghijklmnopqrstuvwxzy 0123456789 ./(), "
                .byte $ff

.segment "CHARSET"
        .incbin "fonts/shackled_xy_multi.64c",2

.segment "SIDMUSIC"
         .incbin "music.sid",$7e


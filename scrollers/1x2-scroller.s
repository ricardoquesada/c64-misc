;
; scrolling 1x2 test
; Compile it using cc65: http://cc65.github.io/cc65/
;
; Command line:
;    cl65 -o file.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg 1x2-scroller.s
;


.macpack cbm

; exported by the linker
.import __SIDMUSIC_LOAD__

; defines
; Use 1 to enable raster-debugging in music
DEBUG = 1

SCROLL_AT_LINE = 12
RASTER_START = 50

SCREEN = $0400 + SCROLL_AT_LINE * 40
SPEED = 1

MUSIC_INIT = __SIDMUSIC_LOAD__
MUSIC_PLAY = __SIDMUSIC_LOAD__ + 3

.segment "CODE"

        jsr $ff81           ; Init screen

        ; default is #$15  #00010101
        lda #%00011110
        sta $d018           ; Logo font at $3800

        sei

        ; turn off cia interrups
        lda #$7f
        sta $dc0d
        sta $dd0d

        lda $d01a           ; enable raster irq
        ora #$01
        sta $d01a

        lda $d011           ; clear high bit of raster line
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

        lda #0
        jsr MUSIC_INIT

        cli



mainloop:
        lda sync            ; init sync
        and #$00
        sta sync
@0:     cmp sync
        beq @0

        jsr scroll
        jmp mainloop

irq1:
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
        sta $d016

        jmp $ea81


irq2:
        asl $d019

        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        lda #RASTER_START+SCROLL_AT_LINE*8-1
        sta $d012

        lda #1
        sta $d020

        ; no scrolling, 40 cols
        lda #%00001000
        sta $d016

        inc sync

.if DEBUG = 1
        inc $d020
.endif

        jsr MUSIC_PLAY

.if DEBUG = 1
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
        bcc @0
        rts

@0:

        ; move the chars to the left
        ldx #0
@1:     lda SCREEN+1,x          ; scroll top part of 1x2 char
        sta SCREEN,x
        lda SCREEN+40+1,x       ; scroll bottom part of 1x2 char
        sta SCREEN+40,x
        inx
        cpx #39
        bne @1

        ; put next char in column 40
        ldx lines_scrolled
        lda label,x
        cmp #$ff
        bne @2

        ; reached $ff ? Then start from the beginning
        ldx #0
        stx lines_scrolled
        lda label

@2:     sta SCREEN+39       ; top part of the 1x2 char
        ora #$40            ; bottom part is 64 chars ahead in the charset
        sta SCREEN+40+39    ; bottom part of the 1x2 char
        inx
        stx lines_scrolled

endscroll:
        rts


; variables
sync:           .byte 1
scroll_x:       .byte 7
speed:          .byte SPEED
lines_scrolled: .byte 0

label:
                scrcode "hello world! abc def ghi jkl mno pqr stu vwx yz 01234567890 .()"
                .byte $ff


.segment "CHARSET"
         ; !bin "fonts/1x2-chars.raw"
         ; !bin "fonts/devils_collection_25_y.64c",,2
         .incbin "fonts/devils_collection_26_y.64c",2

.segment "SIDMUSIC"
         .incbin "music.sid",$7e

;
; scrolling 2x2 test
; Compile it using cc65: http://cc65.github.io/cc65/
;
; Command line:
;    cl65 -o file.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg 2x1-scroller.s
;


; Use 1 to enable raster-debugging in music
DEBUG = 1

SCROLL_AT_LINE = 12
RASTER_START = 50

SCREEN = $0400 + SCROLL_AT_LINE * 40
SPEED = 2

.macpack cbm
.code
        jsr $ff81                               ; Init screen

        ; default is #$15  #00010101
        lda #%00011110
        sta $d018                               ; Logo font at $3800

        sei

        ; turn off cia interrups
        lda #$7f
        sta $dc0d
        sta $dd0d

        lda $d01a                               ; enable raster irq
        ora #$01
        sta $d01a

        lda $d011                               ; clear high bit of raster line
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

        ; Init music
        lda #0          ; start song
        jsr $1000

        cli


mainloop:
        lda sync                                ; init sync
        and #$00
        sta sync
:       cmp sync
        beq :-

        jsr scroll
        jmp mainloop

irq1:
        asl $d019

        lda #<irq2
        sta $0314
        lda #>irq2
        sta $0315

        lda #RASTER_START+(SCROLL_AT_LINE+1)*8
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

;        jsr $1003

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
        bcc :+
        rts
:

        ; move the chars to the left
        ldx #0
@loop:  lda SCREEN+1,x                      ; scroll top part of 1x2 char
        sta SCREEN,x
        inx
        cpx #39
        bne @loop

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


:       ora half_char                       ; right part ? left part will be 0

        sta SCREEN+39                       ; top part of the 2x2
        ora #$80                            ; bottom part is 128 chars ahead in the charset
        sta SCREEN+40+39                    ; bottom part of the 1x2 char

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

label:          scrcode "hello world! abc def ghi jkl mno pqr stu vwx yz 01234567890 @!()/"
                .byte $ff


;.pc = music.location "Music"
;        .fill music.size, music.getData(i)

.segment "CHARSET"
         ; !bin "fonts/yie_are_kung_fu_x.64c",,2      ; skip the first 2 bytes (64c format)
         .incbin "fonts/devils_collection_21_x.64c",2

.segment "SIDMUSIC"
         .incbin "music.sid"

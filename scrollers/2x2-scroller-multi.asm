//
// scrolling 2x2 test
// Compile it with KickAssembler: http://www.theweb.dk/KickAssembler/Main.php
//

.pc =$0801 "Basic Upstart Program"
:BasicUpstart($c000)

.pc = $c000 "Main Program"

// Use 1 to enable raster-debugging in music
.const DEBUG = 0

.const SCROLL_AT_LINE = 23
.const RASTER_START = 50

.const SCREEN = $0400 + SCROLL_AT_LINE * 40
.const SPEED = 1

.var music = LoadSid("music.sid")

        jsr $ff81                                   // Init screen

        // default is #$15  #00010101
        lda #%00011110
        sta $d018                                   // Logo font at $3800

        sei

        // turn off cia interrups
        lda #$7f
        sta $dc0d
        sta $dd0d

        lda $d01a                                   // enable raster irq
        ora #$01
        sta $d01a

        lda $d011                                   // clear high bit of raster line
        and #$7f
        sta $d011

        // irq handler
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        // raster interrupt
        lda #RASTER_START+SCROLL_AT_LINE*8-1
        sta $d012

        // clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019

        lda #$00
        tax
        tay

        // init music
        lda #music.startSong-1
        jsr music.init

        cli

        // set multi colors
        lda #$01
        sta $d021
        lda #$02
        sta $d022
        lda #$0c
        sta $d023

        // char color
        ldx #0
        lda #$0b
!:      sta $d800 + SCROLL_AT_LINE * 40,x
        inx
        cpx #80
        bne !-



mainloop:
        lda sync                                    // init sync
        and #$00
        sta sync
!:      cmp sync
        beq !-

        jsr scroll1
        jmp mainloop

irq1:
        asl $d019

        lda #<irq2
        sta $0314
        lda #>irq2
        sta $0315

        lda #RASTER_START+[SCROLL_AT_LINE+2]*8
        sta $d012

        lda #0
        sta $d020

        lda scroll_x
        ora #%00010000          // set MCM on
        sta $d016

        jmp $ea81


irq2:
        asl $d019

        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        // FIXME If I don't add the -1 it won't scroll correctly.
        // FIXME Raster is not stable.
        lda #RASTER_START+SCROLL_AT_LINE*8-1
        sta $d012

        lda #1
        sta $d020

        // no scrolling, 40 cols
        lda #%00011000
        sta $d016

        inc sync

        .if (DEBUG==1) inc $d020
        jsr music.play
        .if (DEBUG==1) dec $d020

        jmp $ea31

scroll1:
        dec speed
        bne endscroll

        // restore speed
        lda #SPEED
        sta speed

        // scroll
        dec scroll_x
        lda scroll_x
        and #07
        sta scroll_x
        cmp #07
        bne endscroll

        // move the chars to the left
        ldx #0
!:      lda SCREEN+1,x                          // scroll top part of 1x2 char
        sta SCREEN,x
        lda SCREEN+40+1,x                       // scroll bottom part of 1x2 char
        sta SCREEN+40,x
        inx
        cpx #39
        bne !-

        // put next char in column 40
        ldx lines_scrolled
        lda label,x
        cmp #$ff
        bne !+

        // reached $ff ? Then start from the beginning
        lda #0
        sta lines_scrolled
        sta half_char
        lda label

!:      ora half_char                           // right part ? left part will be 0

        sta SCREEN+39                           // top part of the 2x2
        ora #$80                                // bottom part is 128 chars ahead in the charset
        sta SCREEN+40+39                        // bottom part of the 1x2 char

        // half char
        lda half_char
        eor #$40
        sta half_char
        bne endscroll
        
        // only inc lines_scrolled after 2 chars are printed
        inx
        stx lines_scrolled

endscroll:
        rts


// variables
sync:           .byte 1
scroll_x:       .byte 7
speed:          .byte SPEED
lines_scrolled: .byte 0
half_char:      .byte 0

label:
                .text "hello world, testing 2x2 multi color scroller abcdefghijklmnopqrstuvwxzy 0123456789 ./(), "
                .byte $ff


.pc = music.location "Music"
        .fill music.size, music.getData(i)


.pc = $3800 "Chars"
        .import c64 "fonts/shackled_xy_multi.64c"


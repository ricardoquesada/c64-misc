//
// scrolling 2x2 test
//

.pc =$0801 "Basic Upstart Program"
:BasicUpstart($c000)

.pc = $c000 "Main Program"

.label SCREEN = $0400 + 23 * 40                // start at line 23
.label SPEED = 1

.label MUSIC_INIT = $1000
.label MUSIC_PLAY = $1003


        jsr $ff81                               // Init screen

        // default is #$15  #00010101
        lda #%00011110
        sta $d018                               // Logo font at $3800

        sei

        // turn off cia interrups
        lda #$7f
        sta $dc0d
        sta $dd0d

        lda $d01a                               // enable raster irq
        ora #$01
        sta $d01a

        lda $d011                               // clear high bit of raster line
        and #$7f
        sta $d011

        // irq handler
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        // raster interrupt
        lda #233
        sta $d012

        // clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019

        lda #$00
        tax
        tay
        jsr MUSIC_INIT                          // Init music

        cli



mainloop:
        lda sync                                // init sync
        and #$00
        sta sync
!:      cmp sync
        beq !-

        jsr scroll1
        jsr MUSIC_PLAY
        jmp mainloop

irq1:
        asl $d019

        lda #<irq2
        sta $0314
        lda #>irq2
        sta $0315

        lda #250
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

        lda #233
        sta $d012

        lda #1
        sta $d020

        // no scrolling, 40 cols
        lda #%00001000
        sta $d016

        inc sync

        // inc $d020
        // jsr MUSIC_PLAY
        // dec $d020
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
!:      lda SCREEN+1,x                      // scroll top part of 1x2 char
        sta SCREEN,x
        lda SCREEN+40+1,x                   // scroll bottom part of 1x2 char
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

!:      ora half_char                       // right part ? left part will be 0

        sta SCREEN+39                       // top part of the 2x2
        ora #$80                            // bottom part is 128 chars ahead in the charset
        sta SCREEN+40+39                    // bottom part of the 1x2 char

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
sync:               .byte 1
scroll_x:           .byte 7
speed:              .byte SPEED
lines_scrolled:     .byte 0
half_char:          .byte 0

label:              .text "hello world! abc def ghi jkl mnopqrstuvwxyz 01234567890 .()"
                    .byte $ff

.pc = $1000 "Music"
                .import binary "music.sid",$7e

.pc = $3800 "Chars"
                .import binary "fonts/2x2-inverted-chars.raw"
                // !bin "fonts/rambo_xy.64c",384,24


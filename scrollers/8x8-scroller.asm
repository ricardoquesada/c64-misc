//
// scrolling 8x8 test
// Use ACME assembler
//

.pc =$0801 "Basic Upstart Program"
:BasicUpstart($c000)

.pc = $c000 "Main Program"

.label SCREEN = $0400 + 16 * 40                 // start at line 4 (kind of center of the screen)
.label CHARSET = $3800
.const SPEED = 1                                // must be between 1 and 8

.var music = LoadSid("music.sid")

        jsr $ff81 //Init screen

        // default is #$15  #00010101
        lda #%00011110
        sta $d018 //Logo font at $3800

        sei

        // turn off cia interrups
        lda #$7f
        sta $dc0d
        sta $dd0d

        lda $d01a       // enable raster irq
        ora #$01
        sta $d01a

        lda $d011       // clear high bit of raster line
        and #$7f
        sta $d011

        // irq handler
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        // raster interrupt
        lda #185        // last 8 lines of the screen
        sta $d012

        // clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019

        lda #$00
        tax
        tay

        lda #music.startSong-1
        jsr music.init 

        cli


mainloop:
        lda sync   //init sync
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

        lda #185
        sta $d012

        lda #1
        sta $d020

        // no scrolling, 40 cols
        lda #%00001000
        sta $d016

        inc sync

        inc $d020
        jsr music.play 
        dec $d020

        jmp $ea31


scroll1:
        dec speed
        beq !+
        rts

        // restore speed
!:      lda #SPEED
        sta speed

        // scroll
        dec scroll_x
        lda scroll_x
        and #07
        sta scroll_x
        cmp #07
        beq !+
        rts

!:
        // move the chars to the left
        ldx #0
!:
        .for(var i=0;i<8;i++) {
            lda SCREEN+40*i+1,x
            sta SCREEN+40*i,x
        }
        inx
        cpx #39
        bne !-

        // put next char in column 40
        ldx label_index
        lda label,x
        cmp #$ff
        bne !+

        // reached $ff ? Then start from the beginning
        lda #0
        sta label_index
        sta chars_scrolled
        lda label

!:      tax
        // where to put the chars
        lda #<SCREEN+39
        sta $fc
        lda #>SCREEN+39
        sta $fd

        ldy #8

        {
!loop:
            // print 8 rows
            lda CHARSET,x
            and chars_scrolled
            beq empty_char
            lda #0
            jmp print_to_screen

empty_char:
            lda #1

print_to_screen:
            sta ($fc),y

            // next line #40
            lda $fc
            adc #40
            sta $fc
            bcc !+
            inc $fd

!:          inx                 // next charset definition
            dey
            bne !loop-
        }


        lsr chars_scrolled
        bcc endscroll

        lda #128
        sta chars_scrolled

        inc label_index

endscroll:
        rts


// variables
sync:            .byte 1
scroll_x:        .byte 7
speed:           .byte SPEED
label_index:     .byte 0
chars_scrolled:  .byte 128


label:
                .text "hello world! abc def ghi jkl mno pqr stu vwx yz 01234567890 @!()/"
                .byte $ff


.pc = CHARSET "Chars"
//         !bin "fonts/1x1-inverted-chars.raw"
//         !bin "fonts/yie_are_kung_fu.64c",,2    // skip the first 2 bytes (64c format)
//         !bin "fonts/geometrisch_4.64c",,2    // skip the first 2 bytes (64c format)
//         !bin "fonts/sm-mach.64c",,2    // skip the first 2 bytes (64c format)
         .import binary "fonts/1x1-inverted-chars.raw"

.pc = music.location "Music"
        .fill music.size, music.getData(i)

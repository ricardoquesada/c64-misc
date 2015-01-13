//
// scroller 8x16 test
// Compile it with KickAssembler: http://www.theweb.dk/KickAssembler/Main.php
//
// Zero Page global registers:
//     ** MUST NOT be modifed by any other functions **
//   $f7/$f8 -> charset upper part pointer
//   $f9/$fa -> charset bottom part pointer
//
//
// Zero Page: modified by the program, but can be modified by other functions
//   $fb/$fc -> screen pointer


.pc =$0801 "Basic Upstart Program"
:BasicUpstart($c000)

.pc = $c000 "Main Program"

.label SCREEN = $0400 + 5 * 40                 // start at line 4 (kind of center of the screen)
.label CHARSET = $3800
.label SPEED = 5                               // must be between 1 and 8

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
        lda #89
        sta $d012

        // clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019

        jsr setup_block_char

        lda #music.startSong-1
        jsr music.init  

        cli

mainloop:
        lda sync   //init sync
        and #$00
        sta sync
!:      cmp sync
        beq !-

        jsr scroll
        jmp mainloop


setup_block_char:
        // charset = $3800
        // char used as block = $ff
        // $3800 + $ff * 8 = $3ff8
        ldx #$ff
        stx $3ff8
        stx $3ff9
        stx $3ffa
        stx $3ffb
        stx $3ffc
        stx $3ffd
        stx $3ffe
        stx $3fff
        rts


irq1:
        asl $d019

        lda #<irq2
        sta $0314
        lda #>irq2
        sta $0315

        lda #217
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

        lda #89
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

//
// main scroll function
//
scroll:
        // speed control
        ldx scroll_x

        .for(var i=SPEED;i>=0;i--) {
            dec scroll_x
        }

        lda scroll_x
        and #07
        sta scroll_x

        cpx scroll_x
        bcc !+
        rts

!:
        jsr scroll_screen

        lda chars_scrolled
        cmp #%10000000
        bne !+

        // A and current_char will contain the char to print
        // $f7/$f8, $f9/$fa  points to the charset definition of A
        jsr setup_charset

!:
        // basic setup
        ldx #<SCREEN+39
        ldy #>SCREEN+39
        stx $fb
        sty $fc

        ldy #0              // 8 rows

        // start draw char loop

        {
draw_char_loop:
            cpy #8
            bmi !+
            lda ($f9),y         // upper 8 chars
            jmp !skip+
!:          lda ($f7),y         // lower 8 chars
!skip:

            // empty bit or not
            and chars_scrolled
            beq !+
//          lda current_char
            lda #255            // block char
            jmp !skip+

!:          lda #' '            // empty char
!skip:
            ldx #0
            sta ($fb,x)

            // for next line add #40
            clc
            lda $fb
            adc #40
            sta $fb
            bcc !+
            inc $fc

!:          iny                 // next charset definition
            cpy #16
            bne draw_char_loop
        }


        lsr chars_scrolled
        bcc endscroll

        lda #128
        sta chars_scrolled

        inc label_index

endscroll:
        rts

//
// args: -
// modifies: A, X, Status
//
scroll_screen:
        // move the chars to the left
        ldx #0
!:
        .for(var i=0; i<16; i++) {
            lda SCREEN+40*i+1,x
            sta SCREEN+40*i,x
        }
        inx
        cpx #39
        bne !-
        rts

//
// Args: -
// Modifies A, X, Status
// returns A: the character to print
//
setup_charset:
        // put next char in column 40
        ldx label_index
        lda label,x
        cmp #$ff
        bne !+

        // reached $ff ? Then start from the beginning
        lda #128
        sta chars_scrolled
        lda #0
        sta label_index
        lda label
!:
        sta current_char

        tax

        // address = CHARSET + 8 * index
        // multiply by 8 (LSB)
        asl
        asl
        asl
        clc
        adc #<CHARSET
        sta $f7

        // multiply by 8 (MSB)
        // 256 / 8 = 32
        // 32 = %00100000
        txa
        lsr
        lsr
        lsr
        lsr
        lsr

        clc
        adc #>CHARSET
        sta $f8


        // pointer to the second part of the char
        // it is 64 chars ahead = 64 * 8 = 512 bytes = 
        // to reduce complixity on main code
        // pointer of bottom part will be 512 - 8
        // since it will be indexed by 'y', and 'y' will already have a value
        // of 8
        sec
        // LBS
        lda $f7
        sbc #8
        sta $f9

        // MBS
        lda $f8
        sbc #0
        sta $fa

        clc
        adc #2
        sta $fa

        rts


// variables
sync:            .byte 1
scroll_x:        .byte 7
label_index:     .byte 0
chars_scrolled:  .byte 128
current_char:    .byte 0

label:
                .text "hello world! this is a test of a 8x16 scroller. do you like it? "
                .byte $ff


.pc = CHARSET "Chars"
        .import c64 "fonts/devils_collection_25_y.64c"
//         !bin "fonts/final_designer_scroll_y.64c",,2

.pc = music.location "Music"
        .fill music.size, music.getData(i)
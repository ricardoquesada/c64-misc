//
// double 8x8 scroller test
// Compile it with KickAssembler: http://www.theweb.dk/KickAssembler/Main.php
//
// Zero Page global registers:
//     ** MUST NOT be modifed by any other functions **
//   $f9/$fa -> charset
//
//
// Zero Page: modified by the program, but can be modified by other functions
//   $fb/$fc -> screen pointer (upper)
//   $fd/$fe -> screen pointer (bottom)


.pc =$0801 "Basic Upstart Program"
:BasicUpstart($c000)

.pc = $c000 "Main Program"

.label SCREEN = $0400 + 0 * 40                 // start at line 4 (kind of center of the screen)
.label CHARSET = $3800
.const SPEED = 5                               // must be between 1 and 8

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
        lda #43         // first 43 lines
        sta $d012

        // clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019

        lda #music.startSong-1
        jsr music.init  
        
        cli


mainloop:
        lda #0
        sta sync
!:      cmp sync
        beq !-

        jsr scroll
        jmp mainloop

irq1:
        asl $d019

        lda #<irq2
        sta $0314
        lda #>irq2
        sta $0315

        lda #115
        sta $d012

        lda #3
        sta $d020

        // scroll left, upper part
        lda scroll_left
        sta $d016

        jmp $ea81

irq2:
        asl $d019

        lda #<irq3
        sta $0314
        lda #>irq3
        sta $0315

        lda #186
        sta $d012

        lda #1
        sta $d020

        // no scroll
        lda #%00001000
        sta $d016

        jmp $ea81


irq3:
        asl $d019

        lda #<irq4
        sta $0314
        lda #>irq4
        sta $0315

        lda #250
        sta $d012

        lda #0
        sta $d020

        // scroll right, bottom part
        lda scroll_left
        eor #$07    // negate "scroll left" to simulate "scroll right"
        and #$07
        sta $d016

        jmp $ea81


irq4:
        asl $d019

        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        lda #49
        sta $d012

        lda #1
        sta $d020

        // no scroll
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

        ldx scroll_left         // save current value in X

        .for(var i=SPEED;i>=0;i--) {
            dec scroll_left
        }

        lda scroll_left
        and #07
        sta scroll_left
    
        cpx scroll_left         // new value is higher than the old one ? if so, then scroll
        bcc !+

        rts

!:
        jsr scroll_screen

        lda chars_scrolled
        cmp #%10000000
        bne !+

        // A and current_char will contain the char to print
        // $fd, $fe points to the charset definition of A
        jsr setup_charset

!:
        // basic setup
        ldx #<SCREEN+39
        ldy #>SCREEN+39
        stx $fb
        sty $fc
        ldx #<SCREEN+40*24
        ldy #>SCREEN+40*24
        stx $fd
        sty $fe

        ldy #0              // 8 rows


        {
!loop:
            lda ($f9),y
            and chars_scrolled
            beq empty_char

            lda current_char
            jmp print_to_screen

empty_char:
            lda #' '

print_to_screen:
            ldx #0
            sta ($fb,x)
            sta ($fd,x)

            // next line for upper scroller
            clc
            lda $fb
            adc #40
            sta $fb
            bcc !+
            inc $fc

            // next line for bottom scroller
!:          sec 
            lda $fd
            sbc #40
            sta $fd
            bcs !+
            dec $fe

!:          iny                 // next charset definition
            cpy #8
            bne !loop-
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
        ldy #38

!:      
        .for(var i=0;i<8;i++) { 
            lda SCREEN+40*i+1,x
            sta SCREEN+40*i,x
        }

        .for(var i=0;i<8;i++) {
            lda SCREEN+40*[17+i]+0,y
            sta SCREEN+40*[17+i]+1,y
        }

        inx
        dey
        cpy #$ff
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
        lda #%10000000
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
        sta $f9

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
        sta $fa

        rts


// variables
sync:            .byte 1
scroll_left:     .byte 7
label_index:     .byte 0
chars_scrolled:  .byte 128
current_char:    .byte 0

           //          1         2         3
           //0123456789012345678901234567890123456789

label:
                .text " hello world! testing a double scroller demo. so far, so good. "
                .byte $ff


.pc = CHARSET "Chars"
//         !bin "fonts/1x1-inverted-chars.raw"
//         !bin "fonts/yie_are_kung_fu.64c",,2    // skip the first 2 bytes (64c format)
//         !bin "fonts/geometrisch_4.64c",,2    // skip the first 2 bytes (64c format)
//         !bin "fonts/sm-mach.64c",,2    // skip the first 2 bytes (64c format)
            .import c64 "fonts/scrap_writer_iii_16.64c"

.pc = music.location "Music"
        .fill music.size, music.getData(i)

//
// scrolling 1x1 test
// Compile it with KickAssembler: http://www.theweb.dk/KickAssembler/Main.php
//


.pc =$0801 "Basic Upstart Program"
:BasicUpstart($c000)



.pc = $c000 "Main Program"

// Use 1 to enable raster-debugging in music
.const DEBUG = 0

.const SCROLL_AT_LINE = 10
.const RASTER_START = 50

.const SCREEN = $0400 + SCROLL_AT_LINE * 40
.const SPEED = 1


.var music = LoadSid("music.sid")

        jsr $ff81						// Init screen

        // default is #$15  #00010101
        lda #%00011110
        sta $d018						// Logo font at $3800

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
        lda #RASTER_START+SCROLL_AT_LINE*8
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


mainloop:
        lda sync   //init sync
        and #$00
        sta sync
!loop:	cmp sync
        beq !loop-

        jsr scroll1
        jmp mainloop

irq1:
        asl $d019

        lda #<irq2
        sta $0314
        lda #>irq2
        sta $0315

        // FIXME Raster is not stable.
        lda #RASTER_START+[SCROLL_AT_LINE+1]*8
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

        // FIXME If I don't add the -1 it won't scroll correctly.
        // FIXME Raster is not stable.
        lda #RASTER_START+SCROLL_AT_LINE*8-1                   
        sta $d012

        lda #1
        sta $d020

        // no scrolling, 40 cols
        lda #%00001000
        sta $d016

        inc sync

        .if (DEBUG==1) { inc $d020 }
            
        jsr music.play

        .if (DEBUG==1) { dec $d020 }

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
!loop:	lda SCREEN+1,x
        sta SCREEN,x
        inx
        cpx #39
        bne !loop-

        // put next char in column 40
        ldx lines_scrolled
        lda label,x
        cmp #$ff
        bne !+

        // reached $ff ? Then start from the beginning
        ldx #0
        stx lines_scrolled
        lda label

 !:
 		sta SCREEN+39
        inx
        stx lines_scrolled

endscroll:
        rts


// variables
sync:           .byte 1
scroll_x:       .byte 7
speed:          .byte SPEED
lines_scrolled: .byte 0

label:
		.text "Hello World! abc DEF ghi JKL mno PQR stu VWX yz 01234567890 ()."
	    .byte $ff



.pc = music.location "Music"
        .fill music.size, music.getData(i)

.pc = $3800 "CharGen"
        // .import binary "fonts/rambo_font.ctm",24    // skip first 24 bytes which is CharPad format information
        // .import c64 "fonts/yie_are_kung_fu.64c"
        // .import c64 "fonts/devils_collection_01.64c"
		.import binary "fonts/1x1-inverted-chars.raw"

;
; double 8x8 scroller test
; Compile it using cc65: http://cc65.github.io/cc65/
;
; Command line:
;    cl65 -o file.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg 8x8-scroller.s
;
;
; Zero Page global registers:
;     ** MUST NOT be modifed by any other functions **
;   $f9/$fa -> charset
;
;
; Zero Page: modified by the program, but can be modified by other functions
;   $fb/$fc -> screen pointer (upper)
;   $fd/$fe -> screen pointer (bottom)


; exported by the linker
.import __CHARSET_LOAD__, __SIDMUSIC_LOAD__

; Use 1 to enable music-raster debug
DEBUG = 1

RASTER_START = 50

SCROLL_1_AT_LINE = 2
SCROLL_2_AT_LINE = 15

SCREEN_1 = $0400 + SCROLL_1_AT_LINE * 40
SCREEN_2 = $0400 + SCROLL_2_AT_LINE * 40


MUSIC_INIT = __SIDMUSIC_LOAD__
MUSIC_PLAY = __SIDMUSIC_LOAD__ + 3

SPEED = 5            ; must be between 1 and 8


.macpack cbm         ; adds support for scrcode

.segment "CODE"

        jsr $ff81 ;Init screen

        ; default is #$15  #00010101
        lda #%00011110
        sta $d018 ;Logo font at $3800

        sei

        ; turn off cia interrups
        lda #$7f
        sta $dc0d
        sta $dd0d

        lda $d01a       ; enable raster irq
        ora #$01
        sta $d01a

        lda $d011       ; clear high bit of raster line
        and #$7f
        sta $d011

        ; irq handler
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        ; raster interrupt
        lda #RASTER_START+SCROLL_1_AT_LINE*8
        sta $d012

        ; clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019

        lda #0
        jsr MUSIC_INIT

        cli


mainloop:
        lda #0
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

        lda #RASTER_START+(SCROLL_1_AT_LINE+8)*8
        sta $d012

        lda #3
        sta $d020

        ; scroll left, upper part
        lda scroll_left
        sta $d016

        jmp $ea81

irq2:
        asl $d019

        lda #<irq3
        sta $0314
        lda #>irq3
        sta $0315

        ; FIXME If I don't add the -1 it won't scroll correctly.
        ; FIXME Raster is not stable.
        lda #RASTER_START+(SCROLL_2_AT_LINE)*8-1
        sta $d012

        lda #1
        sta $d020

        ; no scroll
        lda #%00001000
        sta $d016

        jmp $ea81


irq3:
        asl $d019

        lda #<irq4
        sta $0314
        lda #>irq4
        sta $0315

        lda #RASTER_START+(SCROLL_2_AT_LINE+8)*8
        sta $d012

        lda #0
        sta $d020

        ; scroll right, bottom part
        lda scroll_left
        eor #$07    ; negate "scroll left" to simulate "scroll right"
        and #$07
        sta $d016

        jmp $ea81


irq4:
        asl $d019

        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        ; FIXME If I don't add the -1 it won't scroll correctly.
        ; FIXME Raster is not stable.
        lda #RASTER_START+SCROLL_1_AT_LINE*8-1
        sta $d012

        lda #1
        sta $d020

        ; no scroll
        lda #%00001000
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


;
; main scroll function
;
scroll:
        ; speed control

        ldx scroll_left         ; save current value in X


.repeat SPEED
            dec scroll_left
.endrepeat

        lda scroll_left
        and #07
        sta scroll_left

        cpx scroll_left         ; new value is higher than the old one ? if so, then scroll
        bcc :+

        rts

:
        jsr scroll_screen

        lda chars_scrolled
        cmp #%10000000
        bne :+

        ; A and current_char will contain the char to print
        ; $f9/$fa points to the charset definition of the char
        jsr setup_charset

:
        ; basic setup
        ldx #<(SCREEN_1+39)
        ldy #>(SCREEN_1+39)
        stx $fb
        sty $fc
        ldx #<(SCREEN_2+8*40)
        ldy #>(SCREEN_2+8*40)
        stx $fd
        sty $fe

        ldy #0              ; 8 rows


loop:
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

            ; next line for upper scroller
            clc
            lda $fb
            adc #40
            sta $fb
            bcc :+
            inc $fc

            ; next line for bottom scroller
:           sec
            lda $fd
            sbc #40
            sta $fd
            bcs :+
            dec $fe

:           iny                 ; next charset definition
            cpy #8
            bne loop

        lsr chars_scrolled
        bcc endscroll

        lda #128
        sta chars_scrolled

        inc label_index

endscroll:
        rts

;
; args: -
; modifies: A, X, Status
;
scroll_screen:
        ; move the chars to the left and right
        ldx #0
        ldy #38

@loop:
.repeat 8,I
        lda SCREEN_1+40*I+1,x
        sta SCREEN_1+40*I+0,x
.endrepeat

.repeat 8,I
        lda SCREEN_2+40*I+0,y
        sta SCREEN_2+40*I+1,y
.endrepeat

        inx
        dey
        cpy #$ff
        bne @loop
        rts

;
; Args: -
; Modifies A, X, Status
; returns A: the character to print
;
setup_charset:
        ; put next char in column 40
        ldx label_index
        lda label,x
        cmp #$ff
        bne :+

        ; reached $ff ? Then start from the beginning
        lda #%10000000
        sta chars_scrolled
        lda #0
        sta label_index
        lda label
:
        sta current_char

        tax

        ; address = CHARSET + 8 * index
        ; multiply by 8 (LSB)
        asl
        asl
        asl
        clc
        adc #<__CHARSET_LOAD__
        sta $f9

        ; multiply by 8 (MSB)
        ; 256 / 8 = 32
        ; 32 = %00100000
        txa
        lsr
        lsr
        lsr
        lsr
        lsr

        clc
        adc #>__CHARSET_LOAD__
        sta $fa

        rts


; variables
sync:            .byte 1
scroll_left:     .byte 7
label_index:     .byte 0
chars_scrolled:  .byte 128
current_char:    .byte 0

label:
                scrcode " hello world! testing a double scroller demo. so far, so good. "
                .byte $ff


.segment "CHARSET"
        .incbin "fonts/scrap_writer_iii_16.64c",2

.segment "SIDMUSIC"
         .incbin "music.sid",$7e


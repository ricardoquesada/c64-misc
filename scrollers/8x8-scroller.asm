;
; scrolling 8x8 test
; Use ACME assembler
;

!cpu 6510
!to "build/scroller8x8.prg",cbm    ; output file


;============================================================
; BASIC loader with start address $c000
;============================================================

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152


* = $c000                               ; start address for 6502 code

SCREEN = $0400 + 16 * 40                ; start at line 16
CHARSET = $3800
SPEED = 1

MUSIC_INIT = $1000
MUSIC_PLAY = $1003


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
        lda #185        ; last 8 lines of the screen
        sta $d012

        ; clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019

        lda #$00
        tax
        tay
        jsr MUSIC_INIT      ; Init music

        cli



mainloop
        lda sync   ;init sync
        and #$00
        sta sync
-       cmp sync
        beq -

        jsr scroll1
        jmp mainloop

irq1
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


irq2
        asl $d019

        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        lda #185
        sta $d012

        lda #1
        sta $d020

        ; no scrolling, 40 cols
        lda #%00001000
        sta $d016

        inc sync

;        inc $d020
        jsr MUSIC_PLAY
;        dec $d020
        jmp $ea31

scroll1
        dec speed
        beq +
        rts

        ; restore speed
+       lda #SPEED
        sta speed

        ; scroll
        dec scroll_x
        lda scroll_x
        and #07
        sta scroll_x
        cmp #07
        beq +
        rts

+
        ; move the chars to the left
        ldx #0
-       lda SCREEN+40*0+1,x
        sta SCREEN+40*0,x
        lda SCREEN+40*1+1,x
        sta SCREEN+40*1,x
        lda SCREEN+40*2+1,x
        sta SCREEN+40*2,x
        lda SCREEN+40*3+1,x
        sta SCREEN+40*3,x
        lda SCREEN+40*4+1,x
        sta SCREEN+40*4,x
        lda SCREEN+40*5+1,x
        sta SCREEN+40*5,x
        lda SCREEN+40*6+1,x
        sta SCREEN+40*6,x
        lda SCREEN+40*7+1,x
        sta SCREEN+40*7,x
        inx
        cpx #39
        bne -

        ; put next char in column 40
        ldx label_index
        lda label,x
        cmp #$ff
        bne +

        ; reached $ff ? Then start from the beginning
        lda #0
        sta label_index
        sta chars_scrolled
        lda label

+       tax
        ; where to put the chars
        lda #<SCREEN+39
        sta $fc
        lda #>SCREEN+39
        sta $fd

        ldy #8

-       lda CHARSET,x
        and chars_scrolled
        beq empty_char
        lda #0
        jmp print_to_screen

empty_char
        lda #1

print_to_screen
        sta ($fc),y

        ; next line #40
        lda $fc
        adc #40
        sta $fc
        bcc +
        inc $fd

+       inx                 ; next charset definition
        dey
        bne -


        lsr chars_scrolled
        bcc endscroll

        lda #128
        sta chars_scrolled

        inc label_index

endscroll
        rts


; variables
sync            !byte 1
scroll_x        !byte 7
speed           !byte SPEED
label_index     !byte 0
chars_scrolled  !byte 128

           ;          1         2         3
           ;0123456789012345678901234567890123456789
label !scr "hello world! abc def ghi jkl mno pqr stu vwx yz 01234567890 @!()/",$ff



* = $1000
         !bin  "music.sid",,$7e

* = CHARSET
         !bin "fonts/1x1-inverted-chars.raw"


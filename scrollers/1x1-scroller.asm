;
; scrolling 1x1 test
; Use ACME assembler
;

!cpu 6510
!to "build/scroller1x1.prg",cbm    ; output file


;============================================================
; BASIC loader with start address $c000
;============================================================

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152


* = $c000                               ; start address for 6502 code

SCREEN = $0400 + 24 * 40
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
        lda #241
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
        jsr MUSIC_PLAY
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

        lda #241
        sta $d012

        lda #1
        sta $d020

        ; no scrolling, 40 cols
        lda #%00001000
        sta $d016

        inc sync

        ; inc $d020
        ; jsr MUSIC_PLAY
        ; dec $d020
        jmp $ea31

scroll1
        dec speed
        bne endscroll

        ; restore speed
+       lda #SPEED
        sta speed

        ; scroll
        dec scroll_x
        lda scroll_x
        and #07
        sta scroll_x
        cmp #07
        bne endscroll

        ; move the chars to the left
        ldx #0
-       lda SCREEN+1,x
        sta SCREEN,x
        inx
        cpx #39
        bne -

        ; put next char in column 40
        ldx lines_scrolled
        lda label,x
        cmp #$ff
        bne +

        ; reached $ff ? Then start from the beginning
        ldx #0
        stx lines_scrolled
        lda label

+       sta SCREEN+39
        inx
        stx lines_scrolled

endscroll
        rts


; variables
sync           !byte 1
scroll_x       !byte 7
speed          !byte SPEED
lines_scrolled !byte 0

           ;          1         2         3
           ;0123456789012345678901234567890123456789
label !scr "Hello World! abc DEF ghi JKL mno PQR stu VWX yz 01234567890 ().",$ff



* = $1000
         !bin  "music.sid",,$7e

* = $3800
         ; !bin "fonts/rambo_font.ctm",,24   ; skip first 24 bytes which is CharPad format information
         ; !bin "fonts/yie_are_kung_fu.64c",,2    ; skip the first 2 bytes (64c format)
         !bin "fonts/1x1-inverted-chars.raw"
         ; !bin "fonts/devils_collection_01.64c",,2    ; skip the first 2 bytes (64c format)

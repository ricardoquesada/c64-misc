;
; scroller 8x16 test
; Use ACME assembler
;
; global registers:
;   $f9/$fa -> screen pointer
;   $fb/$fc -> charset upper part pointer
;   $fd/$fe -> charset bottom part pointer

!cpu 6510
!to "build/scroller8x8.prg",cbm    ; output file


;============================================================
; BASIC loader with start address $c000
;============================================================

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152


* = $c000                               ; start address for 6502 code

SCREEN = $0400 + 5 * 40                 ; start at line 4 (kind of center of the screen)
CHARSET = $3800
SPEED = 5                               ; must be between 1 and 8


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
        lda #89
        sta $d012

        ; clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019

        jsr setup_block_char

        cli

mainloop
        lda sync   ;init sync
        and #$00
        sta sync
-       cmp sync
        beq -

        jsr scroll
        jmp mainloop


setup_block_char
        ; charset = $3800
        ; char used as block = $ff
        ; $3800 + $ff * 8 = $3ff8
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


irq1
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


irq2
        asl $d019

        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        lda #89
        sta $d012

        lda #1
        sta $d020

        ; no scrolling, 40 cols
        lda #%00001000
        sta $d016

        inc sync

        jmp $ea31

;
; main scroll function
;
scroll

        ; speed control
        ldx scroll_x

        !set i = SPEED
        !do {
            dec scroll_x
            !set i = i - 1
        } while i > 0

        lda scroll_x
        and #07
        sta scroll_x
    
        cpx scroll_x
        bcc +

        rts

+

        jsr scroll_screen

        lda chars_scrolled
        cmp #%10000000
        bne +

        ; A and current_char will contain the char to print
        ; $fb/$fc, $fd/$fe  points to the charset definition of A
        jsr setup_charset

+
        ; basic setup
        ldx #<SCREEN+39
        ldy #>SCREEN+39
        stx $f9
        sty $fa

        ldy #0              ; 8 rows

        ; start draw char loop
        
draw_char_loop
        cpy #8
        bmi +
        lda ($fd),y         ; upper 8 chars
        jmp ++
+       lda ($fb),y         ; lower 8 chars
++

        ; empty bit or not
        and chars_scrolled
        beq +
;        lda current_char
        lda #255            ; block char
        jmp ++

+       lda #' '            ; empty char
++
        ldx #0
        sta ($f9,x)

        ; for next line add #40
        clc
        lda $f9
        adc #40
        sta $f9
        bcc +
        inc $fa

+       iny                 ; next charset definition
        cpy #16
        bne draw_char_loop


        lsr chars_scrolled
        bcc endscroll

        lda #128
        sta chars_scrolled

        inc label_index

endscroll
        rts

;
; args: -
; modifies: A, X, Status
;
scroll_screen
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
        lda SCREEN+40*8+1,x
        sta SCREEN+40*8,x
        lda SCREEN+40*9+1,x
        sta SCREEN+40*9,x
        lda SCREEN+40*10+1,x
        sta SCREEN+40*10,x
        lda SCREEN+40*11+1,x
        sta SCREEN+40*11,x
        lda SCREEN+40*12+1,x
        sta SCREEN+40*12,x
        lda SCREEN+40*13+1,x
        sta SCREEN+40*13,x
        lda SCREEN+40*14+1,x
        sta SCREEN+40*14,x
        lda SCREEN+40*15+1,x
        sta SCREEN+40*15,x
        inx
        cpx #39
        bne -
        rts

;
; Args: -
; Modifies A, X, Status
; returns A: the character to print
;
setup_charset
        ; put next char in column 40
        ldx label_index
        lda label,x
        cmp #$ff
        bne +

        ; reached $ff ? Then start from the beginning
        lda #128
        sta chars_scrolled
        lda #0
        sta label_index
        lda label
+
        sta current_char

        tax

        ; address = CHARSET + 8 * index
        ; multiply by 8 (LSB)
        asl
        asl
        asl
        clc
        adc #<CHARSET
        sta $fb

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
        adc #>CHARSET
        sta $fc


        ; pointer to the second part of the char
        ; it is 64 chars ahead = 64 * 8 = 512 bytes = 
        ; to reduce complixity on main code
        ; pointer of bottom part will be 512 - 8
        ; since it will be indexed by 'y', and 'y' will already have a value
        ; of 8
        sec
        ; LBS
        lda $fb
        sbc #8
        sta $fd

        ; MBS
        lda $fc
        sbc #0
        sta $fe

        clc
        adc #2
        sta $fe

        rts


; variables
sync            !byte 1
scroll_x        !byte 7
label_index     !byte 0
chars_scrolled  !byte 128
current_char    !byte 0

           ;          1         2         3
           ;0123456789012345678901234567890123456789
label !scr "hello world! this is a test of a 8x16 scroller. do you like it? ",$ff



* = CHARSET
         !bin "fonts/devils_collection_25_y.64c",,2
;         !bin "fonts/final_designer_scroll_y.64c",,2

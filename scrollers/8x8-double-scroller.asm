;
; double 8x8 scroller test
; Use ACME assembler
;

!cpu 6510
!to "build/scro-double-8x8.prg",cbm    ; output file


;============================================================
; BASIC loader with start address $c000
;============================================================

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152


* = $c000                               ; start address for 6502 code

SCREEN = $0400 + 0 * 40                 ; start at line 16
CHARSET = $3800
SPEED = 3                               ; must be between 1 and 8


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
        lda #43         ; first 43 lines
        sta $d012

        ; clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019

        cli



mainloop
        lda #0
        sta sync
-       cmp sync
        beq -

        jsr scroll
        jmp mainloop

irq1
        asl $d019

        lda #<irq2
        sta $0314
        lda #>irq2
        sta $0315

        lda #107
        sta $d012

        lda #3
        sta $d020

        ; scroll left, upper part
        lda scroll_left
        sta $d016

        jmp $ea81

irq2
        asl $d019

        lda #<irq3
        sta $0314
        lda #>irq3
        sta $0315

        lda #187
        sta $d012

        lda #1
        sta $d020

        ; no scroll
        lda #%00001000
        sta $d016

        jmp $ea81


irq3
        asl $d019

        lda #<irq4
        sta $0314
        lda #>irq4
        sta $0315

        lda #250
        sta $d012

        lda #0
        sta $d020

        ; scroll bottom
        lda scroll_right
        sta $d016

        jmp $ea81


irq4
        asl $d019

        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        lda #49
        sta $d012

        lda #1
        sta $d020

        ; no scroll
        lda #%00001000
        sta $d016

        inc sync

        jmp $ea31

;
; main scroll function
;
scroll

        ; speed control
        ldx scroll_left

        !set i = SPEED
        !do {
            dec scroll_left
            inc scroll_right
            !set i = i - 1
        } while i > 0

        lda scroll_right
        and #07
        sta scroll_right

        lda scroll_left
        and #07
        sta scroll_left
    
        cpx scroll_left
        bcc +

        rts

+

        jsr scroll_screen

        lda chars_scrolled
        cmp #%10000000
        bne +

        ; A and current_char will contain the char to print
        ; $fd, $fe points to the charset definition of A
        jsr setup_charset

+
        ; basic setup
        ldx #<SCREEN+39
        ldy #>SCREEN+39
        stx $fb
        sty $fc
        ldx #<SCREEN+40*24
        ldy #>SCREEN+40*24
        stx $f9
        sty $fa

        ldy #0              ; 8 rows

-       lda ($fd),y
        and chars_scrolled
        beq empty_char

        lda current_char
        jmp print_to_screen

empty_char
        lda #' '

print_to_screen
        ldx #0
        sta ($fb,x)
        sta ($f9,x)

        ; next line for upper scroller
        clc
        lda $fb
        adc #40
        sta $fb
        bcc +
        inc $fc

        ; next line for bottom scroller
+       sec 
        lda $f9
        sbc #40
        sta $f9
        bcs +
        dec $fa

+       iny                 ; next charset definition
        cpy #8
        bne -


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
        ldy #38

-       
        lda SCREEN+40*0+1,x
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

        lda SCREEN+40*17+0,y
        sta SCREEN+40*17+1,y
        lda SCREEN+40*18+0,y
        sta SCREEN+40*18+1,y
        lda SCREEN+40*19+0,y
        sta SCREEN+40*19+1,y
        lda SCREEN+40*20+0,y
        sta SCREEN+40*20+1,y
        lda SCREEN+40*21+0,y
        sta SCREEN+40*21+1,y
        lda SCREEN+40*22+0,y
        sta SCREEN+40*22+1,y
        lda SCREEN+40*23+0,y
        sta SCREEN+40*23+1,y
        lda SCREEN+40*24+0,y
        sta SCREEN+40*24+1,y

        inx
        dey
        cpy #$ff
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
        sta $fd

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
        sta $fe

        rts


; variables
sync            !byte 1
scroll_left     !byte 7
scroll_right    !byte 0
label_index     !byte 0
chars_scrolled  !byte 128
current_char    !byte 0

           ;          1         2         3
           ;0123456789012345678901234567890123456789
label !scr "Hello World! This is a test 0123456789...",$ff



* = CHARSET
;         !bin "fonts/1x1-inverted-chars.raw"
;         !bin "fonts/yie_are_kung_fu.64c",,2    ; skip the first 2 bytes (64c format)
;         !bin "fonts/geometrisch_4.64c",,2    ; skip the first 2 bytes (64c format)
         !bin "fonts/sm-mach.64c",,2    ; skip the first 2 bytes (64c format)


; 
; scrolling 1 line
;

!cpu 6510
!to "build/test.prg",cbm    ; output file


;============================================================
; BASIC loader with start address $c000
;============================================================

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152


* = $c000                               ; start address for 6502 code

SCREEN = $0400 + 24 * 40
SPEED = 1

      jsr $e544 

+     sei

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

      ; 38 columns
      lda $d016
      and #%11110111
      sta $d016

      ; raster interrupt
      lda #241
      sta $d012
      
      ; clear interrupts and ACK irq
      lda $dc0d
      lda $dd0d
      asl $d019

      cli   
      rts

irq1
      inc $d019        

      lda #<irq2
      sta $0314
      lda #>irq2
      sta $0315

      lda #254
      sta $d012

      lda #0
      sta $d020
      
      dec speed
      bne +

      ; restore speed
      lda #SPEED
      sta speed


      ; scroll
      dec scroll_x
      lda scroll_x
      and #07   
      sta $d016
      cmp #00
      bne +

      jsr move_chars

+
      jmp $ea31

move_chars
      ; move the chars to the left
      ldx #0
-     lda SCREEN+1,x
      sta SCREEN,x
      inx
      cpx #39
      bne -

      ; put next char in column 40
      ldx lines_scrolled
      lda label,x
      cmp #$ff
      beq +
      sta SCREEN+39
      inx
      stx lines_scrolled
      rts

+     lda #0
      sta lines_scrolled 
      rts


irq2
      inc $d019        

      lda #<irq1
      sta $0314
      lda #>irq1
      sta $0315

      lda #241
      sta $d012

      lda #1
      sta $d020

      ; no scrolling
      lda #%00001000
      sta $d016

      jmp $ea81


; variables
scroll_x       !byte 7
speed          !byte SPEED
lines_scrolled !byte 0    


           ;          1         2         3        
           ;0123456789012345678901234567890123456789
label !scr "hello world world, will you scroll ? testing scrolling one line  ",$ff

;============================================================
; Empty Assembler project with Basic Loader
; Code by actraiser/Dustlayer
;
; http://www.dustlayer.com
; 
;============================================================

;============================================================
; index file which loads all source code and resources files
;============================================================

;============================================================
;    specify output file
;============================================================

!cpu 6502
!to "build/double-raster.prg",cbm    ; output file


;============================================================
; BASIC loader with start address $c000
;============================================================

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152

* = $c000     				; start address for 6502 code

;===================================
; main.asm triggers all subroutines 
; and runs the Interrupt Routine
;===================================

main 
        sei

        ; jsr $e544  ; clear the screen


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

        ; set text mode
        lda #$1b
        ldx #$08
        ldy #$14
        sta $d011
        stx $d016
        sty $d014

        lda #<irq1   ; point IRQ Vector to our custom irq routine
        ldx #>irq1 
        sta $0314    ; store in $314/$315
        stx $0315   

        lda #$0     ; trigger interrupt at row zero
        sta $d012

        ; clear interrupts and ACK irq
        lda $dc0d
        lda $dd0d
        asl $d019
        cli

; loop
;         sei
;            lda #$40       ; wait until Raster Line 249
;            cmp $d012
;            bne *-3

; inc_color
;            inc $d020

;            lda $d012 ;load the current raster line into the accumulator
;            clc       ;make sure carry is clear
;            adc #$05  ;add lines to wait
;            cmp $d012
;            bne *-3   ;check *until* we're at the target raster line

;            lda #$b0       ; wait until Raster Line 249
;            cmp $d012
;            bpl inc_color

;            lda #0
;            sta $d020

;            cli
;            jmp loop


        ; jmp *       ; infinite loop
        rts




;================================
; Our custom interrupt routines 
;================================

irq1 
        lda #$05
        sta $d020
        sta $d021

        lda #<irq2   ; point IRQ Vector to our custom irq routine
        ldx #>irq2 
        sta $0314    ; store in $314/$315
        stx $0315   
        lda #160    ; trigger interrupt at row zero
        sta $d012

        asl $d019      ; acknowledge IRQ / clear register for next interrupt
        jmp $ea31      ; return to Kernel routine


irq2        

        lda #$01
        sta $d020
        sta $d021

        lda #<irq1      ; point IRQ Vector to our custom irq routine
        ldx #>irq1 
        sta $0314       ; store in $314/$315
        stx $0315   
        lda #$20        ; trigger interrupt at row zero
        sta $d012

        asl $d019       ; acknowledge IRQ / clear register for next interrupt

        ; jmp $ea31      ; return to Kernel routine

        pla             ; we exit interrupt entirely.
        tay             ; since happening 120 times per
        pla             ; second, only 60 need to go to
        tax             ; hardware Rom. The other 60 simply
        pla             ; end
        rti



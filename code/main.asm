;===================================
; main.asm triggers all subroutines 
; and runs the Interrupt Routine
;===================================

main 
        sei

        jsr clear_screen  ; clear the screen
        jsr init_sprites


        lda #$7f
        sta $dc0d
        sta $dd0d
        
        lda #$01    ; Set Interrupt Request Mask...
        sta $d01a   ; ...we want IRQ by Rasterbeam (%00000001)

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

        jmp *       ; infinite loop




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

        lda #<irq1   ; point IRQ Vector to our custom irq routine
        ldx #>irq1 
        sta $0314    ; store in $314/$315
        stx $0315   
        lda #$20      ; trigger interrupt at row zero
        sta $d012

        asl $d019      ; acknowledge IRQ / clear register for next interrupt
        jmp $ea31      ; return to Kernel routine

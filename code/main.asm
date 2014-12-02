;===================================
; main.asm triggers all subroutines 
; and runs the Interrupt Routine
;===================================

main 
          sei

          jsr clear_screen  ; clear the screen
          jsr init_sprites


          lda #$01    ; Set Interrupt Request Mask...
          sta $d01a   ; ...we want IRQ by Rasterbeam (%00000001)

          lda #<irq   ; point IRQ Vector to our custom irq routine
          ldx #>irq 
          sta $0314    ; store in $314/$315
          stx $0315   

          lda #$00    ; trigger interrupt at row zero
          sta $d012

          cli

loop
           sei

           lda #$40       ; wait until Raster Line 249
           cmp $d012
           bne *-3

inc_color
           inc $d020

           lda $d012 ;load the current raster line into the accumulator
           clc       ;make sure carry is clear
           adc #$05  ;add lines to wait
           cmp $d012
           bne *-3   ;check *until* we're at the target raster line

           lda #$b0       ; wait until Raster Line 249
           cmp $d012
           bpl inc_color

           lda #0
           sta $d020

           cli
           jmp loop

          rts



;================================
; Our custom interrupt routines 
;================================

irq        
           dec $d019      ; acknowledge IRQ / clear register for next interrupt

           inc $d000

           jmp $ea31      ; return to Kernel routine

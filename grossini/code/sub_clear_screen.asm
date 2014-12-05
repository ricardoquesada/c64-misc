;============================================================
; clear screen and turn black
;============================================================

clear_screen     ldx #$00     ; start of loop
                 stx $d020    ; write to border register
                 stx $d021    ; write to screen register
clear            lda #$20     ; #$20 is the spacebar screencode
                 sta $0400,x  ; fill four areas with 256 spacebar characters
                 sta $0500,x 
                 sta $0600,x 
                 sta $06e8,x 
                 lda #$0c     ; puts into the associated color ram dark grey ($0c)...
                 sta $d800,x  ; and this will become color of the scroll text
                 sta $d900,x
                 sta $da00,x
                 sta $dae8,x
                 inx         
                 bne clear   
                 rts 
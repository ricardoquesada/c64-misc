;coded by Bitbreaker Oxyron ^ Nuance ^ Arsenic
;feel free to change $d020/$d021 to other registers like $d022/$d023 for effects with multicolor charsets
;as you see, there are plenty of cycles free for more action.

; code downloaded from: http://codebase64.org/doku.php?id=base:rasterbars_with_screen_on
;
; modified it to compile with ACME
;
; run it with:
; sys 49152
;

!cpu 6502
!to "build/rasterbars3.prg",cbm    ; output file


* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152

        * = $c000
 
tmpa    = $22
tmpx    = $23
tmpy    = $24
tmp_1   = $25
 
         sei
         lda #$7f
         sta $dc0d
         lda $dc0d
         lda #$01
         sta $d01a
         sta $d019
         lda #$32
         sta $d012
         lda $d011
         and #$3f
         sta $d011
         lda #$34
         sta $01
         lda #<irq1
         sta $fffe
         lda #>irq1
         sta $ffff
         cli
         jmp *
 
irq1
         ;irq enter stuff
         sta tmpa
         stx tmpx
         sty tmpy
         lda $01
         sta tmp_1
         lda #$35
         sta $01
         dec $d019
 
         ldx #$01
         dex
         bpl *-1
 
         ;do raster
         jsr raster
 
         ;exit irq
         lda tmp_1
         sta $01
         ldy tmpy
         ldx tmpx
         lda tmpa
         rti
 
raster  
         ldx #$00
--
         ldy #$07       ;2
 
         lda tab,x      ;4
         sta $d020      ;4
         sta $d021      ;4
         inx            ;2
         cpx #$c8       ;2
         beq +          ;2
         nop            ;2 _20
-
         lda tab,x      ;4
         sta $d020      ;4
         sta $d021      ;4
         jsr +          ;12
         jsr +          ;12
         jsr +          ;12 _48
         nop            ;2
         inx            ;2
         cpx #$c8       ;2
         beq +          ;2
         dey            ;2
         beq --         ;2 / 3 _61 (+2)
         bne -          ;3     _63
+
         rts
 
!align 255, 0
 
;your colors go here
tab
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
        !text "@kloaolk"
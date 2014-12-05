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
!to "build/cocos2d.prg",cbm    ; output file

;============================================================
; resourcefiles like character sets, music or sprite shapes
; are usually explicitly loaded to a specific location in
; memory. The addresses and loading is handled here
;============================================================

!source "code/config_resources.asm"
!source "code/config_symbols.asm"


;============================================================
; BASIC loader with start address $c000
;============================================================

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152
* = $c000     				            ; start address for 6502 code

!source "code/main.asm"
!source "code/sprites.asm"
!source "code/sub_clear_screen.asm"



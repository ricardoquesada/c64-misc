
; 
; just for testing
;

!cpu 6510
!to "build/test.prg",cbm    ; output file


;============================================================
; BASIC loader with start address $c000
;============================================================

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152
* = $c000     				            ; start address for 6502 code


SCREEN = $0400

	jsr $e544

	ldx #0
-	lda label,x
	cmp #$ff
	beq +
	sta SCREEN,x
	inx	
	jmp -
+	

	lda #$18
	sta $d018
	
	rts



label !scr "hello world world, will you scroll?",$ff

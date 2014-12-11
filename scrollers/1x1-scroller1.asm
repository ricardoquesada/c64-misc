;
; code download from somewhere in the internet
; I don't know its license
;
!cpu 6502
!to "build/scroller1.prg",cbm    ; output file

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152

         *= $c000
 
Q        = 2
XPIXSHIFT = 4
TMP1     = 5
TEXTADR  = 6
 
SCRLADR  = $0400
 
         JSR $E544
 
         SEI
TEXTRESTART
         LDA #<TEXT
         STA TEXTADR
         LDA #>TEXT
         STA TEXTADR+1
 
LOOP     INC $d012
         BNE LOOP
 
DESTSTART = *+1
         LDX #39;39
SRCSTART = *+1
         LDY #39;37
 
XPIXSHIFTADD
         DEC XPIXSHIFT
 
         LDA XPIXSHIFT
         AND #7
         STA $D016
 
         CMP XPIXSHIFT
         STA XPIXSHIFT
         BEQ LOOP
 
         LDA SCRLADR,Y
         STA TMP1
         LDA SCRLADR-1,Y
         PHA
-
         LDA TMP1
         STA SCRLADR-1,X
         PLA
         STA TMP1
         LDA SCRLADR-2,Y
         PHA
         DEY
         DEX
         BNE -
         PLA
GETNEWCHAR
;TEXTADR  = *+1
         LDA (TEXTADR,X)
         BEQ TEXTRESTART
 
         INY
         BMI *+4
         LDX #$27
 
NOBEGIN  INC TEXTADR
         BNE *+4
         INC TEXTADR+1
 
         TAY
         BMI DIRCHANGE
 
         STA SCRLADR,X
         BPL LOOP
;---------------------------------------
DIRCHANGE LDA XPIXSHIFTADD
         EOR #$20
         STA XPIXSHIFTADD
 
         LDX DESTSTART
         LDY SRCSTART
         DEX
         INY
         STX SRCSTART
         STY DESTSTART
         BNE LOOP
;---------------------------------------
TEXT     
         !scr " this scroller can scroll in forward and backward direction!"
         !scr "                                            "
         !BYTE $FF
         !scr "won gnillorcs morf tfel ot thgir ... . "
         !scr "                                        "
         !BYTE $FF,0
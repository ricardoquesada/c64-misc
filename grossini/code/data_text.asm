;============================================================
; Three Lines of Text - our custom character set translates
; the ']' char to a heart symbol in the actual intro 
;============================================================


         *= $1000
 
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
S
         LDA TMP1
         STA SCRLADR-1,X
         PLA
         STA TMP1
         LDA SCRLADR-2,Y
         PHA
         DEY
         DEX
         BNE S
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
TEXT     .TEXT " THIS SCROLLER CAN"
         .TEXT " SCROLL IN FORWARD"
         .TEXT " AND BACKWARD DIREC"
         .TEXT "TION!               "
         .TEXT "                    "
         .TEXT "         "
         .BYTE $FF
         .TEXT "WON GNILLORCS MORF "
         .TEXT "TFEL OT THGIR ... . "
         .TEXT "                    "
         .TEXT "                    "
         .BYTE $FF,0
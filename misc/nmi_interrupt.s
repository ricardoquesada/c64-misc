;--------------------------------------------------------------------------
;
; generates a stable interrupt using NMI
;
;--------------------------------------------------------------------------

.segment "CODE"

        sei
        lda #$35
        sta $01

        ldx #<nmi
        ldy #>nmi
        stx $fffa
        sty $fffb

        lda #$0                         ; stop timer A
        sta $dd0e

        ldx #<$4cc7
        ldy #>$4cc7
        stx $dd04                       ; low-cycle-count
        sty $dd05                       ; high-cycle-count

        lda #%10000001                  ; enable timerA interrupt
        sta $dd0d

:       lda $d012                       ; wait for start of raster (more stable results)
:       cmp $d012
        beq :-
        cmp #$f9
        bne :--

        lda #%10010001                  ; fire the one-shot timer at 50Hz
        sta $dd0e

loop:
        jmp loop


nmi:
        lda $dd0d                       ; acknowledge nmi, i.e. enable it

        inc $d020

        lda $d011                       ; open vertical borders trick
        and #%11110111                  ; first switch to 24 cols-mode...
        sta $d011

        lda #$fc
:       cmp $d012
        bne :-

        lda $d011                       ; ...a few raster lines switch to 25 cols-mode again
        ora #%00001000
        sta $d011

        dec $d020

        rti

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
;
; VChar64 c64 loader example
;
; Compile it using ca65 (http://cc65.github.io/cc65/)
;
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;

.segment "CODE"

        jsr clear_screen

        lda #0
        sta $d020                       ; border color
        lda #10
        sta $d021                       ; background color (from VChar64)
        lda #15
        sta $d022                       ; multicolor #1 (from VChar64)
        lda #0
        sta $d023                       ; multicolor #2 (from VChar64)

        lda #%00011000                  ; no scroll, multi-color,40-cols
        sta $d016

        lda #%00011110                  ; charset at $3800
        sta $d018

        jsr setup_charset
        jsr display_logo

        sei

        lda #$7f                        ; turn off cia interrups
        sta $dc0d
        sta $dd0d

        lda #01                         ; enable raster irq
        sta $d01a

        lda $dc0d                       ; ack possible interrupts
	lda $dd0d
        asl $d019

        ldx #<irq
        ldy #>irq
        stx $314
        sty $315
        cli

        jmp *                           ; infinite loop

irq:
	asl $d019

        ldx index
        lda luma,x
        sta $d022
        inx
        cpx #30
        bne @end
        ldx #$00
@end:
        stx index
        jmp $ea81

index:
        .byte 0

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; clear_screen
; clears screen RAM and color RAM
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc clear_screen
        ; "jsr $e544" cleans the screen using $20
        ; but since we are using a custom charset, we should use 
        ; $67 (103) as the clear char
        ; also, we should clear the color ram as well

        lda #$67                        ; screen code
        ldx #$00
loop1:  sta $0400,x                     ; clears the screen memory
        sta $0500,x
        sta $0600,x
        sta $06e8,x
        inx
        bne loop1

        lda colors + $67               ; get color for tile $67
        ldx #$00
loop2:  sta $d800,x                    ; clears the color RAM
        sta $d900,x
        sta $da00,x
        sta $dae8,x
        inx
        bne loop2

        rts
.endproc

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; setup_charset
; copies charset to $3800
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc setup_charset
        ; copies the charset to $3800
        ; The alternative, is to import the charset data directly to $3800

        ldy #7                          ; 256 * 8 = 2048 bytes to copy
outer_loop:
        ldx #0
inner_loop:
src_hi = * + 2
        lda charset,x
dst_hi = * + 2
        sta $3800,x
        dex
        bne inner_loop
        inc src_hi
        inc dst_hi
        dey
        bpl outer_loop
        rts
        
.endproc

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; display_logo
; copies logo and colors to screen RAM and color RAM
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.proc display_logo
        ; displays the logo: 40x10 (400 bytes)
        ; with an unrolled loop: copies 256 + 144 chars

        ; copies 256 chars
        ldx #$00
loop:   lda map + $0000,x
        sta $0400 + $0000,x             ; screen chars

        ; copies its color
        tay
        lda colors,y
        sta $d800,x                     ; colors for the chars

        ; copies 256 chars as well, but overwrites
        ; some of the previous one. it copies 144 new chars
        lda map + (MAP_COUNT .MOD 256),x
        sta $0400 + (MAP_COUNT .MOD 256),x ; screen chars

        ; copies its colors
        tay
        lda colors,y
        sta $d800 + (MAP_COUNT .MOD 256),x ; colors for the chars

        inx
        bne loop

        rts
.endproc

        ;$01,$0d,$07,$03,$0f,$05,$0a,$0e,$0c,$08,$04,$02,$0b,$09,$06,$00
luma:
.byte $01,$0d,$07,$03,$0f,$05,$0a,$0e,$0c,$08,$04,$02,$0b,$09,$06,$00


; Exported using VChar64 v0.0.10-83-g24ef-dirty
; Total bytes: 2048
charset:
.byte $7a,$6a,$6a,$6a,$2a,$aa,$aa,$aa,$b4,$a4,$a5,$a4,$a1,$a9,$a8,$ab	; 0
.byte $fa,$ea,$aa,$aa,$aa,$aa,$aa,$aa,$bb,$af,$af,$be,$fa,$ea,$aa,$aa	; 16
.byte $fa,$ff,$aa,$aa,$aa,$aa,$aa,$aa,$ff,$ff,$aa,$aa,$aa,$aa,$aa,$aa	; 32
.byte $ab,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$3f,$4c,$3f,$4c,$cc,$90,$9c,$90	; 48
.byte $57,$5e,$7a,$ea,$aa,$aa,$aa,$aa,$ab,$a9,$ab,$ab,$a8,$aa,$aa,$aa	; 64
.byte $aa,$ee,$bb,$aa,$aa,$ea,$aa,$aa,$aa,$aa,$fa,$be,$e3,$bc,$f3,$ce	; 80
.byte $aa,$aa,$fa,$bb,$be,$bb,$af,$ae,$aa,$aa,$ff,$ee,$ab,$ea,$ae,$aa	; 96
.byte $aa,$aa,$ff,$ff,$ff,$fe,$bb,$ee,$aa,$ae,$bb,$aa,$aa,$aa,$aa,$aa	; 112
.byte $84,$a6,$a6,$a6,$a2,$aa,$aa,$aa,$ca,$ea,$ea,$ea,$2a,$aa,$aa,$aa	; 128
.byte $45,$51,$45,$41,$07,$07,$17,$07,$c2,$f6,$f2,$f6,$f1,$3d,$f0,$3c	; 144
.byte $7a,$7a,$6a,$6a,$ea,$ea,$aa,$aa,$aa,$aa,$a8,$a8,$ab,$a9,$ab,$ab	; 160
.byte $6a,$6a,$6a,$7a,$ca,$da,$ca,$ce,$30,$3c,$30,$3c,$cc,$8f,$8c,$8f	; 176
.byte $4b,$6a,$6a,$6a,$2a,$aa,$aa,$aa,$a9,$aa,$aa,$aa,$aa,$ea,$ba,$aa	; 192
.byte $40,$41,$50,$40,$47,$11,$47,$53,$5d,$7e,$7e,$7e,$76,$7a,$7a,$7a	; 208
.byte $ad,$ad,$a5,$8d,$94,$91,$94,$90,$2a,$2a,$2a,$2a,$ca,$da,$ca,$da	; 224
.byte $aa,$aa,$aa,$aa,$aa,$ae,$bb,$aa,$f2,$f2,$c6,$36,$ce,$1a,$1a,$1a	; 240
.byte $aa,$ff,$ab,$ab,$ab,$ab,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$ea,$ba,$aa	; 256
.byte $aa,$bb,$ae,$aa,$aa,$ae,$ab,$ea,$ff,$3f,$ff,$3f,$cf,$8f,$8f,$8f	; 272
.byte $aa,$bb,$ee,$aa,$aa,$ee,$bb,$aa,$46,$16,$06,$07,$c1,$c1,$f1,$c1	; 288
.byte $aa,$ba,$ee,$aa,$aa,$bb,$ee,$aa,$aa,$aa,$ab,$ab,$a9,$a9,$ab,$a2	; 304
.byte $04,$44,$04,$44,$d0,$d0,$c4,$50,$aa,$aa,$aa,$aa,$aa,$2a,$4a,$52	; 320
.byte $6a,$ea,$ea,$6a,$2a,$aa,$aa,$aa,$d4,$d0,$d4,$d0,$71,$91,$b1,$91	; 336
.byte $41,$45,$51,$45,$57,$47,$57,$57,$04,$04,$07,$07,$1c,$1c,$18,$18	; 352
.byte $aa,$ee,$bb,$aa,$aa,$fe,$ff,$aa,$fe,$32,$fe,$33,$fc,$fc,$fc,$fc	; 368
.byte $aa,$aa,$00,$ff,$ff,$ff,$ff,$ff,$aa,$aa,$aa,$aa,$aa,$aa,$a9,$aa	; 384
.byte $aa,$ab,$ae,$aa,$aa,$aa,$aa,$ea,$ff,$ff,$ff,$ff,$aa,$aa,$aa,$aa	; 400
.byte $a3,$a3,$a3,$b3,$8f,$8c,$df,$cf,$ff,$ff,$ff,$0c,$ea,$aa,$aa,$aa	; 416
.byte $40,$40,$41,$50,$15,$b4,$9d,$b4,$f5,$dd,$75,$ff,$aa,$aa,$aa,$aa	; 432
.byte $aa,$aa,$aa,$aa,$aa,$aa,$aa,$ea,$77,$15,$11,$77,$aa,$aa,$aa,$aa	; 448
.byte $aa,$aa,$aa,$aa,$aa,$ff,$bf,$aa,$33,$cc,$33,$00,$ff,$ff,$fc,$ff	; 464
.byte $ea,$ea,$ea,$ca,$7a,$7a,$7a,$12,$f3,$33,$f2,$f2,$00,$ff,$ff,$ff	; 480
.byte $d5,$d1,$d5,$41,$04,$01,$10,$00,$6a,$6a,$2a,$48,$19,$7b,$19,$71	; 496
.byte $47,$46,$d6,$96,$9e,$9a,$ba,$2a,$3f,$3c,$3f,$00,$aa,$aa,$aa,$aa	; 512
.byte $ab,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$a6,$ae,$a6,$8c,$91,$93,$91,$13	; 528
.byte $aa,$bb,$ee,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$ab,$ab,$eb,$bb,$fb	; 544
.byte $be,$fe,$fe,$fb,$ab,$a8,$ab,$a8,$aa,$aa,$aa,$aa,$aa,$ff,$fe,$aa	; 560
.byte $ea,$ea,$ea,$aa,$ba,$ba,$ba,$ca,$ff,$ff,$ff,$ef,$bb,$ef,$bf,$ee	; 576
.byte $1c,$1e,$1e,$0e,$12,$1a,$5a,$1a,$aa,$aa,$aa,$aa,$f7,$51,$d0,$44	; 592
.byte $aa,$aa,$aa,$aa,$ff,$f7,$dd,$f5,$aa,$aa,$aa,$aa,$ff,$df,$77,$df	; 608
.byte $aa,$aa,$aa,$aa,$ba,$8a,$9a,$de,$aa,$aa,$aa,$aa,$df,$45,$07,$11	; 624
.byte $8e,$36,$46,$06,$05,$80,$20,$88,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$a2	; 640
.byte $aa,$aa,$a8,$ad,$b7,$cf,$3f,$ef,$aa,$bb,$ef,$aa,$aa,$aa,$aa,$aa	; 656
.byte $aa,$ee,$fb,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$ee,$bb,$aa	; 672
.byte $aa,$aa,$ab,$ab,$a8,$a9,$a8,$ac,$30,$34,$23,$64,$ed,$a9,$a9,$a9	; 688
.byte $a4,$a7,$a0,$b3,$54,$33,$cf,$3f,$aa,$aa,$aa,$a8,$a9,$ab,$ab,$a3	; 704
.byte $aa,$ff,$ff,$aa,$aa,$ef,$bf,$aa,$aa,$aa,$aa,$aa,$aa,$ab,$ae,$aa	; 720
.byte $ff,$ff,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$fe,$fb,$aa	; 736
.byte $04,$41,$04,$5f,$aa,$aa,$aa,$aa,$33,$33,$3f,$2f,$ef,$ef,$ab,$ab	; 752
.byte $ab,$ab,$ab,$af,$cf,$ff,$ff,$ff,$aa,$aa,$aa,$aa,$aa,$ba,$ae,$be	; 768
.byte $b3,$a3,$a0,$a3,$ac,$a9,$a8,$a9,$aa,$aa,$aa,$aa,$aa,$ba,$ea,$aa	; 784
.byte $aa,$aa,$aa,$aa,$aa,$bb,$ee,$aa,$aa,$aa,$aa,$aa,$aa,$bb,$ae,$aa	; 800
.byte $b3,$a3,$a3,$a3,$af,$ab,$ab,$ab,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa	; 816
.byte $aa,$aa,$aa,$aa,$aa,$ff,$ff,$aa,$a3,$a3,$a4,$b7,$8c,$90,$90,$d0	; 832
.byte $2a,$2a,$2b,$3a,$ca,$ca,$ce,$ce,$73,$4f,$3f,$4c,$31,$01,$41,$41	; 848
.byte $f2,$32,$06,$33,$01,$30,$01,$01,$aa,$aa,$aa,$ab,$a9,$a9,$a8,$ad	; 864
.byte $a9,$a9,$e8,$aa,$aa,$ea,$ba,$aa,$aa,$bb,$ee,$aa,$aa,$fe,$fb,$aa	; 880
.byte $aa,$ff,$ff,$aa,$aa,$ff,$ff,$aa,$0c,$0f,$33,$0f,$33,$0c,$ff,$cf	; 896
.byte $aa,$2a,$2b,$2a,$ca,$ca,$ca,$ca,$bb,$ec,$fe,$ba,$aa,$aa,$aa,$aa	; 912
.byte $aa,$ff,$ff,$aa,$aa,$aa,$aa,$aa,$ff,$ff,$ff,$ff,$cf,$cf,$cc,$c3	; 928
.byte $aa,$ee,$bb,$aa,$aa,$ee,$ba,$aa,$f2,$f2,$f2,$fe,$fc,$ff,$fc,$ff	; 944
.byte $ab,$aa,$aa,$aa,$aa,$ea,$ba,$aa,$aa,$ff,$bf,$aa,$aa,$ee,$bb,$aa	; 960
.byte $aa,$ba,$ee,$aa,$aa,$aa,$aa,$aa,$aa,$fe,$fb,$aa,$aa,$ee,$bb,$aa	; 976
.byte $f2,$f3,$f0,$ff,$ff,$ff,$ff,$ff,$aa,$aa,$aa,$aa,$aa,$ff,$bb,$aa	; 992
.byte $aa,$ff,$bf,$aa,$aa,$ef,$bb,$aa,$9d,$af,$ad,$af,$a7,$ab,$ab,$ab	; 1008
.byte $44,$11,$40,$44,$40,$d0,$90,$d3,$aa,$ee,$bb,$aa,$aa,$aa,$aa,$aa	; 1024
.byte $4f,$73,$4f,$73,$cc,$3c,$cc,$3c,$aa,$ee,$bb,$aa,$aa,$ee,$bb,$aa	; 1040
.byte $af,$ab,$aa,$aa,$aa,$ee,$ba,$aa,$10,$00,$44,$51,$ab,$ab,$a8,$ab	; 1056
.byte $aa,$ef,$bb,$aa,$aa,$ee,$aa,$a6,$46,$02,$77,$33,$fc,$fd,$fc,$fc	; 1072
.byte $aa,$aa,$cc,$33,$ff,$ff,$ff,$fe,$aa,$aa,$aa,$aa,$aa,$ae,$ab,$6a	; 1088
.byte $ff,$ff,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$6a,$da,$f6,$7d,$5f,$55,$10	; 1104
.byte $aa,$aa,$aa,$aa,$aa,$6a,$fa,$d6,$ae,$ae,$ae,$9d,$b7,$b7,$b7,$77	; 1120
.byte $aa,$ee,$ba,$aa,$aa,$aa,$ab,$ac,$5d,$1f,$b7,$b5,$8d,$ac,$ac,$a3	; 1136
.byte $aa,$aa,$aa,$aa,$aa,$ba,$ee,$aa,$00,$00,$00,$00,$00,$00,$00,$00	; 1152
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1168
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1184
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1200
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1216
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1232
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1248
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1264
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1280
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1296
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1312
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1328
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1344
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1360
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1376
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1392
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1408
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1424
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1440
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1456
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1472
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1488
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1504
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1520
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1536
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1552
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1568
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1584
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1600
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1616
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1632
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1648
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1664
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1680
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1696
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1712
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1728
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1744
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1760
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1776
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1792
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1808
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1824
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1840
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1856
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1872
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1888
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1904
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1920
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1936
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1952
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1968
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 1984
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 2000
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 2016
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 2032
CHARSET_COUNT = 2048

; Exported using VChar64 v0.0.10-83-g24ef-dirty
; Total bytes: 256
colors:
.byte $0c,$0c,$0a,$0a,$0a,$0a,$0a,$0c,$0c,$09,$0a,$0a,$0a,$0a,$0a,$0a	; 0
.byte $08,$0f,$0f,$0c,$0c,$0f,$0c,$0c,$0c,$0a,$0f,$0f,$0f,$0c,$0a,$0c	; 16
.byte $0a,$0a,$0a,$0c,$0a,$0c,$0a,$0c,$0f,$08,$0f,$0f,$0f,$0c,$0a,$0a	; 32
.byte $0c,$08,$0a,$0a,$0c,$0c,$0f,$0f,$0c,$0f,$0a,$0c,$0f,$0c,$0f,$0f	; 48
.byte $0c,$0c,$0c,$0f,$0a,$0a,$0c,$0a,$0c,$0a,$0f,$0f,$0f,$0f,$0c,$0f	; 64
.byte $0f,$08,$0c,$0a,$0a,$0a,$0c,$0c,$0c,$0f,$0a,$0a,$0c,$0a,$0f,$0a	; 80
.byte $0a,$0a,$0c,$0a,$0a,$0a,$0c,$08,$0a,$0c,$0c,$0c,$0c,$0c,$0a,$0a	; 96
.byte $0a,$0c,$0c,$0c,$0a,$0c,$0a,$0a,$0a,$0a,$0a,$0a,$0c,$0a,$0a,$0f	; 112
.byte $0c,$0a,$0c,$0a,$0a,$0c,$0a,$0c,$0a,$0a,$0c,$0f,$09,$0f,$0a,$0f	; 128
.byte $0a,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 144
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 160
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 176
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 192
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 208
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 224
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; 240
COLORS_COUNT = 256

; Exported using VChar64 v0.0.10-83-g24ef-dirty
; Total bytes: 1000
map:
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 0
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 16
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 32
.byte $67,$67,$67,$67,$31,$8c,$67,$67,$67,$67,$67,$67,$67,$67,$4e,$67	; 48
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 64
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$8f,$8b,$29	; 80
.byte $67,$67,$67,$67,$67,$56,$87,$38,$67,$67,$67,$67,$67,$67,$67,$67	; 96
.byte $67,$67,$67,$67,$67,$67,$67,$67,$70,$70,$70,$70,$70,$70,$70,$70	; 112
.byte $70,$70,$70,$6f,$24,$6e,$80,$71,$72,$83,$7e,$7b,$76,$34,$75,$6a	; 128
.byte $83,$86,$79,$5a,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70	; 144
.byte $68,$68,$68,$68,$68,$47,$64,$63,$51,$65,$90,$45,$61,$6d,$82,$5f	; 160
.byte $77,$5b,$64,$64,$27,$6b,$57,$6c,$38,$8d,$89,$55,$3a,$68,$68,$68	; 176
.byte $68,$68,$68,$68,$68,$68,$68,$68,$74,$74,$74,$74,$74,$54,$8e,$52	; 192
.byte $50,$4f,$4d,$4c,$4b,$58,$3d,$60,$49,$48,$44,$7a,$43,$40,$42,$36	; 208
.byte $3f,$3e,$3c,$44,$53,$74,$74,$74,$74,$74,$74,$74,$74,$74,$74,$74	; 224
.byte $70,$70,$70,$70,$2e,$83,$84,$73,$41,$5e,$39,$37,$85,$3b,$35,$33	; 240
.byte $46,$2f,$32,$59,$2c,$2a,$26,$7f,$28,$2d,$25,$22,$24,$5a,$70,$70	; 256
.byte $70,$70,$70,$70,$70,$70,$70,$70,$68,$68,$68,$68,$68,$68,$68,$68	; 272
.byte $68,$5d,$55,$21,$69,$1f,$1e,$55,$78,$23,$1d,$1c,$1b,$1e,$55,$19	; 288
.byte $2b,$18,$17,$16,$55,$55,$7d,$7d,$7d,$7d,$3a,$68,$68,$68,$68,$68	; 304
.byte $74,$74,$74,$74,$74,$74,$74,$74,$74,$44,$44,$15,$1a,$14,$44,$44	; 320
.byte $7a,$62,$13,$12,$11,$44,$44,$7a,$10,$0f,$66,$7c,$30,$88,$0e,$0d	; 336
.byte $0c,$0b,$0a,$81,$74,$74,$74,$74,$67,$67,$67,$67,$67,$67,$67,$67	; 352
.byte $67,$67,$67,$09,$08,$67,$67,$67,$67,$42,$07,$4a,$67,$67,$67,$67	; 368
.byte $67,$67,$06,$8a,$5c,$05,$04,$20,$03,$02,$67,$67,$67,$67,$67,$67	; 384
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 400
.byte $67,$67,$01,$00,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 416
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 432
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 448
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 464
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 480
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 496
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 512
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 528
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 544
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 560
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 576
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 592
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 608
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 624
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 640
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 656
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 672
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 688
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 704
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 720
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 736
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 752
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 768
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 784
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 800
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 816
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 832
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 848
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 864
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 880
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 896
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 912
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 928
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 944
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 960
.byte $67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67,$67	; 976
.byte $67,$67,$67,$67,$67,$67,$67,$67	; 992
MAP_COUNT = 1000

;--------------------------------------------------------------------------
;
; PET RAM check
;
;--------------------------------------------------------------------------

.segment "CODE"

        sei
        ldx #0
        lda #$20

l_clean:
        sta $8000,x                     ; clear screen
        sta $8100,x
        sta $8200,x
        sta $82e8,x

        inx
        bne l_clean

main:

        ldx #0
        lda #$55
l0_sta_ram:                                             ; $0000 - $0800
        .repeat 16*8,J
                sta $00 + (J * $0100),x
        .endrepeat
        inx
        beq next
        jmp l0_sta_ram

next:
        .repeat 16,J                                    ; A max of 16 RAM 4116 chips
                .repeat 4,I                             ; Each chip has 2k (0x800) RAM
                .scope
                        ldy #07                         ; 'g'
                        @l0_cmp0:
                                lda $0000 + (J * $0800) + (I * $0200),x
                                cmp #$55
                                bne @l0_bad0
                                lda $0100 + (J * $0800) + (I * $0200),x
                                cmp #$55
                                bne @l0_bad0
                                inx
                                bne @l0_cmp0

                                beq :+
                        @l0_bad0:
                                dey
                        :
                                sty $8000 + (J * 40) + I
                .endscope
                .endrepeat
        .endrepeat

        inc $83e7

        jmp main

.segment "ROM_VECTOR"
        .word $f000
        .word $f000
        .word $f000

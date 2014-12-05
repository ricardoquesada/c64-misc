;===============================================================
; setting up some general symbols we use in our code
;================================================================

;============================================================
; symbols
;============================================================

screen_ram      = $0400     ; location of screen ram
init_sid        = $11ed     ; init routine for music
play_sid        = $1004     ; play music routine
delay_counter   = $90       ; used to time color switch in the border
pra             = $dc00     ; CIA#1 (Port Register A)
prb             = $dc01     ; CIA#1 (Port Register B)
ddra            = $dc02     ; CIA#1 (Data Direction Register A)
ddrb            = $dc03     ; CIA#1 (Data Direction Register B)
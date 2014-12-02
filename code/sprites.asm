; those are the shared sprite colors
; we could have parsed that information from the sprites.spr file
; but for this simple single-sprite demo we can just write it down
; manually
sprite_background_color = $00
sprite_multicolor_1  	= 3
sprite_multicolor_2  	= 2

; individual sprite color for Sprite#0. This is also stored in Byte 64
; of each Sprite (low nibble) when we use SpritePad. We did not bother
; to parse this information in this case either.
sprite_ship_color		= 10

init_sprites
				; store the pointer in the sprite pointer register for Sprite#0
				; Sprite Pointers are the last 8 bytes of Screen RAM, e.g. $07f8-$07ff
				lda #$80
				sta screen_ram + $3f8 		

				lda #$01     ; enable Sprite#0
				sta $d015 

				lda #$01     ; set multicolor mode for Sprite#0
				sta $d01c

				lda #$00     ; Sprite#0 has priority over background
				sta $d01b

				lda #sprite_background_color ; shared background color
				sta $d021

				lda #sprite_multicolor_1 	 ; shared multicolor 1
				sta $d025

				lda #sprite_multicolor_2 	 ; shared multicolor 2
				sta $d026

				lda #sprite_ship_color 	 	 ; individual Sprite#0 color
				sta $d027

				lda #$00     ; set X-Coord high bit (9th Bit) for Sprite#0
				sta $d010

				lda #$80 	; set Sprite#0 positions with X/Y coords to
				sta $d000   ; lower right of the screen
				lda #$80    ; $d000 corresponds to X-Coord (0-504 incl 9th Bit on PAL systems)
				sta $d001   ; $d001 corresponds to Y-Coord (0-255 on PAL systems)
				rts




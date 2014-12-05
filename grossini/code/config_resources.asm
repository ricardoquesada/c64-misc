; load external binaries

address_sprites = $2000	  ;loading address for ship sprite
address_chars = $3800     ; loading address for charset ($3800: last possible location for the 512bytes in Bank 3)
address_sid = $1001 	  ; loading address for sid tune

* = address_sprites                  
!bin "resources/sprites.spr",512,0  	 ; skip first three bytes which is encoded Color Information
										 ; then load 16x64 Bytes from file
; * = address_sid                         
; !bin "resources/empty_1000.sid",, $7c+2  ; remove header from sid and cut off original loading address 

; * = address_chars                     
; !bin "resources/rambo_font.ctm",384,24   ; skip first 24 bytes which is CharPad format information 

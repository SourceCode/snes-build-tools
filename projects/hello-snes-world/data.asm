;==============================================================================
; Data Includes - Hello SNES World
; Binary asset data embedded into ROM via .incbin
;
; Labels are accessed from C via:
;   extern char label, label_end;
;   u16 size = &label_end - &label;
;==============================================================================

.include "hdr.asm"

;----------------------------------------------------------------------
; Background graphics (4bpp tiles from bg_earthbound.png)
;----------------------------------------------------------------------
.section ".rodata1" superfree

bg_tiles:
.incbin "assets/backgrounds/bg_earthbound.pic"
bg_tiles_end:

.ends

.section ".rodata2" superfree

bg_palette:
.incbin "assets/backgrounds/bg_earthbound.pal"
bg_palette_end:

bg_map:
.incbin "assets/backgrounds/bg_earthbound.map"
bg_map_end:

.ends

;----------------------------------------------------------------------
; Font graphics (4bpp tiles from font_large.png)
;----------------------------------------------------------------------
.section ".rodata3" superfree

font_tiles:
.incbin "assets/fonts/font_large.pic"
font_tiles_end:

font_palette:
.incbin "assets/fonts/font_large.pal"
font_palette_end:

.ends

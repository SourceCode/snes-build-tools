# ==============================================================================
# Hello SNES World - Makefile
# PVSnesLib demo ROM with Earthbound-style background and centered text
# ==============================================================================

ifeq ($(strip $(PVSNESLIB_HOME)),)
$(error "Please set PVSNESLIB_HOME. Run: source ../../env.sh (Unix) or call ../../env.bat (Windows)")
endif

include ${PVSNESLIB_HOME}/devkitsnes/snes_rules

# Add project include directory to compiler search path
CFLAGS += -Iinclude

# Fix snes_rules Windows path conversion bug when using bash shell.
# The LIBDIRSOBJSW conversion (lines 49-53 of snes_rules) breaks because
# $$(echo ...) deferred expansion fails under /usr/bin/sh.
# Override with the forward-slash path which works in both bash and wlalink.
LIBDIRSOBJSW := $(LIBDIRSOBJS)

.PHONY: bitmaps all clean rebuild

# ---- ROM Configuration ----
# ROMNAME is used by snes_rules to produce $(ROMNAME).sfc
export ROMNAME := hello_snes_world

# ---- Default target ----
all: bitmaps $(ROMNAME).sfc

# ---- Clean ----
clean: cleanBuildRes cleanRom cleanGfx cleanAssets

cleanAssets:
	@echo clean asset conversions
	@rm -f assets/fonts/*.pic assets/fonts/*.pal assets/fonts/*.map
	@rm -f assets/fonts/*.inc assets/fonts/*_data.as
	@rm -f assets/backgrounds/*.pic assets/backgrounds/*.pal assets/backgrounds/*.map
	@rm -f assets/backgrounds/*.inc assets/backgrounds/*_data.as

# ---- Rebuild ----
rebuild: clean all

# ==============================================================================
# Asset Conversion Rules
# $(GFXCONV) is defined by snes_rules -> points to gfx4snes
# ==============================================================================

# ---- Font ----
# 4bpp (16 colors), 8x8 tiles
# -s 8 = 8x8 tile size
# -o 16 = output 16 colors to .pal
# -u 16 = use 16 colors
# -e 0 = palette entry 0 in map tiles
# -p = generate palette file
# -m = generate map file (ensures sequential tile ordering in .pic)
# -R = no tile reduction (keep all tiles for predictable indices)
assets/fonts/font_large.pic: assets/fonts/font_large.png
	@echo convert font ... $(notdir $<)
	$(GFXCONV) -s 8 -o 16 -u 16 -e 0 -p -m -R -i $<

# ---- Background ----
# 4bpp, 8x8 tiles, with tilemap
# -m = generate tilemap
assets/backgrounds/bg_earthbound.pic: assets/backgrounds/bg_earthbound.png
	@echo convert background ... $(notdir $<)
	$(GFXCONV) -s 8 -o 16 -u 16 -e 0 -p -m -i $<

# ---- Bitmap target collects all asset conversions ----
bitmaps: assets/fonts/font_large.pic assets/backgrounds/bg_earthbound.pic

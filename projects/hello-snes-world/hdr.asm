;==============================================================================
; SNES ROM Header - Hello SNES World
; LoROM mapping, 4Mbit (512KB), no SRAM
;==============================================================================

;==LoRom==

.MEMORYMAP                      ; Describe the system memory architecture
  SLOTSIZE $8000                ; Each ROM bank is 32KB in LoROM
  DEFAULTSLOT 0
  SLOT 0 $8000                  ; ROM slot at $8000-$FFFF
  SLOT 1 $0 $2000              ; Direct page / stack
  SLOT 2 $2000 $E000           ; Low RAM
  SLOT 3 $0 $10000             ; Full bank (for data sections)
.ENDME

.ROMBANKSIZE $8000              ; 32KB per bank
.ROMBANKS 16                    ; 16 banks = 512KB = 4Mbit

;==============================================================================
; SNES Header (at LoROM offset $00:FFC0)
;==============================================================================

.SNESHEADER
  ID "SNES"

  NAME "HELLO SNES WORLD     "  ; 21 bytes, padded with spaces
  ;    "123456789012345678901"  ; ruler for counting

  SLOWROM
  LOROM

  CARTRIDGETYPE $00             ; ROM only (no SRAM, no battery)
  ROMSIZE $09                   ; 2^9 = 512KB = 4Mbit
  SRAMSIZE $00                  ; No SRAM
  COUNTRY $01                   ; USA / NTSC
  LICENSEECODE $00              ; Homebrew
  VERSION $00                   ; v1.0
.ENDSNES

;==============================================================================
; Interrupt Vectors
;==============================================================================

.SNESNATIVEVECTOR               ; Native mode (65816) vectors
  COP EmptyHandler
  BRK EmptyHandler
  ABORT EmptyHandler
  NMI VBlank                    ; VBlank handler (defined by PVSnesLib)
  IRQ EmptyHandler
.ENDNATIVEVECTOR

.SNESEMUVECTOR                  ; Emulation mode (6502) vectors
  COP EmptyHandler
  ABORT EmptyHandler
  NMI EmptyHandler
  RESET tcc__start              ; C runtime entry point (PVSnesLib crt0)
  IRQBRK EmptyHandler
.ENDEMUVECTOR

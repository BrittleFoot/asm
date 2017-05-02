
STACCATO = 1
LEGATO   = 2


SZ_1     = 1000000000000000b
SZ_2     = 0000000010000000b
SZ_4     = 0000000000001000b
SZ_8     = 0000000000000010b
SZ_16    = 0000000000000001b


Muse struc
   freqence dw  0000h
   len      dw  0000h
   modif    dw  0000h
Muse ends



MUSIC_START:
include     cw.asm
MUSIC_STOP:
    db  "$"

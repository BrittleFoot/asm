
PLAYABLE    =   24h


Note struc
   string   db  00h, 00h
   status   db  00h
   freq     dw  0000h
Note ends



NOTES_START:

    Note ?
FIRST_OCTAVE_SHARP:
    Note ?
    Note <"C#", PLAYABLE, 8609>
    Note <"D#", PLAYABLE, 7670>
    Note ?
    Note <"F#", PLAYABLE, 6449>
    Note <"G#", PLAYABLE, 5746>
    Note <"A#", PLAYABLE, 5119>

SECOND_OCTAVE_SHARP:
    Note ?
    Note <"C#", PLAYABLE, 4304>
    Note <"D#", PLAYABLE, 3834>
    Note ?
    Note <"F#", PLAYABLE, 3224>
    Note <"G#", PLAYABLE, 2873>
    Note <"A#", PLAYABLE, 2559>

FIRST_OCTAVE:
    Note <"C",  PLAYABLE, 9121>
    Note <"D",  PLAYABLE, 8126>
    Note <"E",  PLAYABLE, 7239>
    Note <"F",  PLAYABLE, 6833>
    Note <"G",  PLAYABLE, 6087>
    Note <"A",  PLAYABLE, 5423>
    Note <"B",  PLAYABLE, 4831>

SECOND_OCTAVE:
    Note <"C",  PLAYABLE, 4560>
    Note <"D",  PLAYABLE, 4063>
    Note <"E",  PLAYABLE, 3619>
    Note <"F",  PLAYABLE, 3416>
    Note <"G",  PLAYABLE, 3043>
    Note <"A",  PLAYABLE, 2711>
    Note <"B",  PLAYABLE, 2415>


THIRD_OCTAVE_SHARP:
    Note ?
    Note <"C#", PLAYABLE, 2152>
    Note <"D#", PLAYABLE, 1917>
    Note ?
    Note <"F#", PLAYABLE, 1612>
    Note <"G#", PLAYABLE, 1436>
    Note <"A#", PLAYABLE, 1292>
    Note ?


    Note ?
    Note ?
    Note ?      ;  здесь могла быть ваша октава :)
    Note ?
    Note ?
    Note ?
    Note ?

THIRD_OCTAVE:
    Note <"C",  PLAYABLE, 2280>
    Note <"D",  PLAYABLE, 2031>
    Note <"E",  PLAYABLE, 1809>
    Note <"F",  PLAYABLE, 1715>
    Note <"G",  PLAYABLE, 1521>
    Note <"A",  PLAYABLE, 1355>
    Note <"B",  PLAYABLE, 1207>
    Note <"C",  PLAYABLE, 1140>






translate_into_freq:
;   al - scancode
;   out:
;       ax - freq
;       dx - offset of string note_name
    push    bx
    xor     ah, ah
    xor     bx, bx
    mov     bl, size Note
    mul     bl
    mov     bx, ax
    add     bx, offset NOTES_START

    mov     al, byte ptr [bx+2]
    cmp     al, PLAYABLE
    jne     @@not_A_note

    mov     ax, word ptr [bx+3]
    mov     dx, bx

    pop     bx
    clc
    ret

    @@not_A_note:
    pop     bx
    stc
    ret   

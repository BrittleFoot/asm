include     music\soundlib.asm

STACCATO = 1
LEGATO   = 2

SZ_1     = 8
SZ_2     = 4
SZ_4     = 2
SZ_8     = 1


Muse struc
   freqence dw  0000h
   len      dw  0000h
   modif    dw  0000h
Muse ends

Sound struc
    play_pos      dw    0000h
    music_start   dw    0000h
    music_stop    dw    0000h
    stop_callback dw    0000h
Sound ends


A:
include     music\lalalala.asm
B:
include     music\welcome.asm
C:
include     music\ost.asm
D:
include     music\sot.asm
E:
include     music\end.asm
F:  db '$'



; in all callbacks DI points to current sound

lalalalalala     Sound   <0, offset A, offset B, offset continue_ost>
welcome          Sound   <0, offset B, offset C, offset replay>
ost              Sound   <0, offset C, offset D, offset replay>
sot              Sound   <0, offset D, offset E, offset replay>
endsound         Sound   <0, offset E, offset F, offset dummy>


dummy: ret

replay:
    mov     ax, di
    call    play_sound
    ret


continue_ost:
    lea     ax, ost
    call    play_sound
    ret

continue_sot:
    lea     ax, sot
    call    play_sound
    ret


curr_sound   dw  0000h
take_note:
;   ret     bx - freq
;           dx - len 
;           cx - modif
    mov     di, curr_sound

    mov     ax, [di].play_pos
    mov     bx, [di].music_start
    add     bx, ax

    cmp      bx, [di].music_stop
    jae      @@endplay



    mov     dx, [bx+2]
    mov     cx, [bx+4]
    mov     bx, [bx]


    add     [di].play_pos, size Muse

    clc
    ret

    @@endplay:
    mov     [di].play_pos, 0
    call    stop_play
    call    [di].stop_callback

    stc
    ret


old_timer   dd  00000000h

set_timer_tick proc c uses ax bx cx ds dx
    ; dx - func
    mov     ax, 251Ch
    push    cs
    pop     ds
    int     21h
    ret
set_timer_tick endp

save_old_timer_tick proc c uses ax bx es
    mov     ax, 351Ch
    int     21h
    mov     word ptr [old_timer+2], es
    mov     word ptr [old_timer], bx
    ret
save_old_timer_tick endp

restore_old_timer_tick proc c uses ax bx ds dx

    lds     dx, old_timer
    mov     ax, 251Ch
    int     21h
    ret
restore_old_timer_tick endp


lastnote    Muse    <0000h, 0000h, 0000h> 
timer_tick:
    push    ax bx cx dx

    cmp     lastnote.len, 0
    jnz     @@play
    
    call    take_note
    jc      @@stop_play

    mov     lastnote.freqence, bx
    mov     lastnote.len, dx
    mov     lastnote.modif, cx

    @@play:

    dec         lastnote.len
    mov         bx, lastnote.freqence
    set_freq    bx
    cmp         bx, 0
    jz          @@stop_play
    speaker_on
    jmp @@ret

    @@stop_play:
    speaker_off

    @@ret:
    pop     dx cx bx ax
    iret


play_sound proc c uses ax bx cx dx
;   args - ax - offset to Sound
    mov curr_sound, ax 
    speaker_off
    initialize_timer


    cmp     word ptr old_timer, 0
    jz      @@play
    call    restore_old_timer_tick

    @@play:

    call    save_old_timer_tick
    lea     dx, timer_tick
    call    set_timer_tick
    ret
play_sound endp

stop_play proc c uses ax bx
    cmp     word ptr old_timer, 0
    jz      @@none
    call    restore_old_timer_tick
    @@none:
    speaker_off
    ret
stop_play endp

refresh_sound proc c uses ax bx
    xchg    ax, bx
    mov     [bx].play_pos, 0
    mov     lastnote.len, 0
    
    ret
refresh_sound endp
    .model  tiny
    .code
    org     100h
    locals  @@

start:
    jmp     main


include     soundlib.asm
include     notes.asm



LEN_OF_ONE = 4
LEN_OF_HALF = LEN_OF_ONE / 2


play:
    ; bx - frequency_value
    ; dx - length


    test bx, bx
    jz  @@1
    set_freq    bx
    speaker_on
    @@1:

    mov     bx, LEN_OF_ONE

    push    cx
    cmp     cx, STACCATO
    jne     @@loop
    shr     dx, 1

    @@loop:
        mov     cx, 0FFFFh ; - min discrete sound length
        loop    $
        dec     bx
        jg      @@loop
        shr     dx, 1
        test    dx, dx
        jnz     @@loop


    pop     cx
    cmp     cx, STACCATO
    je      @@staccato

    ret
    @@staccato:
    speaker_off

    mov     cx, 0FFFFh
    loop    $
    mov     cx, 0FFFFh
    loop    $
    ret


include     melody.asm


mptr     dw  offset MUSIC_START

take_note:
    cmp     mptr, offset MUSIC_STOP
    jae     @@stop

    mov     bx, mptr
    mov     cx, [bx+4]
    mov     dx, [bx+2]
    mov     bx, [bx]

    add     mptr, size Muse

    clc
    ret

    @@stop:
    stc
    ret


main proc far
    
    initialize_timer

    main_loop:


        note_play:

            call    take_note
            jc      break

            call    play
            jmp     continue

        stop_play:
            jnz     continue
            speaker_off

        continue:
        jmp main_loop
    break:

    speaker_off

    mov     ax, 4C00h
    int     21h

main endp

end start
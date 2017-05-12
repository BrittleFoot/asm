include     melody.asm


LEN_OF_ONE = 4
LEN_OF_HALF = LEN_OF_ONE / 2


play_note:
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
    mov     mptr, offset MUSIC_START
    stc
    ret


play_melody proc far
    pushf
    push    ax bx cx dx
    
    initialize_timer

    play_melody_loop:

        call    read_buffer
        cmp     al, 1
        je      break_play

        call    take_note
        jc      break_play

        call    play_note
        jmp     play_melody_loop

    break_play:

    speaker_off

    pop dx cx bx ax
    popf
    ret

play_melody endp
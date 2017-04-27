    .model  tiny
    .code
    org     100h
    locals  @@

start:
    jmp     main


include     soundlib.asm


main proc far


    mov         dx, 20000
    initialize_timer

    mov         bx, 1

    @@next_freq:
    
        set_freq    bx
        speaker_on

        mov     cx, 100
        loop    $

        inc     bx
        dec     dx
        jnz     @@next_freq

    speaker_off

    mov     ax, 4C00h
    int     21h
main endp

end start
    .model  tiny
    .code
    org     100h
    locals  @@
    

start:
    jmp main


include     music\playlib2.asm



main proc far

    mov     ax, offset welcome
    call    play_sound
    

    @@while_true:
        xor     ax, ax
        int     16h
        cmp     ah, 1
        je      @@break

        mov     ax, offset lalalalalala
        call    refresh_sound
        call    play_sound

        jmp     @@while_true
    @@break:


    call    stop_play
    mov     ax, 4C00h
    int     21h
main endp

end start 
code ends
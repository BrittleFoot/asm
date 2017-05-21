    .model  tiny
    .code
    org     100h
    locals  @@
    

start:
    jmp main


include     music\playlib2.asm


counter   dw  0h
main proc far


    @@while_true:
        xor     ax, ax
        int     16h
        cmp     ah, 1
        je      @@break

        inc     counter
        test    counter, 1
        jz      @@o
        mov     ax, offset welcome
        jmp lesgo
        @@o:

        mov     ax, offset lalalalalala

        lesgo:
        ; call    refresh_sound
        call    play_sound

        jmp     @@while_true
    @@break:


    call    stop_play
    mov     ax, 4C00h
    int     21h
main endp

end start 
code ends
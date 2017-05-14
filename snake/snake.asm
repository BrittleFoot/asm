    .model  small
    locals  @@

.stack

text    segment
        assume  cs:text, ds:text, es:text

start:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    jmp     main    



main proc far

    mov ax, 4C00h
    int 21h
main endp


include     music\playlib2.asm
; call play_sound  

text ends

include     graphics.asm

end start

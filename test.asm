    .model tiny
    .code
    org 100h
    locals @@

start:
    jmp main

include drawtlib.asm


main:
    mov ax, 0103h
    call draw_table

    mov ax, 4C00h
    int 21h


end start
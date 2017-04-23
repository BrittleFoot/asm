    .model      tiny
    .code
    org         100h
    locals      @@

start:
    jmp     main
    

include     util.asm



oldint  dd 00000000h



get_old_int21h_vector:
;   bx - destination:
;        [bx] - offset
;        [bx+2] - segment
    push    ax bx es di

    mov     di, bx
    mov     ax, 3509h
    mov     cs:[di], bx
    mov     cs:[di+2], es

    pop     di es bx ax
    ret






main:

    mov     bx, offset oldint
    call    get_old_int21h_vector

    
    mov     ax, 4C00h
    int     21h

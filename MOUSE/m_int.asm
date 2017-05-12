text segment

oldmouseroutine:
    omr_s   dw  0000h
    omr_o   dw  0000h
    omr_m   dw  0000h



set_mouse_handler:
    ; dx - offset to handler
    push    ax es dx cx ds
    xor     cx, cx
    mov     cl, 000000001b
    mov     ax, cs
    mov     es, ax
    mov     ax, 14h ; swap interrupt subroutines
    int     33h     

    mov     omr_o, dx
    mov     dx, es
    mov     omr_s, dx
    mov     omr_m, cx

    pop     ds cx dx es ax
    ret

restore_mouse_handler:
    push    ax es dx cx ds
    mov     cx, omr_m
    mov     dx, omr_o
    mov     es, omr_s
    mov     ax, 0Ch
    int     33h

    pop     ds cx dx es ax
    ret

text ends
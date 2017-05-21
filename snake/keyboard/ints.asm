

get_old_int_vector:
;   al - int number
;   bx - destination:
;        [bx] - offset
;        [bx+2] - segment
    push    ax bx es di

    mov     di, bx
    mov     ah, 35h
    int     21h

    mov     cs:[di], bx
    mov     cs:[di+2], es

    pop     di es bx ax
    ret


set_int_vector:
;   al - int number
;   dx - offset
;   ds - segment
    mov     ah, 25h
    int     21h

    ret



rnd_modulus     dw      8000h
rnd_a           dw      5741
rnd_previous    dw      1337



get_next_random proc c uses bx dx
;   returns next random number in ax
    
    mov     ax, word ptr rnd_previous

    xor     dx, dx
    mov     bx, rnd_a
    mul     bx
    
    xor     dx, dx
    mov     bx, rnd_modulus
    div     bx

    xchg    ax, dx
    mov     rnd_previous, ax

    ret
get_next_random endp



    .model  tiny
    .code
    org     100h

start:

    mov ax, 352Fh
    int 21h

    mov ah, 5Ah
    mov al, 80h
    int 2Fh


    lds dx, es:[bx]

    mov ax, 252Fh
    int 21h

    xor bx, bx
    add bx, 141h
    loopp:
        mov dl, es:[bx]

        mov ax, 0200h
        int 21h

        inc bx
        cmp bx, 145h
        jl loopp


    nop
    nop
    nop
    nop



    mov ax, 4C00h
    int 21h




end start
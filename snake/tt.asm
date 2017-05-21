    .model tiny
    .code 
    org     100h

start:
    mov ax, 640
    mov bx, 256

    cmp bx, 640

    jle @@equal

    mov ax, 0900h
    lea dx, n
    int 21h
    int 20h

    @@equal:

    mov ax, 0900h
    lea dx, e
    int 21h
    int 20h



n db "NO", 0dh, 0ah, 24h
e db "YE", 0dh, 0ah, 24h

end start
code ends
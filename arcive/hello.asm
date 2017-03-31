.model tiny
.code

org 100h


start:

    mov ah, 9h  
    mov dx, offset msg

    int 21h
    int 20h


msg db 'Hello, World!', 0dh, 0ah, '$'


code ends
end start

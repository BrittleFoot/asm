    .model tiny
    .code

    org 100h


Rect struc

    x    dw     ?
    y    dw     ?
    w    dw     ?
    h    dw     ?

Rect ends


Person struc

    n    db     "SomeNameSpace"
    age  dw     1111h

Person ends  



start:

    mov ax, offset john
    push ax
    mov ax, offset stew
    push ax

    mov bx, ax
    mov ax, [bx].age

    call agecheck

    int 20h


agecheck proc c near uses ax bx
arg @@first:word, @@second:word


    mov bx, @@first
    mov ax, [bx].age

    mov bx, @@second
    mov bx, [bx].age

    ret
agecheck endp
    

john Person {n="AAAA", age=1234h}
stew Person {n="BBBB", age=9CCCh}


personList  dw  offset john
            dw  offset john
            dw  offset john
            dw  offset john



end start
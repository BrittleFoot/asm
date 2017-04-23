    .model  tiny
    .code 
    org     100h
    locals  @@

start:
    jmp begin


buflen  equ     20
buffer  db      buflen dup (0)
endbuf:
head    dw      offset buffer
tail    dw      offset buffer


; scan code -> command -> handler


write_buf   proc near
    push    bx

    mov     bx, cs:head
    mov     byte ptr cs:[bx], al
    mov     ax, cs:head
    inc     word ptr cs:head  
    cmp     word ptr cs:head, offset endbuf
    jne     @@not_overflow
    mov     cs:head, offset buffer
@@not_overflow:

    mov     bx, cs:head
    cmp     bx, cs:tail
    jnz     @@not_filled
    mov     cs:head, ax
@@not_filled:
    pop     bx

    ret
write_buf   endp
    


read_buf    proc near
    push    bx
    mov     bx, cs:tail
    cmp     bx, cs:head
    jnz     @@1
    pop bx
    stc
    ret

@@1:
    mov     bx, cs:tail
    mov     al, byte ptr cs:[bx]
    inc     word ptr cs:tail
    cmp     word ptr cs:tail, offset endbuf
    jne     @@2
    mov     word ptr cs:tail, offset buffer
@@2:
    pop     bx
    clc
    ret



read_buf    endp


command_mapping:
    db  48h, 1
    db  4Dh, 2
    db  4Bh, 3
    db  50h, 4
    db  1,   5
dw  0FFFFh


handler_mapping:
    dw 1, offset f_up
    dw 2, offset f_right
    dw 3, offset f_left
    dw 4, offset f_down
    dw 5, offset f_exit
dw 0FFFFh



f_exit:
    mov     dx, word ptr [old9o]
    mov     bx, word ptr [old9s]
    mov     ds, bx

    mov     ax, 2509h
    int     21h   

    mov     ax, 0900h
    mov     dx, offset qwe  

    mov     ax, 4C00h
    int     21h

    ret


qwe db "333333333", 0dh, 0ah, '$'

f_down:
    ret

f_left:
    ret

f_right:
    ret

f_up:
    ret



old9o   dw  0
old9s   dw  0


begin   proc near

    mov     ax, 3509h
    int     21h

    mov     word ptr cs:[old9o], bx    
    mov     word ptr cs:[old9s], es  


    push    cs
    pop     es

    mov     dx, offset int9
    mov     ax, 2509h
    int     21h

@@1:
    hlt     ; wait until interruption
    call    read_buf
    jc      @@1
    mov     si, offset handler_mapping
    xor     ah, ah
    mov     bx, ax
@@2:
    lodsw
    cmp     ax, 0FFFFh
    jz      @@1
    cmp     ax, bx
    jz      @@3
    add     si, 2
    jmp     @@2

@@3:
    call    ax
    jmp     @@1

begin   endp



int9 proc near
    push    ax
    in      al, 60h     ; read from 60 port
    call    write_buf

    ;\\\\\\\\\\\\\\
    in      al, 61h     ; моргнули единичкой тип прочитали символ
    mov     ah, al
    or      al, 80h     ; и хотим новый скан-код
    out     61h, al
    mov     al, ah
    out     61h, al
    ;//////////////
    mov     al, 20h
    out     20h, al
    pop     ax
    iret


int9 endp



end start
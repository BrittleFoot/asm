
buflen  equ     20
buffer  db      buflen dup (0)
endbuf:
head    dw      offset buffer
tail    dw      offset buffer


write_buffer   proc near
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
write_buffer   endp
    

read_buffer    proc near
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
read_buffer     endp
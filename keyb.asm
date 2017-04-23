    .model      tiny
    .code
    org         100h
    locals      @@

start:
    jmp main
    

include util.asm



ascii_code      db  00h
scan_code       db  00h


main:

    mov     ax, 0900h
    mov     dx, offset head
    int     21h

    @@loop:

    xor     ax, ax
    mov     ax, 1000h 
    int     16h

    mov     scan_code, ah
    mov     ascii_code, al

    ; shift status?

    mov     al, ascii_code
    call    put_ascii
    call    put_endr

    mov     al, ascii_code
    call    byte_to_str
    call    print_ax
    call    put_endr

    mov     al, scan_code
    call    byte_to_str
    call    print_ax

    mov     dx, offset endl
    mov     ax, 0900h
    int     21h


    mov     al, ascii_code
    cmp     al, 03h

    jne     @@loop 
    int     20h


print_ax:
    push    dx

    mov     dx, ax
    mov     ax, 0200h
    int     21h
    xchg    dh, dl
    int     21h
    mov     dl, 'h'
    int     21h
    
    pop     dx
    ret


put_endr:    
    mov     ax, 0900h
    mov     dx, offset endr
    int     21h
    ret


curr_page db 00h


put_ascii:
    ; al - ascii code
    push    sp bp si di
    push    ax

    mov     ax, 0F00h
    int     10h
    mov     curr_page, bh

    pop     ax
    pop     di si bp sp


    push    sp bp si di
    mov     ah, 0Ah
    xor     bx, bx
    mov     bl, curr_page
    mov     cx, 0001h
    int     10h

    call    inc_cursor

    pop     di si bp sp
    ret


inc_cursor:
    push    ax bx sp bp si di
    mov     ax, 0300h
    xor     bx, bx
    mov     bl, curr_page
    int     10h

    mov     ah, 02h
    inc     dl
    int     10h

    pop     di si bp sp bx ax
    ret


head    db  "hit ctrl+c to exit", 0Dh, 0Ah
        db  "character  ascii code   scan code    ", 0Dh, 0Ah
        db  "-------------------------------------", 0Dh, 0Ah, 24h
endr    db  "          ", 24h
endl    db   0Dh,  0Ah,  24h

end start
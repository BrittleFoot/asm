    .model      tiny
    .code
    org         100h
    locals      @@

start:
    jmp     main
    

include     util.asm
include     ints.asm
;   get_old_int_vector, set_int_vector
include     cb.asm
;   write_buffer, read_buffer


oldint  dd 00000000h


myint9:
    push    ax
    in      al, 60h     ; read from 60 port
    call    write_buffer

    ;\\\\\\\\\\\\\\
    in      al, 61h     ; моргнули единичкой тип прочитали символ
    mov     ah, al
    or      al, 80h     ; и хотим новый скан-код
    out     61h, al
    mov     al, ah
    out     61h, al
    ;//////////////
    mov     al, 20h     ; eoi
    out     20h, al
    pop     ax
    iret



main:

    mov     al, 09h
    mov     bx, offset oldint
    call    get_old_int_vector

    push    ds

    mov     al, 09h
    mov     dx, offset myint9
    push    cs
    pop     ds
    call    set_int_vector



    @@loop:

        hlt
        call    read_buffer

        jc      @@loop

        call    byte_to_str
        stc
        call    print_hex_ax
        call    endl

        jmp @@loop

    

    mov     al, 09h
    mov     dx, word ptr [oldint]
    mov     ds, word ptr [oldint+2]
    call    set_int_vector

    pop     ds
    
    mov     ax, 4C00h
    int     21h

end start
; ints.asm cb.asm keys.asm functions required


keyboard_handler  dw  offset ks_normal
;   scancode in AL -- input for all states    

ks_normal:

    cmp     al, 0E0h
    jae     @@wtf_you_sik_go_gome_boy

    cmp     al, 80h
    jae     @@release

    @@press:

    call    press_key
    jmp     @@ok

    @@release:
    and     al, 01111111b
    call    release_key
    jmp     @@ok

    @@ok:
    clc
    ret

    @@wtf_you_sik_go_gome_boy:
    stc
    ret


myint9:
    push    ax

    in      al, 60h
    push    ax

    ; моргнули единичкой тип прочитали символ
    ; и хотим новый скан-код
    in      al, 61h
    mov     ah, al
    or      al, 80h     
    out     61h, al
    mov     al, ah
    out     61h, al

    ; eoi
    mov     al, 20h
    out     20h, al
    pop     ax

    pushf
    push    ax bx cx dx 
    call    keyboard_handler
    pop     dx cx bx ax
    jc      @@skip_write
    call    write_buffer

    @@skip_write:
    popf

    pop     ax
    iret


oldint  dd 00000000h
acquire_keyboard:
    push    ax bx dx ds

    mov     al, 09h
    mov     bx, offset oldint
    call    get_old_int_vector


    mov     al, 09h
    mov     dx, offset myint9
    push    cs
    pop     ds
    call    set_int_vector

    pop     ds dx bx ax
    ret

release_keyboard:
    push    ax dx ds

    mov     al, 09h
    mov     dx, word ptr [oldint]
    mov     ds, word ptr [oldint+2]
    call    set_int_vector

    pop     ds dx ax
    ret
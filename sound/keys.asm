

press_key:
;   al - scan code
    push    ax bx

    xor     ah, ah
    mov     bx,  offset keys
    add     bx, ax

    mov     al, byte ptr [bx]
    sub     total_pressed, al
    or      byte ptr [bx], 00000001b
    inc     total_pressed

    pop     bx ax
    ret

release_key:
;   al - scan code
    push    ax bx
    
    xor     ah, ah
    mov     bx, offset keys
    add     bx, ax

    mov     al, byte ptr [bx]
    sub     total_pressed, al
    and     byte ptr [bx], 00000000b

    pop     bx ax
    ret

is_pressed:
;   al - scan code
    push    bx
    mov     bx, offset keys
    add     bx, ax
    mov     bl, byte ptr [bx]
    test    bl, bl
    pop     bx
    ret


push_key:
;   al - scan code

    cmp     ks_ptr, KEY_STACK_LEN
    jae     @@overflow

    push    bx
    mov     bx, offset key_stack
    add     bx, ks_ptr
    cmp     byte ptr [bx], al 
    jz      @@ret

    inc     ks_ptr
    mov     bx, offset key_stack
    add     bx, ks_ptr

    mov     byte ptr [bx], al

    @@ret:

    pop     bx
    clc
    ret

    @@overflow:
    stc
    ret


peek_key:
    push    bx

    cmp     total_pressed, 0
    jz      @@empty

    @@try_peek:

        cmp     ks_ptr, offset key_stack
        jz      @@empty


        mov     bx, offset key_stack
        add     bx, ks_ptr
        mov     al, byte ptr [bx]   ; take key on top

        xor     ah, ah
        mov     bx, ax
        add     bx, offset keys
        cmp     byte ptr [bx], 0    ; if it is released 
        jnz     @@peek_success

        dec     ks_ptr              ; remove it from stack
        jmp     @@try_peek


    @@peek_success:
    ; then key code in al

    pop     bx
    clc
    ret
    @@empty:
    mov     ks_ptr, 0
    pop     bx
    stc
    ret


write_out_pressed:
; returns length in cx
    pushf
    push    ax bx dx di
    xor     cx, cx
    xor     bx, bx
    xor     di, di

    @@loop:
        inc     di
        cmp     di, ks_ptr

        ; push    ax dx
        ; mov     dx, di
        ; mov     ax, 0200h
        ; int 21h
        ; pop     dx ax

        jg      @@break


        mov     bl, key_stack[di] ; bl - keycode
        mov     al, keys[bx]      ; al - pressed flag


        test    al, al
        jz      @@loop

        mov     dl, bl
        mov     bx, cx
        mov     pressed[bx], dl
        inc     cx
        jmp     @@loop


    @@break:
    pop    di dx bx ax
    popf
    ret


total_pressed   db 00h
keys            db 0FFh dup (0)

KEY_STACK_LEN = 10h
ks_ptr          dw 0000h
key_stack       db KEY_STACK_LEN dup (0)  
                db 00

pressed         db KEY_STACK_LEN dup (0)
                db 0Dh, 0Ah, 24h


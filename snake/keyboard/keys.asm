

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
    lea     bx, keys
    xlat    keys
    test    al, al
    pop     bx
    ret


total_pressed   db 00h
keys            db 0FFh dup (0)


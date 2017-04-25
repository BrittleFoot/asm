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
include     status.asm
;   write_buffer, read_buffer


oldint  dd 00000000h


myint9:
    push    ax
    in      al, 60h     ; read from 60 port

    cmp     al, 0E0h
    jae     @@ping 
    push    ax

    call    update_pressed
    call    change_status

    ;работает только в настоящем досе.
    ;call    update_leds

    pop     ax
    call    write_buffer

    @@ping:
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


update_pressed:
    push    bx ax
    xor     bx, bx
    xor     ah, ah
    mov     bx, offset pressed_keys


    cmp     al, 80h
    jb      @@pressed
    jmp     @@released

    @@pressed:


    add     bx, ax
    mov     al, byte ptr [bx]
    sub     total_pressed, al
    or      byte ptr [bx], 00000001b
    add     total_pressed, 1

    jmp     @@ret    

    @@released:
    and     al, 01111111b
    add     bx, ax
    
    mov     al, byte ptr [bx]
    sub     total_pressed, al
    and     byte ptr [bx], 00000000b

    jmp     @@ret

    @@ret:
    pop     ax bx
    ret


press_release_key_check:
    
    cmp     al, ch
    je      @@key_pressed
    add     ch, 80h
    cmp     al, ch
    je      @@key_released
    ret
    
    @@key_released:
        mov     bl, cl
        not     bl
        and     shift_status, bl
        ret
    @@key_pressed:
        mov     bl, cl
        or      shift_status, bl
        ret


press_release_led_check:
    
    cmp     al, ch
    je      @@key_pressed
    add     ch, 80h
    cmp     al, ch
    je      @@key_released
    ret
    
    @@key_released:
        mov     bl, cl
        not     bl
        and     kbd_status, bl
        ret
    @@key_pressed:
        mov     bl, cl
        or      kbd_status, bl
        ret


switch_led_check:
    
    cmp     al, ch
    je      @@key_pressed
    ret

    
    @@key_pressed:
        mov     bl, cl
        xor     kbd_status, bl
        ret


change_status:
    push    bx cx

    mov     ch, SC_CTRL
    mov     cl, CTRL_PRESSED
    call    press_release_key_check

    mov     ch, SC_ALT
    mov     cl, ALT_PRESSED
    call    press_release_key_check

    mov     ch, SC_LSHIFT
    mov     cl, LEFT_SHIFT_PRESSED
    call    press_release_key_check

    mov     ch, SC_RSHIFT
    mov     cl, RIGHT_SHIFT_PRESSED
    call    press_release_key_check

    mov     ch, SC_NUM_LOCK
    mov     cl, NUM
    call    switch_led_check

    mov     ch, SC_CAPS_LOCK
    mov     cl, CAPS
    call    switch_led_check

    mov     ch, SC_SCRL_LOCK
    mov     cl, SCRL
    call    switch_led_check

    pop     cx bx
    ret

kbd_status              db 00000000b
shift_status            db 00000000b

LED_CHANGE_REQ  = 0EDh
    

update_leds:
     push    ax

     call    kbd_wait

     mov     al, LED_CHANGE_REQ
     out     60h, al

     call    kbd_wait

     mov     al, [kbd_status]
     out     60h, al

     call    kbd_wait

     pop     ax
     ret


kbd_wait:
        jmp @@0
@@0:    in       al, 64h
        test     al,1
        jz       @@ok
        jmp      @@1
@@1:    in       al, 60h
        jmp      kbd_wait
        @@ok:
        test     al,2
        jnz      kbd_wait
        ret


is_ctrl_pressed:
    push    ax
    mov     al, CTRL_PRESSED
    and     al, shift_status
    cmp     al, CTRL_PRESSED
    pop     ax
    ret



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

        cmp     al, SC_C
        jne     @@continue
        call    is_ctrl_pressed
        je      @@break

        @@continue:
        call    pretty_output

        call    byte_to_str
        stc
        call    print_hex_ax
        call    put_endl
        call    cond_line

        jmp @@loop
    @@break:
    

    mov     al, 09h
    mov     dx, word ptr [oldint]
    mov     ds, word ptr [oldint+2]
    call    set_int_vector

    pop     ds
    
    mov     ax, 4C00h
    int     21h


pretty_output:
    push    bx
    mov     bx, ax
    push    ax

    xor     ax, ax
    mov     al, total_pressed

    cmp     bl, 80h
    jb      @@m1
    jmp     @@1

    @@m1:   dec ax
    @@1:    

    call    put_n_spaces

    pop     ax
    pop     bx
    ret


cond_line:
    cmp     total_pressed, 0
    je      @@1
    ret
    @@1:
    push    ax dx
    mov     ax, 0900h
    mov     dx, offset sLine
    int     21h
    pop     dx ax
    ret

sLine   db  "--------", 0Ah, 0Dh, 24h

end start
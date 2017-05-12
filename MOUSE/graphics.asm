BUFFER_SIZE     = 64000
VMEM_SEGMENT    = 0A000h



segment buffer_segment

    double_buffer   db  BUFFER_SIZE dup(0)

buffer_segment ends


text segment



draw_scene      proc
    call    clear_screen
    call    draw_frame
    call    draw_circle
    call    push_buffer


    ret
draw_scene      endp



clear_screen    proc
    push    es

    mov     ax, buffer_segment
    mov     es, ax
    lea     di, [double_buffer]
    xor     di, di
    xor     ax, ax
    mov     cx, BUFFER_SIZE / 2
    rep     stosw

    pop     es
    ret
clear_screen    endp


push_buffer     proc
    push    es
    push    ds
    mov     ax, VMEM_SEGMENT
    mov     es, ax

    mov     ax, buffer_segment
    mov     ds, ax

    mov     si, offset double_buffer
    xor     di, di
    mov     cx, BUFFER_SIZE / 2
    rep     movsw

    pop     ds
    pop     es
    ret
push_buffer     endp


draw_circle proc c uses ax bx cx
;   brez
    xor     ax, ax
    mov     bx, circle_r
    mov     dx, 1
    mov     cx, circle_r
    add     cx, circle_r
    sub     dx, cx
    xor     cx, cx
    ; x = ax, y = bx, error = cx, delta = dx

    @@while_y_ge_0:
        cmp     bx, 0
        jl      @@break
        call    set_circle_pixels
        mov     cx, dx
        add     cx, bx
        add     cx, cx
        dec     cx      ; error = 2 * (delta + y) - 1

        cmp     dx, 0
        jge     @@nxt
        cmp     cx, 0
        jg      @@nxt   ; if (delta<0) && (error<=0)

            inc     ax              ; delta += 2 * ++x + 1
            add     dx, ax
            add     dx, ax
            inc     dx
            jmp     @@while_y_ge_0  ; continue

        @@nxt:

        mov     cx, dx
        sub     cx, ax
        add     cx, cx
        dec     cx          ; error = 2 * (delta - x) - 1


        cmp     dx, 0
        jle     @@nxt2
        cmp     cx, 0
        jle     @@nxt2  ; if (delta> 0) && (error > 0)

            dec     bx
            inc     dx
            sub     dx, bx 
            sub     dx, bx          ; delta += 1 - 2 * --y
            jmp     @@while_y_ge_0  ; continue

        @@nxt2:

        inc     ax
        add     dx, ax
        add     dx, ax  ;       x++
        sub     dx, bx  ;       delta += 2 * (x - y)
        sub     dx, bx  ;       y--
        dec     bx
        jmp     @@while_y_ge_0


    @@break:


    ret
draw_circle endp


set_circle_pixels proc c uses ax bx cx si di
    mov     si, ax
    mov     di, bx

    mov     cl, circle_color

    mov     ax, circle_x
    mov     bx, circle_y
    add     ax, si
    add     bx, di
    call    set_pixel
    sub     bx, di
    sub     bx, di
    call    set_pixel
    sub     ax, si
    sub     ax, si
    call    set_pixel
    add     bx, di
    add     bx, di
    call    set_pixel

    ret
set_circle_pixels endp



draw_frame  proc c uses ax bx cx dx
    mov     cl, frame_color

    mov     ax, frame_left
    @@top_bot:
        mov     bx, frame_top
        call    set_pixel
        mov     bx, frame_bot
        call    set_pixel
        inc     ax
        cmp     ax, frame_right
        jbe     @@top_bot

    mov     bx, frame_top
    @@left_right:
        mov     ax, frame_left
        call    set_pixel
        mov     ax, frame_right
        call    set_pixel
        inc     bx
        cmp     bx, frame_bot
        jbe     @@left_right

    ret
draw_frame endp






set_pixel       proc c uses ax bx dx es
    ; args:
    ;       ax - column
    ;       bx - row
    ;       cl - color

    xchg    ax, bx
    mov     dx, SCREEN_WIDTH
    mul     dx
    add     bx, ax
    add     bx, offset double_buffer

    mov     ax, buffer_segment
    mov     es, ax
    mov     byte ptr es:[bx], cl

    ret
set_pixel       endp



text ends
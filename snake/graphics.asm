BUFFER_SIZE     = 64000
VMEM_SEGMENT    = 0A000h

SCREEN_WIDTH    = 320
SCREEN_HEIGHT   = 200


segment buffer_segment

    double_buffer   db  BUFFER_SIZE dup(0)

buffer_segment ends


text segment



counter     dw  0000h
draw_scene      proc c uses ax bx dx di

    lea     di, scene
    mov     counter, 0


    @@loop:
        mov     bx, counter
        call    scene2screen

        push    ax bx
        mov     ax, word ptr [di].obj_type


        lea     bx, [draw_functions]
        add     bx, ax
        add     bx, ax
        mov     dx, word ptr [bx]

        pop     bx ax
        call    dx


        add     di, size Object

        inc     counter

        cmp     counter, SCENE_WIDTH * SCENE_HEIGHT
        jnz     @@loop

    ret
draw_scene      endp


scene2screen    proc c uses dx
;   args:
;       bx - scene offset
;   returns
;       ax - screen x
;       bx - screen y

    mov ax, bx
    xor bx, bx
    xor dx, dx

    mov bx, SCENE_WIDTH
    div bx

    mov     bx, ax
    mov     ax, dx

    mov     dx, ax
    shl     ax, 2
    add     ax, dx

    mov     dx, bx
    shl     bx, 2   
    add     bx, dx

    ret
scene2screen    endp




draw_functions:
;   for all functions assume that DI points on current object
;   and    (ax, bx) - screen coords
    dw  offset tail_none
    dw  offset tail_snake_head
    dw  offset tail_snake_body
    dw  offset tail_snack
    dw  offset tail_wall


tail_none: 
    ret

drugcolor   db 1

tail_snake_head:
    mov     dl, 2Ch
    test    snake_status, 1
    jz      snakedrower
    mov     dl, drugcolor
    inc     drugcolor
    and     drugcolor, 00001111b
    jmp     snakedrower

tail_snake_body:
    mov     dl, 4Ch

    test    [di].obj_dir, 1
    jnz     colorize

    test    snake_status, 1
    jnz     colorize
    jmp     snakedrower

    colorize:
    inc     drugcolor
    and     drugcolor, 00001111b
    mov     dl, drugcolor
    mov     cl, drugcolor

    jmp     snakedrower

tail_snack:

    mov     dl, 1
    mov     cl, 1
    cmp     [di].obj_extra, 0C0CAh
    jne      @@drawseed
    inc     drugcolor
    and     drugcolor, 00001111b
    mov     dl, drugcolor
    mov     cl, drugcolor

    @@drawseed:
    call draw_seed
    ret

snakedrower:
    push    si di
    mov     si, 4
    mov     di, 4
    call    draw_frame
    pop     di si
    cmp     [di].obj_extra, 11FEh
    jne     @@ret
    call    draw_seed
    @@ret:
    ret

draw_seed:
    add  bx, 1
    add  ax, 1
    call set_pixel
    add  ax, 1
    call set_pixel
    add  ax, 1
    call set_pixel
    sub  ax, 3
    add  bx, 1
    add  ax, 1
    call set_pixel
    add  ax, 1
    call set_pixel
    add  ax, 1
    call set_pixel
    sub  ax, 3
    add  bx, 1
    add  ax, 1
    call set_pixel
    add  ax, 1
    call set_pixel
    add  ax, 1
    call set_pixel
    sub  ax, 3
    
    ret

tail_wall:
    cmp     [di].obj_extra, 1
    je      @@wall2

    push    si di
    mov     si, 4
    mov     di, 4
    mov     dl, 0
    call    draw_frame
    pop     di si
    ret    

    @@wall2:

    push    si di
    mov     si, 4
    mov     di, 4
    mov     dl, 0
    call    draw_frame
    add     ax, 1
    add     bx, 1
    mov     si, 2
    mov     di, 2
    call    draw_frame
    add     ax, 1
    add     bx, 1
    call    set_pixel
    pop     di si
    ret    


clear_screen    proc c uses ax bx cx si di
;   al -- color
    push    es
    push    ax

    mov     ax, buffer_segment
    mov     es, ax
    lea     di, [double_buffer]
    xor     di, di
    pop     ax
    mov     ah, al
    mov     cx, BUFFER_SIZE / 2
    rep     stosw

    pop     es
    ret
clear_screen    endp


push_buffer     proc c uses ax bx cx di si 
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


circle_x        dw  0000h 
circle_y        dw  0000h
circle_r        dw  0000h
circle_color    dw  0000h

draw_circle proc c uses ax bx cx dx
;   brezenheim algorithm
;   args - (ax, bx) - center coordinates
;               cx  - radius
;               dl  - color

    mov     circle_x, ax
    mov     circle_y, bx
    mov     circle_r, cx
    mov     circle_color, dx

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

    mov     cx, circle_color

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


frame_left  dw 0000h
frame_right dw 0000h
frame_top   dw 0000h
frame_bot   dw 0000h
frame_color dw 0000h

draw_frame  proc c uses ax bx cx dx di si
;   args    ax, di, bx, si, dl == left, width, top, height, color

    mov frame_left, ax    
    mov frame_right, ax
    add frame_right, si
    mov frame_top, bx
    mov frame_bot, bx
    add frame_bot, di
    mov frame_color, dx


    mov     cx, frame_color

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



set_pixel       proc c uses ax bx dx
    ; args:
    ;       ax - column
    ;       bx - row
    ;       cl - color
    cmp     ax, SCREEN_WIDTH
    jae     @@ret
    cmp     bx, SCREEN_HEIGHT  
    jae     @@ret

    xchg    ax, bx
    mov     dx, SCREEN_WIDTH
    mul     dx
    add     bx, ax
    add     bx, offset double_buffer

    mov     ax, buffer_segment
    mov     es, ax
    mov     byte ptr es:[bx], cl

    @@ret:
    ret
set_pixel       endp

get_pixel_addr  proc
        ; args:
        ;       ax - column
        ;       bx - row
        ; ret:
        ;       bx - address of pixel in double buffer

        push    dx
        xchg    ax, bx
        mov     dx, 320
        mul     dx
        add     bx, ax
        add     bx, offset double_buffer

        pop     dx
        ret
get_pixel_addr  endp


bgrnd   db  2
draw_char       proc c near uses ax bx cx si di ds es
        ; args:
        ;       AX = column
        ;       BX = row
        ;       CH = character to write
        ; ret:
        ;       none
        call    get_pixel_addr
        mov     di, bx

        mov     ax, 0f000h
        mov     ds, ax

        mov     ax, buffer_segment
        mov     es, ax

        mov     cl, ch
        xor     ch, ch
        mov     ax, cx
        mov     cl, 3
        shl     ax, cl

        mov     si, 0fa6eh
        add     si, ax

        mov     cx, 8
@@2:
        lodsb
        mov     ah, 80h
@@1:
        test    al, ah
        jz      @@bg

        mov     bl, 13h
        jmp     @@continue

@@bg:
        mov     bl, 2

@@continue:
        mov     es:[di], bl

        inc     di
        shr     ah, 1

        test    ah, ah
        jnz     @@1

        add     di, 320 - 8
        dec     cx
        jnz     @@2

        ret
draw_char       endp


draw_string proc c uses di

    mov     di, dx

    @@loop:
        mov     ch, byte ptr [di]
        cmp     ch, 0
        je      @@ret
        call    draw_char
        add     ax, 8
        inc     di
        jmp     @@loop
    

    @@ret:
    ret
draw_string endp


text ends
text segment


circle_color    db  0Fh
frame_color     db  0Eh

frame_left      dw  50
frame_top       dw  50
frame_right     dw  200
frame_bot       dw  100

circle_x   dw  100
circle_y   dw  50
circle_r   dw  15


change_colors proc c uses ax dx cx
    add     circle_color, al
    add     frame_color, bl

    ret
change_colors endp


delta_x     dw  0000h
delta_y     dw  0000h

move_frame proc
    mov     delta_x, ax
    mov     delta_y, bx

    call    fit_deltas

    mov     ax, delta_x
    add     frame_left, ax 
    add     frame_right, ax 
    add     circle_x, ax

    mov     ax, delta_y
    add     frame_top, ax 
    add     frame_bot, ax 
    add     circle_y, ax
    
    ret
move_frame endp


fit_deltas proc c uses ax bx cx dx di


    mov     ax, frame_left
    mov     bx, circle_x
    sub     bx, circle_r
    call    min
    push    ax

    mov     ax, frame_top
    mov     bx, circle_y
    sub     bx, circle_r
    call    min
    push    ax

    pop     bx
    pop     ax
    call    fit_point_00

    mov     ax, frame_right
    mov     bx, circle_x
    add     bx, circle_r
    call    max
    push    ax

    mov     ax, frame_bot
    mov     bx, circle_y
    add     bx, circle_r
    call    max
    push    ax

    pop     bx
    pop     ax
    call    fit_point_wh

    ret
fit_deltas endp



px  dw 0000h
py  dw 0000h
fit_point_00 proc c uses ax bx cx dx di
    mov     px, ax
    mov     py, bx

    mov     ax, px
    mov     bx, 1
    mov     cx, delta_x
    mov     di, offset max
    call    fit
    mov     delta_x, ax 

    mov     ax, py
    mov     bx, 1
    mov     cx, delta_y
    mov     di, offset max
    call    fit
    mov     delta_y, ax 
    ret
fit_point_00 endp


fit_point_wh proc c uses ax bx cx dx di
    mov     px, ax
    mov     py, bx

    mov     ax, px
    mov     bx, SCREEN_WIDTH - 2
    mov     cx, delta_x
    mov     di, offset min
    call    fit
    mov     delta_x, ax 

    mov     ax, py
    mov     bx, SCREEN_HEIGHT - 2
    mov     cx, delta_y
    mov     di, offset min
    call    fit
    mov     delta_y, ax 
    ret
fit_point_wh endp



fit proc c uses bx cx dx di
    ; ax - x
    ; bx - bound
    ; cx - delta x
    mov     dx, ax
    add     ax, cx
    call    di
    sub     ax, dx
    ret    
fit endp


move_ball proc c uses ax bx cx dx
    mov     delta_x, ax
    mov     delta_y, bx

    mov     ax, circle_x
    mov     bx, circle_y
    sub     ax, circle_r
    sub     bx, circle_r
    call    fit_point_00
    mov     ax, circle_x
    mov     bx, circle_y
    add     ax, circle_r
    add     bx, circle_r
    call    fit_point_wh

    @@try_move_x:

    mov     dx, circle_y
    cmp     dx, frame_top
    je      @@move_X
    cmp     dx, frame_bot
    je      @@move_X
    jmp     @@try_move_y


    @@move_X:
    mov     bx, delta_x
    mov     ax, frame_left
    add     bx, circle_x
    mov     cx, frame_right
    call    middle 
    mov     circle_x, ax

    @@try_move_y:
    mov     dx, circle_x
    cmp     dx, frame_left
    je      @@move_y
    cmp     dx, frame_right
    je      @@move_y
    ret

    @@move_y:
    mov     bx, delta_y
    mov     ax, frame_top
    add     bx, circle_y
    mov     cx, frame_bot
    call    middle 
    mov     circle_y, ax


    ret
move_ball endp



fit_by_width proc c uses bx cx
    ; args:
    ;       ax - number
    ; ret:
    ;       in ax - middle(0, ax, SCREEN_WIDTH)
    mov     bx, ax
    xor     ax, ax
    mov     cx, SCREEN_WIDTH
    call    middle
    ret
fit_by_width endp

fit_by_height proc c uses bx cx
    ; args:
    ;       ax - number
    ; ret:
    ;       in ax - middle(0, ax, SCREEN_HEIGHT)
    mov     bx, ax
    xor     ax, ax
    mov     cx, SCREEN_HEIGHT
    call    middle
    ret
fit_by_height endp


middle         proc
    ; args:
    ;       ax, bx, cx - numbers
    ; ret:
    ;       bx, if ax <= bx <= cx
    ;       ax, if bx < ax
    ;       cx, if cx < bx
    call    max
    mov     bx, cx
    call    min
    ret
middle         endp


min         proc
    ; args:
    ;       ax - first number
    ;       bx - second number
    ; ret:
    ;       ax - minimum of two numbers
    cmp     ax, bx
    jl      @@finish
    xchg    ax, bx
@@finish:
        ret
min         endp


max         proc
    ; args:
    ;       ax - first number
    ;       bx - second number
    ; ret:
    ;       ax - maximum of two numbers
    cmp     ax, bx
    jg      @@finish
    xchg    ax, bx
@@finish:
        ret
max         endp


text ends
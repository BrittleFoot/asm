
include  scene.asm

swapregs macro
    xchg ax, cx
    xchg bx, dx
endm swapregs

ldsnake macro
    mov     ax, snake_pos_x
    mov     bx, snake_pos_y
endm ldsnake

ldcoords macro pointer, reg1, reg2
    mov reg1, word ptr [&pointer&]
    mov reg2, word ptr [&pointer&+2]
endm ldcoords
stcoords macro reg1, reg2, pointer
    mov word ptr [&pointer&], reg1
    mov word ptr [&pointer&+2], reg2
endm stcoords



DIRECTION_UP    = 11h
DIRECTION_LEFT  = 1Eh
DIRECTION_DOWN  = 1Fh
DIRECTION_RIGHT = 20h
DIRECTION_STOP  = 39h


direction_map:
    dw  DIRECTION_UP,     -1, 0
    dw  DIRECTION_DOWN,   1,  0
    dw  DIRECTION_LEFT,   0,  -1
    dw  DIRECTION_RIGHT,  0,  1
    dw  DIRECTION_STOP,   0,  0
direction_map_ends:




init_snake proc c

    mov     ax, snake_pos_x
    mov     bx, snake_pos_x

    call    get_offset
    lea     bx, snake_head_obj
    call    put_on_scene

    mov     ax, snake_tail1x
    mov     bx, snake_tail1y

    call    get_offset
    lea     bx, snake_tail_obj
    call    put_on_scene

    mov     ax, 30
    mov     bx, 30

    call    get_offset
    lea     bx, snack
    call    put_on_scene

    ret
init_snake endp



init_game proc c

    call init_snake

    ret
init_game endp


choose_direction proc c uses ds si
    mov     ax, cs
    mov     ds, ax
    lea     si, direction_map

    @@loop:
        lodsw
        cmp ax, snake_direction
        je  @@ok

        add si, 4
        cmp si, offset direction_map_ends
        jb  @@loop

        xor ax, ax
        xor bx, bx
        jmp @@ret

    @@ok:
    lodsw
    mov bx, ax
    lodsw

    @@ret:
    ret
choose_direction endp


swap_objects proc c
;   swaps object with coordinates A=(ax, bx) and B=(cx, dx)
    call    copy_cell       ; tmp = A
    push    cx dx

    call    get_offset      ; get addr A
    push    ax               

    mov     ax, cx
    mov     bx, dx
    call    get_offset      ; get addr B
    mov     bx, ax
    add     bx, offset scene
    pop     ax
    call    put_on_scene

    pop     bx ax
    call    paste_cell

    ret
swap_objects endp


move_cell proc c
;   _moves_ object (ax, bx) to (ax+cx, ax+dx)
    call copy_cell
    add  ax, cx
    add  bx, dx
    call paste_cell
    ret
move_cell endp


coords1 dd 0
coords2 dd 0

step_on proc c uses di ax bx cx dx
;   arbitrate (ax, bx) which wants to step onto (cx, dx)
    stcoords ax, bx, coords1
    stcoords cx, dx, coords2

    ldcoords coords1, ax, bx
    call    cut_cell  
    call    left_the_cell
    ldcoords coords2, ax, bx
    call    step_on_the_cell
    call    paste_cell
    
    ret
step_on endp


left_the_cell proc c uses ax bx di
;   handle moment when something that in the buffer (temp_obj)
;   leaves the cell (ax, bx)
;   PLEASE, DO NOT REWRITE THE BUFFER

    cmp     temp_obj.obj_extra, 11FEh
    jne     @@ret

    lea     di, temp_obj3 
    call    store_cell
    mov     dx, temp_obj3.obj_extra
    mov     temp_obj3.obj_extra, 11FEh
    mov     temp_obj.obj_extra, dx

    call    get_offset
    lea     bx, temp_obj3 
    call    put_on_scene

    @@ret:
    ret
left_the_cell endp


step_on_the_cell proc c uses ax bx di
;   handle moment when something that in the buffer (temp_obj)
;   steps on the cell at (ax, bx)
;   PLEASE, DO NOT REWRITE THE BUFFER

    lea     di, temp_obj3 
    call    store_cell
    cmp     temp_obj3.obj_extra, 11FEh

    jne     @@ret

    mov     temp_obj.obj_extra, 11FEh

    @@ret:
    ret
step_on_the_cell endp



posNext:
posNextx dw 0
posNexty dw 0
posLast:
posLastx dw 0
posLasty dw 0

move_snake proc c uses si ds di es

    cmp     snake_direction, DIRECTION_STOP
    jne     @@lets_move
    ret    
    @@lets_move:
    call    choose_direction


    add     ax, snake_pos_x
    add     bx, snake_pos_y

    stcoords ax, bx, posNext

    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    lea     si, snake_pos
    lea     di, snake_pos
    ; initialization complete: 
    ; `lodsw` and `stosw` syncronicaly iterates over the snake

    @@loop:

        ; get current snake-part position
        lodsw   
        mov     bx, ax
        lodsw
        xchg    ax, bx
        ; (ax, bx) points on dat^

        cmp     ax, -1
        je      @@snake_moved

        stcoords    ax, bx, posLast

        ldcoords    posNext, cx, dx
        ; (cx, dx) demanded position
        call step_on
        ;   interaction result?

        ; write down new position
        mov     ax, cx
        stosw
        mov     ax, dx
        stosw

        ldcoords posLast, ax, dx
        stcoords ax, dx, posNext

        jmp     @@loop
    
    @@snake_moved:
    ldcoords    posNext, ax, bx
    call        copy_cell   
    cmp         temp_obj.obj_extra, 11FEh
    jne         @@ret

    ; spawn new body part
    call    get_offset
    lea     bx, snake_tail_obj
    call    put_on_scene

    ldcoords    posNext, ax, bx
    stosw
    mov     ax, bx
    stosw

    @@ret:
    ret
move_snake endp


update_world proc c 

    call    move_snake

    ret
update_world endp


snack                Object <3, 1, 11FEh>
snake_head_obj       Object <1, 1, 0>
snake_tail_obj       Object <2, 1, 0>
snake_direction     dw  DIRECTION_STOP
snake_pos:
    snake_pos_x         dw 0010h
    snake_pos_y         dw 0010h
    snake_tail1x        dw 0011h
    snake_tail1y        dw 0010h
snake_body_pos:
    db  SCENE_WIDTH * SCENE_HEIGHT * 4 dup(-1)
snake_body_ends:
db  "Hello, World!", 0Dh, 0Ah, 24h

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


include     mapld.asm


scene_place_offset  dw 0
levelname db "level1.map", 0 
init_game proc c uses dx ds si es di
    
    mov  scene_place_offset, 0
    mov  ax, cs
    mov  ds, ax
    lea  dx, levelname 
    lea  bx, file_buffer
    call read_level
    ; file_buffer contains level

    lea  si, file_buffer

    @@fill_level_loop:
        lodsb
        cmp     al, 0
        je      @@break
        cmp     scene_place_offset, SCENE_WIDTH * SCENE_HEIGHT * size Object
        jae     @@break

        cmp     al, 48
        je      @@scene_element_none
        cmp     al, 49
        je      @@scene_element_wall
        cmp     al, 's'
        je      @@scene_element_snake
        cmp     al, 'e'
        je      @@scene_element_snack
        jmp     @@fill_level_loop

        @@scene_element_none:
        lea     bx, null_obj
        jmp     @@place_element
        @@scene_element_wall:
        lea     bx, wall_obj
        jmp     @@place_element
        @@scene_element_snake:
        lea     bx, snake_head_obj
        jmp     @@place_element
        @@scene_element_snack:
        lea     bx, snack_obj
        jmp     @@place_element

        @@place_element:
        mov     ax, scene_place_offset
        call    put_on_scene

        @@next_element:

        add     scene_place_offset, size Object
        jmp     @@fill_level_loop

    @@break:

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

    lea     bx, step_on_handlers
    add     bx, temp_obj3.obj_type
    add     bx, temp_obj3.obj_type
    mov     dx, word ptr [bx]

    call    dx

    @@ret:
    ret
step_on_the_cell endp


step_on_handlers:
    dw  offset step_on_empty
    dw  offset step_on_head
    dw  offset step_on_tail
    dw  offset step_on_snack
    dw  offset step_on_wall

step_on_empty: 
    cmp     temp_obj3.obj_extra, 11FEh
    jne     @@ret
    mov     temp_obj.obj_extra, 11FEh

    @@ret:
    ret

step_on_head: ret

step_on_tail: 

    ret

step_on_snack: 
    mov     temp_obj.obj_extra, 11FEh
    mov     ax, EVENT_SNACK_EATED
    call    fire_event
    ret
step_on_wall: 
    mov     ax, EVENT_DEATH
    call    fire_event
    ret




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

        ldcoords posLast, ax, bx
        stcoords ax, bx, posNext

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

    ; register as snake part
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





;==========event handlers==========


snack_eated proc c uses di
    lea     ax, lalalalalala
    call    play_sound
    ret
snack_eated endp


tail_eated proc c uses di

    ret
tail_eated endp


wall_eated proc c uses di

    ret
wall_eated endp


;================================



wall_obj             Object <4, 1, 0>
snack_obj            Object <3, 1, 11FEh>
snake_tail_obj       Object <2, 1, 0>
snake_head_obj       Object <1, 1, 0>
snake_direction     dw  DIRECTION_STOP
snake_pos:
    snake_pos_x         dw 0002h
    snake_pos_y         dw 0002h
snake_body_pos:
    db  SCENE_WIDTH * SCENE_HEIGHT * 4 dup(-1)
snake_body_ends:
db  "Hello, World!", 0Dh, 0Ah, 24h


file_buffer db SCENE_WIDTH * SCENE_HEIGHT * 2 dup(0)
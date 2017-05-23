
include  scene.asm
include  random.asm

swapregs macro
    xchg ax, cx
    xchg bx, dx
endm swapregs

ldsnake macro
    mov     ax, snake_pos_x
    mov     bx, snake_pos_y
endm ldsnake

ldcoords macro pointer, reg1, reg2
    mov     reg1, word ptr [&pointer&]
    mov     reg2, word ptr [&pointer&+2]
endm ldcoords
stcoords macro reg1, reg2, pointer
    mov     word ptr [&pointer&], reg1
    mov     word ptr [&pointer&+2], reg2
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
levelname           db "level1.map", 0 
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

        cmp     al, '.'
        je      @@scene_element_none
        cmp     al, '1'
        je      @@scene_element_wall
        cmp     al, '2'
        je      @@scene_element_wall2
        cmp     al, 's'
        je      @@scene_element_snake
        cmp     al, 'e'
        je      @@scene_element_snack
        cmp     al, 'd'
        je      @@scene_element_drug
        cmp     al, 'y'
        je      @@scene_element_drug_tail
        cmp     al, 'l'
        je      @@scene_element_tail
        jmp     @@fill_level_loop

        @@scene_element_none:
        lea     bx, null_obj
        jmp     @@place_element
        @@scene_element_wall:
        lea     bx, wall_obj
        jmp     @@place_element
        @@scene_element_wall2:
        lea     bx, wall2_obj
        jmp     @@place_element
        @@scene_element_snake:
        lea     bx, snake_head_obj
        jmp     @@place_element
        @@scene_element_snack:
        lea     bx, snack_obj
        jmp     @@place_element
        @@scene_element_drug:
        lea     bx, drug_obj
        jmp     @@place_element
        @@scene_element_drug_tail:
        lea     bx, snake_tail_dark_obj
        jmp     @@place_element
        @@scene_element_tail:
        lea     bx, snake_tail_obj
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
    mov     bx, ax
    lodsw

    @@ret:
    ret
choose_direction endp



coords1 dd 0
coords2 dd 0

step_on proc c uses di ax bx cx dx si
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
    jne     @@not_11fe

    lea     di, temp_obj3 
    call    store_cell
    mov     dx, temp_obj3.obj_extra
    mov     temp_obj3.obj_extra, 11FEh
    mov     temp_obj.obj_extra, dx

    call    get_offset
    lea     bx, temp_obj3 
    call    put_on_scene

    @@not_11fe:

    cmp     temp_obj.obj_extra, 0C0CAh
    jne     @@not_coca

    lea     di, temp_obj3 
    call    store_cell
    mov     dx, temp_obj3.obj_extra
    mov     temp_obj3.obj_extra, 0C0CAh
    mov     temp_obj.obj_extra, dx

    call    get_offset
    lea     bx, temp_obj3 
    call    put_on_scene

    @@not_coca:

    ret
left_the_cell endp


target_pos:
    target_pos_x dw 0
    target_pos_y dw 0

step_on_the_cell proc c uses ax bx di
;   handle moment when something that in the buffer (temp_obj)
;   steps on the cell at (ax, bx)
;   PLEASE, DO NOT REWRITE THE BUFFER
    stcoords    ax, bx, target_pos

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
    jne     @@1
    mov     temp_obj.obj_extra, 11FEh

    @@1:

    cmp     temp_obj3.obj_extra, 0C0CAh
    jne     @@ret
    mov     temp_obj.obj_extra, 0C0CAh


    @@ret:
    ret

step_on_head: ret

step_on_tail: 

    ; mov     ax, EVENT_TAIL_EATED


    ; ldcoords    target_pos, cx, dx
    ; call    fire_event

    cmp     temp_obj3.obj_dir, 1
    je      @@wowshit
    mov     ax, EVENT_DEATH 
    call    fire_event
    jmp     @@ret

    @@wowshit:

    ldcoords target_pos, ax, bx
    lea     di, temp_obj3
    ; ax bx di
    call    eat_snakeself

    @@ret:
    ret

step_on_snack: 

    cmp     temp_obj3.obj_extra, 11FEh
    jne     @@not_11fe
    mov     temp_obj.obj_extra, 11FEh
    and     snake_status, 0FFFEh 
    mov     ax, EVENT_DRUG_CURED
    call    fire_event
    mov     ax, EVENT_SNACK_EATED
    call    fire_event

    @@not_11fe:
    cmp     temp_obj3.obj_extra, 0C0CAh
    jne     @@not_coca
    mov     temp_obj.obj_extra, 0C0CAh
    mov     ax, EVENT_DRUG_EATED
    call    fire_event

    @@not_coca:

    ret
step_on_wall: 
    mov     ax, EVENT_WALL_EATED
    call    fire_event
    ret


posNext:
    posNextx dw 0
    posNexty dw 0
posLast:
    posLastx dw 0
    posLasty dw 0

last_move dw 0, 0
check_back_move proc c

    neg     ax
    cmp     word ptr last_move, ax
    je      @@1
    neg     ax

    @@1:

    neg     bx
    cmp     word ptr [last_move+2], bx

    je      @@ret
    neg     bx

    @@ret:
    ret
check_back_move endp


tell_that_to_snake proc c
    test    snake_status, 1
    jz      @@ret    

    neg     ax
    neg     bx

    @@ret:
    ret
tell_that_to_snake endp


move_snake proc c uses si ds di es

    cmp     snake_direction, DIRECTION_STOP
    jne     @@lets_move
    ret    
    @@lets_move:

    call    choose_direction
    call    tell_that_to_snake
    call    check_back_move
    stcoords ax, bx, last_move

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
    cmp         temp_obj.obj_extra, 0
    je          @@ret

    ; spawn new body part
    call    get_offset

    cmp     temp_obj.obj_extra, 0C0CAh
    je      @@spawn_dj_child

    lea     bx, snake_tail_obj
    call    put_on_scene
    jmp     @@reg

    @@spawn_dj_child:

    lea     bx, snake_tail_dark_obj
    call    put_on_scene
    jmp     @@reg

    @@reg:
    ; register as snake part
    ldcoords    posNext, ax, bx
    stosw
    mov     ax, bx
    stosw

    @@ret:
    ret
move_snake endp


interaction_point   dw 0, 0

eat_snakeself proc c uses ds es si di
;   (ax bx) -- interaction point
;   di and temp_obj1 points on object (head? (nomater))
    stcoords    ax, bx, interaction_point
    
    add     ax, snake_pos_x
    add     bx, snake_pos_y

    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    lea     si, [snake_pos+4]
    ; `lodsw` iterates over the snake

    @@loop:
        lodsw
        mov     bx, ax
        lodsw
        xchg    ax, bx

        cmp     ax, -1
        je      @@endsnake

        ldcoords    interaction_point, cx, dx

        cmp     ax, cx
        jne     @@loop
        cmp     bx, dx
        jne     @@loop

    ; lodsw
    ; mov     bx, ax
    ; lodsw
    ; xchg    ax, bx

    ; here is the loop
    mov     di, si
    sub     di, 4
    mov     ax, -1
    stosw
    stosw



    @@turn_into_seeds_loop:
        lodsw
        mov     bx, ax
        lodsw
        xchg    ax, bx
        cmp     ax, -1
        je      @@endsnake

        call    get_offset
        lea     bx, snack_obj
        call    put_on_scene

        mov     ax, -1
        stosw
        stosw
        jmp     @@turn_into_seeds_loop


    jmp     @@ret
    @@endsnake:
    ; wtf? is this real?

    @@ret:
    ret
eat_snakeself endp


update_world proc c 

    call    move_snake

    ret
update_world endp


spawn_new_snack proc c
@@again:
    call    get_next_random
    xor     dx, dx
    mov     bx, SCENE_WIDTH * SCENE_HEIGHT 
    div     bx
    xchg    ax, dx

    xor     dx, dx
    mov     bx, size Object
    mul     bx

    lea     bx, temp_obj2
    call    take_from_scene
    cmp     temp_obj2.obj_type, 0
    jne     @@again


    mov     bx, di
    call    put_on_scene

    ret
spawn_new_snack endp


;==========event=handlers==========

snack_eated proc c uses di
    lea     ax, lalalalalala
    call    refresh_sound
    call    play_sound

    add     snake_score, 13

    lea     di, snack_obj
    call    spawn_new_snack
    ret
snack_eated endp


tail_eated proc c uses di

    @@ret:
    ret
tail_eated endp


wall_eated proc c uses di
    mov     ax, EVENT_DEATH
    call    fire_event
    ret
wall_eated endp


drug_eated proc c

    add     snake_score, 1
    test    snake_status, 1 ; first time - better :^)
    jnz     @@not_first_time 
    add     snake_score, 16
    @@not_first_time:
    call    continue_sot
    lea     di, drug_obj
    call    spawn_new_snack
    call    spawn_new_snack
    or      snake_status, 1
    ret
drug_eated endp


drug_cured proc c

    ret
drug_cured endp

;===============================


wall_obj             Object <4, 0, 0>
wall2_obj            Object <4, 0, 1>
snack_obj            Object <3, 0, 11FEh>
drug_obj             Object <3, 0, 0C0CAh>
snake_tail_obj       Object <2, 0, 0>
snake_tail_dark_obj  Object <2, 1, 0>
snake_head_obj       Object <1, 0, 0>

snake_score          dw     0
;                                          r
snake_status         dw     0000000000000000b
snake_direction      dw     DIRECTION_STOP
snake_pos:
    snake_pos_x      dw 5
    snake_pos_y      dw 13
snake_body_pos:
    dw   5, 12
    dw   5, 11
    dw   5, 10
    dw   5, 9
    dw   5, 8
    dw   5, 7
    dw   5, 6
    dw   5, 5
    dw   5, 4
    db   SCENE_WIDTH * SCENE_HEIGHT * 4 dup(-1)
snake_body_ends:
    db  "Hello, World!", 0Dh, 0Ah, 24h

file_buffer db SCENE_WIDTH * SCENE_HEIGHT * 2 dup(0)

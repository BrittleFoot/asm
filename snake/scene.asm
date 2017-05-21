


Object struc
    obj_type    dw 0000h
    obj_dir     dw 0000h
    obj_extra   dw 0000h
Object ends

SCENE_WIDTH     = 64
SCENE_HEIGHT    = 40


;array of objects types
scene   db  SCENE_WIDTH * SCENE_HEIGHT * size Object dup(00)
scene_end:


get_offset proc c uses cx bx dx
;   args:
;       ax - column
;       bx - row
;   returns:
;       ax - offset
    xchg    ax, bx
    xor     dx, dx

    mov     cx, SCENE_WIDTH
    mul     cx

    add     ax, bx

    xor     dx, dx
    mov     cx, size Object
    mul     cx
    ret
get_offset endp


put_on_scene proc c uses ax bx di
;   _copies_ object to scene
;   args:
;       ax - offset on scene
;       bx - pointer to target objet

    lea     di, scene
    add     di, ax

    cmp     di, offset scene_end
    jae     @@ret

    mov     ax, [bx].obj_type
    mov     [di].obj_type, ax

    mov     ax, [bx].obj_dir
    mov     [di].obj_dir, ax

    mov     ax, [bx].obj_extra
    mov     [di].obj_extra, ax

    @@ret:
    ret
put_on_scene endp


clear_cell proc c uses ax bx
;   _clears_ object from the scene
;   args:
;       ax - x
;       bx - y
    call get_offset
    lea  bx, null_obj
    call put_on_scene
    
    ret
clear_cell endp


copy_cell proc c uses ax bx ds si di
;   _copies_ object from the scene to the temp_obj
;   args:
;       ax - x
;       bx - y
    lea     di, temp_obj
    call    store_cell
    ret
copy_cell endp

store_cell proc c uses ax bx ds si di
;   _stores_ object from the scene to di offset
;   args:
;       ax - x
;       bx - y
;       di - pointer on place to store

    call get_offset
    lea  si, scene
    add  si, ax
    mov  ax, cs
    mov  ds, ax

    lodsw
    mov  [di].obj_type, ax
    lodsw
    mov  [di].obj_dir,  ax
    lodsw
    mov  [di].obj_extra,  ax
    ret
store_cell endp


cut_cell proc c
;   _cuts_ object from the scene to the temp_obj
;   args:
;       ax - x
;       bx - y
    call copy_cell
    call clear_cell
    ret
cut_cell endp


paste_cell proc c uses ax bx
;   _pastes_ object from the temp_obj to the scene
;   args:
;       ax - x
;       bx - y
    call get_offset
    lea  bx, temp_obj
    call put_on_scene
    ret
paste_cell endp


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


temp_obj        Object <0, 0, 0>
temp_obj1       Object <0, 0, 0>
temp_obj2       Object <0, 0, 0>
temp_obj3       Object <0, 0, 0>
null_obj        Object <0, 0, 0>


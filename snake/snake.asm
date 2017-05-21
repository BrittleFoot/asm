    .model  small
    locals  @@

.stack

text    segment
        assume  cs:text, ds:text, es:text

start:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    jmp     main    

include     timer.asm



SK_W = 11h
SK_A = 1Eh
SK_S = 1Fh
SK_D = 20h


my_keyboard_handler:
    ; al - scancode

    cmp     al, SK_W
    je      @@W_pressed
    cmp     al, SK_A
    je      @@A_pressed
    cmp     al, SK_S
    je      @@S_pressed
    cmp     al, SK_D
    je      @@D_pressed

    clc
    ret

    @@W_pressed:
    cmp     snake_direction, SK_S
    jne     @@change_dir
    jmp     @@ret
    @@A_pressed:
    cmp     snake_direction, SK_D
    jne     @@change_dir
    jmp     @@ret
    @@S_pressed:
    cmp     snake_direction, SK_W
    jne     @@change_dir
    jmp     @@ret
    @@D_pressed:
    cmp     snake_direction, SK_A
    jne     @@change_dir
    jmp     @@ret

    @@change_dir:
    xor     ah, ah
    mov     snake_direction, ax

    @@ret:
    clc
    ret 



old_video_mode:
    vm  db 00h
    pg  db 00h



world_timer Timer <0, 5, offset update_world>

main proc far

    ; store vmode and active page
    mov     ax, 0F00h
    int     10h
    mov     vm, al
    mov     pg, bh

    ; set vmode
    ; 320×200 in 256 colors
    mov     ax, 0013h
    int     10h

    call    acquire_keyboard
    mov     keyboard_handler, offset my_keyboard_handler

    call    init_game

    @@main_loop:
        hlt

        call    update_world    

        cli
        mov     ax, 2
        call    clear_screen
        call    draw_scene
        call    push_buffer
        sti


        call read_buffer
        jc   @@main_loop    
        cmp  al, 1
        jne  @@main_loop


    call release_keyboard
    call stop_play

    ; restore vmode and active page
    mov     ah, 00h
    mov     al, vm
    int     10h

    mov     ah, 05h
    mov     al, pg
    int     10h


    mov ax, 4C00h
    int 21h
main endp


include     keyboard\ints.asm
include     keyboard\cb.asm
include     keyboard\keys.asm
include     keyboard\myint9.asm

include     model.asm
include     music\playlib2.asm
; call play_sound  

text ends

include     graphics.asm

end start

    .model  small
    locals  @@


.stack

text segment
    assume  cs:text, ds:text, es:text

start:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    jmp     main



SCREEN_HEIGHT  = 200
SCREEN_WIDTH   = 320

last_x  dw  00
last_y  dw  00


mouse_evnt_handler:
    ; AX = condition mask causing call
    ; CX = horizontal cursor position
    ; DX = vertical cursor position
    ; DI = horizontal counts
    ; SI = vertical counts
    ; DS = mouse driver data segment
    ; BX = button state:
    ;
    ;    |F-2|1|0|
    ;      |  | `--- left button (1 = pressed)
    ;      |  `---- right button (1 = pressed)
    ;      `------ unused
    pushf

    push    bx

    mov     ax, cx
    sub     ax, last_x
    mov     last_x, cx

    mov     bx, dx
    sub     bx, last_y
    mov     last_y, dx

    pop     cx
    ;   ax, bx - x, y deltas
    ;   cx - buttons state

    cmp     cx, 2
    jne     @@1
    call    change_colors
    jmp     @@ret

    @@1:
    cmp     cx, 1
    jne     @@2    
    call    move_frame
    jmp     @@ret

    @@2:
    call    move_ball

    @@ret:
    call draw_scene
    popf
    retf


old_video_mode:
    vm  db 00h
    pg  db 00h



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

    ;   show cursor
    ; mov     ax, 1
    ; int     33h

    call    draw_scene

    mov     dx, offset mouse_evnt_handler
    call    set_mouse_handler

    ; wait any key
    xor     ax, ax
    int     16h
        

    call    restore_mouse_handler


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

text ends

include     m_int.asm
include     ball.asm
include     graphics.asm

end start
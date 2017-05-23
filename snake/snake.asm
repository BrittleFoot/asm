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
include     events.asm


SK_W = 11h
SK_A = 1Eh
SK_S = 1Fh
SK_D = 20h
SK_Q = 10h
SK_E = 12h


my_keyboard_handler:
    ; al - scancode
    cmp     al, SK_W
    je      @@change_dir
    cmp     al, SK_A
    je      @@change_dir
    cmp     al, SK_S
    je      @@change_dir
    cmp     al, SK_D
    je      @@change_dir
    cmp     al, SK_Q
    je      @@up_speed
    cmp     al, SK_E
    je      @@down_speed

    jmp     @@ret

    @@change_dir:
    xor     ah, ah
    mov     snake_direction, ax
    clc
    ret

    @@up_speed:
    inc     update_ratio
    jmp     @@ret

    @@down_speed:
    cmp     update_ratio, 0
    jle     @@ret
    dec     update_ratio

    @@ret:
    clc
    ret 


old_video_mode:
    vm  db 00h
    pg  db 00h


configure_event_subsystem:
    mov     event_starts, offset events
    mov     event_ends, offset events_ends
    ret


EVENT_SNACK_EATED = 1
EVENT_TAIL_EATED  = 2
EVENT_WALL_EATED  = 3
EVENT_DEATH       = 4
EVENT_DRUG_EATED  = 5
EVENT_DRUG_CURED  = 6

events:
    Event <EVENT_SNACK_EATED, 0, offset snack_eated>
    Event <EVENT_TAIL_EATED,  0, offset tail_eated>
    Event <EVENT_WALL_EATED,  0, offset wall_eated>
    Event <EVENT_DEATH,       0, offset death>
    Event <EVENT_DRUG_EATED,  0, offset drug_eated>
    Event <EVENT_DRUG_CURED,  0, offset drug_cured>
events_ends:



snake_dead dw 0
death:
    lea     ax, endsound
    call    play_sound
    mov     snake_dead, 1

    ret


stats           db  " Score: " 
str_score       db  "    "
                db  " ", 0

drug_stats      db  "1111111111111111", 0

ratio     dw 10
ax_to_str proc c uses ax bx cx dx
;   ax - number
;   bx - pointer to target str
    xor     cx, cx
    @@loop:
        xor     dx, dx
        div     ratio
        push    dx
        inc     cx
        test    ax, ax
        jnz     @@loop

    @@loop2:
        pop     ax
        add     ax, '0'
        mov     [bx], al
        inc     bx
        dec     cx
        jnz     @@loop2        


    ret
ax_to_str endp


fill_drug_stats proc c

    call get_next_random
    mov  word ptr [drug_stats], ax
    call get_next_random
    mov  word ptr [drug_stats+2], ax
    call get_next_random
    mov  word ptr [drug_stats+4], ax
    call get_next_random
    mov  word ptr [drug_stats+6], ax
    call get_next_random
    mov  word ptr [drug_stats+8], ax
    call get_next_random
    mov  word ptr [drug_stats+10], ax
    call get_next_random
    mov  word ptr [drug_stats+12], ax
    call get_next_random
    mov  word ptr [drug_stats+14], ax

    ret
fill_drug_stats endp


s_game_hello    db "WELCOME TO PSYCHO-SNAKE!", 0
s_lesgo         db "Will you dare to play this one? ", 0
s_lesgo_help    db "                PRESS ENTER", 0
s_press_e_hello db "Press Esc NOW(!) if you scared.", 0
s_help1         db "Help: WASD Q< E>", 0
s_help2         db " EATE YUMMIES (BUT NOT REAL ONES).", 0


s_game_over     db "GAME OVER", 0
s_again         db "Play again? (type snake again)", 0
s_press_e       db "Press anything to exit.", 0

draw_results proc c

    mov     ax, 30
    mov     bx, 30
    lea     dx, s_game_over
    call    draw_string
    mov     ax, 30
    mov     bx, 60
    lea     dx, s_again
    call    draw_string
    mov     ax, 30
    mov     bx, 90
    lea     dx, s_press_e
    call    draw_string

    ret
draw_results endp

draw_inits  proc c

    mov     ax, 30
    mov     bx, 30
    lea     dx, s_game_hello
    call    draw_string
    mov     ax, 30
    mov     bx, 60
    lea     dx, s_lesgo
    call    draw_string
    mov     ax, 30
    mov     bx, 90
    lea     dx, s_lesgo_help
    call    draw_string
    mov     ax, 30
    mov     bx, 120
    lea     dx, s_press_e_hello
    call    draw_string
    mov     ax, 30
    mov     bx, 160
    lea     dx, s_help1
    call    draw_string
    mov     ax, 30
    mov     bx, 180
    lea     dx, s_help2
    call    draw_string

    ret
draw_inits  endp


update_ratio    dw  0001h
update_counter  dw  0000h
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


    @@init_menu:
        hlt
        cli
        mov     ax, 2
        call    clear_screen
        call    draw_inits
        call    push_buffer
        sti
        call    read_buffer
        jc      @@init_menu
        cmp     al, 1Ch
        je      @@LES_GO_BOYZ
        cmp     al, 1
        je      @@tuff_guy
        jmp     @@init_menu
        @@tuff_guy:
            jmp @@soft_cola

    @@LES_GO_BOYZ:

    call    init_game
    lea     ax, ost
    call    play_sound

    call    configure_event_subsystem

    mov     ax, update_ratio
    mov     update_counter, ax

    @@main_loop:
        cmp     update_ratio, 0
        je      @@nohlt

        hlt
        @@nohlt:

        call    dispatch_events

        cmp     update_counter, 0
        jg      @@nxt
        call    update_world    
        mov     ax, update_ratio
        mov     update_counter, ax
        @@nxt:
        dec     update_counter

        cli
        mov     ax, 2
        test    snake_status,  1
        jz      @@drw
        call    get_next_random
        @@drw:
        mov     bgrnd, al
        call    clear_screen
        call    draw_scene

        mov     ax, snake_score
        lea     bx, str_score
        call    ax_to_str
        mov     ax, -50
        mov     bx, 391
        lea     dx, stats

        test    snake_status,  1
        jz      @@nrm_stats

        call fill_drug_stats
        mov  dx, offset drug_stats
        mov  ax, -50
        mov  bx, 391

        @@nrm_stats:
        call    draw_string 

        call    push_buffer
        sti


        cmp  snake_dead, 1
        je  @@break

        call read_buffer
        jc   @@main_loop    
        cmp  al, 1
        jne  @@main_loop

    @@break:


    @@exit_menu:
        hlt
        cli
        mov     ax, 2
        ; call    clear_screen
        call    draw_results
        call    push_buffer
        sti
        call    read_buffer
        jc      @@exit_menu

    @@soft_cola:

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

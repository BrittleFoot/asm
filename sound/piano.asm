    .model  tiny
    .code
    org     100h
    locals  @@

start:
    jmp     argparse

DEBUG db 0

include     argparse.asm
include     cb.asm
include     ints.asm
include     soundlib.asm
include     keys.asm
include     myint9.asm  
    ;  acquire_keyboard
    ;  release_keyboard
    ;  pressed_keys (array, and functions)
    ;  peek_key
    ;  ks_ptr

include     notes.asm



play:
    ; bx - frequency_value

    set_freq    bx
    speaker_on

    mov     cx, 0FFFFh ; - min discrete sound length
    loop    $
    mov     cx, 09FFFh ; - min discrete sound length
    loop    $

    ret


commands:

cHelp        TCOMMAND  <"help", "$", " ", "$">
cArpegioOff  TCOMMAND  <"s"   , "$", " ", "$">

unnamed_args:
cNone        TCOMMAND   <"mode", "$", " ">

args_storage db 80h dup (0)

argparse:
    mov ax, offset args_storage

    call    init_args
    call    tokenize

    mov     ax, offset commands
    mov     bx, offset unnamed_args
    call    parse_commands
    jmp     main


main proc far
    call    acquire_keyboard

    initialize_timer

    xor     dx, dx
    main_loop:

        call    read_buffer

        cmp     al, 01h
        je      break

        call    peek_key
        jc      stop_play

        cmp     cArpegioOff.used, 1
        je      note_play

        call    write_out_pressed

        inc     dx
        cmp     dx, cx
        jl      @@ok
        xor     dx, dx
        @@ok:
        mov     bx, dx
        mov     al, pressed[bx]

        note_play:; from AL

            ; push    ax
            ; mov     dl, al
            ; mov     ax, 0200h
            ; int     21h
            ; pop     ax

            push    dx
            call    translate_into_freq
            jc      continue

            push    ax
            mov     ax, 0900h
            int     21h
            mov     ax, 0200h
            mov     dl, 0Dh
            int     21h
            pop     ax

            pop     dx

            mov     bx, ax
            call    play
            jmp     continue

        stop_play:
            cmp     total_pressed, 0
            jnz     continue
            speaker_off

        continue:
        jmp main_loop
    break:

    speaker_off
    call    release_keyboard
    mov     ax, 4C00h
    int     21h

main endp

end start
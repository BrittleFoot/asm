
    .model  tiny
    .code
    org     100h
    locals  @@

start:

    jmp init


DEBUG       dw    0000
include     argparse.asm
include     drawtlib.asm
include     util.asm


init:

        mov ax, offset args_storage

        call    init_args
        call    tokenize

        mov     ax, offset commands
        mov     bx, offset unnamed_args
        call    parse_commands
        call    main


;====================================================================

commands:

c7ModePref   TCOMMAND  <"m7p",      "$", " ", "$">
cHelp        TCOMMAND  <"help",     "$", " ", "$">
cPage        TCOMMAND  <"page",     "$", " ", "$">     
cTitleColor  TCOMMAND  <"title",    "$", " ", "$">
cNoBlink     TCOMMAND  <"noblink",  "$", " ", "$">     


unnamed_args:
cMode        TCOMMAND   <"mode", "$", " ">


;====================================================================


main proc near
    push bp
    mov bp, sp

    mov ax, 0900h
    mov dx, offset endl
    int 21h

    call analyze_args
    mov     ah, uMode
    mov     al, uPage
    call check_errors
    mov     ah, uMode
    mov     al, uPage
    mov     bh, uHCol
    mov     bl, uBlnk
    mov     ch, u7Clr
    call draw_table


    mov sp, bp
    pop bp

    mov ax, 4C00h
    int 21h
main endp



uMode   db  00h
uPage   db  00h
uHCol   db  02h  
uBlnk   db  00h  
u7Clr   db  01h 


analyze_args:

    mov     ax, cHelp.used
    cmp     ax, 1
    jne     no_help
    RAISE_ERROR "Usage: .com [mode] -help -page <n> -title <color> -noblink -m7p <n>"

    no_help:

    ;;;
    mov     ax, cMode.used
    cmp     ax, 1
    je      mode_ok
    RAISE_ERROR     "Mode is required argument"
    mode_ok:

    mov     bx, offset cMode.args
    call    parse_int2
    mov     uMode, al
    ;;;

    ;;;
    mov     uPage, 00h
    mov     bx, cPage.used
    jne     @@skrew_page
    mov     bx, offset cPage.args
    call    parse_int2
    mov     uPage, al
    ;;;

    @@skrew_page:

    ;;;
    mov     ax, cTitleColor.used
    cmp     ax, 1
    jne     @@title_ok
    mov     bx, offset cTitleColor.args
    call    parse_int2
    mov     uHCol, al
    @@title_ok:
    ;;;

    ;;;
    mov     ax, cNoBlink.used
    mov     [uBlnk], al
    ;;;

    mov     ax, c7ModePref.used
    cmp     ax, 1
    jne     @@m7p_end

    mov     bx, offset c7ModePref.args
    call    parse_int2
    mov     [u7Clr], al

    @@m7p_end:


    ret



legal_page_values   db 8, 8, 4, 4, 1, 1, 1, 1, 1, 1, 1, 8, 4, 2, 2

__VMODE_RANGE_ERROR:        call VMODE_RANGE_ERROR
__NOT_A_TEXT_MODE_ERROR:    call NOT_A_TEXT_MODE_ERROR

check_errors:
; ah - video mode:al - displayed page
    cmp     ah, 10h
    jg      __VMODE_RANGE_ERROR
    cmp     ah, 07h
    je      @@vm_ok
    cmp     ah, 04h
    jl      @@vm_ok
    jmp     __NOT_A_TEXT_MODE_ERROR

    @@vm_ok:

    push bx

    xor     bx, bx
    mov     bl, ah
    cmp     al, legal_page_values[bx]
    pop  bx
    jl @@ok
    jmp ILLEGAL_PAGE_VALUE

    @@ok:
    ret



sVmodeRangeError db "Vmode must be in  range [0,1,2,3,7].", 0Dh, 0Ah, '$'

sNotATextModeError  db "This is not a text video mode.", 0Dh, 0Ah
                    db "Only modes 0-3,7 is cool", 0Dh, 0Ah, '$'

sIllegalPageValue   db "This page number is illegal for "
                    db "selected video mode.", 0Dh, 0Ah, '$'


VMODE_RANGE_ERROR:
    mov ax, 0900h
    mov dx, offset sVmodeRangeError
    int 21h
    ; good bye and terminate
    mov ax, 4C00h
    int 21h

NOT_A_TEXT_MODE_ERROR:
    mov ax, 0900h
    mov dx, offset sNotATextModeError
    int 21h
    ; good bye and terminate
    mov ax, 4C00h
    int 21h

ILLEGAL_PAGE_VALUE:
    mov ax, 0900h
    mov dx, offset sIllegalPageValue
    int 21h
    ; good bye and terminate
    mov ax, 4C00h
    int 21h



args_storage:
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db                                   0Dh, 0Ah, '$'


end start



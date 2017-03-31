
    .model  tiny
    .code
    org     100h
    locals  @@


start:

    jmp init



include     util.asm


init:

        call    init_args
        call    tokenize
        call    main


iArgc   dw  0000h
pArgv   dw  0000h

sUsage               db  "Usage: dascii xx xx", 0dh, 0ah, '$'
sTokenizeSuccessful  db  "Tokenize Successful.", 0dh, 0ah, '$'

endl                 db  0dh, 0ah, '$'

;====================================================================


main proc near
    push bp
    mov bp, sp

    ; mov ax, 0900h
    ; mov dx, offset args_storage
    ; int 21h

    mov ax, offset args_storage
    call parse_args
    ; (terminate programm if something went wrong)
    ; ah, al - parsed args
    call check_errors
    call draw_table
    ; wuala


    mov sp, bp
    pop bp

    mov ax, 4C00h
    int 21h
main endp



parse_args:
; ax - offset of arguments 
; terminates programm if something goes wrong

    
    mov bx, ax; bx - pointer
    xor ax, ax; ax - word counter
    xor dx, dx; dx - next word length

    @@argloop:

        test    dx, dx
        jz      @@newword

        push    ax
        call    parse_int
        cmp     ax, 100h
        jge     @@endloop
        mov     cx, ax
        pop     ax

        ; store number
        push    cx
        
        add     bx, dx
        xor     dx, dx

        jmp @@argloop
        
        @@newword:
        mov     dl, byte ptr [bx]
        test    dx, dx
        jz      @@endloop
        cmp     dx, 3
        jg      __ARGUMENT_ERROR

        inc     ax
        inc     bx
        jmp     @@argloop

    @@endloop:

    cmp     ax, 2
    jne     __ARGUMENT_ERROR

    pop ax
    pop dx
    mov ah, dl

    ret




legal_page_values   db 8, 8, 4, 4, 0, 0, 0, 0, 0, 0, 0, 8, 4, 2, 2

__ARGUMENT_ERROR:           call ARGUMENT_ERROR
__VMODE_RANGE_ERROR:        call VMODE_RANGE_ERROR
__VMODE_7H_ERROR:           call VMODE_7H_ERROR
__NOT_A_TEXT_MODE_ERROR:    call NOT_A_TEXT_MODE_ERROR

check_errors:
; ah - video mode:al - displayed page
    cmp     ah, 10h
    jg      __VMODE_RANGE_ERROR
    cmp     ah, 07h
    je      __VMODE_7H_ERROR
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


sArgumentError db "This programm takes exacly 2 arguments. ",0Dh,0Ah
               db "There are must be two space-delimeted "
               db "digits: VMODE[0, 10h] and PAGE[<8].", 0Dh, 0Ah, '$'

sVmodeRangeError db "Vmode must be in  range [0, 10h].", 0Dh, 0Ah, '$'
s7hError         db "This mode doesn't support colored output :c", 0Dh, 0Ah, '$'

sNotATextModeError  db "This is not a text video mode.", 0Dh, 0Ah
                    db "Only modes 0-3 is cool", 0Dh, 0Ah, '$'

sIllegalPageValue   db "This page number is illegal for "
                    db "selected video mode.", 0Dh, 0Ah
                    db "FUI:", 0Dh, 0Ah
                    db "Video mode  | Legal Pages", 0Dh, 0Ah
                    db "    00h           0-7   ", 0Dh, 0Ah
                    db "    01h           0-7   ", 0Dh, 0Ah
                    db "    02h           0-3   ", 0Dh, 0Ah
                    db "    03h           0-3   ", 0Dh, 0Ah
                    db "    04h            0    ", 0Dh, 0Ah
                    db "    05h            0    ", 0Dh, 0Ah
                    db "    06h            0    ", 0Dh, 0Ah
                    db "    07h            0    ", 0Dh, 0Ah
                    db "    08h            0    ", 0Dh, 0Ah
                    db "    09h            0    ", 0Dh, 0Ah
                    db "    0Ah            0    ", 0Dh, 0Ah
                    db "    0Dh           0-7   ", 0Dh, 0Ah
                    db "    0Eh           0-3   ", 0Dh, 0Ah
                    db "    0Fh           0-1   ", 0Dh, 0Ah
                    db "    10h           0-1   ", 0Dh, 0Ah
                    db "", 0Dh, 0Ah, '$'

ARGUMENT_ERROR:
    mov ax, 0900h
    mov dx, offset sArgumentError
    int 21h
    ; good bye and terminate
    mov ax, 4C00h
    int 21h

VMODE_RANGE_ERROR:
    mov ax, 0900h
    mov dx, offset sVmodeRangeError
    int 21h
    ; good bye and terminate
    mov ax, 4C00h
    int 21h

VMODE_7H_ERROR:
    mov ax, 0900h
    mov dx, offset s7hError
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



include drawtlib.asm

;====================================================================

init_args:
    
    mov     bx, 0080h
    mov     ax, 0000h
    mov     al, [bx]
    mov     iArgc, ax
    inc     bx
    mov     pArgv, bx

    ret


;====================ARGV=PARSING=AUTHOMAT=HERE======================


VK_SPACE = 20h



STATE_SPACE:

        cmp     dl, VK_SPACE
        je      @@return

        mov     state, offset STATE_WORD

    @@return:
        ret


STATE_WORD:

        cmp     dl, VK_SPACE
        jne     @@return

        mov     state, offset STATE_WORD_ENDS

    @@return:
        ret


STATE_WORD_ENDS:

        cmp     dl, VK_SPACE
        je      @@space

        mov state, offset STATE_WORD
        jmp @@return

    @@space:
        mov state, offset STATE_SPACE

    @@return:
        ret


;====================ARGV=PARSING=AUTHOMAT=ENDS======================


state       dw  offset STATE_SPACE
cmdCounter  dw  0000h
cmdBuffer   db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, '$'


;====================COMMAND=LINE=ARGUMENTS=PARSE====================

tokenize:

    xor     cx, cx
    cmp     [iArgc], 0
    je @@show_usage

    @@loop:
        mov     bx, pArgv
        add     bx, cx
        mov     dx, 0000h
        mov     dl, [bx]
        @@short_loop:

        @@yal:
        push    bx cx dx
        ; for each dl <- symbol in argv 

        call    state
        call    state_payload

        ;;
        pop     dx cx bx

        inc     cx
        cmp     cx, [iArgc]
        jl      @@loop
        mov     dl, 20h
        jle     @@short_loop

    jmp     @@tokenize_successful


    @@show_usage:
        mov     ah, 9h  
        mov     dx, offset sUsage
        int     21h


    @@tokenize_successful:
    ; mov     ah, 9h  
    ; mov     dx, offset sTokenizeSuccessful
    ; int     21h

    ret



WORD_PTR        dw 0000h
WORD_BUFFER     db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                db 0Dh, 0Ah, '$'


state_payload:
    
        cmp state, offset STATE_WORD
        je  @@write_to_buffer

        cmp state, offset STATE_WORD_ENDS
        je  @@store

        ret

    @@write_to_buffer:

        mov     bx, word ptr [WORD_PTR]
        cmp     bx, 20
        jge     @@return

        add     bx, offset WORD_BUFFER
        mov     byte ptr [bx], dl
        inc     [WORD_PTR]
        ret


    @@store:

        push ax bx cx dx es di

        mov     dx, [WORD_PTR]
        mov     bx, word ptr [args_ptr]
        add     bx, offset args_storage
        mov     byte ptr [bx], dl
        inc     [args_ptr]  
        ; записали длину слова и увеличели указатель

        xor     cx, cx

        @@copyloop:


            mov bx, offset WORD_BUFFER
            add bx, cx
            mov al, byte ptr [bx]

            mov bx, word ptr [args_ptr]
            add bx, offset args_storage
            mov byte ptr [bx], al
            inc [args_ptr]
            inc  cx

            cmp cx, dx
            jl  @@copyloop



        xor     cx, cx
        @@purify:
            mov bx, offset WORD_BUFFER
            add bx, cx

            mov byte ptr [bx], 00h
            inc cx
            cmp cx, 20
            jl  @@purify
        mov     word ptr [WORD_PTR], 0000h

        pop di es dx cx bx ax

    @@return:
        ret






;================COMMAND=LINE=ARGUMENTS=PARSE=ENDS===================


print_argv:

    xor     cx, cx
    @@loop:
        mov     bx, pArgv
        add     bx, cx
        mov     dl, [bx]
        mov     ax, 0200h

        push    cx
        int     21h
        pop     cx

        inc     cx
        cmp     cx, [iArgc]
        jle     @@loop

    mov     dl, 0Dh
    mov     ax, 0200h
    int     21h

    mov     dl, 0Ah
    mov     ax, 0200h
    int     21h

    ret


args_ptr dw 0000h
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



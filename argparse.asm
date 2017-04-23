
iArgc   dw  0000h
pArgv   dw  0000h

iArgsCounter dw 0000h
pArgsPointer dw 0000h



TCOMMAND struc
    cmd_name    db  "Less than 20 symbols"
    alignment   db  "$"
    args        db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    used        dw  0000h
    alignment2  db  "$"
TCOMMAND ends



;====================================================================
printf macro msg
    mov     ah, 9
    mov     dx, offset msg
    int     21h
endm

RAISE_ERROR macro msg
    local   m1
    local   m2

    jmp     m2
m1  db      msg, 0dh, 0ah, 24h
m2:
    printf  m1
    mov     ax, 4C00h
    int     21h
endm
;====================================================================




;====================================================================
VK_MODE = '-'

parse_state             dw  offset NO_COMMAND_STATE
pCurrentCommand     dw  0000h
pUnnamedCommand     dw  0000h


flush_cmd:
    ; bx - ptr on token
    ; dx - length of token
    
    push es  di
    mov  ax, cs
    mov  es, ax
    mov  di, pCurrentCommand


    test dx, dx;  no args?
    jz @@what_the_command
    jmp @@alright

    @@what_the_command:
    cmp di, pUnnamedCommand;   untagged command?
    je  @@after_copying    ;   then dont flush at all

    @@alright:

    add  di, used
    mov  word ptr [di], 0001h  ;  only mark as used

    test dx, dx
    jz   @@after_copying

    mov  di, pCurrentCommand
    add  di, args

    mov  al, dl
    stosb

    @@loop:
        mov     al, byte ptr [bx]
        stosb
        inc     bx
        dec     dx
        test    dx, dx
        jnz     @@loop 

    @@after_copying:
    pop  di es
    mov ax, pUnnamedCommand
    mov pCurrentCommand, ax
    ret


find_cmd:
    ; bx - ptr on token
    ; dx - length of token

    mov     ax, pCommandSection
    @@loop:

        push    ax bx
        call    strcmp
        pop     bx ax

        cmp     cx, 1
        je      @@found_command

        add     ax, size TCOMMAND
        cmp     ax, pUnnamedArgsSection
        jl      @@loop

    jmp @@command_not_found

    @@found_command:
    mov pCurrentCommand, ax

    ret

    @@command_not_found:
        RAISE_ERROR "Unexpected argument"


NO_COMMAND_STATE:
    ; bx - ptr on token
    ; dx - length of token
    ; global parse_state
    push bx dx

    xor     ax, ax
    mov     al, byte ptr [bx]
    cmp     al, VK_MODE
    je      @@cmd_gate

    @@arg_gate:

        call    flush_cmd
        jmp     @@return

    @@cmd_gate:

        inc     bx
        dec     dx
        call    find_cmd
        mov     parse_state, offset COMMAND_STATE

    @@return:
    pop  dx bx
    ret


COMMAND_STATE:
    ; bx - ptr on token
    ; dx - length of token
    ; global parse_state
    push bx dx

    xor     ax, ax
    mov     al, byte ptr [bx]
    cmp     al, VK_MODE
    je      @@cmd_gate

    @@arg_gate:

        call    flush_cmd
        jmp     @@return

    @@cmd_gate:

        push    dx
        xor     dx, dx
        call    flush_cmd
        pop     dx

        inc     bx
        dec     dx
        call    find_cmd
        mov     parse_state, offset COMMAND_STATE

    @@return:
    pop  dx bx
    ret



pCommandSection     dw  0000h
pUnnamedArgsSection dw  0000h



parse_commands:
;   ax - offset of command section
;   bx - offset of unnamed args section
    mov     pCommandSection, ax
    mov     pUnnamedArgsSection, bx
    mov     pUnnamedCommand, bx
    mov     pCurrentCommand, bx

    xor     dx, dx 
    mov     bx, pArgsPointer
    @@loop:

        mov     dl, byte ptr [bx]
        test    dx, dx
        jz      @@loop_ends
        inc     bx
        ; bx - ptr on token
        ; dx - length of token
        call parse_state

        add     bx, dx
        jmp     @@loop

    @@loop_ends:
    call parse_state

    cmp [DEBUG], 0
    je @@return
    call print_command_table
    @@return:
    ret



print_command_table:

    mov ax, 0900h
    mov dx, offset table_head
    int 21h

    mov     bx, pCommandSection
    @@loop:
        mov     ax, 0900h
        mov     dx, bx
        int     21h
        add     dx, args
        int     21h
        mov     dx, offset endl
        int     21h

        add     bx, size TCOMMAND
        cmp     bx, pUnnamedArgsSection
        jle      @@loop

    ret


table_head: 
th TCOMMAND <"  NAME", " ", " ARGS", "SU", "E">
ed      db "D", 0Dh, 0Ah, 24h
;====================================================================

sUsage               db  "Switch -help for usage", 0dh, 0ah, '$'
sTokenizeSuccessful  db  "Tokenize Successful.", 0dh, 0ah, '$'

endl                 db  0dh, 0ah, '$'
;====================================================================

init_args:

    mov pArgsPointer, ax
    
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

    cmp DEBUG, 0
    je @@return
    mov     ah, 9h  
    mov     dx, offset sTokenizeSuccessful
    int     21h
    @@return:
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
        mov     bx, word ptr [iArgsCounter]
        add     bx, word ptr [pArgsPointer]
        mov     byte ptr [bx], dl
        inc     [iArgsCounter]  
        ; записали длину слова и увеличели указатель

        xor     cx, cx

        @@copyloop:


            mov bx, offset WORD_BUFFER
            add bx, cx
            mov al, byte ptr [bx]

            mov bx, word ptr [iArgsCounter]
            add bx, word ptr [pArgsPointer]
            mov byte ptr [bx], al
            inc [iArgsCounter]
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


strcmp:
    ; ax - offset of the first string
    ; bx - offset of the second string
    ; dx - length of compareing

    push ax bx dx di

    mov  di, ax
    xor  ax, ax

    @@loop:
        mov ah, byte ptr [bx]
        mov al, byte ptr [di]

        ; push ax dx
        ; mov  dx, ax
        ; mov  ax, 0200h
        ; int 21h
        ; xchg dh, dl
        ; int 21h
        ; pop  dx ax

        cmp al, ah
        jne @@not_ok

        inc bx
        inc di
        dec dx
        test dx, dx
        jnz @@loop
        jz  @@ok


    @@not_ok:
        mov cx, 2
        jmp @@return

    @@ok:
        mov cx, 1
        jmp @@return

    @@return:
    ; mov ax, 0200h
    ; mov dl, cl
    ; int 21h
    pop  di dx bx ax
    ret
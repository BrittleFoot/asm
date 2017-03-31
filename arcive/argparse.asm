
    .model  tiny
    .code
    org     100h
    locals  @@



start:

    jmp main


include commands.asm



main:

        call    init_args

        ; call    print_argv
            
        call    tokenize

        jmp     terminate


    terminate:
        int     20h




iArgc   dw  0000h
pArgv   dw  0000h

sUsage               db  'Use --help or -h to show help!', 0dh, 0ah, '$'
sParseError          db  'Unexpected symbol.', 0dh, 0ah, '$'
sTokenizeSuccessful  db  'Tokenize Successful.', 0dh, 0ah, '$'
sUnknownOption       db  'Unknown option -$'
sUnknownOptionLong   db  'Unknown option --$'

endl                 db  0dh, 0ah, '$'

;====================================================================


TCOMMAND struc
    longname    db  'Less than 20 symbols'
    alignment   db  '$'
    shortname   db  'o'
    handler     dw  0000h
    usageCount  dw  0000h
TCOMMAND ends


                            commands:

cmdHelp         TCOMMAND <"help",      '$', "h", offset hHelp>
cmdTest         TCOMMAND <"test",      '$', "t", offset hTest>
cmdInstall      TCOMMAND <"install",   '$', "i", offset hInstall>
cmdTryUninstall TCOMMAND <"uninstall", '$', "u", offset hUninstall>
cmdUninstallFrd TCOMMAND <"UNINSTALL", '$', "U", offset hUI_Forced>   

                          commandsEnd:
;====================================================================


hHelp proc near
    push bp
    mov bp, sp
    push ax dx

    mov ax, 0900h
    mov dx, offset sHelpfullMessage
    int 21h

    call terminate
    
    pop dx ax
    mov sp, bp
    pop bp
    ret
hHelp endp

sHelpfullMessage    db  "Helpfull message!", 0dh, 0ah, '$'


;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;12301203103013013010305023523423424234018410938510840192801840918490
                         invoke_command:
;                 bx -- pointer onto selected command
    
    mov bx, [bx.handler]
    push es ds si di
    call bx
    pop  di si ds es

    ret
;////////////////////////////////////////////////////////////////////


init_args:

    mov     bx, 0080h
    mov     ax, 0000h
    mov     al, [bx]
    mov     iArgc, ax
    inc     bx
    mov     pArgv, bx

    ret


;====================ARGV=PARSING=AUTHOMAT=HERE======================

VK_SPACE        = 20h
VK_DASH         = 2Dh


STATE_SPACE:
    
        cmp     dl, VK_SPACE                ; if dl == ' ':
        je      @@return

        cmp     dl, VK_DASH                 ; elif dl == '-':
        je      @@dash

        mov     state, offset STATE_ERROR   ; else:
        jmp     @@return

    @@dash:
        mov     state, offset STATE_DASH 

    @@return:
        ret
                                ; SAME LOGICK TILL THI END

STATE_DASH:

        cmp     dl, VK_SPACE            
        je      @@error

        cmp     dl, VK_DASH 
        jle     @@change_to_long
        

        mov     state, offset STATE_STORE_SHORT
        jmp     @@return

    @@change_to_long:
        mov     state, offset STATE_DOUBLE_DASH
        jmp     @@return

    @@error:
        mov     state, offset STATE_ERROR

    @@return:
        ret


STATE_DOUBLE_DASH:

        cmp     dl, VK_SPACE
        je      @@error
        cmp     dl, VK_DASH
        je      @@error

        mov     state, offset STATE_COLLECT_LONG
        jmp     @@return

    @@error:
        mov     state, offset STATE_ERROR

    @@return:
        ret


STATE_STORE_SHORT:

        cmp     dl, VK_DASH
        je      @@error

        cmp     dl, VK_SPACE
        jne     @@return

        mov     state, offset STATE_SPACE
        jmp     @@return


    @@error:
        mov     state, offset STATE_ERROR

    @@return:
        ret

STATE_COLLECT_LONG:

        cmp     dl, VK_SPACE
        jne     @@return

        mov     state, offset STATE_STORE_LONG

    @@return:
        ret


STATE_STORE_LONG:

        cmp     dl, VK_SPACE
        je      @@space
        
        cmp     dl, VK_DASH
        je      @@dash


    @@space:
        mov     state, offset STATE_SPACE
        jmp     @@return

    @@dash:
        mov     state, offset STATE_DASH
        jmp     @@return

    @@error:
        mov     state, offset STATE_ERROR

    @@return:
        ret


STATE_ERROR:
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

        @@yal:
        push    bx cx dx
        ; for each dl <- symbol in argv 

        call state
        call state_payload


        ;;
        pop     dx cx bx
        cmp     state, offset STATE_ERROR
        je  PARSE_ERROR

        inc     cx
        cmp     cx, [iArgc]
        jl      @@loop

    cmp     state, offset STATE_DASH
    je      @@yet_one_loop
    cmp     state, offset STATE_DOUBLE_DASH
    je      @@yet_one_loop
    cmp     state, offset STATE_COLLECT_LONG
    je      @@yet_one_loop

    jmp     @@tokenize_successful

    @@yet_one_loop:
    ; If ends in (-) or (--) or (collect) state
        mov dx, 0020h
        jmp @@yal

    @@show_usage:
        mov     ah, 9h  
        mov     dx, offset sUsage
        int     21h


    @@tokenize_successful:
    ; mov     ah, 9h  
    ; mov     dx, offset sTokenizeSuccessful
    ; int     21h


    ret

PARSE_ERROR:
    
        mov     ah, 9h   
        mov     dx, offset sParseError
        int     21h

    ret


state_payload:

        cmp     state, offset STATE_STORE_SHORT
        je      @@invoke_short

        cmp     state, offset STATE_STORE_LONG
        je      @@invoke_long

        cmp     state, offset STATE_COLLECT_LONG
        je      @@collect_long

        jmp     @@return

    ;=============
    @@collect_long:

        cmp     [cmdCounter], 20
        jge     @@return1

        mov     bx, [cmdCounter]
        add     bx, offset cmdBuffer
        mov     [bx], dl

        inc     cmdCounter
        jmp     @@return1

    ;==============
    @@invoke_short:

        xor     cx, cx
        mov     bx, offset commands

        @@short_loop:
            cmp     byte ptr [bx].shortname, dl

            jne     @@continue

            ; Payload here
            ; bx - pointer onto selected command
            call invoke_command

            ; debug :
            ; push    bx cx dx
            ; mov     ax, 0200h
            ; int     21h
            ; pop     dx cx bx
            inc     cx

            @@continue:
            add     bx, size TCOMMAND
            cmp     bx, offset commandsEnd
            jl      @@short_loop

        ; debug:
        ; push    dx
        ; mov     ax, 0900h
        ; mov     dx, offset endl
        ; int     21h 
        ; pop     dx

        cmp     cx, 0

        jne     @@return


      @@unknown_option:

        push    dx

        mov     ax, 0900h
        mov     dx, offset sUnknownOption
        int     21h

        pop     dx
        mov     ax, 0200h
        int     21h

        mov     ax, 0900h
        mov     dx, offset endl
        int     21h

        jmp     @@return


    @@return1:
        jmp @@return

    ;=============
    @@invoke_long:

        xor     cx, cx
        mov     bx, offset commands

        @@long_loop:
            mov dx, offset bx.longname

            call cmdWithStrCompare
            cmp ax, 0
            jne @@continue_long

            ; payload here

            ; in bx -- pointer onto selected command 
            call invoke_command

            ; debug
            ; mov ax, 0900h
            ; int 21h

            inc cx

            @@continue_long:

            add     bx, size TCOMMAND
            cmp     bx, offset commandsEnd
            jl      @@long_loop

        cmp     cx, 0
        jne     @@alright


        mov     ax, 0900h
        mov     dx, offset sUnknownOptionLong
        int     21h

        mov     dx, offset cmdBuffer
        int     21h

        mov     ax, 0900h
        mov     dx, offset endl
        int     21h     

        jmp @@done
        @@alright:

        ; mov     ax, 0900h
        ; mov     dx, offset endl
        ; int     21h     

        @@done:

        mov     bx, offset cmdBuffer
        xor cx, cx
        @@clear_loop:
            mov     byte ptr [bx], 00h
            inc bx
            inc cx

            cmp cx, [cmdCounter]
            jle @@clear_loop



        mov     [cmdCounter], 0

        jmp     @@return

    ;=============

    @@return:
        ret


cmdWithStrCompare:
; dx - pointer to string 1
; offset cmdBuffer - pointer to string 2
; cmdCounter - pointer to length of comparation 
    push    bx cx si

    xor     cx, cx
    mov     si, dx
    mov     bx, offset cmdBuffer

    @@loop:
        mov     al, byte ptr [si]
        mov     ah, byte ptr [bx]
        cmp     ah, al

        jne     @@not_equal

        inc     cx
        inc     si
        inc     bx
        cmp     cx, [cmdCounter]
        jl      @@loop

    @@equal:

    ; mov     ax, 0900h
    ; int     21h
    mov     ax, 0000h

    jmp     @@return
    @@not_equal:

    mov     ax, 0001h


    @@return:
    pop     si cx bx
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



end start

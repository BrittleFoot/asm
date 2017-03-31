

;================================TSR=================================
newInt2F:

        cmp     ah, cs:[fFunction]
        jne     tsrRefuse

        cmp     al, fCheck
        je      tsrDoCheck

        cmp     al, fIdentify
        je      tsrDoIdentify

        cmp     al, fGetSegmentAddr
        je      tsrDoGetSegmentAddr

        jmp     tsrRefuse

    tsrDoCheck:
        mov     al, 0FFh
        jmp     tsrReturn

    tsrDoIdentify:
        cmp     dx, CONFORMATION
        jne     tsrRefuse

        sub     dx, 0A00h
        jmp     tsrReturn

    tsrDoGetSegmentAddr:
        mov     ax, cs
        mov     es, ax
        mov     bx, offset oldInt2F
        jmp tsrReturn

    tsrReturn:
        iret    

    tsrRefuse:
        jmp     cs:[oldInt2F]



oldInt2F    label   dword
int2F_off   dw      0000h
int2F_seg   dw      0000h

fFunction   db  ?

fCheck          = 00h
fIdentify       = 24h
fGetSegmentAddr = 80h

CONFORMATION    = 05A5Ah
UPPER_BOUND     = 005Ah

;=============================TSR=ENDS===============================


;===========================INSTALLATION=============================
hInstall proc near
    push    bp
    mov     bp, sp
    push    ax bx cx dx es
    ;------------------------------


        mov     ax, 0900h
        mov     dx, offset sCheking
        int     21h
        
        call    check_installed
        test    ax, ax
        jnz     already_installed_error

        push    ax
        mov     ax, 0900h
        mov     dx, offset sSelecting
        int     21h
        pop     ax

        call    select_free_id
        test    ax, ax
        jz      no_free_id_error

        ;\
        mov     byte ptr [fFunction], ah 
        ;/


    set_IVector:
        mov     ax, 352Fh
        int     21h

        mov     word ptr cs:[int2F_off], bx    
        mov     word ptr cs:[int2F_seg], es    

        mov     ax, 252Fh
        mov     dx, offset newInt2F
        int     21h 

        mov     ax, 0900h
        mov     dx, offset sInstalled
        int     21h

        mov     dx, offset hInstall + 1
        int     27h


    no_free_id_error:
        mov     ax, 0900h
        mov     dx, offset sNoFreeId
        int     21h
        mov     ax, 4C00h
        int     21h
        jmp     hInstal_return

    already_installed_error:
        mov     ax, 0900h
        mov     dx, offset sAlreadyInstalled
        int     21h
        mov     ax, 4C00h
        int     21h
        jmp     hInstal_return

    ;------------------------------
    hInstal_return:
    pop     es cx dx bx ax
    mov     sp, bp
    pop     bp
    ret
hInstall endp


sInstalled  db  "Resident installed!", 0Dh, 0Ah, 24h
sNoFreeId   db  "No free id to setup. Excuse me, plz :c", 0Dh, 0Ah, 24h
sAlreadyInstalled:
            db  "This resident is already installed c:", 0Dh, 0Ah, 24h
sCheking    db  "Checking installed...", 0Dh, 0Ah, 24h
sSelecting  db  "Selecting identity...", 0Dh, 0Ah, 24h


select_free_id:
        ; returns: ah = ID, if ID is found, ax = 0 otherwise

        ;           function:uId
        mov     cx, UPPER_BOUND
    @@select_id_loop:
        xor     ax, ax            ; loop over all IDs
        mov     ah, cl
        int     2Fh
        test    al, al            ; if ok to install (al = 0), return this
        jz      @@select_id_finish
        dec     cx
        jnz     @@select_id_loop
        xor     ax, ax            ; if not ok for all, return 0
    @@select_id_finish:
        ret


check_installed:

    mov     cx, UPPER_BOUND
    @@check_loop:
        mov     al, fIdentify
        mov     ah, cl
        mov     dx, CONFORMATION
        int     2Fh
        cmp     dx, 505Ah
        je      @@foud_yourself
        dec     cx
        jnz     @@check_loop
        xor     ax, ax            ; if not ok for all, return 0

    @@foud_yourself:
    ; in al place of installation now.
    ret


;=========================INSTALLATION=ENDS==========================


hUninstall proc near
    push    bp
    mov     bp, sp
    push    ax bx cx dx
    ;------------------------------

    call    check_installed
    test    ax, ax
    jz      @@not_installed_error

    call    check_it_on_top_of_stack
    test    ax, ax
    jz      @@not_on_top_of_stack_error

    call    uninstall
    mov     ax, 4C00h
    int     21h

    @@not_on_top_of_stack_error:
        mov     ax, 0900h
        mov     dx, offset sUninstalationNotAvailable
        int     21h
        mov     ax, 4C00h
        int     21h
        jmp     @@return

    @@not_installed_error:

        mov     ax, 0900h
        mov     dx, offset sNotInstalled
        int     21h
        mov     ax, 4C00h
        int     21h
        jmp     @@return


    @@return:
    ;------------------------------
    pop     cx dx bx ax
    mov     sp, bp
    pop     bp
    ret
hUninstall endp



hUI_Forced proc near
    push bp
    mov bp, sp
    push ax bx cx dx
    ;------------------------------

    call    check_installed
    test    ax, ax
    jz      @@not_installed_error

    call uninstall
    mov     ax, 4C00h
    int     21h

    @@not_installed_error:
        mov     ax, 0900h
        mov     dx, offset sNotInstalled
        int     21h
        mov     ax, 4C00h
        int     21h
        jmp     @@return
    
    ;------------------------------
    @@return:
    pop cx dx bx ax
    mov sp, bp
    pop bp
    ret
hUI_Forced endp



sNotInstalled   db "Resident is not installed yet", 0Dh, 0Ah, 24h
sUninstalationNotAvailable:
                db "Uninstalation may cause errors. ", 0Dh, 0Ah
                db "Use -U to forced uninstalation.", 0Dh, 0Ah, 24h


check_it_on_top_of_stack:

    
    push ax dx
    mov ax, ax
    mov ax, 0200h
    int 21h
    pop dx ax


    push ax
    mov al, fGetSegmentAddr
    int 2Fh
    ; es - segment adress
    mov cx, es

    push ax
    mov ax, 352Fh
    int 21h
    pop ax
    ; es - segment adress
    ; bx - offset

    mov dx, es


    cmp dx, cx ; does segments match?
    jne @@not_on_top

    cmp bx, offset newInt2F ; offsets?
    jne @@not_on_top

    pop ax
    jmp @@return

    @@not_on_top:
    xor ax, ax

    @@return:
    ret


uninstall:

    push es

    mov     ah, ah
    mov     al, fGetSegmentAddr
    int     2Fh
    ; now in es - tsr segment adress

    push    ds
    lds     dx, es:[bx]
    mov     ax, 252Fh
    int     21h
    mov     ax, ds
    pop     ds

    @@mem_free:
    mov     ax, es:2Ch
    push    es
    mov     es, ax
    mov     ax, 4900h
    int     21h
    pop     es

    jc @@error_free

    mov ax, 4900h
    int 21h

    jc @@error_free

    pop     es
    mov ax, 0900h
    mov dx, offset sUninstalled
    int 21h


    ret

    @@error_free:

    mov ax, 0900h
    mov dx, offset sMemFreeError
    int 21h

    ret

sMemFreeError   db  "Memory free error", 0dh, 0ah, 24h
sUninstalled    db  "Resident uninstalled!", 0dh, 0ah, 24h


hTest proc near
    push bp
    mov bp, sp
    push ax bx cx dx
    ;------------------------------


    mov ax, 0900h
    mov dx, offset sTestMessage
    int 21h
    
    ;------------------------------
    pop cx dx bx ax
    mov sp, bp
    pop bp
    ret
hTest endp

sTestMessage db  "", 0dh, 0ah
db  "                         _", 0dh, 0ah
db  "                        _ooOoo_", 0dh, 0ah
db  "                       o8888888o", 0dh, 0ah
db  '                       88" . "88', 0dh, 0ah
db  "                       (| -_- |)", 0dh, 0ah
db  "                       O\  =  /O", 0dh, 0ah
db  "                    ____/`---'\____", 0dh, 0ah
db  "                  .'  \\|     |//  `.", 0dh, 0ah
db  "                 /  \\|||  :  |||//  \", 0dh, 0ah
db  "                /  _||||| -:- |||||_  \", 0dh, 0ah
db  "                |   | \\\  -  /'| |   |", 0dh, 0ah
db  "                | \_|  `\`---'//  |_/ |", 0dh, 0ah
db  "                \  .-\__ `-. -'__/-.  /", 0dh, 0ah
db  "              ___`. .'  /--.--\  `. .'___", 0dh, 0ah
db  "           ."" '<  `.___\_<|>_/___.' _> \"".", 0dh, 0ah
db  "          | | :  `- \`. ;`. _/; .'/ /  .' ; |", 0dh, 0ah
db  "          \  \ `-.   \_\_`. _.'_/_/  -' _.' /", 0dh, 0ah
db  "===========`-.`___`-.__\ \___  /__.-'_.'_.-'================", 0dh, 0ah, 24h


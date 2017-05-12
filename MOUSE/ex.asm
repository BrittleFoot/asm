    .model  tiny
    .code
    .386
    org     100h
    locals  @@


start:
    jmp     main


include     util.asm


main:

    call    with_mouse
    mov     ax, 4C00h
    int     21h


with_mouse:
    ; main routine
    push    ax

    call    checkPS2
    jc      NOMOUSE
    call    enablePS2
    jc      NOMOUSE
    ; -------------------

    int     16h

    ; -------------------
    call    disablePS2
    mov     ax, 0C201h          ; Reset PS2
    int     15h

    NOMOUSE:
    pop     ax
    stc
    ret

checkPS2:
    int     11h         ; get equipment list
    test    al, 3
    jz      noPS2       ; jump if PS/2-Mouse not indicated

    mov     bh,3
    mov     ax, 0C205h
    int     15h             ; initialize mouse, bh=datasize
    jc      noPS2

    mov     bh,3
    mov     ax, 0C203h
    int     15h             ; set mouse resolution bh
    jc      noPS2

    mov     ax, cs
    mov     es, ax
    mov     bx, offset PS2dummy
    mov     ax, 0C207h
    int     15h             ; mouse, es:bx=ptr to handler
    jc      noPS2

    xor     bx, bx
    mov     es, bx      ; mouse, es:bx=ptr to handler
    mov     ax, 0C207h
    int     15h
    ret

noPS2:
    stc
    ret

PS2dummy:
    retf

enablePS2:
    call disablePS2
    mov ax, cs
    mov es, ax
    mov bx, OFFSET IRQhandler
    mov ax, 0C207h  ; es:bx=ptr to handler
    int 15h
    mov bh,1        ; set mouse on
    mov ax, 0C200h
    int 15h
    ret


disablePS2:
    xor bx, bx      ; set mouse off
    mov ax, 0C200h
    int 15h
    xor bx, bx
    mov es, bx
    mov ax, 0C207h  ; es:bx=ptr to handler
    int 15h
    ret


IRQhandler:
    assume  ds:nothing,es:nothing
    cld
    push ds
    push es
    pusha

    mov ax, cs
    mov ds, ax
    mov bp, sp
    mov al, [bp+24+6]    ; buttons
    mov bl, al
    shl al, 3            ; CF=Y sign bit
    sbb ch, ch           ; signed extension 9->16 bit
    cbw                 ; extend X sign bit
    mov al, [bp+24+4]    ; AX=X movement
    mov cl, [bp+24+2]    ; CX=Y movement
    xchg bx, ax
    neg cx              ; reverse Y movement

    popa
    pop es
    pop ds
    retf



end start
code ends
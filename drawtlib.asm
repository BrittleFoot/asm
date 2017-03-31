

VMEMORY_SEGMENT = 0B800h
V_HEIGHT  db  19h
V_WIDTH   db  0h


OLD_VMODE   db  0
OLD_VPAGE   db  0

CURR_VMODE  db  0
CURR_VPAGE  db  0


draw_table:
    ; ah:al 
    mov     [CURR_VMODE], ah
    mov     [CURR_VPAGE], al

    mov     ax, 0f00h
    int     10h

    mov     [OLD_VMODE], al
    mov     [OLD_VPAGE], bh;

    mov     ah, 00h
    mov     al, [CURR_VMODE]
    int     10h

    mov     ah, 05h
    mov     al, [CURR_VPAGE]
    int     10h;

    mov     ax, 0100h
    mov     cx, 2000h
    int     10h

    mov     ax, 0f00h
    int     10h
    mov     [V_WIDTH], ah

    push    ax bx cx dx ds es di
    ;\\\\\\\\\\\\\\\\\\\\\\\\\\\

    mov     ax, VMEMORY_SEGMENT
    mov     es, ax
    xor     di, di

    cmp     V_WIDTH, 40
    jne     @@80
    mov     ax, 800h
    jmp     @@page_done
    @@80:
    mov     ax, 1000h
    
    @@page_done:
    xor     cx, cx
    mov     cl, CURR_VPAGE
    mul     cx
    mov     bx, ax


    xor     ax, ax
    mov     cx, 8
    mov     al, V_WIDTH
    mul     cl
    mov     di, ax 

    xor     cx, cx
    mov     cl, V_WIDTH
    add     di, cx
    sub     di, 20h
    add     di, bx

    call    print_info

    xor     ax, ax
    mov     cx, 10
    mov     al, V_WIDTH
    mul     cl
    mov     di, ax 
    add     di, bx

    xor     cx, cx
    mov     cl, V_WIDTH
    add     di, cx
    sub     di, 20h

    xor     bx, bx
    xor     ax, ax

    @@loop:

        push ax

        and ah, 01110111b
        test    ah, ah
        pop     ax
        jnz     @@prnt

        test    bx, bx
        jz      @@prnt

        push ax
        mov ah, 01010010b
        stosw
        pop ax
        jmp @@nxt

        @@prnt:
        ;symbol
        stosw;
        jmp @@nxt    

        @@loop1:
            jmp @@loop


        @@nxt:

        ;space
        push    ax
        mov     ax, 0020h
        stosw
        pop ax

        inc     bx
        cmp     bx, 10h
        jl      @@first
        cmp     bx, 20h
        jl      @@second
        cmp     bx, 30h
        jl      @@third
        cmp     bx, 40h
        jl      @@fourth 
        cmp     bx, 50h
        jl      @@fifth
        add     ax, 0101h
        jmp     @@color_was_chosen

        @@first:
            inc     ah
            inc     al
            jmp     @@color_was_chosen
        @@second:
            or      ah, 10000000b
            inc     al
            jmp     @@color_was_chosen
        @@third:
            mov     ah, 01011010b
            inc     al
            jmp     @@color_was_chosen
        @@fourth:
            mov     ah, 00100101b
            inc     al
            jmp     @@color_was_chosen
        @@fifth:
            mov     ah, 5fh
            inc     al 
            jmp     @@color_was_chosen

        @@color_was_chosen:

        push    ax bx cx

        mov     ax, bx  
        mov     cl, 10h
        div     cl
        cmp     ah, 0
        jne     @@continue

        xor     cx, cx
        mov     cl, V_WIDTH
        add     di, cx
        add     di, cx
        sub     di, 40h

        @@continue:

        pop     cx bx ax

        cmp     bx, 100h
        jl      @@loop1

    ;///////////////////////////

    mov     ax, 0000h
    int     16h

    pop     di es ds dx cx bx ax

    mov     ah, 00h
    mov     al, [OLD_VMODE]
    int     10h

    mov     ah, 05h
    mov     al, [OLD_VPAGE]
    int     10h;


    ret




print_info:
; assume that es:di is good for stosw
    push    ax bx


    mov     al, [CURR_VMODE]
    call    byte_to_str
    mov     vm, ax 

    mov     al, [CURR_VPAGE]
    call    byte_to_str
    mov     pg, ax

    xor     bx, bx

    @@loop:
        mov     ah, 00000010h
        mov     al, infostr[bx]
        stosw

        inc     bx
        cmp     bx, 20h
        jl      @@loop 

    pop  bx ax

    ret



infostr db  "   MODE "
vm      dw  3030h
        db  "h          PAGE "
pg      dw  3030h
        db  "h   "


byte_to_str:
;  al -> byte
;  ax <- hex symbols of this byte
    push    bx dx
    mov     ah, 0
    xor     bx, bx
    mov     bl, 10h
    div     bl

    add     ax, 3030h
    cmp     ah, 3Ah
    jl      @@1
    add     ax, 0700h

    @@1:
    cmp     al, 3Ah
    jl      @@2
    add     ax, 0007h

    @@2:

    pop bx dx
    ret

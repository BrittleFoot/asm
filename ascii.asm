
    .model  tiny
    .code
    org     100h

start:

    xor cx, cx

    print_cycle:

        test    cx, cx
        jz      continue

        mov     ax, cx
        mov     bl, 10h
        div     bl
        test    ah, ah
        jnz     continue

        line_terminate:
        mov     ax, 0Ah
        call    putchar

        continue:

        mov     ax, cx
        jmp     print
        cmp     ax, 00h     ; \0
        je      escape
        cmp     ax, 07h     ; \a
        je      escape
        cmp     ax, 08h     ; \b
        je      escape
        cmp     ax, 09h     ; \t
        je      escape
        cmp     ax, 0Ah     ; \r
        je      escape
        cmp     ax, 0Dh     ; \n
        je      escape
        cmp     ax, 1Bh     ; esc
        je      escape

        jmp     print
        escape:
        mov     ax, 02Eh

        print:
        call    putchar

        ; mov     ax, 20h
        ; call    putchar


        inc     cx
        cmp     cx, 20h
        jl      print_cycle

    mov     ax, 0Ah
    call    putchar

    mov ax, 4C00h
    int 21h


putchar:
;   ax to screen
    push    ax bx dx cx
    mov     dx, ax
    mov     ax, 0200h

    int     21h
    pop     cx dx bx ax
    ret

end start
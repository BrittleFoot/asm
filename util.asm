


parse_int proc near
; in:
;   bx -> pointer to the target string
;   dx -> length of that string
; returns:
;   ax <- integer contained in this string 
;   todo: if CF is set it means parseing error
    push    bx cx dx

    push    bp
    mov     bp, sp

    sub     sp, 4

    ; [bp-2]      - result
    ; [bp-4]    - temp digit
    mov     word ptr [bp-2], 0000h
    mov     word ptr [bp-4], 0000h

    mov cx, dx

    @@loop:
        xor dx, dx
        mov dl, byte ptr [bx]

        ; make digit from character (todo: hex-parseing?)
        sub dx, 30h
        ; todo: some error handling?

        mov word ptr [bp-4], dx

        inc bx
        dec cx

        mov ax, 10
        call pow
        mul word ptr [bp-4]
        add word ptr [bp-2], ax

        test cx, cx
        jnz @@loop

    mov     ax, [bp-2]


    mov     sp, bp
    pop     bp
    pop     dx cx bx

    ret
parse_int endp




pow proc near
; in:
;   ax - x
;   cx - n
; returns:
;   dx:ax <- x^n

    test cx, cx
    jz @@return1

    push    bx cx

    mov     bx, ax
    mov     ax, 0001h
    xor     dx, dx

    @@loop:
        mul     bx
        dec     cx
        test    cx, cx
        jnz     @@loop

    pop     cx bx
    ret

    @@return1:
    mov ax, 0001h
    xor dx, dx
    ret
pow endp
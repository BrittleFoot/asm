text segment

parse_int2:
; in -> bx - pointer to the string where 
;   [bx] - length
;   and bx+1 pointed onto string begin
    xor     dx, dx
    mov     dl, byte ptr [bx]
    inc     bx
    call    parse_int
    ret

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

    pop     dx bx
    ret


print_hex_ax:
    ; ax - target
    ; if CF is on then format HHh else format HH 
    push    dx

    mov     dx, ax
    mov     ax, 0200h
    int     21h
    xchg    dh, dl
    int     21h

    jnc     @@return
    mov     dl, 'h'
    int     21h

    @@return:
    
    pop     dx
    ret


sEndl       db  0Dh, 0Ah, 24h
put_endl:
    push    ax dx
    mov     ax, 0900h
    mov     dx, offset sEndl
    int     21h
    pop     dx ax
    ret




put_n_spaces:
;   n in ax
    test    ax, ax
    jz      @@ret

    @@loop:
        push    ax dx
        mov     ax, 0900h
        mov     dx, offset spaces
        int     21h
        pop     dx ax
        dec     ax
        test    ax, ax
        jnz     @@loop
    @@ret:
    ret

spaces  db  "  $"


text ends
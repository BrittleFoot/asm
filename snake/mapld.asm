

file_handle  dw     0
read_level proc c
;   args:
;       ds:dx - filename
;       ds:bx - offst to buffer

    mov     ah, 3DH ; open file
    mov     al, 0   ; only read
    int     21h
    jc      @@error

    mov     file_handle, ax

    mov     dx, bx  ; buffer
    mov     ah, 3Fh
    mov     bx, file_handle
    mov     cx, SCENE_WIDTH * SCENE_HEIGHT * 2
    int     21h
    jc      @@error

    jmp     @@ret
    @@error:
    mov     ax, EVENT_DEATH
    call    fire_event

    @@ret:

    ; `finaly`
    ; close file
    mov     bx, file_handle
    mov     ah, 3Eh
    int     21h

    ret
read_level endp
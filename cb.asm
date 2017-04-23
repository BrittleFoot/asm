

lastchar        db 00h
has_been_read   db 00h


write_buffer:
    ; from al
    mov     lastchar, al
    mov     has_been_read, 0
    ret

read_buffer:
    ; to al

    cmp     has_been_read, 0
    jne     @@fail

    mov     al, lastchar
    inc     has_been_read
    clc
    ret

    @@fail:
    stc
    ret
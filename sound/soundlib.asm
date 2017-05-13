PPI_CHIP_PORT       =   61h
TIMER_CONFIG_PORT   =   42h
TIMER_INIT_PORT     =   43h


;-o0o-o0o-o0o-o0o-o0o-o0o-o0o-o0o
THE_MAGIC_NUMBER    =   10110110b
;-o0o-o0o-o0o-o0o-o0o-o0o-o0o-o0o



initialize_timer macro
    mov     al, THE_MAGIC_NUMBER
    out     TIMER_INIT_PORT, al
endm initialize_timer


set_freq macro frequency_value
    push    bx
    mov     bx, frequency_value

    mov     ax, bx
    out     TIMER_CONFIG_PORT, al
    mov     al, ah
    out     TIMER_CONFIG_PORT, al
    pop     bx
endm set_freq


speaker_on macro
    in      al, PPI_CHIP_PORT   ; store initial bits
    or      al, 00000011b       ; SPEAKER_ON flag
    out     61h, al             ; turn speaker ON
endm speaker_on


speaker_off macro
    in      al, PPI_CHIP_PORT   ; store initial bits
    and     al, 11111100b       ; SPEAKER_ON flag
    out     61h, al             ; turn speaker oFF
endm speaker_off
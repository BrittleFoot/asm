
nah: ret


Timer struc

    elapsed_time        dw 0000h
    repeat_period        dw 0000h
    target_function     dw offset nah

Timer ends


timer_elapsed_time  dw 0000h
update_timer_gobal proc c uses ax bx
    mov     bx, ax

    mov     al, 0        ; фиксация значения счетчика в канале 0
    out     43h,al       ; порт 43h: управляющий регистр таймера
    ; так как этот канал инициализируется 
    ;BIOS для 16-битного чтения/записи, другие
    ; команды не требуются
    in      al,40h       ; младший байт счетчика
    mov     ah,al        ; в АН
    in      al,40h       ; старший байт счетчика в AL
    xchg    ah,al        ; поменять их местами
    neg     ax           ; обратить его знак, так как счетчик
                            ; уменьшается
    mov     timer_elapsed_time, ax
    ret
update_timer_gobal endp




update_timer proc c uses ax bx
    mov     bx, ax
    mov     ax, timer_elapsed_time
    
    add     [bx].elapsed_time, ax  ; добавить к сумме

    mov     ax, [bx].repeat_period
    cmp     [bx].elapsed_time, ax
    jb      @@skipf

    call    [bx].target_function 
    mov     [bx].elapsed_time, 0
    @@skipf:
    ret
update_timer endp


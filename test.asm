    .model tiny
    .code
    org 100h
    locals @@

start:
    jmp main


kbd_status  db 00000111b


main:
    call update_leds

    int 20h




LED_CHANGE_REQ  = 0EDh
LED_CHANGE_ACK  = 0FAh


update_leds:
     push    ax

     call    kbd_wait

     mov     al, LED_CHANGE_REQ
     out     60h, al

     call    kbd_wait

     mov     al, [kbd_status]
     out     60h, al

     call    kbd_wait

     pop     ax
     ret



;------------------;
;  keyboard wait   ;
;------------------;
kbd_wait:
        jmp @@0
@@0:    in       al, 64h
        test     al,1
        jz       @@ok
        jmp      @@1
@@1:    in       al, 60h
        jmp      kbd_wait
        @@ok:
        test     al,2
        jnz      kbd_wait
        ret


end start
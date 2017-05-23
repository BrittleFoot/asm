

empty_func: ret


Event struc 
    eid         dw 0 ; event id
    fired       dw 0
    callback    dw offset empty_func
    param1      dw 0
    param2      dw 0
Event ends


event_starts    dw 0
event_ends      dw 0


fire_event proc c uses  di
;   fires event(s) with mask ax
;   sends params in cx dx
    mov     di, event_starts

    @@loop:
        cmp     di, event_ends
        jae     @@ret

        cmp     [di].eid, ax
        jne     @@continue

        mov     [di].fired, 1
        mov     [di].param1, cx
        mov     [di].param2, dx

        @@continue:
        add     di, size Event
        jmp     @@loop

    @@ret:
    ret
fire_event endp


dispatch_events proc c uses di
;   dispatch fired event(s)
;   invoke callback with di pointed on Event object
    mov     di, event_starts

    @@loop:
        cmp     di, event_ends
        jae     @@ret

        cmp     [di].fired, 0
        je      @@continue

        push    di
        call    [di].callback
        pop     di
        mov     [di].fired, 0

        @@continue:
        add     di, size Event
        jmp     @@loop

    @@ret:
    ret
dispatch_events endp



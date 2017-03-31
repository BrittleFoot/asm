
       .model   tiny
       .code
        org     100h

start:
        jmp     installer

newint2f:
        jmp     dword ptr cs:[oldint2f] 

oldint2f  label dword
int2f_off dw    0000h
int2f_seg dw    0000h

installer:
        mov     ax, 352Fh                
        int     21h                     
                                        
        mov     word ptr cs:[int2f_off], bx 
        mov     word ptr cs:[int2f_seg], es 

        mov     ax, 252Fh                
        mov     dx, offset newint2f      
        int     21h

        mov     es, word ptr cs:[int2f_seg]
        mov     bx, word ptr cs:[int2f_off]
        call    print_adress

        mov     ax, cs
        mov     es, ax
        mov     bx, offset newint2f
        call    print_adress


        ; сделаем программу резидентом.
        mov     dx, offset installer+1   
        int     27h

print_adress:
    
    mov ax, es
    call print_ax

    mov ah, 02h
    mov dl, 3Ah
    int 21h

    mov ax, bx
    call print_ax

    mov ah, 02h
    mov dl, 0Ah
    int 21h

    ret


print_ax:
    
    mov ax, ax
    mov bx, offset sbuffer + 3
    @loop:

        mov dx, 0
        mov cx, 10h
        div cx

        ; al - div
        ; ah - mod
        add dx, 30h
        cmp dx, 39h

        jle @digit
            add dx, 7

        @digit:


        mov [bx], dl
        dec bx

        cmp bx, offset sbuffer - 1

        jne @loop

    mov ah, 09h
    mov dx, offset sbuffer
    int 21h
    ret


divider     db  10h
sbuffer     db  0,0,0,0,'$'
sbend:






end      start

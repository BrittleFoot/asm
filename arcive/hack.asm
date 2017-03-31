code    segment                          
        assume  cs:code,ds:code          
        org     100h                     

start:  jmp     load                     
          
end_resident_things:                            

load:   
        ; find environment adress
        mov bx, 002ch
        mov ax, [bx]

        ; free eovironment segment
        mov es, ax
        mov ah, 49h
        int 21h

        ; acquire some memory space
        mov ah, 48h
        mov bx, 5
        int 21h        

        jc error

        ; set new memory as program`s own environment
        mov bx, 002ch
        mov [bx], ax

        ; fill the environment
        mov es, ax
        xor di, di
        xor bx, bx

        @@1:
            mov al, newname[bx]
            inc bx
            mov ah, newname[bx]
            inc bx
            stosw
            cmp bx, nen - newname
            jl @@1


        jmp stay_resident
        ; yeah ^

    error:

        int 20h


    stay_resident:

        mov     ax,  3100h               
        mov     dx, (end_resident_things - start + 10Fh) / 16 
        int     21h                      

        newname db 'P', 0, 0, 1, 0, 'C:\E\KERNEL_SECURITY_SERVICE.COM ', 0
        nen:

code    ends                             
end     start                    
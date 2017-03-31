code    segment                          
        assume  cs:code,ds:code          
        org     100h                     

start:  jmp     onload                     
          
end_resident_things:                            

onload: 


    
    stay_resident_27h:

    


    stay_resident_21h:

        mov     ax,  3100h               
        mov     dx, (end_resident_things - start + 10Fh) / 16 
        int     21h                      

        nen:



code    ends                             
end     start                    
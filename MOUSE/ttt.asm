    .model  tiny
    .code
    org     100h

start:

    call main
    int 20h


main proc c uses ax bx cx dx
    ret
main endp




end start
code ends
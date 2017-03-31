; This program will check if it's already in memory, and then it'll show us a
; stupid message. If not, it'll install and show another msg.
; Эта программа будет проверять, находиться ли она уже в памяти, и показывать
; глупое сообщение, если это так. В противном случае она будет инсталлировать
; в память и показывать другое сообщение.

       .model   tiny
       .code
        org     100h

start:
        jmp     fuck

newint21:
        cmp     ax,0ACDCh               ; Пользователь вызывает нашу функцию?
        je      is_check                ; Если да, отвечаем на вызов
        jmp     dword ptr cs:[oldint21] ; Или переходим на исходный int21

is_check:
        mov     ax,0DEADh               ; Мы отвечаем на звонок
        iret                            ; И принуждаем прерывание возвратиться

oldint21  label dword
int21_off dw    0000h
int21_seg dw    0000h

fuck:
        mov     ax,0ACDCh               ; Проверка на резидентность
        int     21h                     ;
        cmp     ax,0DEADh               ; Мы здесь?
        je      stupid_yes              ; Если да, показываем сообщение 2

        mov     ax,3521h                ; Если, инсталлируем программу
        int     21h                     ; Функция, чтобы получить векторы
                                        ; INT 21h
        mov     word ptr cs:[int21_off],bx ; Мы сохраняем смещение в oldint21+0
        mov     word ptr cs:[int21_seg],es ; Мы сохраняем сегмент в oldint21+2

        mov     ax,2521h                ; Функция для помещения нового
                                        ; обработчика int21
        mov     dx,offset newint21      ; где он находится
        int     21h

        mov     ax,0900h                ; Показываем сообщение 1
        mov     dx,offset msg_installed
        int     21h

        mov     dx,offset fuck+1        ; Делаем резидент от смещения 0 до
        int     27h                     ; смещения в dx используя int 27h
                                        ; Это также прервет программу

stupid_yes:
        mov     ax,0900h                ; Показываем сообщение 2
        mov     dx,offset msg_already
        int     21h
        int     20h                     ; Прерываем программу.

msg_installed db "Stupid resident is not installed. Installing...$"
msg_already   db "Stupid resident is alive! And it's kicking your ass!$"

end      start

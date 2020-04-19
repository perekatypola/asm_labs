.model	small
.stack	100h
.386
.data
  
  quitmsg db 39 , "Thanks for playing! hope you enjoyed it!$",0
  scoremsg db 6 , "Score:" , 0
  gameovermsg db 10 , "Game Over!"
  instructions db 0AH,0DH,"Use a, s, d and w to control your snake",0AH,0DH,"Use q to quit",0DH,0AH, "Press any key to continue$"
  
  four equ 4
  one equ 1
  three equ 3
  left equ 0
  top equ 2
  row equ 15
  col equ 40
  right equ left+col
  bottom equ top+row
  
  temp db 0
  temp_score db 0
  null db '0'
  flag db 0
  score db 0
  score_len db 0
  quit db 0  
  gameover db 0
  head_start_x equ left+3
  head_start_y equ top+3
  body_start_x equ left+2
  body_start_y equ top+3
  
  max_length equ  3*row
 
  up_head equ '^'
  down_head equ 'v'
  left_head equ '<'
  right_head equ '>'
  
  head db right_head
  real_len dw 3
  snake db head_start_x , head_start_y , body_start_x , body_start_y  , body_start_x - 1,  body_start_y , 60 dup(0)

  fruit_x db , 0
  fruit_y db , 0
  fruitactive db 0
  

  delaytime db 10


 

.code

getTicks MACRO
	push ax 

	mov ax, 00h
	int 1Ah

	pop ax
ENDM 



main proc ;far

	mov ax, @data	;init
	mov ds, ax


	mov ax, 0b800H ; устанавливаем на адрес начала видеопамяти
	mov es, ax

        ;очистка экрана
	mov ax, 0003H
	int 10h
   
      call hello ; вывод приветственного сообщения
    
      call printbox 

game:
  
  call move_snake
  call keyboard
  cmp quit , 1
  je quitpressed
  call score_out
  call draw_snake

jmp game


quitpressed:
    mov ax, 0003H
	int 10H    
    mov delaytime, 50
    xor dx , dx
    lea bx, quitmsg
    call write_string
    call sleep    
    jmp quit_

game_over:
    mov ax, 0003H
	int 10H    
    mov delaytime, 50
    xor dx , dx
    lea bx, gameovermsg
    call write_string
    call sleep    
    jmp quit_

quit_:
mov ax, 0003H
int 10h    
mov ax, 4c00h
int 21h
   
   


printbox proc
;Draw a box around
    mov dh, top
    mov dl, left
    mov cx, col
   
    mov bl, '#'
l1:                 
    call drawcharat
    inc dl
    loop l1
    
    mov cx, row
l2:
    call drawcharat
    inc dh
    loop l2
    
    mov cx, col
l3:
    call drawcharat
    dec dl
    loop l3

    mov cx, row     
l4:
    call drawcharat    
    dec dh 
    loop l4    
    
    ret
printbox endp


drawcharat proc

  push cx
  push ax
  push bx
 
  xor ax , ax
  xor bx , bx

  mov ax , dx ; запоминаем в регистр значения и текущего столбца, и строки
  and ax , 0FF00h ; накладываем маску
  ;  получаем строку (старшую часть dx)
  xor cx , cx
  mov cl , 8
  shr  ax , cl ; сдвиг вправо 8 раз, чтобы получить в регистре ax номер текущей строки для вывода
  
  mov ch , 160
  mul ch ;  умножаем количество возможных байтов, помещающихся в экран на количество строк, предшествующих нужной

  mov bx , dx
  and bx , 00FFh ; накладываем маску для получения значения младшего байта регистра(столбец)
  shl bx , 1 ; умножаем на 2, чтобы записывать в нужный байт экрана(не задающий цвет) сдвигом влево
  add ax , bx
  
  mov di, ax

  pop bx   
  mov es:[di],  bl ; запись символа в нужный байт 
 

pop ax
pop cx

ret
drawcharat endp

readcharat proc

  push cx
  push ax
 
 
  xor ax, ax
  xor bx , bx
  mov ax , dx ; запоминаем в регистр значения и текущего столбца, и строки
  and ax , 0FF00h ; накладываем маску
  ;  получаем строку (старшую часть dx)
  xor cx , cx
  mov cl , 8
  shr  ax , cl ; сдвиг вправо 8 раз, чтобы получить в регистре ax номер текущей строки для вывода
  
  mov ch , 160
  mul ch ;  умножаем количество возможных байтов, помещающихся в экран на количество строк, предшествующих нужной

  mov bx , dx
  and bx , 00FFh ; накладываем маску для получения значения младшего байта регистра(столбец)
  shl bx , 1 ; умножаем на 2, чтобы читать нужный байт экрана(не задающий цвет) сдвигом влево
  add ax , bx
  
  mov di, ax

 
  mov bl,es:[di] ; запись нужного байта  
 
pop ax
pop cx
ret
readcharat endp



random_fruit proc


st_rand:
 push ax
 push bx
 push cx
 push dx
 
st_rand_:

cmp fruitactive , 1
je draw_on_same_pos

 getTicks
 mov bx , dx
 and bx , 00FFh

 push bx

 xor dx , dx
 xor cx , cx
 

 cmp bx , col ; сравниваем с максимальным количеством столбцов в окне
 jb add_x
 mov cl , 3
 shr bl , cl ; если число больше нужного - делим на 8 сдвигом
 cmp bl , col
 je st_rand

add_x:
 
  mov dl , bl
  add dl , 1
  mov fruit_x , dl


  xor bx , bx
  pop bx

  cmp bx , row ; сравниваем с максимальным количеством строк в окне
  jb add_y
  mov cl , 4
  shr bx , cl; еслі число больше, делим на 16 сдвигом
  cmp bl , row
  je st_rand

add_y:
 
  mov dh , bl
  add dh , top
  mov fruit_y , dh
  
  call readcharat
  cmp bl , '#'
  je st_rand
  cmp bl , '*' ; проверяем пустое ли место
  je st_rand
  cmp bl , '<'
  je st_rand
  cmp bl , '>'
  je st_rand
  cmp bl , '^'
  je st_rand
  cmp bl , 'v'
  je st_rand
  mov fruitactive , 1

draw:
  xor bx , bx
  mov bl , 40h ; символическое обозначение фрукта - @
  call drawcharat
  jmp end_draw

draw_on_same_pos:
  mov dh , fruit_y
  mov dl , fruit_x
  jmp draw
 
end_draw:
 pop dx
 pop cx
 pop bx
 pop ax

  ret

random_fruit endp


sleep proc 
  
  push bx
  push dx
    
    getTicks
    mov bx, dx ; запоминаем начальное значение тиков в bx
    
delay:
    getTicks
    sub dx, bx ; отнимаем от изначального значения тиков текущее
    cmp dl, delaytime ; сравниваем младший бит после вычитания с нунжной задержкой                                                 
    jl delay; если нужное значение еще не достигнуто, повторяем 
   
  pop dx
  pop bx
    
  ret
    
sleep endp


setcurs proc
    push bx
    push ax

    mov ah, 02H ; устанавливает на dh строку dl столбец
    mov bh,0 ;  
    int 10h

    pop ax
    pop bx

    ret
setcurs endp

draw_snake proc

  push di
  call sleep
  pop di

  mov ax, 0003H
  int 10h

  push di
  call printbox
  pop di

  push di
  call random_fruit
  pop di

xor dx , dx
xor cx , cx

draw_head:

 xor dx , dx
 mov bl , head
 mov dl , [snake]
 mov dh , [snake+1]
 push di
  
 call drawcharat

 pop di

mov cx , real_len

xor dx , dx
mov di , 2
draw_loop:

  mov bl , '*'
  mov dl , [snake+di]
  inc di
  mov dh , [snake+di]

con:
  
  inc di
  push di
  
  call drawcharat

  pop di

loop draw_loop

ret

draw_snake endp



move_snake proc
  xor ax , ax
  xor bx , bx
   
   mov dl , [snake]
   mov dh , [snake+1]
   push di
   call readcharat
   pop di
   cmp bl , '*' ; проверяем, не съела ли змея сама себя
   je game_over
   
   mov ah , [snake]
   cmp fruit_x , ah
   jne change_body

check_y:
   mov ah , [snake+1]
   cmp fruit_y , ah
   je make_larger; сравниваем байт по кооридинатам головы с фруктом

 change_body:  
   mov cx , real_len
   sub cx , 1
  ; цикл для передвижения змейки
   loop_:
   
   mov bx , 2
   mov ax , cx
   mul bx
   mov di , ax
   mov ax , cx
   dec ax 
   mul bx
   mov si , ax
   
   
   xor ax , ax
   mov al , [snake+si]
   mov [snake+di] , al
   mov al , [snake+si +1]
   mov [snake+di+1] , al
   
   dec cx
   cmp cx , 0

   jne loop_
    

  xor bx , bx


 if_up:
   
   cmp head , up_head
   jne if_down

   mov dl , [snake] ; запоминаем координату головы по y
   mov ah , [snake+1]
   sub ah , 1
   cmp ah , top
   je reset_up_head
   mov [snake+1] , ah
   mov dh , [snake+1]
   ret
 
   
if_down:
    
   cmp head , down_head
   jne if_left
   
   mov dl , [snake]

   mov ah , [snake+1]
   add ah , 1
   cmp ah , row + top
   je reset_head_down
   mov [snake+1] , ah
   mov dh , [snake+1] 
   
   ret

   
   if_left:
    
   cmp head , left_head
   jne if_right

    mov ah , [snake] 
    sub ah , 1           ; передвижение по x вперед
 
    mov [snake] , ah
    cmp ah , left
    je reset_head_left
    mov dl , [snake] ; текущий cтолбец
    mov dh , [snake+1] 
  
    ret

 if_right:

    mov ah , [snake] 
    add ah , 1           ; передвижение по x вперед
    mov [snake] , ah
    cmp ah , col
    je reset_head_right
    mov dl , [snake] ; текущий cтолбец
    mov dh , [snake+1] ; текущая строка

 ret


  reset_up_head:
    
    mov [snake+1] , row + top - 1
    ret
  
  reset_head_down:

    mov [snake+1] , top + 1
    ret

   reset_head_right:

    mov [snake] , 1
    ret
  reset_head_left:

    mov [snake] , col-1
    ret

  make_larger:
   
  add real_len , 1
  mov fruitactive , 0
  add score , 1
  
  call speed_up
 
  jmp change_body


   
move_snake endp

speed_up proc

push ax
push dx
push bx
 xor ax , ax
 xor dx , dx
 mov al , score 
 mov bx , 3
 div bx
 cmp dx , 0
 je change_speed
 jmp end_speed
; если счет игры делится на 3 нацело - уменьшаем время задержки
change_speed:

  cmp delaytime , four
  je change_body
  sub delaytime , one

end_speed:
 pop bx
 pop dx
 pop ax
 ret
speed_up endp 

score_out proc
  
  push bx
  push dx
  push ax
  
  
  lea bx , scoremsg

  push di
  call write_string
  pop di

 xor ax , ax
 mov al , score
 mov temp_score , al 
 mov temp , col
 mov cl , 0

 xor ax , ax
 write_num:
  
  xor dx , dx
  
  mov al , temp_score
  mov bx , 10
  div bx
  mov temp_score , al
  add dl , null

  mov bl , dl
  
  mov dl , temp
  sub dl , cl
  mov temp , dl
  mov dh , 0
 
  call drawcharat
 
  inc cl

  mov al , temp_score
  cmp al , 0
  jne write_num

  pop ax
  pop dx
  pop bx

  ret
score_out endp

read_from_buf proc

   mov ah, 01H
    int 16H
    jnz key_pressed
    xor dl, dl
    ret
key_pressed:
 
    mov ah, 00H
    int 16H
    mov dl,al
    ret
read_from_buf endp


keyboard proc

  call read_from_buf
  cmp dl , 0 
  je check_q
  cmp al , 'w'
  jne check_d
  cmp head , down_head
  je check_q
  mov head , up_head
  ret
check_d:
  cmp al , 's'
  jne check_r
  cmp head , up_head
  je check_q
  mov head , down_head
  ret
check_r:
  cmp al , 'd'
  jne check_l
  cmp head , left_head
  je check_q
  mov head , right_head
  ret
check_l:
  cmp al , 'a'
  jne check_q
  cmp head , right_head
  je check_q
  mov head ,left_head
  ret
check_q:
  cmp al , 'q'
  je quit_keyboard
  ret
quit_keyboard:
  mov quit , 1
  ret
  
keyboard endp

write_string proc

push ax
push dx
push di

mov dl , col - 15


xor ax  , ax
mov cl , [bx]
inc bx


and dx , 00FFh
shl dx , 1
mov di , dx

write_loop:

mov al , [bx]
mov es:[di] , al

inc bx
inc di
inc di
dec cx
cmp cx , 0
jne write_loop

pop di
pop dx
pop ax

ret

write_string endp 

hello proc

mov dl , 1
mov dh , 0
call setcurs

lea dx, instructions
mov ah, 09H
int 21h

mov ah, 07h
int 21h

mov ax, 0003H
int 10h

ret
hello endp   

main endp 
end main

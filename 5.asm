.model small

.stack 100h
.386
.data	  

max_length	           equ 30

startProcessing            db "Working with files started", '$'			
startText	           db  "Program is started", '$'
startReverse               db  "Start reverse output", '$'
badCMDArgsMessage          db  "Bad command-line arguments.", '$'
badSourceText	           db  "Open error", '$'    
fileNotFoundText           db  "No such file", '$'
FileIs			   db  "File already exists"
endText 	               db  0Dh,0Ah,"Program is ended", '$'
errorReadSourceText        db  "Error reading from file", '$'
errorClosingSource         db  "Cannot close file", '$'
emptyFileMsg               db  "File is empty", '$'

destinationPath            db 'output.txt', 0h

destinationPath2           db 'output.txt', 0h

destinationPlate           db "output.txt" , '$'
extension	           db "txt"	     
point2		           db '.'
buf		           db 1025 dup(?)
	
sourceLen db , 0
destLen db , 0	 
sourceID	           dw  0
destinationID              dw  0	

string		           db  0Dh, 0Ah
number		           dw  0
spaces                     dw  0     
array_positions            dw  max_length dup (?) 

cmd_len	               	   db  ?

sourcePath	           db  129 dup (0) 
tempSourcePath	           db  129 dup (0)					


cmd_text	           db  129 dup(0)	
		   
three equ 3

check_last 			db 0
forLoop    			dw 0
temp_size  			dw 0
pos 				dw 0
temp_pos 			dw 0
long_pos 			dw 0
symb 				db 0
lastSymb 			db 0
size_ 				dw 0
isLastSym 			db 0 
error 				dw 0

.code

printString macro info	    ;вывод на экран заданной строки
	push ax 		
	push dx 		
			    
	mov ah, 09h		    ; Команда вывода 
	lea dx, info		; Загрузка в dx смещения выводимого сообщения
	int 21h 		    ; Вызов прервывания для выполнения вывода
			    
	mov dl, 0Ah		    ; Символ перехода на новую строку
	mov ah, 02h		    ; Команда вывода символа
	int 21h 		    ; Вызов прерывания
			    
	mov dl, 0Dh		    ; Символ перехода в начало строки   
	mov ah, 02h		
	int 21h 		     
			    
	pop dx			
	pop ax			
endm

fseek macro ID   ; перемещение курсора(позиции) в файле 
	push ax 		    
	push bx 		    
	push cx 		    
	push dx 		                  ; Сохраняем значения регистров
				
	mov ah, 42h		                  ; Записываем в ah код 42h - ф-ция DOS уставноки указателя файла 
	mov bx, ID                        ; Дескриптор файла
	xor al ,al				  
	mov al, 01h	              ; al - с начала, с конца или с текущей позиции
	mov cx, 1
	neg cx		                  ; Обнуляем cx
	mov dx, size_ 	
	neg dx	          ; Обнуляем dx, т.е премещаем указатель на 0 символов от начала файла (cx*2^16)+dx 
	int 21h 		                  ; Вызываем прерывания DOS для исполнения кодманды	
				
	pop dx			                  ; Восстанавливаем значения регистров и выходим из процедуры
	pop cx			   
	pop bx			    
	pop ax			    
endm

strcpy macro destination, source, count   ; Макрос, предназначенный для копирования из source в destination заданное количество символов
    push cx
    push di
    push si
    
    xor cx, cx
    
    mov cl, count
    lea si, source
    lea di, destination
    
    rep movsb
    
    pop si
    pop di
    pop cx

endm

main proc
	    mov ax, @data		    ; Загружаем данные
	    mov es, ax	
			    
	    xor ch, ch	
	    mov cl, ds:[80h]		; Количество символов строки, переданной через командную строку
	    mov bl, cl
	    mov cmd_len, cl		; В cmd_len загружаем длину командной строки
	    dec bl			        ; Уменьшаем значение количества символов в строке на 1, т.к. первый символ пробел
	    mov si, 81h		        ; Смещение на параметр, переданный через командную строки
	    lea di, tempSourcePath	      
	
	    rep movsb		        ; Записать в ячейку адресом ES:DI байт из ячейки DS:SI
		
	    mov ds, ax		        ; Загружаем в ds данные  
	    mov cmd_len, bl	
	
            mov cl, bl
	    lea di, cmd_text
	    lea si, tempSourcePath
	    inc si
	    rep movsb
				
	    printString startText	    ; Вывод строки о начале работы программы
			    
	    call processCMD		    ; Вызов обработки данных из командной строки
	    cmp error, 0		
	    jne endMain				; Если error != 0, т.е. при выполении процедуры произошла ошибка - завершаем программу   
	
	    call openFiles		    ; Вызываем процедуру, которая открывает файл, переданный через командную строку
	    cmp error, 0		
	    jne endMain	
	

	    	
	    call workWithFile  
            printString endText
             			
	   
    mov ah, 3Eh
    mov bx, sourceID
    int 21h

    mov ah, 3Eh
    mov bx, destinationID
    int 21h
		
    endMain:

	    mov ah, 4Ch		
	    int 21h      
		   
workWithFile proc 


    printString startProcessing
	 
begin:
	
 	xor si, si
	xor di, di 
	xor bx, bx  
	xor ax , ax
	xor bx , bx


        call readFromFile
	

checkEnd:

;проверяем, если достигнут конец файла или если строка длиной 1024

	cmp check_last , 1
	je set	
	
	cmp isLastSym  , 1
	je set

        xor di , di
	mov cx, forLoop ;заносим переменную для цикла в cx
	mov si , size_
	sub si , three
	jmp reverse
set:
	xor di , di
	mov cx, forLoop
	mov si , size_
	sub si , 1

reverse:

	xor dx, dx
	mov dl, [buf+di]     ;меняем местами символы строки
	mov dh, [buf+si]
	mov [buf+di], dh
	mov [buf+si], dl
	inc di            ;передвигаем индекс начала дальше
	dec si  	
	dec cx
	cmp cx , 0
	jne reverse
       
	      
writeToFile:

	xor ax , ax
	xor dx , dx
	xor bx , bx

	mov dl , '.'
	mov ah , 02h
	int 21h

	fseek sourceID
	
	lea dx , buf
	mov ah , 40h
        mov bx , sourceID
	xor cx, cx
        mov cx , size_
	int 21h
	
	cmp check_last , 1
	je end_
	; обнуляем буфер
	cld
	lea di, buf
	mov cx, size_
	sub al, al ;обнуляем записываемый байт 
	repne stosb ;

	mov size_ , 0

	jmp begin
	
	

end_:
	ret

workWithFile endp 
	
readFromFile proc

        push di
        push bx
        push dx
        push cx
	push si

        xor di , di 

get_length:
	
        xor dx, dx
	
	
        mov ah, 3Fh  ; Загружаем в ah код 3Fh - код ф-ции чтения из файла
	mov bx, sourceID  ; В bx загружаем ID файла, из которого собираемся считывать
	mov cx, 1	 ; В cx загружаем количество считываемых символов
	lea dx, symb
	int 21h 
	cmp ax , cx; проверяем, что достигнут конец файла
	jne set_last_size

	mov dl , symb
	
	mov [buf+di] , dl ; Запоминаем в строку полученный символ

        cmp dl, 0Ah
        je set_size
	cmp dl , 00h
	je set_size
	cmp dl , 0Dh
	je set_size
	inc di			      
	
	cmp di , 1025
	je isLast  ; если количество символов в строке максимально - тогда устанавливаем соответств. размер
	jmp get_length
	
	jnb successfullyRead	    ; Если ошибок во время счтения не произошло - прыгаем в goodRead
	
	printString errorReadSourceText	; Иначе выводим сообщение об ошибке чтения из файла
	mov ax, 0			
	    
    successfullyRead:
	pop si
        pop cx
        pop dx			       
	pop bx 
        pop di				      
	ret

isLast:
	
	xor dx, dx
	mov size_ , di
	mov ax , size_
	mov bl , 2
	div bx
      	mov isLastSym , 1
	mov forLoop , ax ; колічество повтореній

	jmp successfullyRead 
	

set_size:

	xor cx , cx
 	xor ax , ax
	xor bx , bx
	xor dx , dx
	xor si , si

	
	mov size_ , di    ; запоминаем текущий индекс строки как размер 
	

	mov ah, 3Fh     ; считываем энтер, чтобы перейти к следующей строке
	mov bx, sourceID		    
	mov cx, 1			       
	lea dx, symb
	int 21h 
	add di , 1 

	mov [buf+di] , 0Ah ; запись энтера
	
	

	mov si , size_ 
	mov ax , si ; 
	sub si , 1   ;получение индекса последнего знаащего символа(до каретки и энтера)
	
	add size_ , 1; размер вместе с энтером и переносом каретки
	add size_ , 1

	xor dx, dx
	xor di , di
  	
	mov bl , 2
	div bx
      
	mov forLoop , ax ; количество повторений

	jmp successfullyRead 

;если считали последнюю строку 
set_last_size:

	xor dx, dx
	mov size_ , di
	mov ax , size_ ;
	mov bl , 2
	div bx
        mov check_last , 1
	mov forLoop , ax ; колічество повтореній

	jmp successfullyRead 

	   
readFromFile endp

	
processCMD proc
        xor ax, ax
        xor cx, cx
    
        cmp cmd_len, 0		        ; Если параметр не был передан, то переходим в notFound 
        je notFound
        cmp cmd_len , 10
        jne ok

xor di , di

ok:
  	xor ax, ax
        xor cx, cx

  	mov cl, cmd_len
    	lea di, cmd_text   ; устанавливаем на смещение cmd_text di
	
	
        mov cl, cmd_len
    
        lea di, cmd_text   ; устанавливаем на смещение cmd_text di
        mov al, cmd_len ; в al - длина
        add di, ax  ; переходим в конец строки, содержащейся в cmd_text
        dec di
    
    findPoint:  ; Ищем точку с конца строки, т.к. после неё идет раcширение файла
        mov al, '.'
        mov bl, [di]
        cmp al, bl
        je pointFound
        dec di
        loop findPoint
    
    notFound:			            ; Если точка не найдена выводим badCMDArgsMessage и завершаем программу
        printString badCMDArgsMessage
        mov error, 1
    ret
    
    pointFound:  ; Количество символов должно быть равно 3, т.к. "txt", если отлично от этого => файл не подходит
        mov al, cmd_len ;вычитаем из длины текущую позицию
        sub ax, cx
        cmp ax, 3  
        jne notFound    
    
        xor ax, ax
        lea di, cmd_text
        lea si, extension
        add di, cx
    
        mov cx, 3
    
        repe cmpsb   ; Сравниваем со строкой Extension расширение файла, если всё совпало - копируем адрес файла в sourcePath 
        jne notFound
    
        strcpy sourcePath, cmd_text, cmd_len
        mov error, 0
    ret 	

processCMD endp 


openFiles proc		     
	    push bx 		    
	    push dx 			       
	    push si 				    
				 
	    mov ah, 3Dh				        ; Функция 3Dh - открыть существующий файл
	    mov al, 02h				        ; 100 - запрещений нет
	    lea dx, sourcePath	            ; Загружаем в dx название исходного файла 
	    int 21h 		    
			      
	    jb badOpenSource		        ; Если файл не открылся, то прыгаем в badOpenSource
			      
	    mov sourceID, ax		        ; Загружаем в sourceId значение из ax, полученное при открытии файла
	     
	    mov error, 0				        ; Загружаем в ax 0, т.е. ошибок во время выполнения процедуры не произшло    
	    jmp endOpenProc 		        ; Прыгаем в endOpenProc и корректно выходим из процедуры
			
badOpenSource:		    
	    printString badSourceText	        ; Выводим соответсвующее сообщение
	
	    cmp ax, 02h		                ; Сравниваем ax с 02h
	    jne errorFound		            ; Если ax != 02h file error, прыгаем в errorFound
				
	    printString fileNotFoundText        ; Выводим сообщение о том, что файл не найден  
				
	    jmp errorFound		            ; Прыгаем в errorFound
			       
    errorFound: 		    
	    mov error, 1
			   
    endOpenProc:
        pop si		 
	    pop dx							   
	    pop bx			
	ret			
endp				

closeFiles proc 		
	    push bx 		    
	    push cx 		    
				
	    xor cx, cx		   
				
	    mov ah, 3Eh		                     ; Загружаем в ah код 3Eh - код закрытия файла
	    mov bx, sourceID	                   ; В bx загружаем ID файла, подлежащего закрытию
	    int 21h 		                     ; Выпоняем прерывание для выполнения 
			 		                     ; Выпоняем прерывание для выполнения 
			
	    jnb goodCloseOfSource		         ; Если ошибок при закрытии не произошло, прыгаем в goodCloseOfSource
				
	    printString errorClosingSource           ; Иначе выводим соответсвующее сообщение об ошибке	     
				  
	    inc cx				  
			
goodCloseOfSource:		
	    mov error, cx			      ; Записываем в ax значение из cx, если ошибок не произошло, то это будет 0, иначе 1 или 2, в зависимости от
				                     ; количества незакрывшихся файлов
	    pop cx			    
	    pop bx			                ; Восстанавливаем значения регистров и выходим из процедуры
	ret	
closeFiles endp	

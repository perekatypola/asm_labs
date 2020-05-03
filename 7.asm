.model small
.stack 100h                    
.data 
            
EPB dw ?   
    dw 0  
overlay_offset   dw 0   
overlaySeg dw ?
code_seg dw ?

pathMul                 db "MUL.EXE", 0 
pathDiv                 db "DIV.EXE", 0
pathAdd                 db "ADD.EXE", 0
pathSub                 db "SUB.EXE", 0  
emptyLine               db 0Ah, 0Dh, 'No parametrs in cmd$'
tooMany                 db 0Ah, 0Dh, 'Too many arguments. You should input one string$'   
cmdString               db 80 dup('$') 
stringOfResult          db ' = $'    
stringZero              db 0Ah, 0Dh, 'Division by zero is forbidden!$' 
wrongParametrs          db 0Ah, 0Dh, 'Bad parametrs in comand line$'
overflowString          db 0Ah, 0Dh, 'Numbers are too big for two bytes$'  
overflowOc              db 0Ah, 0Dh, 'Overflow occured$'
loadEr                  db 0Ah, 0Dh, 'Error loading the memory for overlay$'
operations              db 80 dup ('$')  
numbers                 dw 80 dup('$')
result                  db 80 dup('$')
;bigPart                 db '63556$'
 
negNum                  dw 0 
notNegNum               dw 0
regSiBeg                dw ?
regSiEnd                dw ?
lastOperation           db ? 
optimizationOn          dw 0
numLen                  db 0
tempNum                 db 80 dup('$')
Num                     dw 0
numPos                  dw 0
numQ                    dw 0
cur_pos                 dw 0
cmd_len 		db 0
isEnd                   db 0
isNum                   db 0
isMul                   db 0
isAdd		        db 0 
isSub		        db 0
isDiv		        db 0 
tempRes			dw 0
 
.code  
 
printString macro string  
    lea dx, string
    mov ah, 09h
    int 21h
endm  

operate proc

      xor dx , dx 
     
      mov cur_pos , si; запоминаем позицию, на которую надо сдвинуть число
      add cur_pos , 1
      mov ax,si 
      mov dl, 2
      mul dl
      mov si, ax
      
      mov ax, [numbers+si]  
      mov cx, [numbers+si+2]
      mov negNum, 0  
      call dword ptr overlay_offset 
      js negative

       mov tempRes , ax
       cmp ax , 8000h
       ja overflow

afterNeg:
       mov tempRes , ax
       mov si, cur_pos
       sub si , 1
       mov ax,si 
       mov dl, 2
       mul dl
       mov si, ax
       mov ax, tempRes
       mov [numbers+si] , ax
       xor cx , cx
       mov cx , numQ
       sub cx , cur_pos
       sub cx , 1
       call moveNumbers   
       mov si, cur_pos
       sub si , 1
       call moveOperations    
       mov si, cur_pos
       sub si , 1 
      ret
  overflow:  
       printString overflowOc
       jmp exit 

  negative: 
 
        jo overflow  
        mov negNum, 1
        jmp afterNeg
  ch_:
      
   
endp

moveNumbers proc 
  
    mov ax , cur_pos
    mov bl , 2
    mul bl
    mov si , ax

move:
   cmp cx , 0
   je stop
    
    mov bx,[numbers+si+2]
    mov [numbers+si], bx
    dec cx
    add si , 2
    jmp move
stop:   
    ret

endp
  
moveOperations proc  
 
    shift: 
    mov bl,[operations+si+1]
    mov [operations+si], bl
    inc si   
    cmp bl, '$'
    jne shift 
    ret
endp 

runOverlay proc    
    
;освобождение памяти

  ; получить PSP
     xor ax , ax
     mov ah , 62h
     int 21h

    mov es , bx
    mov ax, bx                      ;PSP      
    mov bx, zseg
    sub bx, ax
    mov ah, 4Ah
    int 21h       

    mov bx, 1000h                   ;64Kb 
    mov ah, 48h        
    int 21h 
    
    mov EPB, ax                     ;EPB(bx)=segment address for overlay load  
    mov EPB+2, ax                   ;for using in commands 
    mov overlaySeg, ax             ;save overlay segment 
    mov ax, ds
    mov es, ax   

    mov bx, offset EPB  ;(es:bx)
    mov ax, 4B03h  ; выполнение загрузки оверлея
    int 21h   
    jc load_error

        ret 

load_error:
    printString loadEr
     jmp exit
   
endp   

start:  
   
    call getCmd     
    continue: 
        printString cmdString 
        call checkString 
        call setNumbers 

        call makeOperation     
        call show   
    
    exit:
        mov ax,4c00h
        int 21h 


getCmd proc

         mov ax, @data           
         mov es , ax

		    
	    xor ch, ch	
	    mov cl, ds:[80h]	
	    cmp cl, 0 
            je emptyCommandLine	; Количество символов строки, переданной через командную строку
	    mov bl, cl
            dec cl  ;первый символ - пробел
	    mov cmd_len, cl		; В cmd_len загружаем длину командной строки
	  	
			        ; Уменьшаем значение количества символов в строке на 1, т.к. первый символ пробел
	    mov si, 82h		        ; Смещение на параметр, переданный через командную строки
	    lea di, cmdString
	    
            rep movsb

            mov ds, ax		        ; Загружаем в ds данные  
	    mov cmd_len, bl

           ret

emptyCommandLine:
     mov ds, ax	
     printString emptyLine 
     jmp exit
   
getCmd endp


checkString proc 

	lea si, cmdString
	cmp byte ptr [si], 30h
	jl checkFailed
	cmp byte ptr [si], 39h
	jg checkFailed
	inc si
	mov isNum , 1 ; для проверки, что в строке только число

beg:

	cmp byte ptr[si] , 24h
	je checkEnd
	cmp byte ptr [si], 30h
	jl checkOperations
	cmp byte ptr [si], 39h
	jg checkOperations
contCheck:
	inc si
	jmp beg
	
checkEnd:
	cmp isNum , 1
	je checkFailed
	cmp byte ptr [si - 1] , 30h
	jl checkFailed
	cmp byte ptr [si - 1] , 39h
	jg checkFailed
	jmp stopCheck
 
checkOperations:
	cmp byte ptr [si], '+'
	je checkAfter
	cmp byte ptr [si], '-'
	je checkAfter
	cmp byte ptr [si], '*'
	je checkAfter
	cmp byte ptr [si], '/'
	je checkZero
	jmp checkFailed


checkAfter:
	mov isNum , 0
	cmp byte ptr [si+1], 30h
	jl checkFailed
	cmp byte ptr [si+1], 39h
	jg checkFailed
	jmp contCheck

checkZero:
	cmp byte ptr [si+1], 30h
	je checkFailedZero
	jmp checkAfter

checkFailedZero:
	printString stringZero
	jmp exit


checkFailed:
	printString wrongParametrs
	jmp exit 

stopCheck:
    ret

checkString endp    

makeOperation proc 

    xor si,si  
    
    find:
     
    cmp [operations+si], '$' 
    jne k
    jmp othersOperations
k:
    cmp [operations+si] , '*' 
    jne l
    jmp makeMul
l:
    cmp [operations+si] , '/' 
    jne f
    jmp makeDiv
f:
    inc si
    jmp find
   
makeMul:
    mov dx, offset pathMul 
    ;mov cur_path , dx
    cmp isMul, 1
    je optimazeOnMul
    mov isMul,  1
    mov isSub , 0
    mov isDiv , 0
    mov isAdd , 0
    call runOverlay 
 
optimazeOnMul:

    call operate
    
    jmp find

makeDiv: 
    mov dx, offset pathDiv  
    cmp isDiv, 1
    je optimazeOnDiv
    mov isMul,  0
    mov isSub , 0
    mov isDiv , 1
    mov isAdd , 0

    call runOverlay 

optimazeOnDiv:
    call operate
    jmp find 


makeAdd: 
    mov dx, offset pathAdd 
    cmp isAdd , 1
    je optimazeOnAdd
    mov isMul,  0
    mov isSub , 0
    mov isDiv , 0
    mov isAdd , 1
    call runOverlay
  
optimazeOnAdd:
    call operate
    jmp makeItAll

makeSub:  
    mov dx, offset pathSub
    cmp isSub , 1
    je optimazeOnSub
    mov isMul,  0
    mov isSub , 1
    mov isDiv , 0
    mov isAdd , 0
    call runOverlay  

optimazeOnSub:
    call operate
    jmp makeItAll

othersOperations: 
  xor si, si 
   makeItAll:
   cmp [operations+si], '$' 
   je endMake
   cmp [operations+si], '+' 
   je makeAdd   
   cmp [operations+si], '-' 
   je makeSub 

endMake:
     ret
endp   

setNumbers proc 

  xor di, di
  xor ax,ax 
  xor bx , bx

new_num:
  xor si, si

  convert:

        mov dl,[cmdString+di]  
        cmp dl , 24h
        je is_end   
        cmp dl, 30h
        jl setOperation
	
        cmp dl, 39h
        jg setOperation
	add numLen , 1
	mov byte ptr [tempNum+si] , dl ; записываем во временную строку число
        inc di
	inc si
   
	jmp convert
    
ready:  
   ret

  setOperation: 
  mov dl,[cmdString+di]
  mov [operations+bx], dl 
  inc bx
  inc di
  jmp setNumber

is_end:

 mov isEnd , 1
 setNumber:
  push di
  push bx

    
   lea     si, tempNum ; устанавливаем на временную строку 
   lea     di, Num   ; на временное число
                                
    xor ax,ax
    xor cx,cx
   
    mov cl , numLen;запоминание длины числа в cl
    xor ch,ch

    mov     bx, 10 ; основание системы счисления для формирования числа
    
loop_:
    mul bx; умножаем ax на 10(если произошло переполнение, то лишняя часть занесется в dx)
    mov [di] , ax
    cmp     dx, 0
    jnz error 

    mov al , [si] 
    cmp al , '0'
    jb error
    
    cmp al , '9'
    ja error
    
    sub al , '0' ; вычитаем символ нуля для получения числа из символа
    xor ah , ah
    add ax , [di]
    jo error; если флаг переноса установлен в 1

    cmp ax , 8000h
    jae  checkOverflow

endloop:
    inc si
loop loop_
 
    ;pop si
    inc si
   ; cmp     byte ptr [si], '-'
    ;je Negative

StoreRes:
    mov [di] , ax
    mov si , numPos
    mov [numbers+si] , ax
    add numPos , 2
    inc numQ
    pop bx
    pop di
    mov numLen , 0
    cmp isEnd, 1
    je ready
    jmp new_num
  
error:
    clc; сброс флага перенос
    pop bx
    pop di 
    mov Num , 0
    lea dx, wrongParametrs      
    mov ah, 09h                   
    int 21h 
    jmp exit

checkOverflow:
   printString overflowString
   jmp exit
    
endp


show proc 
    
    lea si, numbers 
    xor di, di   
    mov  ax, [si]  
    ;cmp [notNegNum], 0
    ;jne addBigPart
    cmp [negNum], 0
    je loop1
    jmp makeNeg 
    
loop1:
    xor dx , dx
    mov bx, 10
    div bx
    add dl, 30h
    mov  [result+di], dl 
    inc di
    cmp ax, 0
    je showAll
    xor dl, dl
jmp loop1 
   
showAll:
    printString stringOfResult   
    cmp [negNum], 1
    je addMinus
showResult: 
    cmp di, 0
    je endShow
    dec di
    mov dl, [result+di]
    mov ah, 02h
    int 21h 
    jmp showResult

addMinus:
    cmp [notNegNum], 0
    jne showResult 
    mov  [result+di], '-'  
    inc di
    jmp showResult

makeNeg:
    neg ax 
    jmp loop1

endShow: 
 	ret
endp




zseg segment
zseg ends 
end start  
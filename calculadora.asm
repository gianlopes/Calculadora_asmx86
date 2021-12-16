global _start

section .data
msgInit db "Calculadora: Escolha uma das opções. (Só aceita valores de 16 bits com sinal [-32768,32767])", 0
msgOpcoes db "1 - soma, 2 - subtração, 3 - multiplicação, 4 - dividir, 5 - potenciação, 6 - fatorial ou 7 - sair", 0
msgOverflow db "Deu overflow",0
msgNewLine db 0xD, 0xA
msgNewLineSize EQU $-msgNewLine

section .bss
sinal resb 1
num resb 2
input resb 1
numString resb 6

section .text
_start:
    ; Imprimindo opções iniciais
    push msgInit
    call printLine

    push msgOpcoes
    call printLine

    ; Pegando input
    call readInt

    mov ax,[num]

op7: ; Opção para sair
    cmp ax,7
    jne primeiroInput
    jmp sair

primeiroInput:
    call readInt
    push word [num]

; Funções que usam apenas um input
op6:
    cmp ax,6
    jne segundoInput
    call fatorial
    jmp imprimir

segundoInput:
    call readInt
    push word [num]

; Funções que usam dois inputs
op1:
    cmp ax,1
    jne op2
    call soma
    jmp imprimir

op2:
    cmp ax,2
    jne op3
    call subtracao
    jmp imprimir

op3:
    cmp ax,3
    jne op4
    call multiplicacao
    jmp imprimir

op4:
    cmp ax,4
    jne op5
    call divisao
    jmp imprimir

op5:
    cmp ax,5
    jne sair
    call potencia
    jmp imprimir



imprimir:
    ; Imprimindo resultado
    push word [num]
    call convertIntAscii

    push numString
    call printLine

sair:
    mov eax,1 ; system call number (sys_exit)
    mov ebx,0 ; return value
    int 0x80 ; syscall

overflow:
    push msgOverflow
    call printLine
    jmp sair

;----------------------------------------------------------------------------------------------
; soma, recebe dois números e soma
; recebe via stack:
;  - nA [2bytes]
;  - nB [2bytes]
; Retorna nA + nB em num
;----------------------------------------------------------------------------------------------
soma:
    enter 0,0
    push eax

    mov ax,[ebp+8] ; ax = num
    add ax,[ebp+10]

    mov [num],ax

    pop eax
    leave
    ret 4

;----------------------------------------------------------------------------------------------
; subtração, recebe dois números e subtrai
; recebe via stack:
;  - nA [2bytes]
;  - nB [2bytes]
; Retorna nA - nB em num
;----------------------------------------------------------------------------------------------
subtracao:
    enter 0,0
    push eax

    mov ax,[ebp+10] ; nA
    sub ax,[ebp+8] ; - nB

    mov [num],ax

    pop eax
    leave
    ret 4

;----------------------------------------------------------------------------------------------
; multiplicação, recebe dois números e multiplica
; recebe via stack:
;  - nA [2bytes]
;  - nB [2bytes]
; Retorna nA * nB em num
; O resultado deve estar entre -32768 e 32767, ou teremos overflow
; Se o sinal da saída não for compatível com a entrada, teremos overflow
;----------------------------------------------------------------------------------------------
multiplicacao:
    enter 0,0
    push eax
    push ebx
    push edx

    mov dx,0
    mov ax,[ebp+10] ; nA
    mov bx,[ebp+8] ; nB
    imul bx
    jo overflow
    ; O professor falou para checar o dx, mas acho que a flag de overflow já faz o trabalho.
    cmp dx,0
    je multiplicacaoContinua
    cmp dx,-1
    je multiplicacaoContinua
    ; Se não for zero nem um, deu overflow
    jmp overflow


multiplicacaoContinua:
    mov [num],ax
    pop edx
    pop ebx
    pop eax
    leave
    ret 4

;----------------------------------------------------------------------------------------------
; divisão, recebe dois números e divide
; recebe via stack:
;  - nA [2bytes]
;  - nB [2bytes]
; Retorna nA/nB em num
; O resultado deve estar entre -32768 e 32767
divisao:
    enter 0,0
    push eax
    push ebx
    push edx

    mov ax,[ebp+10] ; nA
    cwd
    mov bx,[ebp+8] ; nB
    idiv bx
    mov [num],ax ; Armazenando resultado

    pop edx
    pop ebx
    pop eax
    leave
    ret 4


;----------------------------------------------------------------------------------------------
; potência, recebe dois números e calcula a potenciação
; recebe via stack:
;  - nA [2bytes]
;  - nB [2bytes]
; Retorna nA ^ nB em num
;----------------------------------------------------------------------------------------------
potencia:
    enter 0,0
    push eax
    push ebx
    push ecx
    push edx

    mov ax,[ebp+10] ; nA
    mov bx,ax
    mov dx,0
    mov cx,[ebp+8] ; nB
    
    cmp cx,1 ; Se o expoente for 1, num = nA
    je potenciaExit
    cmp cx,0
    jne potenciaDec ; Se n for 0 nem 1, continua no loop
    mov ax,1 ; Se o expoente for 0, num = 1
    jmp potenciaExit

potenciaDec:
    dec cx ; a^n -> multiplicar por a (n-1) vezes
potenciaLoop:
    imul bx
    jo overflow
    loop potenciaLoop

    ; Checagem adicional de overflow (realmente não sei se precisa)
    cmp dx,0
    je multiplicacaoContinua
    cmp dx,-1
    je multiplicacaoContinua
    jmp overflow

potenciaExit:
    mov [num],ax ; Salva o resultado

    pop edx
    pop ecx
    pop ebx
    pop eax
    leave
    ret 4

;----------------------------------------------------------------------------------------------
; fatorial, recebe um número e calcula o fatorial
; recebe via stack:
;  - nA [2bytes]
; Retorna !nA em num
;----------------------------------------------------------------------------------------------
fatorial:
    enter 0,0
    push eax
    push ebx
    push ecx
    push edx

    mov ax,[ebp+8] ; ax = num
    mov dx,0
    mov cx,ax ;cópia
fatorialLoop:
    sub ax,1 ; ax = n - 1
    jz fatorialExit
    mov bx,ax ; temp = n-1
    imul cx ; ax = n * n-1
    jo overflow
    mov cx,ax ; total = ax
    mov ax,bx ; ax = n - 1
    jmp fatorialLoop

fatorialExit:
    mov [num],cx
    pop edx
    pop ecx
    pop ebx
    pop eax
    leave
    ret 4

;----------------------------------------------------------------------------------------------
; convertIntAscii, recebe um número e converte para ascii colocando-o em numString
; recebe via stack:
;  - número [2bytes]
;----------------------------------------------------------------------------------------------
convertIntAscii:
    enter 0,0
    pusha

    mov edi,0 ; i=0
    mov ax,[ebp+8] ; ax = num
    mov bx,10

    ;Removendo menos
    mov byte [sinal],0
    cmp ax,0
    jge convertIntAsciiLoop
    mov byte [sinal],1 ; negativo
    mov cx,-1
    imul cx
convertIntAsciiLoop:
    mov dx,0
    div bx ; (dx.ax)/10
    add dx,0x30 ; 1 + 0x30 = '1'
    push dx ; coloca o char na pilha
    add edi,1 ; incrementa o contador
    cmp ax,0
    jne convertIntAsciiLoop
    
    cmp byte [sinal],0
    je convertIntAsciiInvert
    mov byte [numString],45 ; sinal de menos
    mov eax,1
convertIntAsciiInvert:
    ; o número entra na pilha ao contrário e precisa ser desempilhado
    pop cx
    mov [numString + eax],cl
    dec edi
    inc eax
    cmp edi,0
    jne convertIntAsciiInvert

convertIntAsciiEnd:
    mov byte [numString + eax],0
    popa
    leave
    ret 2

;----------------------------------------------------------------------------------------------
;readInt lê um inteiro de até dois bytes do teclado e coloca em num
;----------------------------------------------------------------------------------------------
readInt:
    enter 0,0
    pusha

    mov word [num],0 ; Zera o num
    mov byte [sinal],0 ; zera o sinal

readIntRead:
    mov eax,3 ; system call number (sys_read)
    mov ebx,0 ; file descriptor (stdin)
    mov ecx,input; message para printar
    mov edx,1 ; 1 byte
    int 0x80 ; syscall

    movzx bx, byte [input]

    cmp bx, 10 ; Vendo se foi enter
    je readIntEnd

    cmp bx, 45 ; Sinal de menos
    jne readIntConvert
    mov byte [sinal],1
    jmp readIntRead

readIntConvert:
    sub bx, 0x30 ; bx = 'A' - 0x30
    mov ax, [num] ; ax = num
    mov cx, 10
    mul cx ; num * 10
    add ax,bx ; ax = num*10 + ('A'- 0x30)
    mov [num],ax

    jmp readIntRead

readIntEnd:
    cmp byte [sinal],1
    jne readIntExit ; Pula se não tem sinal
    
    ;Colocando Sinal de menos
    mov ax,[num]
    mov bx,-1
    imul bx
    mov [num],ax

readIntExit:
    popa
    leave
    ret

;----------------------------------------------------------------------------------------------
; printline imprime uma string teminada por '\0'
; recebe via stack:
;  -string a ser printada
;----------------------------------------------------------------------------------------------
%define msg [ebp+8]
printLine:
    enter 0,0
    pusha

    ; Contando caracteres
    mov edi,0 ; inicia o contador em 0
    mov ebx, msg ; coloca o endereço de msg em bx
printLineSize:
    mov byte al,[ebx+edi]
    inc edi
    cmp al,0 ; testa se não é \0
    jne printLineSize ;loop

    sub edi,1 ; ignora o \0
    

    mov eax,4 ; system call number (sys_write)
    mov ebx,1 ; file descriptor (stdout)
    mov ecx,msg; message para printar
    mov edx,edi ; message size
    int 0x80 ; syscall

    ; Imprime quebra de linha
    mov eax,4 ; system call number (sys_write)
    mov ebx,1 ; file descriptor (stdout)
    mov ecx,msgNewLine
    mov edx,msgNewLineSize
    int 0x80 ; syscall

    popa
    leave
    ret 4
Trabalho 2 SB - Gianlucas Dos Santos Lopes - 180041991

A calculadora só funciona com valores de 16 bits com sinal (-32768 a 32767), 
mas não faz checagem se os valores inseridos estão dentro do range.
Os únicos erros apontados são overflow em multiplicação, potencição e fatorial.

Para rodar a calculadora (Testado em ubuntu 16.04 x64)
nasm -f elf -o calculadora.o calculadora.asm
ld -m elf_i386 -o calculadora calculadora.o
./calculadora
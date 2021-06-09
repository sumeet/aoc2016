TOTAL_WIDTH equ 50

TOTAL_HEIGHT equ 6
OFF equ 0
ON equ 1

section .data

printf_msg: db "%d", 10, 0
input: incbin "./input"
db 10 ; add a newline after the input
db 0 ; null terminate the input

screen_a: times 0 db TOTAL_HEIGHT * TOTAL_WIDTH
screen_b: times 0 db TOTAL_HEIGHT * TOTAL_WIDTH

this_screen: dq screen_a
next_screen: dq screen_b

%macro swap_screens 0
  push rax
  push rbx

  mov rax, this_screen
  mov rbx, next_screen

  mov qword [this_screen], rax
  mov qword [next_screen], rbx

  pop rbx
  pop rax
%endmacro

section .text
;; TODO: without libc
global main
extern printf

main:
  %define input_cursor dword [rbp - 4]
  enter 4, 0
  mov input_cursor, 0
  leave


print:
  mov rdi, printf_msg
  mov rsi, 234
  mov rax, 0
  call printf
  mov rax, 0
  ret

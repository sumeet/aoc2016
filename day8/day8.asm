TOTAL_WIDTH equ 50
TOTAL_HEIGHT equ 6
OFF equ 0
ON equ 1

section .data
printf_msg: db "%d", 10, 0
input: incbin "./input"
db 10 ; add a newline after the input
db 0 ; null terminate the input

screen_a: times 0 db TOTAL_WIDTH * TOTAL_HEIGHT
screen_b: times 0 db TOTAL_WIDTH * TOTAL_HEIGHT

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

%macro match_exact_str 2
; %1: input cursor (addr)
; %2: string literal
    %assign i 1
    %strlen len %2
    %rep len
        %substr this_char %2 i

        mov rcx, i
        mov rbx, this_char

        mov eax, %1
        cmp byte [rax + i - 1], this_char
        jne %%false
        
        %assign i i+1
    %endrep
    %%true:
        add %1, len
    
        mov rax, 1
        cmp rax, 1
        jmp %%end
    %%false:
        mov rax, 0
        cmp rax, 1
    %%end:
%endmacro

section .text
;; TODO: without libc
global main
extern printf

main:
  %define input_cursor dword [rbp - 4]
  enter 4, 0
  mov input_cursor, input ; first character
  input_loop:    
    mov eax, input_cursor
    cmp byte [rax], 0
    je end_input_loop
    
    .rect:
      match_exact_str input_cursor, "rect "
      jne .not_rect
      consume_number input_cursor, r10
      jne .not_rect
      match_exact_str input_cursor, "x"
      jne .not_rect
      consume_number input_cursor, r11
      jne .not_rect

    .not_rect:
    
    
  continue_input_loop:
    inc input_cursor
  end_input_loop:
  %undef input_cursor
  leave


print:
  mov rdi, printf_msg
  mov rsi, 234
  mov rax, 0
  call printf
  mov rax, 0
  ret

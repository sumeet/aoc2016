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

%macro cmp_between 3
; %1: value
; %2: lower bound (inclusive)
; %3: upper bound (inclusive)
; sets flags (true or false)
  cmp %1, %2 ; val < lower bound
  jl %%false
  cmp %1, %3 ; val <= upper bound
  jle %%true
  jmp %%false
  %%true:
    mov rax, 0
    cmp rax, 0
    jmp %%end
  %%false:
    mov rax, 1
    cmp rax, 0
  %%end:
%endmacro

%macro match_exact_str 2
; %1: input cursor (addr)
; %2: string literal
; can use je if string matches otherwise jne
; clobbers: rax, rbx, rcx
    %assign i 1
    %strlen len %2
    %rep len
        %substr this_char %2 i

        mov rcx, i
        mov rbx, this_char

        mov rax, %1
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

%macro times_ten 1
; %1: register
  lea %1, [%1 + %1 + %1 + %1 + %1 + %1 + %1 + %1 + %1 + %1]
%endmacro

%macro consume_number 2
; %1: input cursor (addr)
; %2: into register
; can use je if number actually consumed otherwise jne
; clobbers: rax, rbx
%define input_cursor_reg rbx
  mov input_cursor_reg, %1

  ; first iteration
  cmp_between byte [input_cursor_reg], '0', '9'
  jne %%false
  
  movzx rax, byte [input_cursor_reg]
  lea %2, [rax  - '0']
  inc byte [input_cursor_reg]

  %%loop:
    cmp_between byte [input_cursor_reg], '0', '9'
    jne %%true ; can now bail with true because we would've already consumed a single number

    movzx rax, 
  %%true:
    mov %1, input_cursor_reg ; save the new input cursor, consuming the number

    mov rax, 1
    cmp rax, 1
    jmp %%end
  %%false:
    mov rax, 0
    cmp rax, 1
  %%end:
%undef input_cursor_reg
%endmacro

section .text
;; TODO: without libc
global main
extern printf

main:
  %define input_cursor qword [rbp - 8]
  enter 8, 0
  mov input_cursor, input ; first character
  input_loop:    
    mov rax, input_cursor
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

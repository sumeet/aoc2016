NUM_LETTERS equ 26
MAX_MESSAGE_SIZE equ 10

section .data
total_count: dq 0
printf_msg: db "%d", 10, 0
input: incbin "./input"
db 10 ; add a newline after the input
db 0 ; null terminate the input

section .text
;; TODO: without libc
global main
extern printf

main:
  %define input_cursor dword [rbp - 4]
  %define is_outer_contains_abba byte [rbp - 5]
  %define is_inner_contains_abba byte [rbp - 6]
  %define is_inside_inner byte [rbp - 7]
  enter 7, 0

  mov input_cursor, 0

  .start_of_line:
    mov is_inner_contains_abba, 0
    mov is_outer_contains_abba, 0
    mov is_inside_inner, 0
  .input_loop:
    mov eax, input_cursor

    cmp byte [input + rax], 0
    je .done

    cmp byte [input + rax], 10
    je .on_line_end

    cmp byte [input + rax], '['
    je .bracket_begin

    cmp byte [input + rax], ']'
    je .bracket_end

    mov bl, byte [input + rax]
    cmp bl, byte [input + rax + 3]
    jne .next_char

    ; if the 4 continguous chars are the same, then invalid
    mov bl, byte [input + rax]
    cmp bl, byte [input + rax + 1]
    je .next_char

    mov bl, byte [input + rax + 1]
    cmp bl, byte [input + rax + 2]
    jne .next_char

    ; abba
    ; cursor and cursor + 3 are the same
    ; cursor + 1 and cursor + 2 are the same

    ; sets is_inner_contains_abba to true if inside inner
    movzx rax, is_inside_inner
    or is_inner_contains_abba, al

    ; or the other way around
    not rax
    or is_outer_contains_abba, al
    
    jmp .next_char
  .bracket_begin:
    mov is_inside_inner, 1
    jmp .next_char
  .bracket_end:
    mov is_inside_inner, 0
    jmp .next_char
  .on_line_end:
    cmp is_inner_contains_abba, 0
    jne .next_line

    cmp is_outer_contains_abba, 0
    je .next_line

    inc qword [total_count]
  .next_line:
    inc input_cursor
    jmp .start_of_line
  .next_char:
    inc input_cursor
    jmp .input_loop

  %undef input_cursor
  %undef is_outer_contains_abba
  %undef is_inner_contains_abba
  %undef is_inside_inner
  .done:
    leave


print:
  mov rdi, printf_msg
  mov rsi, [total_count]
  mov rax, 0
  call printf
  mov rax, 0
  ret


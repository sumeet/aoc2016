%macro cmp_between 3
  %define TEMP_REG rax

  push TEMP_REG

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
    mov TEMP_REG, 0
    cmp TEMP_REG, 0
    jmp %%end
  %%false:
    mov TEMP_REG, 1
    cmp TEMP_REG, 0
  %%end:

  pop TEMP_REG
%endmacro

NUM_LETTERS equ 26
MAX_MESSAGE_SIZE equ 10

section .data
; 16 bit counts ('a' - 'z' for each column position of the message)
letter_counts: times (NUM_LETTERS * MAX_MESSAGE_SIZE) dw 0
printf_msg: db "%s", 0
input: incbin "./input"
db 0 ; null terminate the input

output: times MAX_MESSAGE_SIZE db 0

section .text
;; TODO: without libc
global main
extern printf

main:
  %define input_cursor word [rbp - 2]
  %define pos_in_line word [rbp - 4]
  enter 4, 0

  mov input_cursor, 0
  mov pos_in_line, 0

  .parse_loop:
    movzx rax, input_cursor
    cmp_between byte [input + rax], 'a', 'z'
    je .count_another_char

    cmp byte [input + rax], 10
    je .next_line

    cmp byte [input + rax], 0
    je .end

    hlt ; unreachable by input
  .count_another_char:
    ; move the actual current char into rbx
    movzx rbx, byte [input + rax]

    ; get offset of letter_counts for this position in the line
    mov rax, 26 * 2
    mov rdx, 0
    mul pos_in_line

    inc word [letter_counts + rax + (rbx - 'a')*2] ; * 2 because 2 bytes for every char

    inc pos_in_line
    jmp .continue_loop
  .next_line:
    mov pos_in_line, 0
  .continue_loop:
    inc input_cursor
    jmp .parse_loop
  .end:

  %undef input_cursor
  %undef line_num
  leave

  %define loser_char byte [rbp - 1] ; offset from 0 - 26
  %define loser_count word [rbp - 3] ; how many did we see?
  %define current_col byte [rbp - 4] ; the current column we're looking at
  %define cursor byte [rbp - 5] ; the position 0 - 26 inside the current column
  enter 5, 0

  mov current_col, 0

  .begin_new_column:
    mov loser_char, 0
    mov loser_count, -1 ; unsigned so -1 will wrap around to max
    mov cursor, 0
  .collect_loop:
    ; calculate the base offset for this column
    movzx rax, current_col
    mov rbx, 26 * 2
    mov rdx, 0
    mul rbx

    ; the offset for this cursor
    movzx rbx, cursor
    movzx rbx, word [letter_counts + rax + (rbx*2)]
    cmp rbx, 0
    je .continue_collect_loop

    cmp bx, loser_count
    jb .new_loser
    jmp .continue_collect_loop
  .new_loser:
    movzx rax, cursor
    add rax, 'a'
    mov loser_char, al
    mov loser_count, bx
  .continue_collect_loop:
    cmp cursor, 26 - 1
    jge .add_loser_to_output
    
    inc cursor
    jmp .collect_loop
  .add_loser_to_output:
    ; if there is no loser, just get out of here... we're past the columns from the input
    cmp loser_char, 0
    je .done_collect_loop

    movzx rax, loser_char
    movzx rbx, current_col
    mov byte [output + rbx], al
    jmp .next_col
  .next_col:
    inc current_col
    jmp .begin_new_column

  %undef loser_char
  %undef loser_count
  .done_collect_loop:
    leave


print:
  mov rdi, printf_msg
  mov rsi, output
  mov rax, 0
  call printf
  mov rax, 0
  ret


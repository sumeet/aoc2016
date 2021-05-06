section .text
;; TODO: without libc
global main
extern printf

%define possible_count_reg r8
%define side_a_reg r9
%define side_b_reg r10
%define side_c_reg r11
%define num_valid_triangles_reg r12
%define parse_cursor_reg r13
%define num_sides_counted_reg r14
%define number_parse_reg r15

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

%macro test_need_to_store_number 0
  cmp number_parse_reg, 0
  je %%false

  cmp_between this_char, '0', '9'
  je %%false
  %%true:
    mov rax, 0
    cmp rax, 0
    jmp %%end
  %%false:
    mov rax, 1
    cmp rax, 0
  %%end:
%endmacro

%macro clear_all_sides 0
  mov side_a_reg, 0
  mov side_b_reg, 0
  mov side_c_reg, 0
  mov num_sides_counted_reg, 0
%endmacro

%define this_char byte [input + parse_cursor_reg]

main:
init:
  mov possible_count_reg, 0
  mov num_valid_triangles_reg, 0
  mov number_parse_reg, 0
  clear_all_sides
start_next_column:
  mov parse_cursor_reg, 0
  inc byte [current_column_no]
  cmp byte [current_column_no], 1
  je start_column_1
  cmp byte [current_column_no], 2
  je start_column_2
  cmp byte [current_column_no], 3
  je start_column_3
  ; or else we're done
  jmp print
  start_column_1:
    mov byte [num_numbers_to_skip], byte 0
    jmp parse_loop
  start_column_2:
    mov byte [num_numbers_to_skip], byte 1
    jmp parse_loop
  start_column_3:
    mov byte [num_numbers_to_skip], byte 2
    jmp parse_loop
parse_loop:
  cmp_between this_char, '0', '9'
  je parse_another_digit
  test_need_to_store_number
  je store_another_number
  cmp num_sides_counted_reg, 3
  je evaluate_all_sides
  jmp continue_parse_loop
parse_another_digit:
  mov rax, number_parse_reg
  mov rdx, 10
  mul rdx
  movzx rbx, this_char
  lea rax, [rax + rbx - '0']
  mov number_parse_reg, rax
  jmp continue_parse_loop
store_another_number:
  cmp byte [num_numbers_to_skip], byte 0
  je keep_storing_another_number
  dec byte [num_numbers_to_skip]
  jmp done_storing
keep_storing_another_number:
  cmp side_a_reg, 0
  je store_into_a
  cmp side_b_reg, 0
  je store_into_b
  cmp side_c_reg, 0
  je store_into_c
  jmp unreachable
  store_into_a:
    mov side_a_reg, number_parse_reg
    inc num_sides_counted_reg
    mov byte [num_numbers_to_skip], byte 2
    jmp done_storing
  store_into_b:
    mov side_b_reg, number_parse_reg
    inc num_sides_counted_reg
    mov byte [num_numbers_to_skip], byte 2
    jmp done_storing
  store_into_c:
    mov side_c_reg, number_parse_reg
    inc num_sides_counted_reg
    mov byte [num_numbers_to_skip], byte 2
    jmp done_storing
  done_storing:
    mov number_parse_reg, 0
    jmp continue_parse_loop
  unreachable:
    hlt
evaluate_all_sides:
  mov rax, side_a_reg
  add rax, side_b_reg
  cmp rax, side_c_reg
  jle invalid_triangle

  mov rax, side_b_reg
  add rax, side_c_reg
  cmp rax, side_a_reg
  jle invalid_triangle

  mov rax, side_a_reg
  add rax, side_c_reg
  cmp rax, side_b_reg
  jle invalid_triangle
valid_triangle:
  inc num_valid_triangles_reg
invalid_triangle:
  clear_all_sides
continue_parse_loop:
  inc parse_cursor_reg
  cmp this_char, 0
  je start_next_column
  jmp parse_loop
print:
  mov rsi, num_valid_triangles_reg
  mov rdi, printf_msg
  mov rax, 0
  call printf
  mov rax, 0
  ret

section .data
current_column_no: db 0
num_numbers_to_skip: db 0
printf_msg: db "%d", 10, 0
input: incbin "./input"
; null terminate the read file
db 0

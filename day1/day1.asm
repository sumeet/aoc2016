section .text
;; TODO: without libc
global main
extern printf

;;;;;;;;;;;;;;;;;
;;; REGISTERS ;;;
;;;;;;;;;;;;;;;;;
%define dir_reg r8 ; i64: direction
%define init_dir_reg() mov dir_reg, 0

; -4 (north): r10 += 1
; -3 (east): r9 += 1
; -2 (south): r10 -= 1
; -1 (west): r9 -= 1
; 0 (north): r10 += 1
; 1 (east): r9 += 1
; 2 (south): r10 -= 1
; 3 (west): r9 -= 1
; 4 (north): r10 += 1
; ...
; basically this means rem 4, r8 => positive values for north to west above

%define N 0
%define E 1
%define S 2
%define W 3


; accumulators:
%define east_reg r9 ; i64: total moved east (can be negative)
%define init_east_reg() mov east_reg, 0

%define north_reg r10 ; i64: total moved north (can be positive)
%define init_north_reg() mov north_reg, 0

%define str_index_reg r11 ; u64: position in parsed string
%define init_str_index() mov str_index_reg, 0

%define number_parse_reg r12 ; u64: built up parsed number
%define init_number_parse_reg() mov number_parse_reg, 0

; misc:
%define op_reg r13 ; for operations
%define op_regb r13b
%define init_op_reg() mov op_reg, 0

; data string to run on, can either be sample or input
%define run_input input
%define this_char [run_input + str_index_reg]

;;;;;;;;;;;;;;;
;;; MACROS  ;;;
;;;;;;;;;;;;;;;
%macro rem 2
; %1: value
; %2: input and output register
  mov rdx, 0
  mov rax, %2
  mov op_reg, %1
  idiv op_reg
  mov %2, rdx
%endmacro

; from https://stackoverflow.com/a/11927940/149987
%macro abs 1
  mov op_reg, %1
  neg %1
  cmovl %1, op_reg ; if %1 is now negative, restore its saved value
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
  jg %%false
  %%true:
    mov op_reg, 0
    cmp op_reg, 0
    jmp %%end
  %%false:
    mov op_reg, 1
    cmp op_reg, 0
  %%end:
%endmacro

handle_digit: ; uses arg from rdi
  cmp dir_reg, N
  je north
  cmp dir_reg, E
  je east
  cmp dir_reg, S
  je south
  cmp dir_reg, W
  je west
  hlt
north:
  add north_reg, rdi
  ret
east:
  add east_reg, rdi
  ret
south:
  sub north_reg, rdi
  ret
west:
  sub east_reg, rdi
  ret
turn_right:
  inc dir_reg
  rem 4, dir_reg
  ret
turn_left:
  dec dir_reg
  rem 4, dir_reg
  ret

main:
init:
  init_dir_reg()
  init_east_reg()
  init_north_reg()
  init_str_index()
  init_op_reg()
  init_number_parse_reg()
parse_loop:
  cmp_between byte this_char, '0', '9'
  je is_a_number
  jne not_a_number
is_a_number:
  mov op_reg, 0
  mov op_regb, byte this_char
  sub op_regb, '0'
  mov rax, number_parse_reg
  mov rdx, 10
  mul rdx
  mov number_parse_reg, rax
  add number_parse_reg, op_reg
  jmp continue_parse_loop
end_of_number:
  mov rdi, number_parse_reg
  call handle_digit
  mov number_parse_reg, 0
  ret
not_a_number:
  cmp byte this_char, 'R'
  push continue_parse_loop
  je turn_right
  add rsp, 8
  cmp byte this_char, 'L'
  push continue_parse_loop
  je turn_left
  add rsp, 8
  ; ' ' means end of command
  cmp byte this_char, ' '
  je end_of_single_command
  ; null terminator means end of proggy, handle this int first and terminate
  cmp byte this_char, 0 ; end of string
  je end_of_all_commands
continue_parse_loop:
  inc str_index_reg
  jmp parse_loop
end_of_single_command:
  call end_of_number
  jmp continue_parse_loop
end_of_all_commands:
  call end_of_number
done:
  abs north_reg
  abs east_reg
  mov rax, 0
  add rax, north_reg
  add rax, east_reg
print:
  mov rsi, rax
  mov rdi, message
  mov rax, 0
  call printf
  ret

section .data
FALSE equ 0
TRUE equ -1
message db "%d", 10, 0
;sample db "R156", 0
input db "L3, R2, L5, R1, L1, L2, L2, R1, R5, R1, L1, L2, R2, R4, L4, L3, L3, R5, L1, R3, L5, L2, R4, L5, R4, R2, L2, L1, R1, L3, L3, R2, R1, L4, L1, L1, R4, R5, R1, L2, L1, R188, R4, L3, R54, L4, R4, R74, R2, L4, R185, R1, R3, R5, L2, L3, R1, L1, L3, R3, R2, L3, L4, R1, L3, L5, L2, R2, L1, R2, R1, L4, R5, R4, L5, L5, L4, R5, R4, L5, L3, R4, R1, L5, L4, L3, R5, L5, L2, L4, R4, R4, R2, L1, L3, L2, R5, R4, L5, R1, R2, R5, L2, R4, R5, L2, L3, R3, L4, R3, L2, R1, R4, L5, R1, L5, L3, R4, L2, L2, L5, L5, R5, R2, L5, R1, L3, L2, L2, R3, L3, L4, R2, R3, L1, R2, L5, L3, R4, L4, R4, R3, L3, R1, L3, R5, L5, R1, R5, R3, L1", 0

TOTAL_WIDTH equ 50
TOTAL_HEIGHT equ 6
OFF equ 0
ON equ 1

section .data
printf_msg: db "%d", 10, 0
input: incbin "./input"
db 0 ; null terminate the input so we can tell when it's over
output_len: dq 0

%macro match 2-*
; %1: where to jump if match isn't found
; %2-*: array of "string matcher" macro invocations
  %assign no_match_jmp_point %1
  %rep (%0-1)
    %rotate 1
    %1
    jne no_match_jmp_point
  %endrep
%endmacro

%macro times_ten 1
; %1: register
  lea %1, [%1 + %1 + %1 + %1 + %1] ; * 5
  lea %1, [%1 + %1] ; * 2
%endmacro


%macro cmp_between 3
; %1: value
; %2: lower bound (inclusive)
; %3: upper bound (inclusive)
; sets flags (true or false)
  push rax

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

  pop rax
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

%macro consume_number 2
; %1: input cursor (addr)
; %2: into register
; can use je if number actually consumed otherwise jne
; clobbers: rax, rbx
%define input_cursor_reg rbx
  mov %2, 0
  mov input_cursor_reg, %1

  ; first iteration
  cmp_between byte [input_cursor_reg], '0', '9'
  jne %%false

  movzx rax, byte [input_cursor_reg]
  lea %2, [rax  - '0']
  inc input_cursor_reg

  %%loop:
    cmp_between byte [input_cursor_reg], '0', '9'
    jne %%true ; can now bail with true because we would've already consumed a single number

    times_ten %2
    movzx rax, byte [input_cursor_reg]
    lea %2, [%2 + rax - '0']
    inc input_cursor_reg
    jmp %%loop
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
  mov input_cursor, input
  .outer_input_loop:
    mov rax, input_cursor

    ; jump to the end if we encounter either a newline or null byte
    cmp byte [rax], 0
    je .end_input_loop
    cmp byte [rax], 10
    je .end_input_loop

    match_exact_str input_cursor, "("
    jne .not_a_compression_marker
    consume_number input_cursor, r10
    jne .not_a_compression_marker
    match_exact_str input_cursor, "x"
    jne .not_a_compression_marker
    consume_number input_cursor, r11
    jne .not_a_compression_marker
    match_exact_str input_cursor, ")"
    jne .not_a_compression_marker

    .not_a_compression_marker:
      inc qword [output_len]
      jmp .continue_outer_input_loop
    .continue_outer_input_loop:
      inc input_cursor
      jmp .outer_input_loop
  .end_input_loop:
  leave
  %undef input_cursor

print:
  mov rdi, printf_msg
  mov rsi, 234
  mov rax, 0
  call printf
  mov rax, 0
  ret

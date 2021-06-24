TOTAL_WIDTH equ 50
TOTAL_HEIGHT equ 6
OFF equ 0
ON equ 1

section .data
printf_msg: db "%d", 10, 0
;input: incbin "./input"
input: incbin "./sample"
db 0 ; null terminate the input so we can tell when it's over
output_len: dq 0

%macro match 2-*
; %1: where to jump if match isn't found
; %2-*: array of "string matcher" macro invocations
  %define no_match_jmp_point %1
  %rep (%0-1)
    %rotate 1
    %1
    jne no_match_jmp_point
  %endrep
  %undef no_match_jmp_point
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

count_decompressed:
; rdi: start addr
; rsi: length
; returns count to rax
  %define count qword [rbp - 8]
  %define input_cursor qword [rbp - 16]
  %define length qword [rbp - 24]
  ;int1
  enter 24, 0
    mov count, 0
    mov input_cursor, rdi
    mov length, rsi
    .outer_input_loop:
      cmp length, 0
      je .end_input_loop

      mov rax, input_cursor
      ; bail if we encounter a newline or null byte, means we're at the end
      ; of the input
      cmp byte [rax], 0
      je .end_input_loop
      cmp byte [rax], 10
      je .end_input_loop

      match .not_a_compression_marker, \
        {match_exact_str input_cursor, "("}, \
        {consume_number input_cursor, r10}, \
        {match_exact_str input_cursor, "x"}, \
        {consume_number input_cursor, r11}, \
        {match_exact_str input_cursor, ")"}

      .is_a_compression_marker:
        %define num_chars r10
        %define num_repeats r11

        push num_chars
        push num_repeats

        mov rdi, input_cursor
        mov rsi, num_chars
        call count_decompressed
        ; rax contains the return value

        pop num_repeats
        pop num_chars

        int1

        mul num_repeats
        add count, rax

        add input_cursor, num_chars
        sub length, num_chars
        jmp .outer_input_loop
        %undef num_chars
        %undef num_repeats

      .not_a_compression_marker:
        inc count
        inc input_cursor
        dec length
        jmp .outer_input_loop

    .end_input_loop:
      mov rax, count
      ;int1
  %undef count
  %undef input_cursor
  %undef length
  leave
  ret
main:
  mov rdi, input
  mov rsi, -1
  call count_decompressed
print:
  mov rdi, printf_msg
  mov rsi, rax
  mov rax, 0
  call printf
  mov rax, 0
  ret

NUM_LETTERS equ 26
MAX_MESSAGE_SIZE equ 10
SIZE_OF_ABS_BUFFERS_IN_WORDS equ 100
SIZE_OF_ABS_BUFFERS_IN_BYTES equ (SIZE_OF_ABS_BUFFERS_IN_WORDS*2)
FALSE equ 0
TRUE equ 1

%macro append_to_str 3-*
  ; appends to the end of a null-terminated string
  ;
  ; WARNING: does not handle writing off the end of the string
  ;
  ; %1: addr of str
  ; %2: total length of string buffer
  ; %3-*: operands of chars to append

  push rax

  ; find the first zero in the string
  mov rax, 0
  mov rcx, %2
  mov esi, 0
  mov rdi, %1
  repne scasb

  pop rax

  %assign i 0
  %rotate 2 ; pull arg %3 to the front
  %rep (%0-2)
    push rax ; push rax because the operands reference rax, clobbering them would be suicide

    movzx rax, %1
    mov rbx, i
    mov byte [rdi - 1 + i], al

    pop rax
    %rotate 1 ; move the next arg to position %1
    %assign i i+1
  %endrep
%endmacro

section .data
total_count: dq 0
printf_msg: db "%d", 10, 0
input: incbin "./input"
db 10 ; add a newline after the input
db 0 ; null terminate the input

outer_abs: times SIZE_OF_ABS_BUFFERS_IN_WORDS dw 0 ; pairs of "ab" (parts of "aba")
inner_abs: times SIZE_OF_ABS_BUFFERS_IN_WORDS dw 0 ; pairs of "ab" (parts of "bab")

section .text
;; TODO: without libc
global main
extern printf

main:
  %define input_cursor dword [rbp - 4]
  %define is_inside_inner byte [rbp - 5]
  enter 5, 0

  mov input_cursor, 0

  .start_of_line:
    mov rdi, outer_abs
    mov rax, 0x00
    mov rcx, SIZE_OF_ABS_BUFFERS_IN_WORDS
    rep stosw

    mov rdi, inner_abs
    mov rax, 0x00
    mov rcx, SIZE_OF_ABS_BUFFERS_IN_WORDS
    rep stosw

    mov is_inside_inner, FALSE
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

    ; look for aba pattern
    ; cursor and cursor + 2 are the same
    mov bl, byte [input + rax]
    cmp bl, byte [input + rax + 2]
    jne .next_char

    ; cursor and cursor + 1 are different
    cmp bl, byte [input + rax + 1]
    je .next_char

    cmp is_inside_inner, FALSE
    je .store_outer_ab
    jmp .store_inner_ab

  .store_outer_ab:
    append_to_str outer_abs, SIZE_OF_ABS_BUFFERS_IN_BYTES, \
                  byte [input + rax], byte [input + rax + 1]
    jmp .next_char
  .store_inner_ab:
    append_to_str inner_abs, SIZE_OF_ABS_BUFFERS_IN_BYTES, \
                  byte [input + rax + 1], byte [input + rax]
    jmp .next_char
  .bracket_begin:
    mov is_inside_inner, TRUE
    jmp .next_char
  .bracket_end:
    mov is_inside_inner, FALSE
    jmp .next_char
  .on_line_end:
  .prep_outer_abs_loop:
    mov rax, 0
  .outer_abs_loop:
    cmp word [outer_abs + (rax*2)], 0
    je .next_line

    mov rbx, 0
    .inner_abs_loop:
      cmp word [inner_abs + (rbx*2)], 0
      je .continue_outer_abs_loop

      movzx rcx, word [outer_abs + (rax*2)]
      cmp cx, word [inner_abs + (rbx*2)]
      je .found_match

      inc rbx
      jmp .inner_abs_loop
  .continue_outer_abs_loop:
    inc rax
    jmp .outer_abs_loop
  .found_match:
    inc qword [total_count]
    jmp .next_line
    
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

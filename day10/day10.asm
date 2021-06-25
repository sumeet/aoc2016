section .data

printf_msg: db "%u", 10, 0
input: incbin "./input"
db 0 ; null terminate the input so we can tell when it's over

; one 2-byte slot for each bot
; lower byte of word is "low"
; higher byte of word is "high"
bot_mapping: times 300 dw 0

%macro match 3-*
; %1: where to jump if match is found
; %2: input cursor
; %3-*: array of "string matcher" macro invocations
  %define match_jmp_point %1
  %define match_input_cursor %2
  %rep (%0-2)
    %rotate 1
    %2, match_input_cursor
    jne %%end
  %endrep
  jmp match_jmp_point
  %undef match_jmp_point
  %undef match_input_cursor
  %%end:
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
%define arg_string_literal %1
%define arg_input_cursor %2
; can use je if string matches otherwise jne
; clobbers: rax, rbx, rcx

  %assign i 1
  %strlen len arg_string_literal
  %rep len
      %substr this_char arg_string_literal i

      mov rcx, i
      mov rbx, this_char

      mov rax, arg_input_cursor
      cmp byte [rax + i - 1], this_char
      jne %%false

      %assign i i+1
  %endrep
  %%true:
      add arg_input_cursor, len

      mov rax, 1
      cmp rax, 1
      jmp %%end
  %%false:
      mov rax, 0
      cmp rax, 1
  %%end:
  
%undef arg_string_literal
%undef arg_input_cursor
%endmacro

%macro consume_number 2
%define arg_into_register %1
%define arg_input_cursor %2
; %2: into register
; can use je if number actually consumed otherwise jne
; clobbers: rax, rbx
%define input_cursor_reg rbx
  mov arg_into_register, 0
  mov input_cursor_reg, arg_input_cursor

  ; first iteration
  cmp_between byte [input_cursor_reg], '0', '9'
  jne %%false

  movzx rax, byte [input_cursor_reg]
  lea arg_into_register, [rax  - '0']
  inc input_cursor_reg

  %%loop:
    cmp_between byte [input_cursor_reg], '0', '9'
    jne %%true ; can now bail with true because we would've already consumed a single number

    times_ten arg_into_register
    movzx rax, byte [input_cursor_reg]
    lea arg_into_register, [arg_into_register + rax - '0']
    inc input_cursor_reg
    jmp %%loop
  %%true:
    mov arg_input_cursor, input_cursor_reg ; save the new input cursor, consuming the number

    mov rax, 1
    cmp rax, 1
    jmp %%end
  %%false:
    mov rax, 0
    cmp rax, 1
  %%end:
%undef input_cursor_reg
%undef arg_into_register
%undef arg_input_cursor
%endmacro

section .text
;; TODO: without libc
global main
extern printf

main:
  %define input_cursor qword [rbp - 8]
  enter 8, 0
    mov input_cursor, input
    .bot_mapping_loop:
      mov rax, input_cursor

      ; jump to the end if we encounter either a newline or null byte
      cmp byte [rax], 0
      je .end_bot_mapping_loop

      %define bot_no r10
      %define low_dest_bot r11
      %define high_dest_bot r12
      match .is_a_bot_mapping, input_cursor, \
        {match_exact_str "bot "}, \
        {consume_number bot_no}, \
        {match_exact_str " gives low to bot "}, \
        {consume_number low_dest_bot}, \
        {match_exact_str " and high to bot "}, \
        {consume_number high_dest_bot}

      jmp .not_a_bot_mapping

      .is_a_bot_mapping:
        mov rax, bot_mapping
        lea rax, [rax + bot_no + bot_no]
        mov byte [rax], low_dest_bot%+b
        mov byte [rax + 1], high_dest_bot%+b

      %undef bot_no
      %undef low_dest_bot
      %undef high_dest_bot

      .not_a_bot_mapping:
        inc input_cursor
        jmp .bot_mapping_loop
    .end_bot_mapping_loop:
    int1
  leave
  %undef input_cursor

; just move the value to print into rsi before jumping here
print:
  mov rdi, printf_msg
  mov rsi, rsi
  mov rax, 0
  call printf
  mov rax, 0
  ret

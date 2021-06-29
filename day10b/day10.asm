section .data

printf_msg: db "%u", 10, 0
input: incbin "./sample"
db 0 ; null terminate the input so we can tell when it's over

NUM_BOTS equ 209
NUM_OUTPUTS equ 20

; one 2-byte slot for each bot
; lower byte of word is "low"
; higher byte of word is "high"
bot_holding: times NUM_BOTS dw 0
; outputs needs to come directly after bot_mapping because bot_holding overflows into it
outputs: times NUM_OUTPUTS dw 0
bot_mapping: times NUM_BOTS dw 0

; clobbers rax
%macro add_bot_holding 2
  %define arg_dest_bot %1
  %define arg_value %2

  mov rax, bot_holding
  lea rax, [rax + arg_dest_bot + arg_dest_bot]
  cmp byte [rax], 0
  je %%add_holding
  add rax, 1
%%add_holding:
  mov byte [rax], arg_value
  

  %undef arg_value
  %undef arg_dest_bot
%endmacro

%macro match 3-*
; %1: where to jump if match is found
; %2: input cursor
; %3-*: array of "string matcher" macro invocations
  %define match_jmp_point %1
  %define match_input_cursor %2

  push match_input_cursor

  %rep (%0-2)
    %rotate 1
    %2, match_input_cursor
    jne %%end
  %endrep

  add rsp, 8 ; we're going to use the modified input_cursor, so no need to reset 
             ; it back to the old value
  jmp match_jmp_point
  %%end:
  pop match_input_cursor
  %undef match_jmp_point
  %undef match_input_cursor
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
extern exit

; just move the value to rsi before calling this
print_and_exit:
  mov rdi, printf_msg
  mov rsi, rsi
  mov rax, 0
  call printf
  mov rax, 0
  mov rdi, 0 
  call exit
value_passing:
; arg: starting_bot passed through rdi
  %define arg_starting_bot rdi

  %define low_val r11
  %define high_val r12

  mov rax, bot_holding
  mov rbx, arg_starting_bot
  lea rax, [rax + rbx + rbx]
  mov low_val%+b, [rax]
  mov high_val%+b, byte [rax + 1]

  cmp low_val, high_val
  jg .swap
  jmp .noswap
    .swap:
      xchg low_val, high_val
    .noswap:

  .set_targets:
    mov rax, bot_mapping
    mov rbx, arg_starting_bot
    lea rax, [rax + rbx + rbx]
    movzx rcx, byte [rax]
    movzx rdx, byte [rax + 1]

    add_bot_holding rcx, low_val%+b
    add_bot_holding rdx, high_val%+b

  ; dup of .determine_is_starting_bot
  .determine_is_starting_bot2: 
    mov rax, bot_holding
    lea rax, [rax + rcx + rcx]
    cmp byte [rax], 0
    je .try_next
    cmp byte [rax + 1], 0
    je .try_next

    mov rdi, rcx
    push rdx
    call value_passing
    pop rdx

  .try_next:
    mov rax, bot_holding
    lea rax, [rax + rdx + rdx]
    cmp byte [rax], 0
    je .end2
    cmp byte [rax + 1], 0
    je .end2

    mov rdi, rdx
    call value_passing

    .end2:
  %undef low_val
  %undef high_val
  ret
main:
  %define input_cursor qword [rbp - 8]
  %define starting_bot qword [rbp - 16]
  enter 16, 0
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

      match .is_an_output_bot_mapping, input_cursor, \
        {match_exact_str "bot "}, \
        {consume_number bot_no}, \
        {match_exact_str " gives low to output "}, \
        {consume_number low_dest_bot}, \
        {match_exact_str " and high to bot "}, \
        {consume_number high_dest_bot}

      match .is_a_bot_output_mapping, input_cursor, \
        {match_exact_str "bot "}, \
        {consume_number bot_no}, \
        {match_exact_str " gives low to bot "}, \
        {consume_number low_dest_bot}, \
        {match_exact_str " and high to output "}, \
        {consume_number high_dest_bot}

      match .is_an_output_output_mapping, input_cursor, \
        {match_exact_str "bot "}, \
        {consume_number bot_no}, \
        {match_exact_str " gives low to output "}, \
        {consume_number low_dest_bot}, \
        {match_exact_str " and high to output "}, \
        {consume_number high_dest_bot}

      jmp .continue

      .is_a_bot_mapping:
        mov rax, bot_mapping
        lea rax, [rax + bot_no + bot_no]
        mov byte [rax], low_dest_bot%+b
        mov byte [rax + 1], high_dest_bot%+b
        jmp .continue

      .is_an_output_bot_mapping:
        add low_dest_bot, NUM_BOTS

        mov rax, bot_mapping
        lea rax, [rax + bot_no + bot_no]
        mov byte [rax], low_dest_bot%+b
        mov byte [rax + 1], high_dest_bot%+b
        jmp .continue

      .is_a_bot_output_mapping:
        add high_dest_bot, NUM_BOTS

        mov rax, bot_mapping
        lea rax, [rax + bot_no + bot_no]
        mov byte [rax], low_dest_bot%+b
        mov byte [rax + 1], high_dest_bot%+b
        jmp .continue

      .is_an_output_output_mapping:
        add low_dest_bot, NUM_BOTS
        add high_dest_bot, NUM_BOTS

        mov rax, bot_mapping
        lea rax, [rax + bot_no + bot_no]
        mov byte [rax], low_dest_bot%+b
        mov byte [rax + 1], high_dest_bot%+b
        jmp .continue

      %undef bot_no
      %undef low_dest_bot
      %undef high_dest_bot

      .continue:
        inc input_cursor
        jmp .bot_mapping_loop
    .end_bot_mapping_loop:

    ; loop the input again from the beginning
    mov input_cursor, input
    .bot_holding_loop:
      mov rax, input_cursor

      ; jump to the end if we encounter either a newline or null byte
      cmp byte [rax], 0
      je .end_bot_holding_loop

      %define value_no r11
      %define dest_bot r12
      match .is_a_bot_holding, input_cursor, \
        {match_exact_str "value "}, \
        {consume_number value_no}, \
        {match_exact_str " goes to bot "}, \
        {consume_number dest_bot}

      jmp .not_a_bot_holding

      .is_a_bot_holding:
        add_bot_holding dest_bot, value_no%+b

      ; there is only one bot in this input that receives two values
      .determine_is_starting_bot:
        mov rax, bot_holding
        lea rax, [rax + dest_bot + dest_bot]
        cmp byte [rax], 0
        je .end
        cmp byte [rax + 1], 0
        je .end

        mov starting_bot, dest_bot
        .end:

      %undef bot_no
      %undef low_dest_bot
      %undef high_dest_bot

      .not_a_bot_holding:
        inc input_cursor
        jmp .bot_holding_loop
    .end_bot_holding_loop:

  mov rdi, starting_bot
  leave
  ;int1
  call value_passing
  %undef input_cursor



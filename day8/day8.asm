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

%macro memcpy 3
; %1: dest addr
; %2: src addr
; %3: num_bytes
  cld
  mov rdi, %1
  mov rsi, %2
  mov rcx, %3
  rep movsb
%endmacro

%macro copy_this_screen_to_next_screen 0
  memcpy [next_screen], [this_screen], TOTAL_WIDTH * TOTAL_HEIGHT
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
  lea %1, [%1 + %1 + %1 + %1 + %1] ; * 5
  lea %1, [%1 + %1] ; * 2
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

      %define x r10
      %define y r11
      %define orig_y r12
      mov orig_y, y
      .outer_loop:
        mov y, orig_y
        .inner_loop:
          mov rax, x
          sub rax, 1 ; because we're indexing by 0 instead of 1
          mov rdx, TOTAL_WIDTH
          mul rdx
          add rax, y
          sub rax, 1
          add rax, [this_screen]

          mov byte [rax], 1

          dec y
          cmp y, 0
          jg .inner_loop
        
        dec x
        cmp x, 0
        jg .outer_loop
      %undef x
      %undef y
      jmp continue_input_loop
    .not_rect:

    .rotate_row:
      match_exact_str input_cursor, "rotate row y="
      jne .not_rotate_row
      consume_number input_cursor, r10
      match_exact_str input_cursor, " by "
      consume_number input_cursor, r11

      copy_this_screen_to_next_screen
      %define y r10
      %define shift_len r11
      %define row_i r12
      mov row_i, 0
      .rotate_loop:
        mov rax, y
        mov rdx, TOTAL_WIDTH
        mul rdx

        add rax, row_i
        ; rbx contains the source
        movzx rbx, byte [this_screen + rax]

        ; set up the dest
        mov rax, y
        add rax, shift_len

        mov rcx, TOTAL_WIDTH
        div rcx

        mov rdx, 0

        mov byte [next_screen + rdx], bl

        inc row_i
        cmp row_i, TOTAL_WIDTH
        jl .rotate_loop
      swap_screens
      %undef row_i
      %undef y
      %undef shift_len
      nop
      
    .not_rotate_row:
    
    
  continue_input_loop:
    inc input_cursor
    jmp input_loop
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
